// Lock Designs login screen for SDDM (Qt 6).
//
// Root-owned, and the only QML the greeter executes besides Omarchy's own
// greeter and the root-owned design snapshot installed next to it. Everything
// that varies comes from theme.conf.user, which the plugin rewrites as the
// user: which mode to show, which design, the theme colors, the font, a copy
// of the wallpaper. Media paths are only honoured inside this theme's own
// current/ folder.
//
// Modes (config.mode):
//   omarchy        Omarchy's stock greeter, loaded from its own theme folder
//   omarchy-theme  the same layout, recolored from the Omarchy theme
//   design         the lock design named in config.design, live
//   anything else  a plain built-in layout on the wallpaper (also the
//                  fallback when a design or Omarchy's greeter cannot load)
import QtQuick
import QtQuick.Effects
import QtMultimedia
import "shim/Commons"
import "shim/Quickshell"

Rectangle {
  id: root
  width: 1920
  height: 1080

  function pick(value, fallback) {
    var s = value === undefined || value === null ? "" : String(value)
    return s.length > 0 ? s : fallback
  }
  readonly property color bg: pick(config.background, "#101315")
  readonly property color fg: pick(config.foreground, "#cacccc")
  readonly property color accent: pick(config.accent, "#cacccc")
  readonly property color mutedColor: pick(config.muted, "#707880")
  readonly property color errorColor: pick(config.urgent, "#a55555")
  readonly property string fontFamily: pick(config.font, "monospace")
  readonly property bool twelveHour: pick(config.twelveHour, "false") === "true"
  readonly property string hostName: pick(config.hostname, "omarchy")
  readonly property string mode: pick(config.mode, "")
  readonly property string omarchyThemeDir: "/usr/share/sddm/themes/omarchy"
  readonly property real u: Math.min(width, height) / 100

  readonly property string currentDir: decodeURIComponent(Qt.resolvedUrl("current/").toString().replace(/^file:\/\//, ""))
  function inCurrent(path) {
    var s = String(path || "")
    return s.length > 0 && s.indexOf(currentDir) === 0 && s.indexOf("..") === -1
  }
  readonly property string wallpaper: inCurrent(config.wallpaper) ? String(config.wallpaper) : ""
  readonly property string designFile: {
    var f = pick(config.design, "")
    return /^[A-Za-z0-9_-]+\.qml$/.test(f) ? f : ""
  }

  property bool designFailed: false
  property bool omarchyFailed: false
  readonly property string effectiveMode: {
    if (mode === "design" && designFile.length > 0 && !designFailed) return "design"
    if (mode === "omarchy" && !omarchyFailed) return "omarchy"
    if (mode === "omarchy-theme") return "omarchy-theme"
    return "builtin"
  }

  function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
  function fileUrl(path) {
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
  }

  // Authentication state, shared by every mode.
  property string currentUser: userModel.lastUser
  property bool failed: false
  property bool busy: false
  property string passwordText: ""
  property string failureMessage: ""
  property int failedAttempts: 0
  readonly property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1) return i
    }
    return sessionModel.lastIndex
  }
  readonly property string sessionName: {
    var idx = sessionIndex
    if (idx < 0 || idx >= sessionModel.rowCount()) return ""
    return (sessionModel.data(sessionModel.index(idx, 0), Qt.DisplayRole) || "").toString()
  }

  property date now: new Date()
  Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

  color: bg

  function attemptWith(text) {
    var pw = String(text || "")
    if (root.busy || pw.length === 0) return
    root.failed = false
    root.failureMessage = ""
    root.busy = true
    sddm.login(root.currentUser, pw, root.sessionIndex)
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.busy = false
      root.failed = true
      root.failedAttempts += 1
      root.failureMessage = "Login failed (" + root.failedAttempts + ")"
      root.passwordText = ""
      password.text = ""
      themedPassword.text = ""
      if (root.effectiveMode === "builtin") password.forceActiveFocus()
      if (root.effectiveMode === "omarchy-theme") themedPassword.forceActiveFocus()
      shake.restart()
    }
    function onLoginSucceeded() { root.busy = false }
  }

  // Feed the stand-in shell singletons the designs read.
  Binding { target: Color; property: "background"; value: root.bg }
  Binding { target: Color; property: "foreground"; value: root.fg }
  Binding { target: Color; property: "accent"; value: root.accent }
  Binding { target: Color; property: "urgent"; value: root.errorColor }
  Binding { target: Color; property: "muted"; value: root.mutedColor }
  Binding { target: Style; property: "fontFamily"; value: root.fontFamily }
  Binding { target: Quickshell; property: "userName"; value: root.currentUser }
  Binding { target: Quickshell; property: "hostName"; value: root.hostName }

  // ---- mode: omarchy, the stock greeter itself --------------------------
  Loader {
    id: omarchyLoader
    anchors.fill: parent
    active: root.mode === "omarchy" && !root.omarchyFailed
    source: active ? "file://" + root.omarchyThemeDir + "/Main.qml" : ""
    onStatusChanged: if (status === Loader.Error) root.omarchyFailed = true
  }

  // ---- mode: omarchy-theme, the stock layout in theme colors ------------
  component Tinted: Item {
    property url source
    property color tint: root.fg
    implicitWidth: img.implicitWidth
    implicitHeight: img.implicitHeight
    Image { id: img; anchors.fill: parent; source: parent.source; fillMode: Image.PreserveAspectFit; visible: false }
    MultiEffect { anchors.fill: img; source: img; colorization: 1.0; colorizationColor: parent.tint }
  }
  Item {
    anchors.fill: parent
    visible: root.effectiveMode === "omarchy-theme"

    Column {
      anchors.centerIn: parent
      spacing: 40

      Tinted {
        id: themedLogo
        anchors.horizontalCenter: parent.horizontalCenter
        source: "file://" + root.omarchyThemeDir + "/logo.png"
        width: Math.min(implicitWidth, root.width * 0.8)
        height: implicitWidth > 0 ? Math.round(width * implicitHeight / implicitWidth) : 0
        tint: root.fg
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 15

        Tinted {
          anchors.verticalCenter: parent.verticalCenter
          source: "file://" + root.omarchyThemeDir + "/lock.png"
          width: 34
          height: 38
          tint: root.failed ? root.errorColor : root.fg
        }

        Item {
          width: themedEntry.implicitWidth
          height: themedEntry.implicitHeight

          Tinted {
            id: themedEntry
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            source: "file://" + root.omarchyThemeDir + "/entry.png"
            tint: root.failed ? root.errorColor : root.fg
          }

          Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Repeater {
              model: Math.min(themedPassword.text.length, 21)
              Tinted {
                width: 7
                height: 7
                source: "file://" + root.omarchyThemeDir + "/bullet.png"
                tint: root.fg
              }
            }
          }

          TextInput {
            id: themedPassword
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            font.family: root.fontFamily
            font.pixelSize: 24
            font.letterSpacing: 5
            passwordCharacter: "•"
            color: "transparent"
            selectionColor: "transparent"
            selectedTextColor: "transparent"
            cursorDelegate: Item {}
            enabled: !root.busy
            onTextChanged: root.failed = false
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.attemptWith(text); event.accepted = true }
              else if (event.key === Qt.Key_Escape) { text = ""; event.accepted = true }
            }
          }
        }
      }
    }
    MouseArea {
      anchors.fill: parent
      z: -1
      onClicked: themedPassword.forceActiveFocus()
    }
  }

  // ---- mode: design, the lock design running live ----------------------
  Loader {
    id: designLoader
    anchors.fill: parent
    active: root.mode === "design" && root.designFile.length > 0 && !root.designFailed
    source: active ? Qt.resolvedUrl("designs/" + root.designFile) : ""
    onLoaded: {
      var it = item
      it.inputEnabled = true
      it.loadBackground = true
      if (it.videoPlaying !== undefined) it.videoPlaying = true
      if (it.displayFont !== undefined) it.displayFont = root.fontFamily
      if (it.twelveHour !== undefined) it.twelveHour = root.twelveHour
      it.backgroundPath = Qt.binding(function() { return root.wallpaper })
      it.passwordText = Qt.binding(function() { return root.passwordText })
      it.failureMessage = Qt.binding(function() { return root.failureMessage })
      it.failedAttempts = Qt.binding(function() { return root.failedAttempts })
      it.authenticatingPassword = Qt.binding(function() { return root.busy })
      if (typeof it.forcePasswordFocus === "function") Qt.callLater(it.forcePasswordFocus)
    }
    onStatusChanged: {
      if (status === Loader.Error) {
        console.warn("lock-designs greeter: the design could not be loaded, showing the built-in layout")
        root.designFailed = true
      }
    }
  }
  Connections {
    target: designLoader.item
    ignoreUnknownSignals: true
    function onSubmitPassword(pw) { root.attemptWith(pw) }
    function onPasswordTextEdited(t) { root.passwordText = t }
    function onClearFailureRequested() { root.failureMessage = "" }
  }

  // ---- built-in layout, and the fallback -------------------------------
  Item {
    anchors.fill: parent
    visible: root.effectiveMode === "builtin"

    Image {
      id: wall
      anchors.fill: parent
      visible: root.wallpaper.length > 0
      source: visible ? root.fileUrl(root.wallpaper) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      sourceSize.width: width
      sourceSize.height: height
    }
    MultiEffect {
      anchors.fill: wall
      source: wall
      visible: wall.visible && wall.status === Image.Ready
      autoPaddingEnabled: false
      blurEnabled: true
      blur: 1.0
      blurMax: 96
      blurMultiplier: 1.2
      contrast: -0.06
    }
    Rectangle { anchors.fill: parent; color: root.withAlpha(root.bg, 0.35) }

    MouseArea { anchors.fill: parent; onClicked: password.forceActiveFocus() }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(root.height * 0.16)
      spacing: Math.round(root.u * 1.2)
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(root.now, root.twelveHour ? "h:mm AP" : "HH:mm")
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.u * 14)
        font.weight: Font.Light
        font.letterSpacing: root.u * 0.4
        renderType: Text.CurveRendering
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(root.now, "dddd, d MMMM")
        color: root.withAlpha(root.fg, 0.7)
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.u * 1.7)
        font.letterSpacing: 2
      }
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(root.height * 0.52)
      spacing: Math.round(root.u * 1.6)
      transform: Translate { id: nudge }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(root.u * 9)
        height: width
        radius: width / 2
        color: root.accent
        Text {
          anchors.centerIn: parent
          text: root.currentUser.length > 0 ? root.currentUser.charAt(0).toUpperCase() : "?"
          color: root.bg
          font.family: root.fontFamily
          font.pixelSize: Math.round(parent.height * 0.5)
          font.weight: Font.Bold
        }
      }

      TextInput {
        id: userField
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(root.u * 30)
        text: root.currentUser
        color: root.fg
        horizontalAlignment: TextInput.AlignHCenter
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.u * 2)
        selectionColor: root.withAlpha(root.accent, 0.45)
        selectedTextColor: root.fg
        onTextChanged: root.currentUser = text
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
            password.forceActiveFocus()
            event.accepted = true
          }
        }
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(root.u * 30)
        height: Math.round(root.u * 4.6)
        radius: Math.round(root.u * 0.9)
        color: root.withAlpha(root.bg, 0.8)
        border.width: 2
        border.color: root.failed ? root.errorColor : root.accent

        Text {
          anchors.left: parent.left
          anchors.leftMargin: root.u * 1.4
          anchors.verticalCenter: parent.verticalCenter
          text: root.busy ? "󰔟" : (root.failed ? "󰍁" : "󰌾")
          color: root.failed ? root.errorColor : root.withAlpha(root.fg, 0.6)
          font.family: root.fontFamily
          font.pixelSize: Math.round(root.u * 1.9)
        }
        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: root.u * 4
          anchors.rightMargin: root.u * 4
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          echoMode: TextInput.Password
          passwordCharacter: "●"
          passwordMaskDelay: 0
          color: root.accent
          selectionColor: root.withAlpha(root.accent, 0.45)
          selectedTextColor: root.bg
          font.family: root.fontFamily
          font.pixelSize: text.length > 0 ? Math.round(root.u * 2.2) : Math.round(root.u * 1.8)
          font.letterSpacing: text.length > 0 ? 3 : 0
          enabled: !root.busy
          cursorVisible: activeFocus && text.length > 0
          cursorDelegate: Rectangle { width: 2; color: root.accent; visible: password.cursorVisible }
          onTextChanged: if (text.length > 0) root.failed = false
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.attemptWith(text); event.accepted = true }
            else if (event.key === Qt.Key_Escape) { text = ""; event.accepted = true }
            else if (event.key === Qt.Key_Up) { userField.forceActiveFocus(); userField.selectAll(); event.accepted = true }
          }
        }
        Text {
          anchors.fill: password
          visible: password.text.length === 0
          text: root.busy ? "Checking…" : (root.failed ? "Wrong password" : "Enter password")
          color: root.busy ? root.fg : (root.failed ? root.errorColor : root.withAlpha(root.fg, 0.55))
          font.family: root.fontFamily
          font.pixelSize: Math.round(root.u * 1.8)
          font.italic: root.failed && !root.busy
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.sessionName
        color: root.withAlpha(root.fg, 0.4)
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.u * 1.3)
        font.letterSpacing: 2
      }
    }
  }

  SequentialAnimation {
    id: shake
    NumberAnimation { target: nudge; property: "x"; from: 0; to: -10; duration: 45 }
    NumberAnimation { target: nudge; property: "x"; from: -10; to: 8; duration: 65 }
    NumberAnimation { target: nudge; property: "x"; from: 8; to: -5; duration: 55 }
    NumberAnimation { target: nudge; property: "x"; from: -5; to: 0; duration: 45 }
  }

  // User chooser, bottom left: the current account, and a list of the others
  // when there is more than one. Omarchy's own greeter is shown as it ships.
  property bool userMenuOpen: false
  Item {
    visible: root.effectiveMode !== "omarchy"
    z: 10
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: Math.round(root.u * 3)
    width: userChip.width
    height: userChip.height

    Rectangle {
      id: userChip
      width: userLabel.implicitWidth + Math.round(root.u * 3)
      height: userLabel.implicitHeight + Math.round(root.u * 1.4)
      radius: height / 2
      color: root.withAlpha(root.bg, 0.55)
      border.width: 1
      border.color: root.withAlpha(root.fg, userChipHover.containsMouse || root.userMenuOpen ? 0.5 : 0.2)
      Text {
        id: userLabel
        anchors.centerIn: parent
        text: "󰀄  " + (root.currentUser.length > 0 ? root.currentUser : "user") + (userModel.rowCount() > 1 ? "  ▴" : "")
        color: root.withAlpha(root.fg, 0.8)
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.u * 1.4)
      }
      MouseArea {
        id: userChipHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: userModel.rowCount() > 1
        onClicked: root.userMenuOpen = !root.userMenuOpen
      }
    }

    Rectangle {
      visible: root.userMenuOpen
      anchors.left: parent.left
      anchors.bottom: userChip.top
      anchors.bottomMargin: Math.round(root.u * 0.8)
      width: Math.max(userChip.width, userList.implicitWidth + Math.round(root.u * 2))
      height: userList.implicitHeight + Math.round(root.u * 1.2)
      radius: Math.round(root.u * 0.8)
      color: root.withAlpha(root.bg, 0.92)
      border.width: 1
      border.color: root.withAlpha(root.fg, 0.25)
      Column {
        id: userList
        anchors.centerIn: parent
        Repeater {
          model: userModel
          delegate: Rectangle {
            id: userRow
            required property string name
            required property string realName
            width: userList.width
            height: Math.round(root.u * 3.2)
            radius: Math.round(root.u * 0.5)
            color: rowHover.containsMouse ? root.withAlpha(root.fg, 0.08) : "transparent"
            Text {
              anchors.left: parent.left
              anchors.leftMargin: Math.round(root.u * 1)
              anchors.verticalCenter: parent.verticalCenter
              text: userRow.name + (userRow.realName.length > 0 && userRow.realName !== userRow.name ? "  ·  " + userRow.realName : "")
              color: userRow.name === root.currentUser ? root.accent : root.fg
              font.family: root.fontFamily
              font.pixelSize: Math.round(root.u * 1.4)
            }
            MouseArea {
              id: rowHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.currentUser = userRow.name
                root.userMenuOpen = false
                root.passwordText = ""
                if (root.effectiveMode === "builtin") password.forceActiveFocus()
                else if (root.effectiveMode === "omarchy-theme") themedPassword.forceActiveFocus()
                else if (designLoader.item && typeof designLoader.item.forcePasswordFocus === "function") designLoader.item.forcePasswordFocus()
              }
            }
          }
        }
      }
    }
  }

  // Power controls, bottom right, in every mode except Omarchy's own, which
  // is shown exactly as it ships.
  Row {
    visible: root.effectiveMode !== "omarchy"
    z: 10
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Math.round(root.u * 3)
    spacing: Math.round(root.u * 2.4)
    Repeater {
      model: [
        { glyph: "󰤄", label: "Sleep", can: sddm.canSuspend, act: function() { sddm.suspend() } },
        { glyph: "󰜉", label: "Restart", can: sddm.canReboot, act: function() { sddm.reboot() } },
        { glyph: "󰐥", label: "Shut down", can: sddm.canPowerOff, act: function() { sddm.powerOff() } }
      ]
      delegate: Column {
        required property var modelData
        visible: modelData.can !== false
        spacing: Math.round(root.u * 0.5)
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData.glyph
          color: hover.containsMouse ? root.fg : root.withAlpha(root.fg, 0.5)
          font.family: root.fontFamily
          font.pixelSize: Math.round(root.u * 2.6)
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData.label
          color: root.withAlpha(root.fg, 0.4)
          font.family: root.fontFamily
          font.pixelSize: Math.round(root.u * 1.1)
        }
        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: modelData.act()
        }
      }
    }
  }

  Component.onCompleted: {
    if (root.effectiveMode === "builtin") password.forceActiveFocus()
    else if (root.effectiveMode === "omarchy-theme") themedPassword.forceActiveFocus()
  }
}

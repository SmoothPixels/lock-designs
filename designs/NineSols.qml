// source: qylock
// Faithful port of Darkkal44's qylock "ninesols" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The QML is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source, and drops the SDDM-specific multi-user/session/restart/shutdown
// menu rows in favor of the shared single password field — "Start Game"
// stays as the unlock action, matching the source's game-menu conceit.
// The source has no clock or date anywhere in its menu; a small one is
// added under the logo so this still reads as an Omarchy lock screen. The
// source's bundled DejaVuSans font tested clean at UI sizes (every glyph
// in "THE QUICK BROWN FOX WELCOME" unambiguous) so it is used throughout,
// matching the original.
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("ninesols-assets/")

  // Original qylock palette: near-black backdrop, muted gold menu text.
  property color goldActive: "#dfd59c"
  property color goldDim: "#6a6245"
  property color barDim: "#3a3525"

  readonly property bool startActive: passwordInput.text.length === 0 && !lock.errorState
  readonly property bool pwdActive: passwordInput.activeFocus

  FontLoader {
    id: dejavuFont
    source: lock.assetsUrl + "font/DejaVuSans.ttf"
  }

  Rectangle { anchors.fill: parent; color: "#050608" }

  // The source bg.png is only 1080x607, stretched edge-to-edge that is a
  // 3x+ upscale on a 4K display and looks visibly soft/pixelated. A light
  // blur turns that softness into an intentional-looking background blur
  // instead of a broken-looking low-res stretch.
  Image {
    id: bgImage
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "bg.png" : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }
  MultiEffect {
    anchors.fill: bgImage
    source: bgImage
    blurEnabled: true
    blur: 0.35
    blurMax: 32
  }

  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: parent.width * 0.45
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "#e6050608" }
      GradientStop { position: 0.6; color: "#b3050608" }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Image {
    id: logo
    source: lock.assetsUrl + "logo.png"
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: 100
    anchors.leftMargin: 120
    width: 220
    height: width * (implicitHeight / implicitWidth)
    fillMode: Image.PreserveAspectFit
  }

  Column {
    id: infoCol
    anchors.top: logo.bottom
    anchors.left: logo.left
    anchors.topMargin: 24
    spacing: 2

    Text {
      text: lock.clock("HH:mm")
      color: lock.goldActive
      font.family: dejavuFont.name
      font.pixelSize: 34
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd, MMMM d")
      color: lock.goldDim
      font.family: dejavuFont.name
      font.pixelSize: 13
      font.letterSpacing: 1
    }
    Text {
      text: lock.userName.toUpperCase()
      color: lock.goldDim
      font.family: dejavuFont.name
      font.pixelSize: 13
      font.letterSpacing: 1
    }
  }

  Column {
    id: menuCol
    // Was independently anchored to logo.bottom with a fixed topMargin
    // that assumed infoCol was always exactly 2 lines tall. Adding the
    // username as a 3rd line grew infoCol past that fixed margin and
    // it started overlapping "Start Game". Anchoring to infoCol's own
    // bottom instead means this never goes stale again if infoCol's
    // height changes.
    anchors.top: infoCol.bottom
    anchors.left: logo.left
    anchors.topMargin: 30
    spacing: 16

    // Start Game — submits the typed password.
    Item {
      width: 320
      height: 24
      Row {
        spacing: 12
        anchors.verticalCenter: parent.verticalCenter
        x: lock.startActive ? (startMa.pressed ? -6 : 0) : 24
        scale: startMa.pressed ? 0.96 : 1.0
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
        Text { text: "|"; color: lock.startActive ? lock.goldActive : lock.barDim; opacity: lock.startActive ? 1.0 : 0.45; font.family: dejavuFont.name; font.pixelSize: 18 }
        Text { text: lock.authenticatingPassword ? "Checking…" : "Start Game"; color: lock.startActive ? lock.goldActive : lock.goldDim; font.family: dejavuFont.name; font.pixelSize: 18 }
      }
      MouseArea {
        id: startMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          var submitted = lock.passwordText
          if (submitted.length > 0) { lock.passwordTextEdited(""); lock.submitPassword(submitted) }
          else lock.forcePasswordFocus()
        }
      }
    }

    // Password entry.
    Item {
      width: 320
      height: 24
      Row {
        spacing: 12
        anchors.verticalCenter: parent.verticalCenter
        x: lock.pwdActive ? 0 : 24
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Text { text: "|"; color: lock.pwdActive ? lock.goldActive : lock.barDim; opacity: lock.pwdActive ? 1.0 : 0.45; font.family: dejavuFont.name; font.pixelSize: 18 }
        Text { text: passwordInput.text.length === 0 && !lock.pwdActive ? "Enter Password" : ""; color: lock.pwdActive ? lock.goldActive : lock.goldDim; font.family: dejavuFont.name; font.pixelSize: 18 }
      }
      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        leftPadding: lock.pwdActive ? 24 : 48
        Behavior on leftPadding { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        verticalAlignment: TextInput.AlignVCenter
        color: lock.goldActive
        font.family: dejavuFont.name
        font.pixelSize: 18
        passwordCharacter: "•"
        selectionColor: lock.goldDim
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle { width: 2; color: lock.goldActive; visible: passwordInput.cursorVisible }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: lock.forcePasswordFocus()
      }
    }
  }

  Text {
    anchors.top: menuCol.bottom
    anchors.left: menuCol.left
    anchors.topMargin: 20
    text: lock.errorState ? "AUTHENTICATION FAILED" : ""
    color: "#df5050"
    font.family: dejavuFont.name
    font.pixelSize: 14
    font.letterSpacing: 2
    opacity: text.length > 0 ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }
  }

  Row {
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.margins: 40
    spacing: 24

    Row {
      spacing: 8
      Rectangle {
        width: 22; height: 22; radius: 11
        color: "#0c0d10"; border.color: "#ffffff"; border.width: 1.5
        Text { anchors.centerIn: parent; text: "A"; color: "#76e82a"; font.bold: true; font.pixelSize: 11 }
      }
      Text { text: "CONFIRM"; color: "#e3e4e6"; font.family: dejavuFont.name; font.pixelSize: 12; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
      spacing: 8
      Rectangle {
        width: 22; height: 22; radius: 11
        color: "#0c0d10"; border.color: "#ffffff"; border.width: 1.5
        Text { anchors.centerIn: parent; text: "B"; color: "#f23c34"; font.bold: true; font.pixelSize: 11 }
      }
      Text { text: "CLEAR"; color: "#e3e4e6"; font.family: dejavuFont.name; font.pixelSize: 12; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
    }
  }
}

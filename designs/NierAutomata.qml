// source: qylock
// Faithful port of Darkkal44's qylock "nier-automata" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The QML is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source. The original is an elaborate ~1100-line SDDM HUD full of
// decorative-only panels (HP bar, hardware monitor, satellite link,
// multi-user list, session dropdown, power/reboot row); this port keeps
// the pieces that read as "NieR Automata" at a glance — the khaki HUD
// palette, top tab bar with LOGIN highlighted, bottom status/key-hint
// bar, the "LOGIN" heading with its authentication box, and the centered
// system-time readout — and drops the rest along with the SDDM-only
// multi-user/session/power row (Omarchy handles that elsewhere) in favor
// of the shared single password field. The source ships no font (font/ is
// an empty .gitkeep placeholder), so every label uses the shell's normal
// font.
import QtQuick
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("nier-automata-assets/")

  // Original qylock khaki HUD palette.
  property color nierBg: "#c0bc9e"
  property color nierDarker: "#1a1814"
  property color nierBorder: "#706c58"
  property color nierAccent: "#d0cca8"
  property color nierText: "#2a2820"
  property color nierTextMid: "#706c58"
  property color nierSelected: "#3e3c33"

  property real scanPos: 0
  NumberAnimation { target: lock; property: "scanPos"; from: 0; to: 1; duration: 4000; loops: Animation.Infinite; running: true }

  Rectangle { anchors.fill: parent; color: lock.nierBg }

  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "bg.png" : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    opacity: 0.92
  }

  Canvas {
    anchors.fill: parent
    opacity: 0.05
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.strokeStyle = "#000000"
      ctx.lineWidth = 1
      for (var y = 0; y < height; y += 3) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke() }
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: lock.nierAccent
    opacity: 0.2
    y: lock.scanPos * parent.height
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  function triRow(ctx, w, yTop, yBot) {
    ctx.fillStyle = "#524e3e"
    var step = 10
    var count = Math.floor(w / step)
    var triSize = 3
    for (var i = 0; i < count; i++) {
      var x = i * step + 2
      ctx.beginPath(); ctx.moveTo(x, yTop); ctx.lineTo(x + triSize, yTop); ctx.lineTo(x + triSize / 2, yTop + triSize); ctx.fill()
      ctx.beginPath(); ctx.moveTo(x, yBot); ctx.lineTo(x + triSize, yBot); ctx.lineTo(x + triSize / 2, yBot - triSize); ctx.fill()
    }
  }

  // Top header bar with tab row (LOGIN highlighted).
  Rectangle {
    id: topBar
    width: parent.width
    height: 40
    color: lock.nierDarker

    Canvas { anchors.fill: parent; onPaint: lock.triRow(getContext("2d"), width, 5, 35) }

    Row {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 10
      spacing: 0
      Repeater {
        model: ["MAP", "QUESTS", "ITEMS", "WEAPONS", "LOGIN", "INTEL", "SYSTEM"]
        Rectangle {
          property bool isActive: modelData === "LOGIN"
          width: tabText.implicitWidth + 20
          height: topBar.height
          color: isActive ? lock.nierSelected : "transparent"
          border.color: isActive ? lock.nierBorder : "transparent"
          border.width: isActive ? 1 : 0
          Text {
            id: tabText
            anchors.centerIn: parent
            text: modelData
            font.family: Style.font.family
            font.pixelSize: 10
            font.letterSpacing: 2
            color: parent.isActive ? lock.nierAccent : lock.nierBorder
          }
        }
      }
    }
  }

  // Bottom status bar with key hints.
  Rectangle {
    id: botBar
    width: parent.width
    height: 36
    anchors.bottom: parent.bottom
    color: lock.nierDarker

    Canvas { anchors.fill: parent; onPaint: lock.triRow(getContext("2d"), width, 3, 33) }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 14
      text: lock.errorState ? lock.failureMessage : "Enter credentials to proceed."
      font.family: Style.font.family
      font.pixelSize: 11
      color: lock.errorState ? "#ff4444" : lock.nierAccent
    }

    Row {
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: 14
      spacing: 12
      Repeater {
        model: [ { k: "Enter", l: "Confirm" }, { k: "Esc", l: "Clear" } ]
        Row {
          spacing: 4
          anchors.verticalCenter: parent.verticalCenter
          Rectangle {
            height: 15
            width: chip.implicitWidth + 8
            color: "#2c2a24"
            border.color: lock.nierBorder
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter
            Text { id: chip; anchors.centerIn: parent; text: modelData.k; font.family: Style.font.family; font.pixelSize: 9; color: lock.nierAccent }
          }
          Text { text: modelData.l; font.family: Style.font.family; font.pixelSize: 10; color: lock.nierBorder; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }
  }

  Item {
    anchors.top: topBar.bottom
    anchors.bottom: botBar.top
    anchors.left: parent.left
    anchors.right: parent.right

    // Left column: LOGIN heading + authentication box.
    Item {
      id: leftPanel
      anchors.top: parent.top; anchors.topMargin: 60
      anchors.left: parent.left; anchors.leftMargin: 70
      width: 330

      Text {
        text: "SYSTEM ACCESS"
        font.family: Style.font.family
        font.pixelSize: 8
        font.letterSpacing: 2
        color: lock.nierTextMid
        rotation: -90
        anchors.right: parent.left
        anchors.rightMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 40
      }

      Item {
        id: heading
        width: parent.width
        height: 42
        Text {
          text: "LOGIN"
          font.family: Style.font.family
          font.pixelSize: 32
          font.letterSpacing: 4
          font.bold: true
          color: lock.nierText
          anchors.bottom: parent.bottom
          anchors.left: parent.left
        }
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: lock.nierBorder }
      }

      Text {
        anchors.top: heading.bottom
        anchors.topMargin: 16
        text: lock.userName.toUpperCase()
        font.family: Style.font.family
        font.pixelSize: 16
        font.letterSpacing: 1
        color: lock.nierText
      }

      Rectangle {
        id: authBox
        anchors.top: heading.bottom
        anchors.topMargin: 56
        width: parent.width
        height: 60
        color: "transparent"
        border.color: lock.nierBorder
        border.width: 1

        Rectangle {
          id: authHdr
          width: parent.width
          height: 24
          color: lock.nierText
          Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "Authentication"; font.family: Style.font.family; font.pixelSize: 12; font.letterSpacing: 1.5; color: lock.nierAccent }
        }

        Rectangle {
          anchors.top: authHdr.bottom
          anchors.topMargin: 8
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.right: parent.right
          anchors.rightMargin: 12
          height: 20
          color: passwordInput.activeFocus ? "#2c2a24" : "#201f1a"
          border.color: lock.errorState ? "#ff4444" : (passwordInput.activeFocus ? lock.nierAccent : lock.nierBorder)
          border.width: 1

          LockInput {
            id: passwordInput
            lock: lock
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.font.family
            font.pixelSize: 13
            font.letterSpacing: 4
            color: lock.nierAccent
            passwordCharacter: "■"
            selectionColor: lock.nierAccent
            cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
            cursorDelegate: Rectangle { width: 8; height: 2; color: lock.nierAccent; visible: passwordInput.cursorVisible }
          }

          Text {
            anchors.left: passwordInput.left
            anchors.verticalCenter: parent.verticalCenter
            text: lock.authenticatingPassword ? "Verifying…" : "Passphrase..."
            opacity: passwordInput.text.length === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
            color: lock.nierBorder
            font.family: Style.font.family
            font.pixelSize: 11
            font.letterSpacing: 1.5
          }
        }
      }
    }

    // Right column: centered system-time readout.
    Column {
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: 220
      spacing: 2

      Text {
        text: "SYSTEM TIME // DATA SYNC"
        font.family: Style.font.family
        font.pixelSize: 9
        color: lock.nierAccent
        font.letterSpacing: 1
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0.7
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: lock.clock("hh:mm")
        font.family: Style.font.family
        font.pixelSize: 46
        font.letterSpacing: 2
        color: lock.nierText
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(lock.now, "yyyy.MM.dd")
        font.family: Style.font.family
        font.pixelSize: 12
        font.letterSpacing: 4
        color: lock.nierTextMid
      }
      Item { width: 1; height: 16 }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "[ NieR:Automata ]"
        font.family: Style.font.family
        font.pixelSize: 20
        font.letterSpacing: 6
        color: lock.nierText
        opacity: 0.85
      }
    }
  }
}

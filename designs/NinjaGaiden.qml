// source: qylock
// Original design inspired by Darkkal44's qylock "ninja_gaiden" theme
// (github.com/Darkkal44/qylock, GPL-3.0). Bundles the source's bg.png and
// its Tektur variable-weight font (bundled alongside this file in
// ninja-gaiden-assets/) for a true-to-source cyberpunk-ninja look. The QML
// itself is written from scratch against Omarchy's DesignBase/LockInput,
// not copied from qylock's GPL source, and drops the SDDM-specific
// multi-user/session/reboot/shutdown menu (Omarchy handles auth elsewhere)
// in favor of the shared single password field.
//
// Tektur was rendered directly (independent of Qt) against the full
// "THE QUICK BROWN FOX JUMPS OVER LAZY DOG" pangram and every glyph came
// back unambiguous, so unlike PixelifySans it is safe to use for word
// labels too, not just the clock.
import QtQuick
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("ninja-gaiden-assets/")

  // Original qylock palette.
  property color backing: "#0d0003"
  property color fg: "#ffffff"
  property color fgDim: "#4a4a4a"
  property color red: "#cc0020"

  FontLoader {
    id: tekturFont
    source: lock.assetsUrl + "font/Tektur-VariableFont.ttf"
  }

  Rectangle { anchors.fill: parent; color: lock.backing }

  Image {
    id: bg
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "bg.png" : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    smooth: true
  }

  Rectangle { anchors.fill: parent; color: lock.backing; opacity: 0.35 }

  // Rising embers, matching the source's particle field.
  Repeater {
    model: 20
    Rectangle {
      id: ember
      property real startX: Math.random() * lock.width
      property real dur: 9000 + Math.random() * 9000
      property real sz: (1 + Math.random() * 2)
      x: startX
      y: lock.height + 10
      width: sz; height: sz
      radius: width / 2
      color: lock.red
      opacity: 0
      SequentialAnimation {
        running: true
        loops: Animation.Infinite
        PauseAnimation { duration: Math.random() * 6000 }
        ParallelAnimation {
          NumberAnimation { target: ember; property: "y"; from: lock.height + 10; to: -20; duration: ember.dur }
          SequentialAnimation {
            NumberAnimation { target: ember; property: "opacity"; from: 0; to: 0.5; duration: ember.dur * 0.3 }
            PauseAnimation { duration: ember.dur * 0.4 }
            NumberAnimation { target: ember; property: "opacity"; to: 0; duration: ember.dur * 0.3 }
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Top-right HUD: status blip, clock, red divider, date badge.
  Item {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 50
    width: 340
    height: 70

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 15

      Text {
        text: lock.clock("HH:mm")
        color: lock.fg
        font.family: tekturFont.name
        font.pixelSize: 32
        font.letterSpacing: 4
        anchors.bottom: parent.bottom
      }

      Rectangle { width: 2; height: 30; color: lock.red; anchors.bottom: parent.bottom }

      Column {
        anchors.bottom: parent.bottom
        spacing: 2
        Text {
          text: "SYS // DATE"
          color: lock.fgDim
          font.family: tekturFont.name
          font.pixelSize: 8
          font.letterSpacing: 2
        }
        Text {
          text: Qt.formatDate(lock.now, "yyyy.MM.dd")
          color: lock.red
          font.family: tekturFont.name
          font.pixelSize: 12
          font.letterSpacing: 2
        }
      }
    }
  }

  // Bottom-right terminal status readout.
  Column {
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.margins: 50
    spacing: 6

    Rectangle {
      width: 200; height: 1
      color: lock.red
      opacity: 0.5
      anchors.right: parent.right
    }
    Text {
      text: "FIRMWARE VER 2.4.11"
      color: lock.fgDim
      font.family: tekturFont.name
      font.pixelSize: 9
      font.letterSpacing: 2
      anchors.right: parent.right
    }
    Text {
      text: "UNAUTHORIZED ACCESS PROHIBITED"
      color: lock.red
      font.family: tekturFont.name
      font.pixelSize: 9
      font.letterSpacing: 1
      anchors.right: parent.right
      SequentialAnimation on opacity {
        loops: Animation.Infinite
        NumberAnimation { to: 0.25; duration: 900 }
        NumberAnimation { to: 0.75; duration: 900 }
      }
    }
  }

  // Password field, styled after the source's bordered passcode row.
  Item {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 40
    width: 360
    height: 44

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.top
      anchors.bottomMargin: 8
      visible: lock.errorState
      text: "ACCESS DENIED"
      color: lock.red
      font.family: tekturFont.name
      font.pixelSize: 11
      font.letterSpacing: 2
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.top
      anchors.bottomMargin: 30
      text: "USER // " + lock.userName.toUpperCase()
      color: lock.fgDim
      font.family: tekturFont.name
      font.pixelSize: 11
      font.letterSpacing: 2
    }

    Rectangle {
      anchors.fill: parent
      color: lock.backing
      opacity: 0.7
      border.color: lock.red
      border.width: 1
    }

    LockInput {
      id: passwordInput
      lock: lock
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      verticalAlignment: TextInput.AlignVCenter
      color: lock.fg
      passwordCharacter: "▪"
      font.family: tekturFont.name
      font.pixelSize: 14
      font.letterSpacing: 3
      selectionColor: lock.red
      cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
      cursorDelegate: Rectangle {
        width: 2
        color: lock.red
        visible: passwordInput.cursorVisible
      }
    }

    Text {
      anchors.left: passwordInput.left
      anchors.verticalCenter: passwordInput.verticalCenter
      text: "ENTER PASSCODE..."
      color: lock.fgDim
      font.family: tekturFont.name
      font.pixelSize: 11
      font.letterSpacing: 2
      opacity: passwordInput.text.length === 0 ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 400 } }
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 28
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "TOUCH SENSOR OR TYPE PASSCODE" : "TYPE PASSCODE · ENTER TO UNLOCK"
    color: lock.withAlpha(lock.fgDim, 0.8)
    font.family: tekturFont.name
    font.pixelSize: 10
    font.letterSpacing: 2
  }
}

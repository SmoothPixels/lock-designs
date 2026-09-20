// source: qylock
// Original design inspired by Darkkal44's qylock "pixel-emerald" theme
// (github.com/Darkkal44/qylock, GPL-3.0), styled after a certain
// Game-Boy-era monster-trainer RPG's menu chrome. Bundles the source's
// bg.mp4 and its PixelifySans-Bold font (bundled alongside this file in
// pixel-emerald-assets/) for a true-to-source look. The QML itself is
// written from scratch against Omarchy's DesignBase/LockInput, not copied
// from qylock's GPL source, and drops the SDDM-specific multi-user/
// session/reboot/shutdown widgets (Omarchy handles auth elsewhere) in
// favor of the shared single password field.
//
// PixelifySans-Bold's capital "C" was found to render nearly fully closed
// at UI text sizes (verified directly against the font file, independent
// of Qt) -- confirmed during the pixel-cyberpunk port -- so it stays on
// the big clock, where digits are unambiguous, and every word label below
// (including "CHRONO INTERFACE" and "ACCESS", both of which have a C)
// uses the shell's normal font instead.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-emerald-assets/")

  // Original qylock palette.
  property color emerald: "#3ec878"
  property color emeraldDark: "#1a6e3c"
  property color gold: "#f0c040"
  property color cardBg: "#d8f5e8"
  property color inkDark: "#1a2e1a"
  property color inkMid: "#2a6040"
  property color accentRed: "#d44040"
  property color accentBlue: "#4080d0"

  FontLoader { id: pixelFont; source: lock.assetsUrl + "font/PixelifySans-Bold.ttf" }

  Rectangle { anchors.fill: parent; color: "#2ab8b8" }

  MediaPlayer {
    id: bgPlayer
    source: lock.loadBackground ? lock.assetsUrl + "bg.mp4" : ""
    videoOutput: bgVideo
    loops: MediaPlayer.Infinite
    autoPlay: true
    Component.onCompleted: if (!lock.videoPlaying) pause()
  }

  // Only the grid cell actually on screen decodes video; every other
  // cell (and the many now in the Third Party tab) stays paused on
  // whatever frame it already has, so scrolling the picker doesn't
  // spin up dozens of concurrent decoders.
  Connections {
    target: lock
    function onVideoPlayingChanged() { if (lock.videoPlaying) bgPlayer.play(); else bgPlayer.pause() }
  }
  VideoOutput {
    id: bgVideo
    anchors.fill: parent
    fillMode: VideoOutput.PreserveAspectCrop
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock card, top-left.
  Item {
    anchors.top: parent.top; anchors.left: parent.left
    anchors.margins: 44
    width: 250; height: 90

    Rectangle { width: parent.width; height: parent.height; x: 3; y: 4; radius: 7; color: "#60000000"; z: -1 }

    Rectangle {
      id: clockCard
      width: 250; height: 90
      color: lock.cardBg; radius: 6
      border.color: lock.emeraldDark; border.width: 2

      Rectangle {
        width: parent.width; height: 18
        color: lock.emeraldDark; radius: 5
        anchors.top: parent.top
        Rectangle { width: parent.width; height: 8; color: lock.emeraldDark; anchors.bottom: parent.bottom }

        Rectangle {
          id: ledDot
          width: 8; height: 8; radius: 4
          color: lock.accentRed
          anchors.left: parent.left; anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation {
            loops: Animation.Infinite; running: true
            NumberAnimation { target: ledDot; property: "opacity"; from: 1; to: 0.3; duration: 800 }
            NumberAnimation { target: ledDot; property: "opacity"; from: 0.3; to: 1; duration: 800 }
          }
        }

        Text { anchors.centerIn: parent; text: "CHRONO INTERFACE"; color: "#ccffee"; font.family: Style.font.family; font.pixelSize: 8; font.letterSpacing: 2 }

        Row {
          anchors.right: parent.right; anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 3
          Repeater { model: 3; Rectangle { width: 4; height: 8; radius: 1; color: lock.accentBlue; opacity: 0.8 } }
        }
      }

      Text {
        anchors.left: parent.left; anchors.leftMargin: 12
        anchors.top: parent.top; anchors.topMargin: 24
        text: lock.clock("HH:mm")
        color: lock.inkDark
        renderType: Text.NativeRendering
        font.family: pixelFont.name
        font.pixelSize: 40
      }

      Rectangle { anchors.left: parent.left; anchors.leftMargin: 12; anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 17; height: 1; color: lock.emerald; opacity: 0.5 }

      Text { anchors.left: parent.left; anchors.leftMargin: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 7; text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase(); color: lock.inkMid; font.family: Style.font.family; font.pixelSize: 8; font.letterSpacing: 1.5 }

      Row {
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.bottom: parent.bottom; anchors.bottomMargin: 9
        spacing: 4
        Repeater { model: [lock.emerald, lock.accentBlue, lock.gold, lock.emeraldDark]; Rectangle { width: 6; height: 6; radius: 1; color: modelData; opacity: 0.85 } }
      }
    }
  }

  // Login card, bottom-right.
  Item {
    anchors.bottom: parent.bottom; anchors.right: parent.right
    anchors.margins: 44
    width: 270; height: 178

    Rectangle { width: loginCard.width; height: loginCard.height; x: 3; y: 4; radius: 6; color: "#60000000"; z: -1 }

    Rectangle {
      id: loginCard
      width: 270; height: 178
      color: lock.cardBg; radius: 6
      border.color: lock.emeraldDark; border.width: 2

      Rectangle {
        id: loginHeader
        width: parent.width; height: 22
        color: lock.emeraldDark; radius: 5
        anchors.top: parent.top
        Rectangle { width: parent.width; height: 8; color: lock.emeraldDark; anchors.bottom: parent.bottom }

        Rectangle {
          id: loginLed
          width: 8; height: 8; radius: 4
          color: lock.accentRed
          anchors.left: parent.left; anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation {
            loops: Animation.Infinite; running: true
            NumberAnimation { target: loginLed; property: "opacity"; from: 1; to: 0.3; duration: 900 }
            NumberAnimation { target: loginLed; property: "opacity"; from: 0.3; to: 1; duration: 900 }
          }
        }

        Text { anchors.centerIn: parent; text: "SYSTEM AUTHENTICATION"; color: "#ccffee"; font.family: Style.font.family; font.pixelSize: 7; font.letterSpacing: 2 }

        Row {
          anchors.right: parent.right; anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 3
          Repeater { model: 3; Rectangle { width: 4; height: 8; radius: 1; color: lock.accentBlue; opacity: 0.8 } }
        }
      }

      Item {
        id: unRow
        anchors.top: loginHeader.bottom; anchors.topMargin: 10
        anchors.left: parent.left; anchors.leftMargin: 14
        anchors.right: parent.right; anchors.rightMargin: 14
        height: 32

        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: trainerLabel.implicitWidth + 14; height: 18; radius: 3; color: lock.emerald; opacity: 0.3 }
        Text { id: trainerLabel; text: "TRAINER"; anchors.left: parent.left; anchors.leftMargin: 7; anchors.verticalCenter: parent.verticalCenter; color: lock.inkMid; font.family: Style.font.family; font.pixelSize: 8; font.letterSpacing: 1 }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: lock.userName.toUpperCase(); color: lock.inkDark; font.family: Style.font.family; font.pixelSize: 14; font.letterSpacing: 1 }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: lock.emerald; opacity: 0.4 }
      }

      Item {
        id: pwRow
        anchors.top: unRow.bottom; anchors.topMargin: 4
        anchors.left: parent.left; anchors.leftMargin: 14
        anchors.right: parent.right; anchors.rightMargin: 14
        height: 40

        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: passkeyLabel.implicitWidth + 14; height: 18; radius: 3; color: lock.emerald; opacity: 0.3 }
        Text { id: passkeyLabel; text: "PASSKEY"; anchors.left: parent.left; anchors.leftMargin: 7; anchors.verticalCenter: parent.verticalCenter; color: lock.inkMid; font.family: Style.font.family; font.pixelSize: 8; font.letterSpacing: 1 }

        LockInput {
          id: passwordInput
          lock: lock
          anchors.right: parent.right; width: parent.width * 0.58; height: parent.height
          color: lock.inkDark
          font.family: Style.font.family
          font.pixelSize: 15
          font.letterSpacing: 4
          passwordCharacter: "●"
          horizontalAlignment: TextInput.AlignRight
          verticalAlignment: TextInput.AlignVCenter
          selectionColor: lock.emerald
          cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
          cursorDelegate: Rectangle { width: 2; color: lock.gold; radius: 1; visible: passwordInput.cursorVisible }
        }

        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "ENTER PIN"; color: lock.inkDark; opacity: passwordInput.text.length === 0 ? 0.28 : 0; font.family: Style.font.family; font.pixelSize: 9; font.letterSpacing: 1; Behavior on opacity { NumberAnimation { duration: 150 } } }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1.5; color: lock.gold; opacity: passwordInput.activeFocus ? 1 : 0.2; Behavior on opacity { NumberAnimation { duration: 200 } } }
      }

      Rectangle {
        width: parent.width; height: 44; color: "transparent"
        anchors.bottom: parent.bottom

        Text { text: lock.errorState ? "ACCESS DENIED" : ""; anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; color: lock.accentRed; font.family: Style.font.family; font.pixelSize: 8 }

        Rectangle {
          id: accessBtn
          anchors.right: parent.right; anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          width: 84; height: 26; radius: 4
          color: accessMouse.containsMouse ? lock.emeraldDark : "transparent"
          border.color: accessMouse.containsMouse ? lock.gold : lock.emeraldDark
          border.width: 2
          Behavior on color { ColorAnimation { duration: 180 } }

          Text { anchors.centerIn: parent; text: lock.authenticatingPassword ? "…" : "ACCESS"; color: accessMouse.containsMouse ? "#ccffee" : lock.inkDark; font.family: Style.font.family; font.pixelSize: 9; font.letterSpacing: 2; Behavior on color { ColorAnimation { duration: 180 } } }
          MouseArea { id: accessMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (passwordInput.text.length > 0) lock.submitPassword(passwordInput.text) }
        }
      }
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 20
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type PIN" : "Type PIN · Enter to unlock"
    color: lock.withAlpha("#ffffff", 0.7)
    font.family: Style.font.family
    font.pixelSize: 10
    font.letterSpacing: 1
  }
}

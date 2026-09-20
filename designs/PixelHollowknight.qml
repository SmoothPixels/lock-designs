// source: qylock
// Original design inspired by Darkkal44's qylock "pixel-hollowknight"
// theme (github.com/Darkkal44/qylock, GPL-3.0). Bundles the source's
// bg.mp4 and its PixelifySans-Bold font (bundled alongside this file in
// pixel-hollowknight-assets/) for a true-to-source look. The QML itself is
// written from scratch against Omarchy's DesignBase/LockInput, not copied
// from qylock's GPL source, and drops the SDDM-specific multi-user/
// session/reboot/shutdown row (Omarchy handles auth elsewhere) in favor of
// the shared single password field.
//
// PixelifySans-Bold's capital "C" was found to render nearly fully closed
// at UI text sizes (verified directly against the font file, independent
// of Qt) -- confirmed during the pixel-cyberpunk port -- so it stays on
// the big clock, where digits are unambiguous, and every word label below
// uses the shell's normal font instead.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-hollowknight-assets/")

  // Original qylock palette.
  property color lantern: "#f5aa5b"
  property color lore: "#8498ab"

  FontLoader { id: pixelFont; source: lock.assetsUrl + "font/PixelifySans-Bold.ttf" }

  Rectangle { anchors.fill: parent; color: "#050505" }

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

  // Falling ash, matching the source's particle field.
  Repeater {
    model: 45
    Rectangle {
      id: ash
      width: 1 + Math.random() * 3; height: width / 2
      color: lock.lore
      opacity: 0
      rotation: Math.random() * 360
      x: Math.random() * lock.width
      y: -20
      SequentialAnimation {
        running: true
        loops: Animation.Infinite
        PauseAnimation { duration: Math.random() * 8000 }
        ParallelAnimation {
          NumberAnimation { target: ash; property: "opacity"; to: 0.8; duration: 2000 }
          NumberAnimation { target: ash; property: "y"; to: lock.height + 20; duration: 8000 + Math.random() * 4000 }
          NumberAnimation { target: ash; property: "x"; to: ash.x + (Math.random() - 0.5) * 200; duration: 8000 }
          RotationAnimation { target: ash; to: ash.rotation + 360; duration: 8000 }
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

  // Bottom-center date + clock, split by a lantern-colored divider.
  Item {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40
    anchors.horizontalCenter: parent.horizontalCenter
    width: dateRow.implicitWidth
    height: 40

    Row {
      id: dateRow
      anchors.centerIn: parent
      spacing: 40
      Text {
        text: Qt.formatDate(lock.now, "ddd, MMM d").toUpperCase()
        color: lock.lore
        font.family: Style.font.family
        font.pixelSize: 14
        font.letterSpacing: 6
        anchors.verticalCenter: parent.verticalCenter
      }
      Rectangle { width: 1; height: 40; color: lock.lantern; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
      Text {
        text: lock.clock("HH:mm")
        color: "white"
        renderType: Text.NativeRendering
        font.family: pixelFont.name
        font.pixelSize: 48
        font.letterSpacing: 4
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  // Top-center login panel, hanging on a lantern chain.
  Item {
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: 320; height: 180

    Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: 40; color: lock.lantern; opacity: 0.4 }

    Rectangle {
      anchors.top: parent.top; anchors.topMargin: 40; anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width; height: 120
      color: "#d0050403"; border.color: lock.lantern; border.width: 1; radius: 4

      Column {
        anchors.centerIn: parent
        spacing: 16
        width: 260

        Text {
          text: lock.userName.toUpperCase()
          color: "white"
          font.family: Style.font.family
          font.pixelSize: 16
          font.letterSpacing: 6
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
          width: parent.width; height: 36

          Rectangle { anchors.fill: parent; color: "#20000000"; border.color: lock.lore; border.width: 1 }
          Rectangle {
            anchors.fill: parent; color: "transparent"
            border.color: lock.lantern; border.width: 1
            opacity: passwordInput.activeFocus ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
          }

          LockInput {
            id: passwordInput
            lock: lock
            anchors.fill: parent
            color: lock.lantern
            font.family: Style.font.family
            font.pixelSize: 14
            font.letterSpacing: 4
            passwordCharacter: "x"
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            selectionColor: lock.lore
            cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
            cursorDelegate: Rectangle { width: 2; color: lock.lore; visible: passwordInput.cursorVisible }
          }

          Text {
            anchors.centerIn: parent
            text: "password..."
            color: lock.lore
            font.family: Style.font.family
            font.pixelSize: 12
            font.letterSpacing: 4
            opacity: passwordInput.text.length === 0 ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
          }
        }

        Text {
          text: lock.errorState ? "ACCESS DENIED" : ""
          height: 12
          verticalAlignment: Text.AlignBottom
          color: "#cc2222"
          anchors.horizontalCenter: parent.horizontalCenter
          font.family: Style.font.family
          font.pixelSize: 10
        }
      }
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.lore, 0.7)
    font.family: Style.font.family
    font.pixelSize: 10
    font.letterSpacing: 2
  }
}

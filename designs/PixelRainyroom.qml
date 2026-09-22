// source: qylock
// name: Pixel Rainy Room
// description: Pixel art video from MoeWalls · Pixelify Sans font
// Original design inspired by Darkkal44's qylock "pixel-rainyroom" theme
// (github.com/Darkkal44/qylock, GPL-3.0). Bundles the source's bg.mp4 and
// PixelifySans-Bold font for a true-to-source look, including a lightweight
// rewrite of its falling-rain effect; the QML itself is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source, and drops the SDDM-only session-switcher/reboot/shutdown row
// (Omarchy handles that elsewhere) in favor of a single password field.
//
// PixelifySans-Bold's capital "C" renders almost fully closed at UI text
// sizes (confirmed directly against the font file) -- "WELCOME BACK" reads
// as "WELOOME BACK". It stays on the big clock digits, but every word label
// uses the shell's normal font instead.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-rainyroom-assets/")

  // Original qylock palette.
  property color background: "#01060c"
  property color lamp: "#e6bb5c"
  property color rainBlue: "#2f9eff"

  FontLoader {
    id: pixelFont
    source: lock.assetsUrl + "font/PixelifySans-Bold.ttf"
  }

  Rectangle { anchors.fill: parent; color: lock.background }

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

  // Rain, a lightweight rewrite of the source's falling-streak effect.
  Repeater {
    model: 60
    delegate: Item {
      id: drop
      property real sx: Math.random() * lock.width
      property real dur: 600 + Math.random() * 800
      property real dl: Math.random() * 4000
      property real len: 15 + Math.random() * 30
      x: sx; y: -len; width: 1; height: len; opacity: 0
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.55) }
        }
      }
      SequentialAnimation {
        running: true
        loops: Animation.Infinite
        PauseAnimation { duration: drop.dl }
        ParallelAnimation {
          NumberAnimation { target: drop; property: "y"; from: -drop.len; to: lock.height + drop.len; duration: drop.dur; easing.type: Easing.Linear }
          SequentialAnimation {
            NumberAnimation { target: drop; property: "opacity"; to: 0.8; duration: drop.dur * 0.1 }
            PauseAnimation { duration: drop.dur * 0.8 }
            NumberAnimation { target: drop; property: "opacity"; to: 0; duration: drop.dur * 0.1 }
          }
        }
      }
    }
  }

  // Sidebar backdrop, matching the source's left-hand gradient panel.
  Rectangle {
    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
    width: 440
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.82) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Column {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 60
    width: 340
    spacing: 40

    Column {
      spacing: 4
      Text {
        text: lock.clock("HH:mm")
        color: "white"
        renderType: Text.NativeRendering
        font.family: pixelFont.name
        font.pixelSize: 84
      }
      Row {
        spacing: 8
        Rectangle { width: 12; height: 1; color: lock.rainBlue; anchors.verticalCenter: parent.verticalCenter }
        Text {
          text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
          color: lock.lamp
          font.family: Style.font.family
          font.pixelSize: 13
          font.letterSpacing: 3
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Column {
      width: parent.width
      spacing: 24

      Text {
        text: lock.userName.toUpperCase()
        color: "white"
        font.family: Style.font.family
        font.pixelSize: 22
        font.letterSpacing: 4
      }

      Item {
        width: parent.width
        height: 40

        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: lock.rainBlue; opacity: passwordInput.activeFocus ? 1.0 : 0.3 }
        Rectangle {
          anchors.bottom: parent.bottom
          width: passwordInput.activeFocus ? parent.width : 0
          height: 2; color: lock.lamp
          Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        }

        LockInput {
          id: passwordInput
          lock: lock
          anchors.fill: parent
          verticalAlignment: TextInput.AlignVCenter
          color: lock.lamp
          passwordCharacter: "─"
          font.family: Style.font.family
          font.pixelSize: 16
          font.letterSpacing: 4
          selectionColor: lock.rainBlue
          cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
          cursorDelegate: Rectangle {
            width: 2
            color: lock.lamp
            visible: passwordInput.cursorVisible
          }
        }

        Text {
          anchors.verticalCenter: passwordInput.verticalCenter
          text: lock.authenticatingPassword ? "Checking…" : "Password…"
          color: lock.rainBlue
          font.family: Style.font.family
          font.pixelSize: 13
          font.letterSpacing: 3
          opacity: passwordInput.text.length === 0 ? 0.5 : 0
          Behavior on opacity { NumberAnimation { duration: 200 } }
        }
      }

      Text {
        visible: lock.errorState
        text: lock.failureMessage
        color: "#ff4444"
        font.family: Style.font.family
        font.pixelSize: 12
      }
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha("#ffffff", 0.4)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

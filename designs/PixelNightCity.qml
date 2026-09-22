// source: qylock
// name: Pixel Night City
// description: Pixel art video from Wallsflow · Pixelify Sans font
// Original design inspired by Darkkal44's qylock "pixel-night-city" theme
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

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-night-city-assets/")

  // Original qylock palette.
  property color background: "#060810"
  property color signTeal: "#50c8d8"
  property color signPink: "#d06880"
  property color textWhite: "#e8e4f0"

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

  Rectangle { anchors.fill: parent; color: "black"; opacity: 0.3 }

  // Rain, a lightweight rewrite of the source's falling-streak effect.
  Repeater {
    model: 40
    delegate: Item {
      id: drop
      property real sx: Math.random() * lock.width
      property real dur: 800 + Math.random() * 1200
      property real dl: Math.random() * 3000
      property real len: 20 + Math.random() * 30
      x: sx; y: -len; width: 1; height: len; opacity: 0
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 1.0; color: Qt.rgba(0.31, 0.78, 0.85, 0.5) }
        }
      }
      SequentialAnimation {
        running: true
        loops: Animation.Infinite
        PauseAnimation { duration: drop.dl }
        ParallelAnimation {
          NumberAnimation { target: drop; property: "y"; from: -drop.len; to: lock.height + drop.len; duration: drop.dur; easing.type: Easing.Linear }
          SequentialAnimation {
            NumberAnimation { target: drop; property: "opacity"; to: 0.6; duration: drop.dur * 0.1 }
            PauseAnimation { duration: drop.dur * 0.8 }
            NumberAnimation { target: drop; property: "opacity"; to: 0; duration: drop.dur * 0.1 }
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

  // Clock, top-left: big HH/mm split by a neon needle.
  Column {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 60
    spacing: 10

    Row {
      spacing: 20
      Text {
        text: lock.clock("HH")
        color: "white"
        renderType: Text.NativeRendering
        font.family: pixelFont.name
        font.pixelSize: 100
        font.letterSpacing: -5
      }
      Rectangle { width: 4; height: 80; color: lock.signPink; radius: 2; anchors.verticalCenter: parent.verticalCenter }
      Text {
        text: lock.clock("mm")
        color: lock.signTeal
        renderType: Text.NativeRendering
        font.family: pixelFont.name
        font.pixelSize: 100
        font.letterSpacing: -5
      }
    }

    Text {
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
      color: "white"
      font.family: Style.font.family
      font.pixelSize: 14
      font.letterSpacing: 8
      opacity: 0.8
    }
  }

  // Login, bottom-center.
  Column {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 80
    width: 360
    spacing: 30

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.textWhite
      font.family: Style.font.family
      font.pixelSize: 20
      font.letterSpacing: 6
    }

    Item {
      width: parent.width
      height: 40

      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: lock.signPink; opacity: passwordInput.activeFocus ? 1.0 : 0.3 }
      Rectangle {
        anchors.bottom: parent.bottom
        width: passwordInput.activeFocus ? parent.width : 0
        height: 2; color: lock.signPink
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
      }

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: lock.signPink
        passwordCharacter: "─"
        font.family: Style.font.family
        font.pixelSize: 16
        font.letterSpacing: 5
        selectionColor: lock.signPink
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle {
          width: 2
          color: lock.signPink
          visible: passwordInput.cursorVisible
        }
      }

      Text {
        anchors.centerIn: parent
        text: lock.authenticatingPassword ? "Connecting…" : "Password"
        color: lock.signTeal
        font.family: Style.font.family
        font.pixelSize: 12
        font.letterSpacing: 3
        opacity: passwordInput.text.length === 0 ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: lock.errorState
      text: lock.failureMessage
      color: "#ff4444"
      font.family: Style.font.family
      font.pixelSize: 12
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.textWhite, 0.4)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

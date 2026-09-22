// source: qylock
// name: Pixel Waterfall
// description: Pixel art video · Pixelify Sans font
// Original design inspired by Darkkal44's qylock "pixel-waterfall" theme
// (github.com/Darkkal44/qylock, GPL-3.0). Bundles the source's bg.mp4 and
// PixelifySans-Bold font for a true-to-source look; the QML itself is
// written from scratch against Omarchy's DesignBase/LockInput, not copied
// from qylock's GPL source, and drops the SDDM-only session-switcher/
// reboot/shutdown row (Omarchy handles that elsewhere) in favor of a single
// password field.
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

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-waterfall-assets/")

  // Original qylock palette.
  property color background: "#0b151f"
  property color cleanWhite: "#ffffff"
  property color lightCyan: "#b2f0f4"
  property color deepIceBlue: "#7bc3d4"
  property color darkTealLine: "#1c5b6e"

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

  Rectangle {
    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
    height: 180
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0.03, 0.07, 0.1, 0.9) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 300
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.05, 0.08, 0.96) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, bottom-left.
  Column {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: 55
    spacing: 6

    Row {
      spacing: 8
      Rectangle { width: 5; height: 5; color: lock.lightCyan; anchors.verticalCenter: parent.verticalCenter }
      Text {
        text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
        color: lock.cleanWhite
        font.family: Style.font.family
        font.pixelSize: 14
        font.letterSpacing: 2
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      text: lock.clock("HH:mm")
      color: lock.cleanWhite
      renderType: Text.NativeRendering
      font.family: pixelFont.name
      font.pixelSize: 76
    }
  }

  // Login, bottom-right.
  Column {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 55
    width: 320
    spacing: 12

    Text {
      anchors.right: parent.right
      text: lock.userName.toUpperCase()
      color: lock.cleanWhite
      font.family: Style.font.family
      font.pixelSize: 20
      font.letterSpacing: 4
      font.bold: true
    }

    Item {
      width: parent.width
      height: 28

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        horizontalAlignment: TextInput.AlignRight
        verticalAlignment: TextInput.AlignVCenter
        color: lock.lightCyan
        passwordCharacter: "■"
        font.family: Style.font.family
        font.pixelSize: 16
        font.letterSpacing: 4
        selectionColor: lock.darkTealLine
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle {
          width: 2
          color: lock.lightCyan
          visible: passwordInput.cursorVisible
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: lock.authenticatingPassword ? "Checking…" : "Enter password"
        color: lock.deepIceBlue
        font.family: Style.font.family
        font.pixelSize: 13
        font.letterSpacing: 2
        opacity: passwordInput.text.length === 0 ? 0.75 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
      }
    }

    Text {
      anchors.right: parent.right
      visible: lock.errorState
      text: lock.failureMessage
      color: "#ff5555"
      font.family: Style.font.family
      font.pixelSize: 12
      font.bold: true
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.cleanWhite, 0.4)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

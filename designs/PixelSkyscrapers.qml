// source: qylock
// name: Pixel Skyscrapers
// description: Pixel art video from Wallsflow · Pixelify Sans font
// Original design inspired by Darkkal44's qylock "pixel-skyscrapers" theme
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

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-skyscrapers-assets/")

  // Original qylock palette.
  property color background: "#14101a"
  property color roseUI: "#d05870"
  property color peachSky: "#f0a060"
  property color sunCream: "#fae8d0"

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
    height: 160
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.38) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 240
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.56) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, top-left.
  Column {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 60
    spacing: 4

    Text {
      text: lock.clock("HH:mm")
      color: lock.sunCream
      renderType: Text.NativeRendering
      font.family: pixelFont.name
      font.pixelSize: 84
      font.letterSpacing: -2
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
      color: lock.roseUI
      font.family: Style.font.family
      font.pixelSize: 13
      font.letterSpacing: 4
    }
  }

  // Login, bottom-center.
  Column {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 60
    width: 320
    spacing: 20

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.sunCream
      font.family: Style.font.family
      font.pixelSize: 20
      font.letterSpacing: 4
    }

    Item {
      width: parent.width
      height: 36

      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: lock.roseUI; opacity: passwordInput.activeFocus ? 1.0 : 0.4 }
      Rectangle {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        width: passwordInput.activeFocus ? parent.width : 0
        height: 2; color: lock.peachSky
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
      }

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: lock.peachSky
        passwordCharacter: "─"
        font.family: Style.font.family
        font.pixelSize: 16
        font.letterSpacing: 4
        selectionColor: lock.roseUI
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle {
          width: 2
          color: lock.roseUI
          visible: passwordInput.cursorVisible
        }
      }

      Text {
        anchors.centerIn: parent
        text: lock.authenticatingPassword ? "Checking…" : "Password…"
        color: lock.roseUI
        font.family: Style.font.family
        font.pixelSize: 13
        font.letterSpacing: 3
        opacity: passwordInput.text.length === 0 ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: lock.errorState
      text: lock.failureMessage
      color: "#ff5555"
      font.family: Style.font.family
      font.pixelSize: 12
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 22
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.sunCream, 0.45)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

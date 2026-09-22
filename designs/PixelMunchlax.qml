// source: qylock
// name: Pixel Munchlax
// description: Pixel art video from MoeWalls · Pixelify Sans font
// Original design inspired by Darkkal44's qylock "pixel-munchlax" theme
// (github.com/Darkkal44/qylock, GPL-3.0). Bundles the source's bg.mp4 and
// PixelifySans-Bold font for a true-to-source look; the QML is written from
// scratch against Omarchy's DesignBase/LockInput, not copied from qylock's
// GPL source, and drops the SDDM-only session-switcher/reboot/shutdown row
// (Omarchy handles that elsewhere) in favor of a single password field.
//
// PixelifySans-Bold's capital "C" renders almost fully closed at UI text
// sizes (confirmed directly against the font file) -- "WELCOME BACK" reads
// as "WELOOME BACK". It stays on the big clock, where digits are
// unambiguous, but every word label uses the shell's normal font instead.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-munchlax-assets/")

  // Original qylock palette.
  property color background: "#25787d"
  property color mTeal: "#50dfd4"
  property color mCream: "#fcf8eb"
  property color mOrange: "#f4a261"

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
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 360
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, top-right.
  Column {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 60
    spacing: 4

    Text {
      anchors.right: parent.right
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
      color: lock.mTeal
      font.family: Style.font.family
      font.pixelSize: 16
      font.letterSpacing: 4
      font.bold: true
    }
    Text {
      anchors.right: parent.right
      text: lock.clock("HH:mm")
      color: lock.mCream
      renderType: Text.NativeRendering
      font.family: pixelFont.name
      font.pixelSize: 72
    }
  }

  // Login, bottom-left.
  Column {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.margins: 60
    spacing: 16
    width: 280

    Text {
      text: lock.userName.toUpperCase()
      color: lock.mCream
      font.family: Style.font.family
      font.pixelSize: 18
      font.letterSpacing: 3
      font.bold: true
    }

    Item {
      width: parent.width
      height: 40

      Rectangle {
        anchors.bottom: parent.bottom; width: parent.width
        height: 1
        color: lock.errorState ? "#ff4444" : lock.mTeal
        opacity: passwordInput.activeFocus ? 1.0 : 0.35
        Behavior on opacity { NumberAnimation { duration: 200 } }
      }
      Rectangle {
        anchors.bottom: parent.bottom
        width: passwordInput.activeFocus ? parent.width : 0
        height: 2
        color: lock.mOrange
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
      }

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        verticalAlignment: TextInput.AlignVCenter
        color: lock.mCream
        passwordCharacter: "─"
        font.family: Style.font.family
        font.pixelSize: 16
        font.letterSpacing: 3
        selectionColor: lock.mOrange
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle {
          width: 2
          color: lock.mOrange
          visible: passwordInput.cursorVisible
        }
      }

      Text {
        anchors.verticalCenter: passwordInput.verticalCenter
        text: lock.authenticatingPassword ? "Checking…" : "Password"
        color: lock.mTeal
        font.family: Style.font.family
        font.pixelSize: 13
        font.letterSpacing: 2
        opacity: passwordInput.text.length === 0 ? 0.55 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
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

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.mCream, 0.4)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

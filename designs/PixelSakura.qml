// source: qylock
// Original design inspired by Darkkal44's qylock "pixel-sakura" theme
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
//
// Unlike the rest of this batch, the source is a light theme -- pale sky
// background with slate-dark text -- kept as-is rather than darkened, since
// that contrast is the theme's actual look.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-sakura-assets/")

  // Original qylock palette.
  property color background: "#ebf0f5"
  property color sakuraPink: "#df7a8c"
  property color slateDark: "#32354c"
  property color slateMid: "#506275"
  property color sunRed: "#e26b67"

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

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, top-left, with a small tick-mark track under the date.
  Column {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 40
    spacing: -4

    Text {
      text: lock.clock("HH:mm")
      color: lock.slateDark
      renderType: Text.NativeRendering
      font.family: pixelFont.name
      font.pixelSize: 64
      font.bold: true
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
      color: lock.sakuraPink
      font.family: Style.font.family
      font.pixelSize: 12
      font.letterSpacing: 2
      font.bold: true
    }
    Item {
      width: 120; height: 20
      Rectangle { width: parent.width; height: 1.5; color: lock.slateMid; opacity: 0.25; anchors.verticalCenter: parent.verticalCenter }
      Row {
        anchors.fill: parent
        spacing: 10
        Repeater {
          model: 11
          Rectangle { width: 2; height: 6; color: lock.slateMid; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }
  }

  // Login, centered.
  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 60
    width: 260
    spacing: 10

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.slateDark
      font.family: Style.font.family
      font.pixelSize: 18
      font.letterSpacing: 4
      font.bold: true
    }

    Item {
      width: 180
      height: 30
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 1
        color: passwordInput.activeFocus ? lock.sakuraPink : lock.slateMid
        opacity: passwordInput.activeFocus ? 0.8 : 0.35
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: lock.slateDark
        passwordCharacter: "■"
        font.family: Style.font.family
        font.pixelSize: 15
        font.letterSpacing: 4
        selectionColor: lock.sakuraPink
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle {
          width: 2
          color: lock.sakuraPink
          visible: passwordInput.cursorVisible
        }
      }

      Text {
        anchors.centerIn: parent
        text: lock.authenticatingPassword ? "Checking…" : "Password"
        color: lock.slateMid
        font.family: Style.font.family
        font.pixelSize: 10
        font.letterSpacing: 2
        opacity: passwordInput.text.length === 0 ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: lock.errorState
      text: lock.failureMessage
      color: lock.sunRed
      font.family: Style.font.family
      font.pixelSize: 10
      font.bold: true
      font.letterSpacing: 2
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.slateDark, 0.45)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

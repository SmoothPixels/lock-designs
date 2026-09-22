// source: qylock
// name: Reverse: 1999 - II
// description: Video from Taptap · Cinzel font
// Original design inspired by Darkkal44's qylock "R1999_2" theme
// (github.com/Darkkal44/qylock, GPL-3.0) -- a "Reverse: 1999" skin. Bundles
// the source's bg.mp4, logo.png and Cinzel-Bold font for a true-to-source
// look; the QML itself is written from scratch against Omarchy's
// DesignBase/LockInput, not copied from qylock's GPL source, and drops the
// SDDM-only multi-user/session-switcher/reboot/shutdown row (Omarchy
// handles that elsewhere) in favor of a single password field. The
// source's own two R1999 sub-themes carry the same generic "Reverse 1999
// Qylock Theme" description with no distinguishing character name, so this
// keeps the batch's fallback name.
//
// The source gates its password field behind a "START" click/keypress
// (an SDDM idle-screen convention); Omarchy always focuses the password
// field for typing, so that gate is dropped and the field is shown
// directly, with the logo dimming once typing starts as the closest
// equivalent to the source's reveal.
//
// Cinzel-Bold was checked directly against the font file (digits, mixed
// case, a full alphabet pangram) and every glyph is unambiguous, so unlike
// this batch's Pixelify-based themes it is used throughout, clock and word
// labels alike.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("reverse1999-second-assets/")
  readonly property bool typing: passwordInput.text.length > 0 || passwordInput.activeFocus

  // Original qylock palette.
  property color background: "#000000"
  property color fg: "#fdfaf2"
  property color gold: "#c9a063"

  FontLoader {
    id: serifFont
    source: lock.assetsUrl + "font/Cinzel-Bold.ttf"
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
    anchors.fill: parent
    color: "black"
    opacity: lock.typing ? 0.7 : 0.4
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, top-left.
  Row {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 60
    spacing: 12
    opacity: lock.typing ? 0.3 : 1.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    Text {
      text: lock.clock("HH:mm")
      color: lock.fg
      font.family: serifFont.name
      font.pixelSize: 48
      font.letterSpacing: 3
    }
    Rectangle { width: 1.2; height: 34; color: lock.gold; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }
    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1
      Text { text: Qt.formatDate(lock.now, "dddd").toUpperCase(); color: lock.gold; font.family: serifFont.name; font.pixelSize: 12; font.letterSpacing: 3 }
      Text { text: Qt.formatDate(lock.now, "MMM dd").toUpperCase(); color: lock.fg; font.family: serifFont.name; font.pixelSize: 9; font.letterSpacing: 2; opacity: 0.6 }
    }
  }

  // Logo, centered -- dims once the field is in use.
  Image {
    source: lock.assetsUrl + "logo.png"
    width: 520
    fillMode: Image.PreserveAspectFit
    anchors.centerIn: parent
    opacity: lock.typing ? 0.15 : 1.0
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
  }

  // Login, bottom-center.
  Column {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 130
    width: 500
    spacing: 14

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.fg
      font.family: serifFont.name
      font.pixelSize: 26
      font.letterSpacing: 8
    }

    Item {
      width: 340
      height: 48
      anchors.horizontalCenter: parent.horizontalCenter

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: lock.fg
        passwordCharacter: "✦"
        font.family: serifFont.name
        font.pixelSize: 24
        font.letterSpacing: 10
        selectionColor: lock.gold
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle {
          width: 2
          color: lock.gold
          visible: passwordInput.cursorVisible
        }
      }

      Text {
        anchors.centerIn: parent
        text: lock.authenticatingPassword ? "Checking…" : "Password"
        color: lock.gold
        font.family: serifFont.name
        font.pixelSize: 13
        font.letterSpacing: 4
        opacity: passwordInput.text.length === 0 ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
      }
    }

    Rectangle { width: 350; height: 1.2; color: lock.gold; opacity: 0.5; anchors.horizontalCenter: parent.horizontalCenter }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: lock.errorState
      text: lock.failureMessage
      color: "#ff4444"
      font.family: serifFont.name
      font.pixelSize: 13
      font.letterSpacing: 2
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.fg, 0.4)
    font.family: serifFont.name
    font.pixelSize: 12
    font.letterSpacing: 2
  }
}

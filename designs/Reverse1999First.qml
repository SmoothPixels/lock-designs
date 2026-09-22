// source: qylock
// name: Reverse: 1999 - I
// description: Video from Taptap · Cinzel font
// Original design inspired by Darkkal44's qylock "R1999_1" theme
// (github.com/Darkkal44/qylock, GPL-3.0) -- a "Reverse: 1999" skin. Bundles
// the source's bg.mp4 and Cinzel-Bold font for a true-to-source look; the
// QML itself is written from scratch against Omarchy's DesignBase/
// LockInput, not copied from qylock's GPL source, and drops the SDDM-only
// multi-user/session-switcher/reboot/shutdown row (Omarchy handles that
// elsewhere) in favor of a single password field. The source's own two
// R1999 sub-themes carry the same generic "Reverse 1999 Qylock Theme"
// description with no distinguishing character name, so this keeps the
// batch's fallback name.
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

  readonly property string assetsUrl: Qt.resolvedUrl("reverse1999-first-assets/")

  // Original qylock palette.
  property color background: "#000000"
  property color fg: "#fdfaf2"
  property color gold: "#c9a063"
  property color orbitClr: "#ffffff"

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
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, top-right, with a small orbiting mote around the time.
  Item {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 100
    width: 340
    height: 140

    Canvas {
      id: ring
      anchors.centerIn: timeLabels
      width: 260; height: 90
      rotation: -18
      opacity: 0.25
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = lock.orbitClr
        ctx.lineWidth = 1.2
        ctx.beginPath()
        ctx.ellipse(2, 2, width - 4, height - 4)
        ctx.stroke()
      }
    }
    Rectangle {
      id: traveler
      width: 7; height: 7; radius: 3.5
      color: lock.orbitClr; opacity: 0.65
      property real t: 0
      NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 18000; loops: Animation.Infinite; running: true }
      x: ring.x + ring.width / 2 + (ring.width / 2) * Math.cos(t) * Math.cos(ring.rotation * Math.PI / 180) - width / 2
      y: ring.y + ring.height / 2 + (ring.height / 2) * Math.sin(t) - height / 2
    }

    Row {
      id: timeLabels
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 15

      Text {
        text: lock.clock("HH")
        color: lock.fg
        font.family: serifFont.name
        font.pixelSize: 90
        font.letterSpacing: 4
      }
      Text {
        text: lock.clock("mm")
        color: lock.fg
        font.family: serifFont.name
        font.pixelSize: 90
        font.letterSpacing: 4
      }
    }

    Column {
      anchors.right: parent.right
      anchors.top: timeLabels.bottom
      spacing: 5

      Text {
        anchors.right: parent.right
        text: Qt.formatDate(lock.now, "dddd").toUpperCase()
        color: lock.gold
        font.family: serifFont.name
        font.pixelSize: 15
        font.letterSpacing: 7
        opacity: 0.8
      }
      Row {
        anchors.right: parent.right
        spacing: 12
        Rectangle { width: 36; height: 1; color: lock.gold; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
        Text {
          text: Qt.formatDate(lock.now, "MMM dd yyyy").toUpperCase()
          color: lock.fg
          font.family: serifFont.name
          font.pixelSize: 11
          font.letterSpacing: 3
          opacity: 0.6
        }
      }
    }
  }

  // Identity, bottom-right.
  Column {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 100
    spacing: 12
    width: 400

    Text {
      anchors.right: parent.right
      text: lock.userName.toUpperCase()
      color: lock.fg
      font.family: serifFont.name
      font.pixelSize: 42
      font.letterSpacing: 4
    }

    Row {
      anchors.right: parent.right
      spacing: 12
      Rectangle { width: 50; height: 1; color: lock.gold; opacity: 0.2; anchors.verticalCenter: parent.verticalCenter }
      Text { text: "✦"; font.pixelSize: 10; color: lock.gold; opacity: 0.4; anchors.verticalCenter: parent.verticalCenter }
      Rectangle { width: 50; height: 1; color: lock.gold; opacity: 0.2; anchors.verticalCenter: parent.verticalCenter }
    }

    Item {
      width: parent.width
      height: 44

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        horizontalAlignment: TextInput.AlignRight
        verticalAlignment: TextInput.AlignVCenter
        color: lock.fg
        passwordCharacter: "✦"
        font.family: serifFont.name
        font.pixelSize: 20
        font.letterSpacing: 8
        selectionColor: lock.gold
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle {
          width: 2
          color: lock.gold
          visible: passwordInput.cursorVisible
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: lock.authenticatingPassword ? "Checking…" : "Waiting for password"
        color: lock.gold
        font.family: serifFont.name
        font.pixelSize: 11
        font.letterSpacing: 3
        opacity: passwordInput.text.length === 0 ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
      }
    }

    Text {
      anchors.right: parent.right
      visible: lock.errorState
      text: lock.failureMessage
      color: "#ff4444"
      font.family: serifFont.name
      font.pixelSize: 12
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

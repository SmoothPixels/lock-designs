// name: TTY
// description: A console login prompt, the way a bare terminal asks
//
// SmoothPixels original. No wallpaper: a full-screen console in the theme's
// background and text colors, showing the banner a login prompt prints, the
// live date and time, and the classic "login:" and "Password:" pair. The
// block cursor blinks while the display is awake, typing echoes nothing (a
// real getty shows nothing either), and a wrong password prints "Login
// incorrect" and asks again. Ctrl+E reveals what you typed, as everywhere.
import QtQuick
import Quickshell.Io
import qs.Commons

DesignBase {
  id: lock
  inputItem: input
  flashOnFail: false

  readonly property real u: Math.min(width, height) / 100
  readonly property int fs: Math.round(lock.u * 2.1)
  readonly property color ink: Color.foreground
  readonly property color dim: lock.withAlpha(Color.foreground, 0.5)
  property string kernel: ""
  property bool cursorOn: true

  FileView {
    path: "/proc/sys/kernel/osrelease"
    printErrors: false
    onLoaded: lock.kernel = String(text() || "").trim()
  }
  Timer {
    interval: 530
    repeat: true
    running: lock.videoPlaying
    onTriggered: lock.cursorOn = !lock.cursorOn
  }
  onVideoPlayingChanged: if (!videoPlaying) cursorOn = true

  Rectangle { anchors.fill: parent; color: Color.background }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  component Line: Text {
    font.family: Style.font.family
    font.pixelSize: lock.fs
    color: lock.ink
    textFormat: Text.PlainText
    lineHeight: 1.3
  }

  Column {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: Math.round(lock.u * 5)
    spacing: 0

    Line { text: "Omarchy Linux " + lock.kernel + " (tty1)" }
    Line { text: Qt.formatDateTime(lock.now, lock.twelveHour ? "ddd MMM d h:mm:ss AP yyyy" : "ddd MMM d HH:mm:ss yyyy") }
    Line { text: " " }

    // Every wrong attempt leaves its trace, up to three, then the prompt
    // comes back.
    Repeater {
      model: Math.min(lock.failedAttempts, 3)
      delegate: Column {
        Line { text: lock.hostName + " login: " + lock.userName }
        Line { text: "Password: " }
        Line { text: " " }
        Line { text: "Login incorrect"; color: Color.lock.textError }
        Line { text: " " }
      }
    }

    Line { text: lock.hostName + " login: " + lock.userName }
    Row {
      Line { text: "Password: " }
      Line { visible: lock.passwordVisible; text: lock.passwordText }
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(lock.fs * 0.6)
        height: Math.round(lock.fs * 1.15)
        color: lock.ink
        visible: !lock.authenticatingPassword && lock.cursorOn
      }
    }
  }

  Line {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: Math.round(lock.u * 5)
    text: lock.fingerprintConfigured
      ? "Typing stays hidden. Press Enter to sign in, or touch the fingerprint sensor."
      : "Typing stays hidden. Press Enter to sign in."
    color: lock.dim
    font.pixelSize: Math.round(lock.u * 1.5)
  }

  // The real input, invisible; it only has to hold focus and take keys.
  LockInput {
    id: input
    lock: lock
    x: Math.round(lock.u * 5)
    y: Math.round(lock.u * 5)
    width: Math.round(lock.u * 40)
    height: Math.round(lock.u * 3)
    opacity: 0
  }
}

// name: Hush
// description: No box at all: just type, and a dot appears for every letter
//
// SmoothPixels original. A thin clock over the wallpaper under a quiet veil,
// and nothing that looks like a form. Start typing and a row of dots grows
// under the date, one per character, centered as it lengthens; Enter sends
// it. A wrong password turns the row to the error color and shivers it, and
// a small caption speaks only when there is something to say.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: input
  shakeOnFail: false

  readonly property real u: Math.min(width, height) / 100
  readonly property int typed: lock.passwordText.length
  // The host clears the text on a wrong password; the dots that were there
  // stay, in the error color, until the next keystroke.
  property int lastTyped: 0
  onTypedChanged: if (typed > 0) lastTyped = typed
  readonly property int shown: Math.min(lock.errorState ? lock.lastTyped : lock.typed, 40)
  readonly property int pitch: Math.round(lock.u * 2.0)
  readonly property int dot: Math.round(lock.u * 1.05)

  Rectangle { anchors.fill: parent; color: Color.background }

  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.fileUrl(lock.backgroundPath) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: width
    sourceSize.height: height
  }
  Rectangle { anchors.fill: parent; color: lock.withAlpha(Color.background, 0.55) }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.30)
    spacing: Math.round(lock.u * 1.6)
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      renderType: Text.CurveRendering
      color: Color.foreground
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 18)
      font.weight: Font.Light
      font.letterSpacing: -Math.round(lock.u * 0.3)
      lineHeight: 0.85
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd, d MMMM")
      color: lock.withAlpha(Color.foreground, 0.7)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.8)
      font.letterSpacing: 3
    }
  }

  // The typed dots, centered as a group so the row grows from the middle.
  // A fixed pool of forty; the ones past the count are scaled away.
  Item {
    id: dots
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.64)
    width: lock.shown * lock.pitch
    height: lock.dot
    visible: !lock.passwordVisible
    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    transform: Translate { id: nudge }
    Repeater {
      model: 40
      delegate: Rectangle {
        required property int index
        readonly property bool on: index < lock.shown
        x: index * lock.pitch + (lock.pitch - lock.dot) / 2
        width: lock.dot
        height: lock.dot
        radius: width / 2
        color: lock.errorState ? Color.lock.textError : Color.foreground
        scale: on ? 1 : 0
        opacity: on ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
      }
    }
    SequentialAnimation {
      id: shiver
      NumberAnimation { target: nudge; property: "x"; from: 0; to: -10; duration: 45 }
      NumberAnimation { target: nudge; property: "x"; from: -10; to: 8; duration: 65 }
      NumberAnimation { target: nudge; property: "x"; from: 8; to: -5; duration: 55 }
      NumberAnimation { target: nudge; property: "x"; from: -5; to: 0; duration: 45 }
    }
  }
  Connections {
    target: lock
    function onFailureMessageChanged() { if (lock.failureMessage.length > 0) shiver.restart() }
  }

  // Ctrl+E reveals the text in place of the dots, as in every design.
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    y: dots.y - Math.round(lock.u * 0.7)
    visible: lock.passwordVisible
    text: lock.passwordText
    color: Color.foreground
    font.family: Style.font.family
    font.pixelSize: Math.round(lock.u * 2.2)
    font.letterSpacing: 2
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    y: dots.y + Math.round(lock.u * 4)
    text: {
      if (lock.authenticatingPassword) return "Checking…"
      if (lock.errorState) return lock.failureMessage
      if (lock.typed === 0) return lock.fingerprintConfigured ? "Just type your password, or touch the sensor" : "Just type your password"
      return ""
    }
    color: lock.errorState ? Color.lock.textError : lock.withAlpha(Color.foreground, 0.5)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.5)
    font.letterSpacing: 1
  }

  // The real input, invisible; it only has to hold focus and take keys.
  LockInput {
    id: input
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: dots.y
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 3)
    opacity: 0
  }
}

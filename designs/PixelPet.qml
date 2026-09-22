// name: Pixel Pet
// description: A little pixel cat that blinks, watches you type, and sulks at a wrong password
//
// SmoothPixels original. A procedural sprite in the theme accent: it bobs,
// blinks now and then, glances around, looks down at the field while you
// type, squints while the password is checked, and flinches (in the error
// color) when it was wrong. All motion stops with the display.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input
  shakeOnFail: false

  readonly property real u: Math.min(width, height) / 100
  readonly property real px: Math.max(4, Math.round(u * 1.55))
  readonly property color fur: lock.errorState ? Color.lock.textError : Color.accent
  readonly property color eye: lock.lightTheme ? Color.foreground : Qt.darker(Color.background, 1.4)
  readonly property color shine: Color.foreground

  readonly property var body: [
    ".X..........X.",
    ".XX........XX.",
    ".XXX......XXX.",
    ".XXXXXXXXXXXX.",
    "XXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXX",
    ".XXXXXXXXXXXX.",
    "..XXXXXXXXXX..",
    "...XX....XX..."
  ]
  readonly property int cols: 14
  readonly property int lines: body.length

  // Expression state.
  property bool blinking: false
  property int glanceX: 0
  readonly property bool typing: passwordText.length > 0
  readonly property bool hurt: errorState
  readonly property bool thinking: authenticatingPassword
  readonly property int lookX: typing || hurt || thinking ? 0 : glanceX
  readonly property int lookY: typing ? 1 : 0
  property int tailFrame: 0

  Timer {
    interval: 2600 + Math.round(Math.random() * 2600)
    running: lock.videoPlaying && !lock.hurt
    repeat: true
    onTriggered: {
      lock.blinking = true
      blinkOff.restart()
      interval = 2600 + Math.round(Math.random() * 2600)
    }
  }
  Timer { id: blinkOff; interval: 140; onTriggered: lock.blinking = false }
  Timer {
    interval: 3200
    running: lock.videoPlaying
    repeat: true
    onTriggered: {
      var r = Math.random()
      lock.glanceX = r < 0.33 ? -1 : (r < 0.66 ? 1 : 0)
    }
  }
  Timer {
    interval: 520
    running: lock.videoPlaying
    repeat: true
    onTriggered: lock.tailFrame = 1 - lock.tailFrame
  }

  Rectangle { anchors.fill: parent; color: lock.deepen(Color.background, 1.15) }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.12)
    text: lock.clock("HH:mm")
    renderType: Text.CurveRendering
    color: Color.foreground
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 11)
    font.weight: Font.DemiBold
    font.letterSpacing: lock.u * 0.3
  }

  // Floor shadow: fixed to the floor, shrinking a little as the cat rises.
  Rectangle {
    anchors.horizontalCenter: sprite.horizontalCenter
    y: sprite.restY + sprite.height + lock.px * 0.35
    width: lock.px * (10 - Math.max(0, -sprite.bob) / lock.px * 2)
    height: lock.px * 0.8
    radius: height / 2
    color: lock.withAlpha(Qt.darker(Color.background, 2.2), 0.8)
  }

  Item {
    id: sprite
    width: lock.px * (lock.cols + 2)
    height: lock.px * lock.lines
    anchors.horizontalCenter: parent.horizontalCenter
    readonly property int restY: Math.round(lock.height * 0.44 - height / 2)
    y: restY + bob
    property real bob: 0
    SequentialAnimation on bob {
      running: lock.videoPlaying
      loops: Animation.Infinite
      NumberAnimation { to: -lock.px * 0.45; duration: 1300; easing.type: Easing.InOutSine }
      NumberAnimation { to: lock.px * 0.15; duration: 1300; easing.type: Easing.InOutSine }
    }

    // Body.
    Repeater {
      model: lock.cols * lock.lines
      delegate: Rectangle {
        required property int index
        readonly property int r: Math.floor(index / lock.cols)
        readonly property int c: index % lock.cols
        visible: lock.body[r].charAt(c) === "X"
        x: c * lock.px
        y: r * lock.px
        width: lock.px
        height: lock.px
        color: lock.fur
        Behavior on color { ColorAnimation { duration: 160 } }
      }
    }

    // Tail, two frames.
    Repeater {
      model: lock.tailFrame === 0 ? [[7, 14], [6, 15], [5, 15], [4, 14]] : [[8, 14], [7, 15], [6, 15], [5, 15]]
      delegate: Rectangle {
        required property var modelData
        x: modelData[1] * lock.px
        y: modelData[0] * lock.px
        width: lock.px
        height: lock.px
        color: lock.fur
      }
    }

    // Eyes: 2x2 blocks that follow lookX/lookY, thin lines when blinking or
    // thinking, and a pair of flat "><" lines when hurt.
    Repeater {
      model: [3, 9]
      delegate: Item {
        required property int modelData
        readonly property int baseX: modelData
        x: (baseX + lock.lookX * 0.5) * lock.px
        y: (5 + lock.lookY * 0.5) * lock.px
        width: lock.px * 2
        height: lock.px * 2
        Behavior on x { NumberAnimation { duration: 120 } }
        Behavior on y { NumberAnimation { duration: 120 } }

        // Open eye.
        Rectangle {
          anchors.fill: parent
          visible: !lock.blinking && !lock.thinking && !lock.hurt
          color: lock.eye
          Rectangle {
            x: lock.px * (0.25 + lock.lookX * 0.25)
            y: lock.px * (0.25 + lock.lookY * 0.25)
            width: lock.px * 0.55
            height: width
            color: lock.shine
          }
        }
        // Closed / squinting.
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: lock.px * 0.75
          width: lock.px * 2
          height: lock.px * 0.5
          visible: (lock.blinking || lock.thinking) && !lock.hurt
          color: lock.eye
        }
        // Hurt: a flat line plus a tick, reads as > <.
        Item {
          anchors.fill: parent
          visible: lock.hurt
          Rectangle { x: 0; y: lock.px * 0.35; width: lock.px * 2; height: lock.px * 0.45; color: lock.eye }
          Rectangle { x: lock.px * 0.75; y: lock.px * 1.1; width: lock.px * 0.5; height: lock.px * 0.6; color: lock.eye }
        }
      }
    }

    // Nose and mouth.
    Rectangle { x: 6.5 * lock.px; y: 7.6 * lock.px; width: lock.px; height: lock.px * 0.6; color: lock.eye }
    Rectangle { x: 5.6 * lock.px; y: 8.4 * lock.px; width: lock.px * 0.9; height: lock.px * 0.45; color: lock.eye; visible: !lock.hurt }
    Rectangle { x: 7.5 * lock.px; y: 8.4 * lock.px; width: lock.px * 0.9; height: lock.px * 0.45; color: lock.eye; visible: !lock.hurt }
    Rectangle { x: 6.1 * lock.px; y: 8.6 * lock.px; width: lock.px * 1.8; height: lock.px * 0.5; color: lock.eye; visible: lock.hurt }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: sprite.bottom
    anchors.topMargin: Math.round(lock.u * 3.5)
    text: lock.hurt ? "Hmm, that was not it" : (lock.thinking ? "Checking…" : (lock.typing ? "…" : lock.greeting() + ", " + lock.userName))
    color: lock.withAlpha(Color.foreground, 0.7)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.8)
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.76 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.withAlpha(lock.deepen(Color.background, 1.15), 0.92)
  }
}

// name: Dot Matrix
// description: The time on a glowing LED board in your accent color
//
// SmoothPixels original. A dark room, a bezelled LED panel, and the time
// picked out in lit dots of the theme accent with the colon blinking the
// seconds. A failed attempt turns the lit dots to the theme's error color
// until you type again.
import QtQuick
import QtQuick.Shapes
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  // Lit dots sit a notch toward the foreground so they clear the accent's own
  // brightness; unlit ones are only a faint trace of the grid, fainter on dark
  // themes where the glow already separates the digits.
  readonly property color lit: lock.errorState ? Color.lock.textError : lock.raise(Color.accent, 1.1)
  readonly property color unlit: lock.withAlpha(Color.foreground, lock.lightTheme ? 0.09 : 0.05)
  readonly property color panel: lock.deepen(Color.background, 1.65)
  readonly property real pitch: lock.u * 2.8
  readonly property string digits: lock.clock("HH:mm").substring(0, 5)
  readonly property bool colonOn: lock.now.getSeconds() % 2 === 0

  // Standard 5x7 digit shapes; the colon is three columns wide.
  readonly property var glyphs: ({
    "0": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["01110", "10001", "00001", "00110", "00001", "10001", "01110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "10000", "11110", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
    ":": ["000", "010", "010", "000", "010", "010", "000"],
    " ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"]
  })

  Rectangle { anchors.fill: parent; color: lock.deepen(Color.background, 1.25) }

  // Vignette: the room falls off into darkness away from the panel.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 0
      fillGradient: RadialGradient {
        centerX: lock.width / 2
        centerY: lock.height * 0.4
        focalX: centerX
        focalY: centerY
        centerRadius: lock.width * 0.7
        GradientStop { position: 0; color: "transparent" }
        GradientStop { position: 0.55; color: lock.withAlpha(lock.deepen(Color.background, 1.8), 0.35) }
        GradientStop { position: 1; color: lock.withAlpha(lock.deepen(Color.background, 1.8), 0.85) }
      }
      PathSvg { path: "M 0 0 H " + lock.width + " V " + lock.height + " H 0 Z" }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // The panel: a bezel with an inset face the LEDs sit on.
  Rectangle {
    anchors.centerIn: board
    width: board.width + lock.pitch * 3.2
    height: board.height + lock.pitch * 2.6
    radius: Math.round(lock.pitch * 0.9)
    color: lock.deepen(Color.background, 1.45)
    border.width: 1
    border.color: lock.withAlpha(Color.foreground, 0.10)

    Rectangle {
      anchors.fill: parent
      anchors.margins: Math.round(lock.pitch * 0.55)
      radius: Math.round(lock.pitch * 0.6)
      color: lock.panel
      border.width: 1
      border.color: lock.withAlpha(Color.background, 0.9)
    }
  }

  Row {
    id: board
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.36 - height / 2)
    spacing: Math.round(lock.pitch * 1.7)

    Repeater {
      model: 5
      delegate: Grid {
        id: digit
        required property int index
        readonly property string ch: lock.digits.charAt(index) || " "
        readonly property var pattern: lock.glyphs[ch] || lock.glyphs[" "]
        readonly property bool colon: ch === ":"
        readonly property int cols: pattern[0].length
        columns: cols
        spacing: Math.round(lock.pitch * 0.26)

        Repeater {
          model: digit.cols * 7
          delegate: Item {
            required property int index
            readonly property bool on: digit.pattern[Math.floor(index / digit.cols)].charAt(index % digit.cols) === "1" && (!digit.colon || lock.colonOn)
            width: Math.round(lock.pitch * 0.74)
            height: width

            Rectangle {
              anchors.centerIn: parent
              width: parent.width * 1.4
              height: width
              radius: width / 2
              color: lock.lit
              opacity: parent.on && !lock.lightTheme ? 0.14 : 0
              visible: opacity > 0
            }
            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: parent.on ? lock.lit : lock.unlit
              Behavior on color { ColorAnimation { duration: 140 } }
            }
          }
        }
      }
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: board.bottom
    anchors.topMargin: Math.round(lock.u * 5.2)
    text: Qt.formatDate(lock.now, "dddd  ·  d MMMM").toUpperCase() + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
    color: lock.withAlpha(Color.foreground, 0.6)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.5)
    font.letterSpacing: 3
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.72 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.panel
    accentColor: Color.accent
    placeholderColor: lock.withAlpha(Color.foreground, 0.45)
  }
}

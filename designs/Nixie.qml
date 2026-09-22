// name: Nixie
// description: Four nixie tubes, the time glowing as bent wire behind glass
//
// SmoothPixels original. The digits are what a nixie tube really holds: ten
// wire cathodes stacked in a glass envelope, drawn here as stroked paths with
// round caps. The lit one glows a hot near-white over neon orange, the other
// nine sit faintly behind it. The one original with a fixed hue on purpose;
// the chrome around the tubes still follows the theme. A neon lamp between
// the pairs blinks the seconds.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color neon: lock.errorState ? Color.lock.textError : "#ff8f2e"
  readonly property color core: lock.errorState ? Qt.lighter(Color.lock.textError, 1.5) : "#ffe9c6"
  readonly property string digits: lock.clock("HH:mm").substring(0, 5)
  readonly property bool colonOn: lock.now.getSeconds() % 2 === 0

  // Each digit as one bent wire in a 100 by 160 box.
  readonly property var wire: ({
    "0": "M 50 12 C 82 12 88 40 88 80 C 88 120 82 148 50 148 C 18 148 12 120 12 80 C 12 40 18 12 50 12 Z",
    "1": "M 30 38 L 56 12 L 56 148",
    "2": "M 14 50 C 14 8 86 8 86 50 C 86 80 30 100 14 148 L 88 148",
    "3": "M 18 34 C 30 6 86 8 86 44 C 86 64 66 76 48 78 C 68 78 90 90 90 116 C 90 156 24 158 12 126",
    "4": "M 70 148 L 70 12 L 10 106 L 92 106",
    "5": "M 84 14 L 24 14 L 18 76 C 44 62 90 68 88 110 C 86 150 30 156 12 126",
    "6": "M 74 16 C 44 30 16 62 16 104 C 16 148 84 152 84 108 C 84 72 34 66 18 90",
    "7": "M 12 14 L 88 14 L 42 148",
    "8": "M 50 76 C 18 76 18 12 50 12 C 82 12 82 76 50 76 C 12 76 12 148 50 148 C 88 148 88 76 50 76",
    "9": "M 26 144 C 56 130 84 98 84 56 C 84 12 16 8 16 54 C 16 90 68 94 82 70"
  })
  readonly property var allDigits: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0; color: lock.deepen(Color.background, 1.85) }
      GradientStop { position: 1; color: lock.deepen(Color.background, 1.25) }
    }
  }

  // Light spilling from the tubes into the room.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 0
      fillGradient: RadialGradient {
        centerX: lock.width / 2
        centerY: lock.height * 0.40
        focalX: centerX
        focalY: centerY
        centerRadius: lock.height * 0.6
        GradientStop { position: 0; color: lock.withAlpha(lock.neon, 0.10) }
        GradientStop { position: 0.55; color: lock.withAlpha(lock.neon, 0.02) }
        GradientStop { position: 1; color: "transparent" }
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

  // One wire digit, scaled to k. Rendered through a parent sized at the
  // scaled size, so glow layers are captured at full resolution.
  component Wire: Item {
    id: w
    property string ch: "0"
    property color stroke: lock.neon
    property real thickness: 7
    property real k: 1
    width: 100 * k
    height: 160 * k
    Shape {
      width: 100
      height: 160
      scale: w.k
      transformOrigin: Item.TopLeft
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: w.stroke
        strokeWidth: w.thickness
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: lock.wire[w.ch] || lock.wire["0"] }
      }
    }
  }

  component Tube: Item {
    id: tube
    property string digit: "0"
    readonly property real glassW: lock.u * 12.5
    readonly property real glassH: lock.u * 25
    readonly property real k: glassH * 0.5 / 160
    readonly property real digitY: glassH * 0.20
    width: glassW
    height: glassH + lock.u * 6.4

    // Socket with a thin rim, pins underneath.
    Rectangle {
      id: socket
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: lock.u * 1.8
      width: tube.glassW * 0.86
      height: lock.u * 4.2
      radius: lock.u * 0.6
      color: Qt.darker(Color.background, 2.5)
      border.width: 1
      border.color: lock.withAlpha(Color.foreground, 0.12)
      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: Math.max(2, lock.u * 0.3)
        radius: height / 2
        color: lock.withAlpha(Color.foreground, 0.22)
      }
    }
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: socket.bottom
      spacing: lock.u * 1.3
      Repeater {
        model: 4
        delegate: Rectangle {
          width: Math.max(2, lock.u * 0.3)
          height: lock.u * 1.8
          color: lock.withAlpha(Color.foreground, 0.3)
        }
      }
    }

    // Glass envelope.
    Rectangle {
      id: glass
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: lock.u * 1.2
      width: tube.glassW
      height: tube.glassH
      radius: width / 2
      color: Qt.rgba(0, 0, 0, 0.34)
      border.width: 1
      border.color: lock.withAlpha(Color.foreground, 0.16)
      clip: true

      // The nine unlit cathodes, stacked with a hint of depth.
      Repeater {
        model: lock.allDigits
        delegate: Wire {
          required property string modelData
          required property int index
          visible: modelData !== tube.digit
          ch: modelData
          k: tube.k
          x: (glass.width - width) / 2 + (index - 4.5) * lock.u * 0.09
          y: tube.digitY + (index - 4.5) * lock.u * 0.05
          stroke: lock.withAlpha(Color.foreground, 0.055)
          thickness: 6
        }
      }

      // The lit cathode: a wide glow, a tight glow, the wire, a hot core.
      Item {
        x: (glass.width - width) / 2
        y: tube.digitY
        width: 100 * tube.k
        height: 160 * tube.k
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; brightness: 0.2 }
        opacity: 0.85
        Wire { anchors.fill: parent; ch: tube.digit; k: tube.k; stroke: lock.neon; thickness: 9 }
      }
      Item {
        x: (glass.width - width) / 2
        y: tube.digitY
        width: 100 * tube.k
        height: 160 * tube.k
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.5; blurMax: 16; brightness: 0.3 }
        Wire { anchors.fill: parent; ch: tube.digit; k: tube.k; stroke: lock.neon; thickness: 8 }
      }
      Wire { x: (glass.width - width) / 2; y: tube.digitY; ch: tube.digit; k: tube.k; stroke: lock.neon; thickness: 7 }
      Wire { x: (glass.width - width) / 2; y: tube.digitY; ch: tube.digit; k: tube.k; stroke: lock.core; thickness: 3 }

      // Glass: a sheen over the dome and a streak down the left.
      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: tube.glassH * 0.3
        gradient: Gradient {
          GradientStop { position: 0; color: lock.withAlpha(Color.foreground, 0.09) }
          GradientStop { position: 1; color: "transparent" }
        }
      }
      Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: tube.glassW * 0.13
        anchors.top: parent.top
        anchors.topMargin: tube.glassH * 0.12
        width: Math.max(2, tube.glassW * 0.045)
        height: tube.glassH * 0.6
        radius: width / 2
        gradient: Gradient {
          GradientStop { position: 0; color: lock.withAlpha(Color.foreground, 0.20) }
          GradientStop { position: 1; color: "transparent" }
        }
      }
    }

    // Exhaust tip.
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: glass.top
      anchors.bottomMargin: -lock.u * 0.35
      width: lock.u * 1.1
      height: lock.u * 1.5
      radius: width / 2
      color: Qt.rgba(0, 0, 0, 0.34)
      border.width: 1
      border.color: lock.withAlpha(Color.foreground, 0.16)
    }
  }

  Row {
    id: tubes
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.40 - height / 2)
    spacing: Math.round(lock.u * 1.8)

    Tube { digit: lock.digits.charAt(0) }
    Tube { digit: lock.digits.charAt(1) }

    // Neon lamp between the pairs.
    Item {
      width: lock.u * 4
      height: lock.u * 31
      Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -lock.u * 2
        spacing: lock.u * 3.6
        Repeater {
          model: 2
          delegate: Item {
            width: lock.u * 1.2
            height: width
            Rectangle {
              anchors.centerIn: parent
              width: parent.width * 3.2
              height: width
              radius: width / 2
              color: lock.neon
              opacity: lock.colonOn ? 0.16 : 0
              Behavior on opacity { NumberAnimation { duration: 160 } }
            }
            Rectangle {
              anchors.centerIn: parent
              width: parent.width * 1.7
              height: width
              radius: width / 2
              color: lock.neon
              opacity: lock.colonOn ? 0.55 : 0.08
              Behavior on opacity { NumberAnimation { duration: 160 } }
            }
            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: lock.core
              opacity: lock.colonOn ? 1 : 0.12
              Behavior on opacity { NumberAnimation { duration: 160 } }
            }
          }
        }
      }
    }

    Tube { digit: lock.digits.charAt(3) }
    Tube { digit: lock.digits.charAt(4) }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: tubes.bottom
    anchors.topMargin: Math.round(lock.u * 3)
    text: Qt.formatDate(lock.now, "dddd  ·  d MMMM").toUpperCase() + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
    color: lock.withAlpha(Color.foreground, 0.55)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.5)
    font.letterSpacing: 3
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.81 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.withAlpha(lock.deepen(Color.background, 1.85), 0.92)
    accentColor: lock.neon
    placeholderColor: lock.withAlpha(Color.foreground, 0.45)
  }
}

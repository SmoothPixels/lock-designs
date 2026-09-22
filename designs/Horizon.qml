// name: Horizon
// description: A sky, sun and moon that follow the hour, over rolling hills in your theme
// timebased: 1
//
// SmoothPixels original. The sky blends between night and day tones derived
// from the active theme, the sun crosses it between 6 and 18 and the moon
// takes the night shift, and three procedural ridges close the bottom. No
// assets, no fixed palette.
import QtQuick
import QtQuick.Shapes
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property real hourFrac: now.getHours() + now.getMinutes() / 60
  // Height of the sun: 1 at noon, 0 at sunrise and sunset, negative at night.
  readonly property real sunElev: Math.sin(Math.PI * (hourFrac - 6) / 12)
  readonly property bool sunUp: sunElev > 0
  // 0 at night, 1 in full day, ramping through twilight.
  readonly property real day: Math.max(0, Math.min(1, (sunElev + 0.15) / 0.5))
  // Peaks around sunrise and sunset, tints the sky with the accent.
  readonly property real twilight: Math.max(0, 1 - Math.abs(sunElev) / 0.3)

  function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
  }

  readonly property color nightTop: lock.deepen(Color.background, 1.7)
  readonly property color nightBottom: Color.background
  readonly property color dayTop: mix(Color.background, Color.foreground, 0.30)
  readonly property color dayBottom: mix(Color.background, Color.accent, 0.30)
  readonly property color skyTop: mix(mix(nightTop, dayTop, day), Color.accent, twilight * 0.20)
  readonly property color skyBottom: mix(mix(nightBottom, dayBottom, day), Color.accent, twilight * 0.55)
  readonly property color ink: Color.foreground

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0; color: lock.skyTop }
      GradientStop { position: 1; color: lock.skyBottom }
    }
  }

  // Stars fade out with the day.
  Repeater {
    model: 110
    delegate: Rectangle {
      required property int index
      readonly property real s1: ((index * 7919 + 104729) % 10007) / 10007
      readonly property real s2: ((index * 15485863 + 32452843) % 10007) / 10007
      x: lock.width * s1
      y: lock.height * 0.72 * s2 * s2
      width: 1 + Math.round(s1 * 2)
      height: width
      radius: width / 2
      color: lock.ink
      opacity: (1 - lock.day) * (0.25 + 0.6 * s2)
    }
  }

  // The sun by day, the moon by night, both on the same arc.
  readonly property real arcT: sunUp ? (hourFrac - 6) / 12 : ((hourFrac + 6) % 24) / 12
  readonly property real arcElev: sunUp ? sunElev : Math.sin(Math.PI * arcT)
  Item {
    id: orb
    readonly property real size: lock.u * (lock.sunUp ? 9 : 7)
    x: lock.width * (0.08 + 0.84 * lock.arcT) - size / 2
    y: lock.height * (0.66 - 0.52 * lock.arcElev) - size / 2
    width: size
    height: size
    readonly property color body: lock.sunUp ? lock.mix(Color.accent, Color.foreground, 0.35) : lock.mix(Color.foreground, Color.background, 0.15)

    // Halo: a radial falloff, so it fades into the sky instead of sitting on
    // it as a flat disc.
    Shape {
      id: halo
      anchors.centerIn: parent
      width: orb.size * 3.4
      height: width
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: 0
        fillGradient: RadialGradient {
          centerX: halo.width / 2
          centerY: halo.height / 2
          focalX: centerX
          focalY: centerY
          centerRadius: halo.width / 2
          GradientStop { position: 0; color: lock.withAlpha(orb.body, lock.sunUp ? 0.30 : 0.16) }
          GradientStop { position: 0.45; color: lock.withAlpha(orb.body, lock.sunUp ? 0.08 : 0.04) }
          GradientStop { position: 1; color: "transparent" }
        }
        PathSvg { path: "M 0 0 H " + halo.width + " V " + halo.height + " H 0 Z" }
      }
    }

    Rectangle {
      visible: lock.sunUp
      anchors.fill: parent
      radius: width / 2
      color: orb.body
    }

    // The moon is a true crescent, so the sky shows through its dark side.
    Shape {
      visible: !lock.sunUp
      anchors.fill: parent
      rotation: -28
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: 0
        fillColor: orb.body
        PathSvg { path: lock.crescent(orb.size) }
      }
    }
  }

  // Outer semicircle on the left, a shallower inner arc back up: the sliver
  // between them is the lit side of the moon.
  function crescent(d) {
    var r = d / 2
    var inner = r * 1.15
    return "M " + r + " 0 A " + r + " " + r + " 0 0 0 " + r + " " + d
         + " A " + inner + " " + inner + " 0 0 1 " + r + " 0 Z"
  }

  // Three ridges, generated from a seed so they are the same every time.
  function ridge(seed, base, amp, segs) {
    var w = width, h = height
    var r = seed
    function rnd() { r = (r * 1103515245 + 12345) & 0x7fffffff; return (r % 1000) / 1000 }
    var pts = []
    for (var i = 0; i <= segs; i++) pts.push({ x: w * i / segs, y: h * (base - amp * rnd()) })
    var d = "M 0 " + h + " L " + pts[0].x + " " + pts[0].y
    for (var j = 0; j < segs; j++) {
      var p0 = pts[j], p1 = pts[j + 1], cx = (p0.x + p1.x) / 2
      d += " C " + cx + " " + p0.y + " " + cx + " " + p1.y + " " + p1.x + " " + p1.y
    }
    return d + " L " + w + " " + h + " Z"
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 0
      fillColor: lock.mix(lock.skyBottom, Qt.darker(Color.background, 1.5), 0.45)
      PathSvg { path: lock.ridge(11, 0.74, 0.14, 7) }
    }
    ShapePath {
      strokeWidth: 0
      fillColor: lock.mix(lock.skyBottom, Qt.darker(Color.background, 1.6), 0.7)
      PathSvg { path: lock.ridge(23, 0.82, 0.11, 6) }
    }
    ShapePath {
      strokeWidth: 0
      fillColor: Qt.darker(Color.background, 1.7)
      PathSvg { path: lock.ridge(37, 0.90, 0.08, 5) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    y: lock.height * 0.22
    spacing: lock.u * 1.2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      renderType: Text.CurveRendering
      color: lock.ink
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 15)
      font.weight: Font.Light
      font.letterSpacing: lock.u * 0.4
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd, d MMMM") + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
      color: lock.withAlpha(lock.ink, 0.75)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.7)
      font.letterSpacing: 2
    }
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: lock.height * 0.80 - height / 2
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.withAlpha(lock.deepen(Color.background, 1.7), 0.85)
    placeholder: lock.greeting() + ", " + lock.userName
  }
}

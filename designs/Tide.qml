// name: Tide
// description: Slow waves in your theme's colors, the sign-in floating on the surface
//
// SmoothPixels original. Three layers of water roll across the bottom third,
// each on its own rhythm, in translucent tints of the theme accent; the clock
// hangs in the air above and the password field sits on the waterline. The
// motion pauses whenever the display is blanked.
import QtQuick
import QtQuick.Shapes
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  property real phase: 0
  NumberAnimation on phase {
    from: 0; to: Math.PI * 2
    duration: 16000
    loops: Animation.Infinite
    running: lock.videoPlaying
  }

  function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0; color: lock.deepen(Color.background, 1.45) }
      GradientStop { position: 1; color: Color.background }
    }
  }

  // A wave as an SVG path: a smooth curve across the width, closed to the
  // bottom edge. freq is how many crests fit the width, speed how fast the
  // phase carries them along.
  function wave(baseline, amp, freq, speed, offset) {
    var w = width, h = height, segs = 14
    var d = "M 0 " + h
    for (var i = 0; i <= segs; i++) {
      var x = w * i / segs
      var y = h * baseline + amp * Math.sin(offset + phase * speed + freq * i / segs * Math.PI * 2)
      if (i === 0) { d += " L " + x + " " + y; continue }
      var px = w * (i - 1) / segs
      var py = h * baseline + amp * Math.sin(offset + phase * speed + freq * (i - 1) / segs * Math.PI * 2)
      var cx = (px + x) / 2
      d += " C " + cx + " " + py + " " + cx + " " + y + " " + x + " " + y
    }
    return d + " L " + w + " " + h + " Z"
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 0
      fillColor: lock.withAlpha(Color.accent, 0.10)
      PathSvg { path: lock.wave(0.68, lock.u * 2.4, 1.6, 1.0, 0.0) }
    }
    ShapePath {
      strokeWidth: 0
      fillColor: lock.withAlpha(Color.accent, 0.16)
      PathSvg { path: lock.wave(0.75, lock.u * 2.0, 2.2, -1.4, 1.9) }
    }
    ShapePath {
      strokeWidth: 0
      fillColor: lock.mix(Color.background, Color.accent, 0.22)
      PathSvg { path: lock.wave(0.83, lock.u * 1.6, 2.8, 2.0, 4.1) }
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
    y: Math.round(lock.height * 0.20)
    spacing: Math.round(lock.u * 1.4)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      renderType: Text.CurveRendering
      color: Color.foreground
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 17)
      font.weight: Font.Light
      font.letterSpacing: lock.u * 0.6
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.greeting() + ", " + lock.userName + "  ·  " + Qt.formatDate(lock.now, "dddd d MMMM") + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
      color: lock.withAlpha(Color.foreground, 0.6)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.6)
      font.letterSpacing: 2
    }
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.68 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    radius: height / 2
    color: lock.withAlpha(lock.deepen(Color.background, 1.45), 0.92)
  }
}

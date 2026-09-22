// name: Circuit
// description: A chip carrying the time, traces routed out to pads, pulses running along them
//
// SmoothPixels original. The clock is etched on an IC package in the middle
// of a board; sixteen traces leave its pins, bend at 45 degrees and end in
// pads, all in the theme accent. A few pulses travel the traces while the
// display is awake. The routing is generated from a fixed seed, so the board
// is the same every time.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color lit: lock.errorState ? Color.lock.textError : Color.accent
  readonly property color traceColor: lock.withAlpha(lit, 0.30)
  readonly property color padColor: lock.withAlpha(lit, 0.55)
  readonly property real chipW: u * 46
  readonly property real chipH: u * 22
  readonly property real chipX: width / 2 - chipW / 2
  readonly property real chipY: height * 0.40 - chipH / 2
  readonly property int pinsPerSide: 8
  readonly property real pinLength: u * 1.8

  // Every trace as a list of points, from the pin outward.
  readonly property var traces: {
    var w = width, h = height
    var list = []
    var r = 90210
    function rnd() { r = (r * 1103515245 + 12345) & 0x7fffffff; return (r % 10000) / 10000 }
    for (var side = -1; side <= 1; side += 2) {
      for (var i = 0; i < pinsPerSide; i++) {
        var y = chipY + chipH * (i + 0.5) / pinsPerSide
        var x = width / 2 + side * (chipW / 2 + pinLength)
        var pts = [[x, y]]
        x += side * u * (3 + rnd() * 9); pts.push([x, y])
        var dir = i < pinsPerSide / 2 ? -1 : 1
        var d = u * (3 + rnd() * 12)
        x += side * d; y += dir * d; pts.push([x, y])
        if (rnd() < 0.6) {
          x += side * u * (2 + rnd() * 8); pts.push([x, y])
          var d2 = u * (2 + rnd() * 7)
          x += side * d2; y += (rnd() < 0.7 ? dir : -dir) * d2; pts.push([x, y])
        }
        var fx = x + side * u * (4 + rnd() * 14)
        fx = side < 0 ? Math.max(fx, u * 3) : Math.min(fx, w - u * 3)
        y = Math.max(u * 3, Math.min(h - u * 3, y))
        pts.push([fx, y])
        list.push(pts)
      }
    }
    return list
  }

  function svgOf(pts) {
    var d = "M " + pts[0][0] + " " + pts[0][1]
    for (var i = 1; i < pts.length; i++) d += " L " + pts[i][0] + " " + pts[i][1]
    return d
  }

  Rectangle { anchors.fill: parent; color: lock.deepen(Color.background, 1.35) }

  // Board: traces, pads and a scattering of vias, painted once.
  Canvas {
    id: board
    anchors.fill: parent
    property color stroke: lock.traceColor
    property color pad: lock.padColor
    property var routes: lock.traces
    onStrokeChanged: requestPaint()
    onRoutesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.lineCap = "round"
      ctx.lineJoin = "round"
      ctx.lineWidth = Math.max(2, lock.u * 0.32)
      ctx.strokeStyle = stroke
      for (var t = 0; t < routes.length; t++) {
        var pts = routes[t]
        ctx.beginPath()
        ctx.moveTo(pts[0][0], pts[0][1])
        for (var i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1])
        ctx.stroke()
        // Pad at the far end: a ring with a drilled center.
        var e = pts[pts.length - 1]
        ctx.lineWidth = Math.max(2, lock.u * 0.4)
        ctx.strokeStyle = pad
        ctx.beginPath(); ctx.arc(e[0], e[1], lock.u * 0.9, 0, Math.PI * 2); ctx.stroke()
        ctx.fillStyle = lock.deepen(Color.background, 1.35)
        ctx.beginPath(); ctx.arc(e[0], e[1], lock.u * 0.35, 0, Math.PI * 2); ctx.fill()
        ctx.lineWidth = Math.max(2, lock.u * 0.32)
        ctx.strokeStyle = stroke
      }
      // Vias: small rings off in the quiet areas.
      var r = 777
      function rnd() { r = (r * 1103515245 + 12345) & 0x7fffffff; return (r % 10000) / 10000 }
      ctx.strokeStyle = Qt.rgba(stroke.r, stroke.g, stroke.b, 0.14)
      ctx.lineWidth = Math.max(1, lock.u * 0.25)
      for (var v = 0; v < 26; v++) {
        var vx = rnd() * width, vy = rnd() * height
        var inChip = vx > lock.chipX - lock.u * 4 && vx < lock.chipX + lock.chipW + lock.u * 4 && vy > lock.chipY - lock.u * 4 && vy < lock.chipY + lock.chipH + lock.u * 4
        if (inChip || vy > height * 0.68 && vy < height * 0.82 && Math.abs(vx - width / 2) < lock.u * 18) continue
        ctx.beginPath(); ctx.arc(vx, vy, lock.u * 0.55, 0, Math.PI * 2); ctx.stroke()
      }
    }
  }

  // Pulses: a bright dot riding a trace from the pin to the pad.
  component Pulse: Item {
    id: pulse
    property int route: 0
    property int duration: 4000
    property real progress: 0
    readonly property var pts: lock.traces[route]
    x: interp.x - width / 2
    y: interp.y - height / 2
    width: lock.u * 1.1
    height: width
    PathInterpolator {
      id: interp
      progress: pulse.progress
      path: Path { PathSvg { path: lock.svgOf(pulse.pts) } }
    }
    SequentialAnimation on progress {
      running: lock.videoPlaying
      loops: Animation.Infinite
      PauseAnimation { duration: pulse.route * 230 }
      NumberAnimation { from: 0; to: 1; duration: pulse.duration; easing.type: Easing.InOutSine }
      PauseAnimation { duration: 900 }
    }
    opacity: progress > 0.02 && progress < 0.98 ? 1 : 0
    Rectangle {
      anchors.centerIn: parent
      width: parent.width * 3
      height: width
      radius: width / 2
      color: lock.lit
      opacity: 0.22
    }
    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: lock.raise(lock.lit, 1.4)
    }
  }
  Pulse { route: 1; duration: 4200 }
  Pulse { route: 5; duration: 5600 }
  Pulse { route: 9; duration: 3900 }
  Pulse { route: 12; duration: 6100 }
  Pulse { route: 14; duration: 4800 }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Pins along both long sides of the chip.
  Repeater {
    model: lock.pinsPerSide * 2
    delegate: Rectangle {
      required property int index
      readonly property int side: index < lock.pinsPerSide ? -1 : 1
      readonly property int slot: index % lock.pinsPerSide
      width: lock.pinLength
      height: Math.max(3, lock.u * 0.7)
      radius: height / 3
      x: side < 0 ? lock.chipX - width : lock.chipX + lock.chipW
      y: lock.chipY + lock.chipH * (slot + 0.5) / lock.pinsPerSide - height / 2
      color: lock.withAlpha(Color.foreground, 0.35)
    }
  }

  // The package.
  Rectangle {
    id: chip
    x: lock.chipX
    y: lock.chipY
    width: lock.chipW
    height: lock.chipH
    radius: Math.round(lock.u * 1.1)
    color: lock.deepen(Color.background, 1.75)
    border.width: 1
    border.color: lock.withAlpha(Color.foreground, 0.16)

    // Pin-one mark.
    Rectangle {
      x: lock.u * 1.6
      y: lock.u * 1.6
      width: lock.u * 1.1
      height: width
      radius: width / 2
      color: lock.withAlpha(Color.foreground, 0.25)
    }

    Column {
      anchors.centerIn: parent
      spacing: Math.round(lock.u * 0.6)
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: lock.clock("HH:mm")
        renderType: Text.CurveRendering
        color: lock.lit
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.chipH * 0.46)
        font.weight: Font.DemiBold
        font.letterSpacing: lock.u * 0.3
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "OMARCHY  ·  " + Qt.formatDate(lock.now, "yyyy-MM-dd  ·  ddd").toUpperCase() + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
        color: lock.withAlpha(Color.foreground, 0.55)
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 1.4)
        font.letterSpacing: 3
      }
    }
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.75 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.deepen(Color.background, 1.75)
    accentColor: Color.accent
    placeholder: lock.greeting() + ", " + lock.userName
  }
}

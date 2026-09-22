// name: Starry City
// description: A procedural pixel skyline whose windows come on and go out through the night
// SmoothPixels lock design: a procedural pixel-block skyline at night, lit
// windows scattered across the silhouette. Started as a riff on the mood of
// Darkkal44's qylock "pixel-cyberpunk" theme, but once every color moved to
// following the active Omarchy theme instead of a fixed neon palette, it
// stopped reading as "cyberpunk" — renamed to match what it actually is.
//
// Fully theme-following: every color reads from Color.lock.*/Color.accent
// so this matches whatever Omarchy theme is active, same as the built-in
// designs (Zen, Neon, etc.) do. No fixed palette.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property color glow: lock.errorState ? Color.lock.textError : Color.lock.borderActive

  Rectangle { anchors.fill: parent; color: lock.deepen(Color.background, 1.15) }

  // The skyline, generated once from a fixed seed: block buildings with a
  // grid of window slots. Most lit windows are painted onto the canvas and
  // never change; a handful become live items below that switch on, hold,
  // and fade out on their own slow schedules, so the city breathes without
  // repainting anything.
  readonly property var city: {
    var w = width, h = height
    var blockW = 28, rowH = 18
    var count = Math.ceil(w / blockW) + 1
    var r = 1337
    function next() { r = (r * 1103515245 + 12345) & 0x7fffffff; return (r % 1000) / 1000 }
    var buildings = [], windows = [], live = []
    for (var i = 0; i < count; i++) {
      var bh = 60 + Math.floor(next() * (h * 0.5))
      var x = i * blockW
      buildings.push({ x: x, y: h - bh, w: blockW - 4, h: bh })
      var rows = Math.floor(bh / rowH)
      for (var row = 0; row < rows; row++) {
        var win = { x: x + 6, y: h - bh + row * rowH + 6 }
        var lit = next() > 0.6
        if (next() < 0.14) live.push(win)
        else if (lit) windows.push(win)
      }
    }
    return { buildings: buildings, windows: windows, live: live }
  }

  Canvas {
    anchors.fill: parent
    property color glowColor: lock.glow
    property var scene: lock.city
    onGlowColorChanged: requestPaint()
    onSceneChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.fillStyle = Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
      var b = scene.buildings
      for (var i = 0; i < b.length; i++) ctx.fillRect(b[i].x, b[i].y, b[i].w, b[i].h)
      ctx.fillStyle = Qt.rgba(lock.glow.r, lock.glow.g, lock.glow.b, 0.55)
      var wins = scene.windows
      for (var k = 0; k < wins.length; k++) ctx.fillRect(wins[k].x, wins[k].y, 6, 6)
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()
  }

  // Windows that come and go. Each has its own pause, warm-up, hold and
  // fade, all long, and all tied to the display being awake.
  Repeater {
    model: lock.city.live
    delegate: Rectangle {
      id: win
      required property var modelData
      required property int index
      readonly property real s: ((index * 7919 + 104729) % 10007) / 10007
      readonly property real t: ((index * 15485863 + 32452843) % 10007) / 10007
      x: modelData.x
      y: modelData.y
      width: 6
      height: 6
      color: lock.glow
      opacity: t < 0.5 ? 0.55 : 0
      SequentialAnimation on opacity {
        running: lock.videoPlaying
        loops: Animation.Infinite
        PauseAnimation { duration: 300 + win.s * 5000 }
        NumberAnimation { to: 0.55; duration: 900 + win.t * 1600; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2500 + win.s * 7000 }
        NumberAnimation { to: 0; duration: 1500 + win.t * 2500; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 1500 + win.t * 5000 }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Column {
    anchors.centerIn: parent
    spacing: 28

    Avatar {
      anchors.horizontalCenter: parent.horizontalCenter
      lock: lock
      width: 88
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      renderType: Text.CurveRendering
      color: lock.glow
      font.family: lock.displayFont
      font.pixelSize: Math.round(Style.font.baseSize * 7)
      font.weight: Font.DemiBold
      font.letterSpacing: 4
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd d MMMM").toUpperCase()
      color: lock.withAlpha(Color.lock.text, 0.65)
      font.family: lock.displayFont
      font.pixelSize: Style.font.subtitle
      font.letterSpacing: 3
    }

    PasswordField {
      id: field
      lock: lock
      anchors.horizontalCenter: parent.horizontalCenter
      width: 380
      height: 54
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: lock.errorState
      text: lock.failureMessage
      color: Color.lock.textError
      font.family: lock.displayFont
      font.pixelSize: Style.font.body
    }
  }
}

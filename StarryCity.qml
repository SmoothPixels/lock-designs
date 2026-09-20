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
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property color glow: lock.errorState ? Color.lock.textError : Color.lock.borderActive

  Rectangle { anchors.fill: parent; color: Qt.darker(Color.background, 1.15) }

  // Placeholder skyline: procedural pixel-block city, no external asset.
  Canvas {
    anchors.fill: parent
    property int seed: 1337
    property color glowColor: lock.glow
    onGlowColorChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var blockW = 28
      var count = Math.ceil(width / blockW) + 1
      var rnd = seed
      function next() { rnd = (rnd * 1103515245 + 12345) & 0x7fffffff; return (rnd % 1000) / 1000 }
      for (var i = 0; i < count; i++) {
        var h = 60 + Math.floor(next() * (height * 0.5))
        var x = i * blockW
        ctx.fillStyle = Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
        ctx.fillRect(x, height - h, blockW - 4, h)
        var winRows = Math.floor(h / 18)
        for (var r = 0; r < winRows; r++) {
          if (next() > 0.6) {
            ctx.fillStyle = Qt.rgba(lock.glow.r, lock.glow.g, lock.glow.b, 0.55)
            ctx.fillRect(x + 6, height - h + r * 18 + 6, 6, 6)
          }
        }
      }
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()
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
      color: lock.glow
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.baseSize * 7)
      font.weight: Font.DemiBold
      font.letterSpacing: 4
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd d MMMM").toUpperCase()
      color: lock.withAlpha(Color.lock.text, 0.65)
      font.family: Style.font.family
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
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}

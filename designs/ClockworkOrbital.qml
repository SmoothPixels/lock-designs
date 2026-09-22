// source: qylock
// name: Clockwork Orbital
// description: Clock mechanism wallpaper from Wallsflow · Outfit font
// Original design inspired by Darkkal44's qylock "clockwork/orbital" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The source renders a huge circular
// minute/second dial centered off-screen so only a bowed vertical slice of
// ticks is visible next to a giant hour digit -- like looking at the edge of
// a clockwork gear. That layout technique (trig-positioned tick Repeaters on
// an off-screen circle) is recreated here from scratch against Omarchy's
// DesignBase/PasswordField, not copied from qylock's GPL source, and drops
// the SDDM-only multi-user/session/power row. Only the bundled Outfit-Black
// font is reused (bundled in clockwork-orbital-assets/), which tested clean
// for every letterform, so it is used throughout.
import QtQuick
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("clockwork-orbital-assets/")
  property color bg: "#000000"
  property color mainText: "#ffffff"
  property color dimText: "#9a9a9a"
  property color pillColor: "#080808"
  property color pillBorder: "#2c2c2c"
  // Everything on the dial scales with the screen; the fixed pixel values
  // this started with were tuned for a 1080p panel and vanish on 4K.
  readonly property real u: Math.min(width, height) / 100

  readonly property real localMs: now.getHours() * 3600000 + now.getMinutes() * 60000 + now.getSeconds() * 1000 + now.getMilliseconds()
  readonly property real minAngle: -((localMs % 3600000) / 3600000.0) * 360.0

  // The minute ring above only needs to move once a second, `now` already
  // ticks that often. The seconds ring is supposed to read as a gear
  // spinning continuously, so it gets its own fast timer instead of
  // inheriting `now`'s 1Hz update: at 1 update/sec each tick visibly jumps
  // 6 degrees, which is what actually reads as "laggy", not a rendering
  // performance problem.
  property real fastSecMs: Date.now() % 60000
  readonly property real secAngle: -((fastSecMs % 60000) / 60000.0) * 360.0
  Timer { interval: 50; running: true; repeat: true; onTriggered: lock.fastSecMs = Date.now() % 60000 }

  FontLoader { id: outfit; source: lock.assetsUrl + "font/Outfit-Black.ttf" }

  Rectangle { anchors.fill: parent; color: lock.bg }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Off-screen circular dial: the same trick as the source, an oversized
  // radius centered just past the left edge so only a bowed vertical slice
  // of ticks is ever on screen.
  Item {
    id: dial
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width * 0.62
    height: parent.height
    readonly property real cx: 56
    readonly property real cy: height * 0.5
    readonly property real minR: Math.min(parent.height, parent.width) * 0.62
    readonly property real secR: minR * 1.5

    // The 120 tick marks (2x60) used to be individual rotated, antialiased
    // Rectangle/Text items — Qt Quick's renderer generally can't batch
    // rotated+antialiased primitives, which is a well-known source of frame
    // jank ("laggy") that doesn't necessarily show up as high average CPU.
    // A single Canvas repaint (only on second/minute change, not per frame)
    // is the same technique StarryCity/Neon already use in this plugin.
    Canvas {
      id: dialCanvas
      anchors.fill: parent
      property real minAngle: lock.minAngle
      property real secAngle: lock.secAngle
      property bool fontReady: outfit.status === FontLoader.Ready
      onMinAngleChanged: requestPaint()
      onSecAngleChanged: requestPaint()
      onFontReadyChanged: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      Component.onCompleted: requestPaint()
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.textBaseline = "middle"
        ctx.textAlign = "center"
        ctx.font = Math.round(lock.u * 2.2) + "px " + (fontReady ? outfit.name : "sans-serif")

        for (var i = 0; i < 60; i++) {
          var disp = (i * 6 + minAngle) * Math.PI / 180
          var tx = dial.cx + dial.minR * Math.cos(disp)
          var ty = dial.cy + dial.minR * Math.sin(disp)
          if (tx < -40 || tx > dial.width + 40) continue
          var major = i % 5 === 0

          ctx.save()
          ctx.translate(tx, ty)
          ctx.rotate(disp + Math.PI / 2)
          ctx.strokeStyle = major ? "rgba(255,255,255,0.75)" : "rgba(255,255,255,0.35)"
          ctx.lineWidth = major ? Math.max(2, lock.u * 0.28) : Math.max(1, lock.u * 0.14)
          var len = major ? lock.u * 2.4 : lock.u * 1.3
          ctx.beginPath(); ctx.moveTo(0, -len / 2); ctx.lineTo(0, len / 2); ctx.stroke()
          ctx.restore()

          if (major) {
            var nr = dial.minR - lock.u * 4.2
            ctx.save()
            ctx.translate(dial.cx + nr * Math.cos(disp), dial.cy + nr * Math.sin(disp))
            ctx.rotate(disp)
            ctx.fillStyle = "rgba(255,255,255,0.65)"
            ctx.fillText(String(i).padStart(2, "0"), 0, 0)
            ctx.restore()
          }
        }

        for (var j = 0; j < 60; j++) {
          var disp2 = (j * 6 + secAngle) * Math.PI / 180
          var tx2 = dial.cx + dial.secR * Math.cos(disp2)
          var ty2 = dial.cy + dial.secR * Math.sin(disp2)
          if (tx2 < -40 || tx2 > dial.width + 40) continue
          var major2 = j % 5 === 0

          ctx.save()
          ctx.translate(tx2, ty2)
          ctx.rotate(disp2 + Math.PI / 2)
          ctx.strokeStyle = major2 ? "rgba(255,255,255,0.5)" : "rgba(255,255,255,0.22)"
          ctx.lineWidth = major2 ? Math.max(1.5, lock.u * 0.2) : Math.max(1, lock.u * 0.12)
          var len2 = major2 ? lock.u * 1.7 : lock.u * 1.0
          ctx.beginPath(); ctx.moveTo(0, -len2 / 2); ctx.lineTo(0, len2 / 2); ctx.stroke()
          ctx.restore()
        }
      }
    }
  }

  // Hour + date in one card. The source theme put a purely decorative pill
  // (just a divider line, no content) floating on its own between the hour
  // digit and the date -- which is exactly what read as broken/missing
  // content here rather than intentional. Putting all three pieces inside
  // one bordered card fixes that: the divider now separates two halves of
  // the same readout instead of sitting empty by itself.
  Rectangle {
    id: card
    anchors.centerIn: parent
    width: Math.round(lock.u * 34)
    height: Math.round(lock.u * 8.2)
    radius: 45
    color: lock.pillColor
    border.color: lock.pillBorder
    border.width: 1

    Text {
      id: hourText
      anchors.right: divider.left
      anchors.rightMargin: 30
      anchors.verticalCenter: parent.verticalCenter
      text: lock.clock("HH")
      font.family: outfit.name
      font.pixelSize: Math.round(lock.u * 6.6)
      font.weight: Font.Black
      color: lock.mainText
    }

    Rectangle {
      id: divider
      anchors.centerIn: parent
      width: 1; height: Math.round(lock.u * 3.8)
      color: "#222222"
    }

    Column {
      anchors.left: divider.right
      anchors.leftMargin: 30
      anchors.verticalCenter: parent.verticalCenter
      spacing: 5
      Text {
        text: Qt.formatDate(lock.now, "dd MMM yyyy").toUpperCase()
        font.family: Style.font.family
        font.pixelSize: Math.round(lock.u * 1.15)
        font.letterSpacing: 4
        color: lock.dimText
      }
      Text {
        text: Qt.formatDate(lock.now, "dddd").toUpperCase()
        font.family: Style.font.family
        font.pixelSize: Math.round(lock.u * 1.55)
        font.letterSpacing: 8
        font.bold: true
        color: lock.mainText
      }
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 156
    text: lock.userName.toUpperCase()
    color: lock.mainText
    font.family: outfit.name
    font.pixelSize: Math.round(lock.u * 1.15)
    font.letterSpacing: 4
  }

  PasswordField {
    id: field
    lock: lock
    accentColor: lock.mainText
    placeholderColor: lock.dimText
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 90
    width: Math.round(lock.u * 28)
    height: Math.round(lock.u * 4.3)
    color: lock.pillColor
    radius: 28
    placeholder: "Enter key"
  
    // PasswordField's own border always follows the active Omarchy theme
    // (Border.surfaceSpec looks up the theme's lock.border-active color
    // before ever considering accentColor), which is right for theme-
    // following designs but wrong here: this design has its own fixed
    // palette and the border should never clash with an unrelated theme
    // accent. Painting our own border on top, same shape, is the only
    // way to override that without touching the shared
    // component. A child of field (not a sibling) so it still works
    // when field's parent is a Column/Row that forbids anchors on its
    // own children.
    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: "transparent"
      border.color: parent.accentColor
      border.width: parent.outlineThickness
    }
}
}

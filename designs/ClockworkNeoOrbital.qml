// source: qylock
// name: Clockwork Neo Orbital
// description: Clock mechanism wallpaper from Wallsflow · Outfit font
// Original design inspired by Darkkal44's qylock "clockwork/neo-orbital" theme
// (github.com/Darkkal44/qylock, GPL-3.0): the same off-screen circular dial
// trick as "clockwork/orbital", but in a soft pastel palette over a bundled
// photo background, with the hour digit sitting in a rounded peach pill
// instead of bare text. Rewritten from scratch against Omarchy's
// DesignBase/PasswordField, not copied from qylock's GPL source, and drops
// the SDDM-only multi-user/session/power row. Only the bundled Outfit-Black
// font is reused (bundled in clockwork-neo-orbital-assets/), which tested
// clean for every letterform, so it is used throughout.
import QtQuick
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("clockwork-neo-orbital-assets/")
  property color mainText: "#231c1a"
  property color dimText: "#6a5a54"
  property color outline: "#161110"
  property color peach: "#ffb3a1"
  property color rose: "#ffcbd5"

  readonly property real localMs: now.getHours() * 3600000 + now.getMinutes() * 60000 + now.getSeconds() * 1000 + now.getMilliseconds()
  readonly property real minAngle: -((localMs % 3600000) / 3600000.0) * 360.0

  // The seconds ring is supposed to read as a gear spinning continuously,
  // so it gets its own fast timer instead of inheriting `now`'s 1Hz update:
  // at 1 update/sec each tick visibly jumps 6 degrees, which is what
  // actually reads as "laggy", not a rendering performance problem.
  property real fastSecMs: Date.now() % 60000
  readonly property real secAngle: -((fastSecMs % 60000) / 60000.0) * 360.0
  Timer { interval: 50; running: true; repeat: true; onTriggered: lock.fastSecMs = Date.now() % 60000 }

  FontLoader { id: outfit; source: lock.assetsUrl + "font/Outfit-Black.ttf" }

  Rectangle { anchors.fill: parent; color: "#faf0e6" }
  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "bg.png" : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Off-screen circular dial, same trick as ClockworkOrbital.qml: a single
  // Canvas repaint instead of 120 individually rotated+antialiased
  // Rectangle/Text items, which Qt Quick's renderer can't batch and which
  // is what actually caused the visible jank here before.
  Item {
    id: dial
    anchors.left: parent.left
    anchors.leftMargin: 20
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width * 0.55
    height: parent.height
    readonly property real cy: height * 0.5
    readonly property real minR: Math.min(parent.height, parent.width) * 0.5
    readonly property real secR: minR * 1.5

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
        ctx.font = "bold 18px " + (fontReady ? outfit.name : "sans-serif")

        for (var i = 0; i < 60; i++) {
          var disp = (i * 6 + minAngle) * Math.PI / 180
          var tx = dial.minR * Math.cos(disp)
          var ty = dial.cy + dial.minR * Math.sin(disp)
          if (tx < -40 || tx > dial.width + 40) continue
          var major = i % 5 === 0

          ctx.save()
          ctx.translate(tx, ty)
          ctx.rotate(disp + Math.PI / 2)
          ctx.strokeStyle = Qt.rgba(lock.outline.r, lock.outline.g, lock.outline.b, 1)
          ctx.lineWidth = major ? 2.5 : 1.2
          var len = major ? 18 : 10
          ctx.beginPath(); ctx.moveTo(0, -len / 2); ctx.lineTo(0, len / 2); ctx.stroke()
          ctx.restore()

          if (major) {
            var nr = dial.minR - 32
            ctx.save()
            ctx.translate(nr * Math.cos(disp), dial.cy + nr * Math.sin(disp))
            ctx.rotate(disp)
            ctx.fillStyle = lock.mainText
            ctx.fillText(String(i).padStart(2, "0"), 0, 0)
            ctx.restore()
          }
        }

        for (var j = 0; j < 60; j++) {
          var disp2 = (j * 6 + secAngle) * Math.PI / 180
          var tx2 = dial.secR * Math.cos(disp2)
          var ty2 = dial.cy + dial.secR * Math.sin(disp2)
          if (tx2 < -40 || tx2 > dial.width + 40) continue
          var major2 = j % 5 === 0

          ctx.save()
          ctx.translate(tx2, ty2)
          ctx.rotate(disp2 + Math.PI / 2)
          ctx.strokeStyle = Qt.rgba(lock.outline.r, lock.outline.g, lock.outline.b, 0.6)
          ctx.lineWidth = major2 ? 1.5 : 1
          var len2 = major2 ? 13 : 8
          ctx.beginPath(); ctx.moveTo(0, -len2 / 2); ctx.lineTo(0, len2 / 2); ctx.stroke()
          ctx.restore()
        }
      }
    }
  }

  Item {
    anchors.centerIn: parent
    width: 560
    height: 120

    Item {
      id: hourBox
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      width: 150; height: 120
      Rectangle { anchors.fill: parent; anchors.topMargin: 4; anchors.leftMargin: 4; anchors.bottomMargin: -4; anchors.rightMargin: -4; radius: 20; color: lock.outline }
      Rectangle {
        anchors.fill: parent
        radius: 20
        color: lock.peach
        border.color: lock.outline
        border.width: 2.5
        Text {
          anchors.centerIn: parent
          text: lock.clock("HH")
          font.family: outfit.name
          font.pixelSize: 70
          font.weight: Font.Black
          color: lock.mainText
        }
      }
    }

    Rectangle {
      anchors.left: hourBox.right
      anchors.leftMargin: 24
      anchors.verticalCenter: parent.verticalCenter
      width: 260; height: 76
      radius: 38
      color: "#35faf0e6"
      border.color: lock.outline
      border.width: 2.5

      Column {
        anchors.centerIn: parent
        spacing: 4
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(lock.now, "dddd").toUpperCase()
          font.family: Style.font.family
          font.pixelSize: 15
          font.bold: true
          font.letterSpacing: 2
          color: lock.mainText
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(lock.now, "dd MMM yyyy").toUpperCase()
          font.family: Style.font.family
          font.pixelSize: 11
          font.letterSpacing: 2
          color: lock.dimText
        }
      }
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 156
    text: lock.userName.toUpperCase()
    color: lock.outline
    font.family: outfit.name
    font.pixelSize: 13
    font.letterSpacing: 4
  }

  PasswordField {
    id: field
    lock: lock
    accentColor: lock.peach
    placeholderColor: lock.dimText
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 90
    width: 360
    height: 56
    color: "#c8faf0e6"
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

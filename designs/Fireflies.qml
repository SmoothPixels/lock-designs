// name: Fireflies
// description: Drifting points of light in your accent color over the dark
//
// SmoothPixels original. Forty-odd fireflies wander and pulse over a dark
// gradient with a warm ground glow, all in the theme accent. Every motion is
// tied to the display being awake, so nothing animates behind a blank screen
// or inside the picker's paused thumbnails.
import QtQuick
import QtQuick.Shapes
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color glow: lock.errorState ? Color.lock.textError : Color.accent

  Rectangle { anchors.fill: parent; color: lock.deepen(Color.background, 1.5) }

  // Ground glow.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 0
      fillGradient: RadialGradient {
        centerX: lock.width / 2
        centerY: lock.height * 1.08
        focalX: centerX
        focalY: centerY
        centerRadius: lock.height * 0.75
        GradientStop { position: 0; color: lock.withAlpha(lock.glow, 0.15) }
        GradientStop { position: 0.6; color: lock.withAlpha(lock.glow, 0.03) }
        GradientStop { position: 1; color: "transparent" }
      }
      PathSvg { path: "M 0 0 H " + lock.width + " V " + lock.height + " H 0 Z" }
    }
  }

  Repeater {
    model: 44
    delegate: Item {
      id: fly
      required property int index
      readonly property real s1: ((index * 7919 + 104729) % 10007) / 10007
      readonly property real s2: ((index * 15485863 + 32452843) % 10007) / 10007
      readonly property real s3: ((index * 2654435 + 40503) % 10007) / 10007
      readonly property real size: lock.u * (0.35 + s1 * 0.55)
      readonly property real homeX: lock.width * s1
      readonly property real homeY: lock.height * (0.12 + s2 * 0.85)
      width: size
      height: size
      x: homeX
      y: homeY
      opacity: 0.05

      SequentialAnimation on opacity {
        running: lock.videoPlaying
        loops: Animation.Infinite
        PauseAnimation { duration: 300 + fly.s3 * 3500 }
        NumberAnimation { to: 0.95; duration: 800 + fly.s2 * 1200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.05; duration: 1400 + fly.s1 * 1800; easing.type: Easing.InOutSine }
      }
      SequentialAnimation on x {
        running: lock.videoPlaying
        loops: Animation.Infinite
        NumberAnimation { to: fly.homeX + lock.u * (5 + fly.s2 * 9); duration: 5000 + fly.s1 * 6000; easing.type: Easing.InOutSine }
        NumberAnimation { to: fly.homeX - lock.u * (4 + fly.s3 * 8); duration: 6000 + fly.s2 * 5000; easing.type: Easing.InOutSine }
      }
      SequentialAnimation on y {
        running: lock.videoPlaying
        loops: Animation.Infinite
        NumberAnimation { to: fly.homeY - lock.u * (4 + fly.s1 * 7); duration: 7000 + fly.s3 * 5000; easing.type: Easing.InOutSine }
        NumberAnimation { to: fly.homeY + lock.u * (2 + fly.s2 * 5); duration: 6000 + fly.s1 * 6000; easing.type: Easing.InOutSine }
      }

      Rectangle {
        anchors.centerIn: parent
        width: fly.size * 4.5
        height: width
        radius: width / 2
        color: lock.glow
        opacity: 0.14
      }
      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: lock.raise(lock.glow, 1.35)
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
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.30)
    spacing: Math.round(lock.u * 1.6)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      renderType: Text.CurveRendering
      color: Color.foreground
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 14)
      font.weight: Font.Normal
      font.letterSpacing: lock.u * 0.3
      style: Text.Outline
      styleColor: lock.withAlpha(lock.glow, 0.25)
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.greeting() + ", " + lock.userName
      color: lock.withAlpha(Color.foreground, 0.65)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.8)
    }
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.66 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    radius: height / 2
    color: lock.withAlpha(lock.deepen(Color.background, 1.5), 0.9)
  }
}

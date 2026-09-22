// name: Spotlight
// description: Your wallpaper in the dark, lit only around the sign-in
//
// SmoothPixels original. The wallpaper is shown sharp but under a veil of the
// theme background, with a soft circle of light around the clock and field
// that drifts very slowly while the display is awake.
import QtQuick
import QtQuick.Shapes
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  property real driftX: 0
  property real driftY: 0
  SequentialAnimation on driftX {
    running: lock.videoPlaying
    loops: Animation.Infinite
    NumberAnimation { to: lock.u * 3; duration: 11000; easing.type: Easing.InOutSine }
    NumberAnimation { to: -lock.u * 3; duration: 11000; easing.type: Easing.InOutSine }
  }
  SequentialAnimation on driftY {
    running: lock.videoPlaying
    loops: Animation.Infinite
    NumberAnimation { to: -lock.u * 2; duration: 9000; easing.type: Easing.InOutSine }
    NumberAnimation { to: lock.u * 2; duration: 9000; easing.type: Easing.InOutSine }
  }

  Rectangle { anchors.fill: parent; color: Color.background }

  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.fileUrl(lock.backgroundPath) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: width
    sourceSize.height: height
  }

  // The veil: opaque theme background at the edges, clear in the middle.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 0
      fillGradient: RadialGradient {
        centerX: lock.width / 2 + lock.driftX
        centerY: lock.height * 0.5 + lock.driftY
        focalX: centerX
        focalY: centerY
        centerRadius: lock.height * 0.66
        GradientStop { position: 0; color: lock.withAlpha(Color.background, 0.0) }
        GradientStop { position: 0.3; color: lock.withAlpha(Color.background, 0.18) }
        GradientStop { position: 0.7; color: lock.withAlpha(Color.background, 0.8) }
        GradientStop { position: 1; color: lock.withAlpha(Color.background, 0.97) }
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

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.31)
    spacing: Math.round(lock.u * 1.2)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      renderType: Text.CurveRendering
      color: Color.foreground
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 13)
      font.weight: Font.DemiBold
      style: Text.Raised
      styleColor: lock.withAlpha(Color.background, 0.6)
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd, d MMMM") + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
      color: lock.withAlpha(Color.foreground, 0.8)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.7)
      font.letterSpacing: 2
      style: Text.Raised
      styleColor: lock.withAlpha(Color.background, 0.6)
    }
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.56)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.withAlpha(Color.background, 0.7)
    placeholder: lock.greeting() + ", " + lock.userName
  }
}

// name: Halo
// description: A ring around the clock that fills as you type
//
// SmoothPixels original. The clock sits inside a thin ring. Idle, a faint
// arc in the accent marks the seconds; start typing and the ring fills in the
// accent, one segment per character, all the way round at sixteen. It spins
// while the password is checked, lights up whole in the error color on a
// wrong one, and empties as the field clears.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property int ringR: Math.round(lock.u * 19)
  readonly property int stroke: Math.max(3, Math.round(lock.u * 0.7))
  readonly property int typed: lock.passwordText.length
  readonly property real target: lock.errorState ? 360 : Math.min(1, lock.typed / 16) * 360
  property real sweep: lock.target
  Behavior on sweep { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
  property real spin: 0
  NumberAnimation {
    target: lock
    property: "spin"
    from: 0
    to: 360
    duration: 900
    loops: Animation.Infinite
    running: lock.authenticatingPassword && lock.videoPlaying
  }

  Rectangle { anchors.fill: parent; color: Color.background }

  Image {
    id: wallpaper
    anchors.fill: parent
    source: lock.loadBackground ? lock.fileUrl(lock.backgroundPath) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: width
    sourceSize.height: height
  }
  MultiEffect {
    anchors.fill: wallpaper
    source: wallpaper
    autoPaddingEnabled: false
    blurEnabled: lock.loadBackground && wallpaper.status === Image.Ready
    blur: 0.8
    blurMax: 96
    brightness: -0.1
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Item {
    id: dial
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.5 - lock.ringR - lock.u * 5)
    width: lock.ringR * 2
    height: lock.ringR * 2

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      // Track.
      ShapePath {
        strokeColor: lock.withAlpha(Color.foreground, 0.12)
        strokeWidth: lock.stroke
        fillColor: "transparent"
        PathAngleArc {
          centerX: lock.ringR; centerY: lock.ringR
          radiusX: lock.ringR - lock.stroke; radiusY: lock.ringR - lock.stroke
          startAngle: 0; sweepAngle: 360
        }
      }
      // Seconds, only while nothing is typed.
      ShapePath {
        strokeColor: lock.typed === 0 && !lock.errorState && !lock.authenticatingPassword
          ? lock.withAlpha(Color.accent, 0.35) : "transparent"
        strokeWidth: lock.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathAngleArc {
          centerX: lock.ringR; centerY: lock.ringR
          radiusX: lock.ringR - lock.stroke; radiusY: lock.ringR - lock.stroke
          startAngle: -90; sweepAngle: Math.max(0.5, 360 * lock.now.getSeconds() / 60)
        }
      }
      // Progress, spinner, or the whole ring in the error color.
      ShapePath {
        strokeColor: lock.sweep < 0.5 && !lock.authenticatingPassword ? "transparent"
          : (lock.errorState ? Color.lock.textError : Color.accent)
        strokeWidth: lock.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathAngleArc {
          centerX: lock.ringR; centerY: lock.ringR
          radiusX: lock.ringR - lock.stroke; radiusY: lock.ringR - lock.stroke
          startAngle: -90 + (lock.authenticatingPassword ? lock.spin : 0)
          sweepAngle: lock.authenticatingPassword ? 100 : lock.sweep
        }
      }
    }

    Column {
      anchors.centerIn: parent
      spacing: Math.round(lock.u * 0.8)
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: lock.clock("HH:mm")
        renderType: Text.CurveRendering
        color: Color.foreground
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 9)
        font.weight: Font.DemiBold
        lineHeight: 0.9
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(lock.now, "dddd, d MMMM")
        color: lock.withAlpha(Color.foreground, 0.65)
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 1.4)
        font.letterSpacing: 2
      }
    }
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: dial.bottom
    anchors.topMargin: Math.round(lock.u * 4)
    width: Math.round(lock.u * 24)
    height: Math.round(lock.u * 4)
    color: lock.withAlpha(Color.background, 0.45)
    showLockGlyph: false
    placeholder: "Enter password"
  }
}

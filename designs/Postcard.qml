// name: Postcard
// description: Clock, avatar and greeting on one frosted card over your wallpaper
//
// SmoothPixels original. The wallpaper, softly blurred, with a single frosted
// card in the middle: the time on top, your avatar with a greeting, and the
// password field along the bottom. Every color comes from the active theme.
import QtQuick
import QtQuick.Effects
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color ink: Color.lock.text
  readonly property color dim: lock.withAlpha(Color.lock.text, 0.55)

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
    blur: 0.6
    blurMax: 96
    brightness: -0.06
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: Math.round(Math.min(lock.width * 0.4, lock.u * 46))
    height: Math.round(lock.u * 54)
    radius: Math.max(Style.cornerRadius, 18)
    color: lock.withAlpha(Color.lock.background, 0.78)
    border.width: 1
    border.color: lock.withAlpha(Color.lock.border, 0.18)
    layer.enabled: true
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowColor: Qt.rgba(0, 0, 0, 0.45)
      shadowBlur: 1.0
      shadowVerticalOffset: 12
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: Math.round(lock.u * 5)
      spacing: Math.round(lock.u * 0.4)
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: lock.clock("HH:mm")
        renderType: Text.CurveRendering
        color: lock.ink
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 12)
        font.weight: Font.DemiBold
        lineHeight: 0.9
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(lock.now, "dddd, d MMMM") + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
        color: lock.dim
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 1.6)
        font.letterSpacing: 1
      }
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: field.top
      anchors.bottomMargin: Math.round(lock.u * 3.4)
      spacing: Math.round(lock.u * 1.6)
      Avatar {
        anchors.horizontalCenter: parent.horizontalCenter
        lock: lock
        width: Math.round(lock.u * 11)
        borderWidth: 3
        borderColor: Color.lock.borderActive
        shadow: false
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: lock.greeting() + ", " + lock.userName
        color: lock.ink
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 2.1)
        font.weight: Font.DemiBold
      }
    }

    PasswordField {
      id: field
      lock: lock
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.round(lock.u * 4)
      width: card.width - Math.round(lock.u * 7)
      height: Math.round(lock.u * 4.6)
      color: lock.withAlpha(Color.background, 0.4)
      placeholder: "Enter password"
    }
  }
}

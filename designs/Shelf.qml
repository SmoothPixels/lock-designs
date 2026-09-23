// name: Shelf
// description: Everything on a slim shelf along the bottom edge
//
// SmoothPixels original. The wallpaper takes the whole screen; a slim
// translucent shelf floats above the bottom edge with your avatar and name
// on the left, the password field in the middle, and the clock and date on
// the right. Nothing else, so the wallpaper is the picture.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color ink: Color.lock.text
  readonly property color dim: lock.withAlpha(Color.lock.text, 0.55)

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

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Rectangle {
    id: shelf
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Math.round(lock.u * 3)
    width: Math.round(Math.min(lock.width - lock.u * 6, lock.u * 120))
    height: Math.round(lock.u * 8.5)
    radius: Math.max(Style.cornerRadius, 16)
    color: lock.withAlpha(Color.lock.background, 0.82)
    border.width: 1
    border.color: lock.withAlpha(Color.lock.border, 0.2)

    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Math.round(lock.u * 2)
      spacing: Math.round(lock.u * 1.4)
      Avatar {
        anchors.verticalCenter: parent.verticalCenter
        lock: lock
        width: Math.round(lock.u * 5.2)
        shadow: false
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(lock.u * 0.3)
        Text {
          text: lock.userName
          color: lock.ink
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.9)
          font.weight: Font.DemiBold
        }
        Text {
          text: lock.greeting()
          color: lock.dim
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.3)
        }
      }
    }

    PasswordField {
      id: field
      lock: lock
      anchors.centerIn: parent
      width: Math.round(shelf.width * 0.36)
      height: Math.round(lock.u * 4.4)
      color: lock.withAlpha(Color.background, 0.4)
      radius: Math.max(Style.cornerRadius, 12)
      placeholder: "Enter password"
    }

    Column {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.rightMargin: Math.round(lock.u * 2.4)
      spacing: Math.round(lock.u * 0.3)
      Text {
        anchors.right: parent.right
        text: lock.clock("HH:mm")
        renderType: Text.CurveRendering
        color: lock.ink
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 3.4)
        font.weight: Font.DemiBold
      }
      Text {
        anchors.right: parent.right
        text: Qt.formatDate(lock.now, "dddd, d MMMM")
        color: lock.dim
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 1.3)
      }
    }
  }
}

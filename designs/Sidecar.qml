// name: Sidecar
// description: Your wallpaper on the left, the sign-in on a panel to the right
//
// SmoothPixels original. The screen splits three fifths to two: the
// wallpaper runs edge to edge on the left with the clock in its lower
// corner, and a solid panel in the theme background carries your avatar,
// name, greeting and the password field on the right.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property int splitX: Math.round(width * 0.6)

  Rectangle { anchors.fill: parent; color: Color.background }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Item {
    id: left
    x: 0
    y: 0
    width: lock.splitX
    height: lock.height
    clip: true

    Image {
      anchors.fill: parent
      source: lock.loadBackground ? lock.fileUrl(lock.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Math.round(parent.height * 0.45)
      gradient: Gradient {
        GradientStop { position: 0.0; color: lock.withAlpha(Color.background, 0.0) }
        GradientStop { position: 1.0; color: lock.withAlpha(Color.background, 0.8) }
      }
    }
    Column {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: Math.round(lock.u * 5)
      spacing: Math.round(lock.u * 0.8)
      Text {
        text: lock.clock("HH:mm")
        renderType: Text.CurveRendering
        color: Color.foreground
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 12)
        font.weight: Font.DemiBold
        lineHeight: 0.9
      }
      Text {
        text: Qt.formatDate(lock.now, "dddd, d MMMM")
        color: lock.withAlpha(Color.foreground, 0.75)
        font.family: lock.displayFont
        font.pixelSize: Math.round(lock.u * 1.8)
        font.letterSpacing: 2
      }
    }
  }

  Rectangle {
    id: panel
    x: lock.splitX
    y: 0
    width: lock.width - lock.splitX
    height: lock.height
    color: Color.background

    Rectangle {
      anchors.left: parent.left
      width: 1
      height: parent.height
      color: lock.withAlpha(Color.lock.border, 0.35)
    }

    Column {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -Math.round(lock.u * 2)
      width: parent.width - Math.round(lock.u * 10)
      spacing: Math.round(lock.u * 2.4)

      Avatar {
        anchors.horizontalCenter: parent.horizontalCenter
        lock: lock
        width: Math.round(lock.u * 13)
        borderWidth: 3
        borderColor: Color.lock.borderActive
        shadow: false
      }
      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.round(lock.u * 0.6)
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: lock.userName
          color: Color.foreground
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 2.8)
          font.weight: Font.DemiBold
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: lock.greeting()
          color: lock.withAlpha(Color.foreground, 0.6)
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.6)
        }
      }
      PasswordField {
        id: field
        lock: lock
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: Math.round(lock.u * 4.6)
        color: lock.deepen(Color.background, 1.12)
        radius: Math.max(Style.cornerRadius, 12)
        placeholder: "Enter password"
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.round(lock.u * 4)
      text: lock.hostName.toUpperCase()
      color: lock.withAlpha(Color.foreground, 0.4)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.3)
      font.letterSpacing: 4
    }
  }
}

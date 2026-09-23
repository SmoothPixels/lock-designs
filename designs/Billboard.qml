// name: Billboard
// description: Huge stacked hours and minutes, the sign-in in the corner
//
// SmoothPixels original. Two enormous numerals stacked on the right of the
// wallpaper: the hour in the theme foreground, the minutes in the accent,
// set tight enough to read as one block. The date and the password field
// keep to the bottom left, small, so the numerals stay the whole point.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property int margin: Math.round(lock.u * 6)

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
  // Deeper toward the right, where the numerals sit, and along the bottom.
  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: lock.withAlpha(Color.background, 0.0) }
      GradientStop { position: 0.45; color: lock.withAlpha(Color.background, 0.1) }
      GradientStop { position: 1.0; color: lock.withAlpha(Color.background, 0.7) }
    }
  }
  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Math.round(parent.height * 0.4)
    gradient: Gradient {
      GradientStop { position: 0.0; color: lock.withAlpha(Color.background, 0.0) }
      GradientStop { position: 1.0; color: lock.withAlpha(Color.background, 0.75) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Text {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: lock.margin
    text: lock.greeting() + ", " + lock.userName
    color: lock.withAlpha(Color.foreground, 0.75)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.7)
    font.letterSpacing: 1
    style: Text.Raised
    styleColor: lock.withAlpha(Color.background, 0.5)
  }

  Column {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: lock.margin
    spacing: -Math.round(lock.u * 5)
    Text {
      anchors.right: parent.right
      text: lock.clock("HH")
      renderType: Text.CurveRendering
      color: Color.foreground
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 40)
      font.weight: Font.Black
      font.letterSpacing: -Math.round(lock.u * 1.2)
      lineHeight: 0.8
    }
    Text {
      anchors.right: parent.right
      text: lock.clock("mm")
      renderType: Text.CurveRendering
      color: Color.accent
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 40)
      font.weight: Font.Black
      font.letterSpacing: -Math.round(lock.u * 1.2)
      lineHeight: 0.8
    }
    Text {
      anchors.right: parent.right
      visible: lock.twelveHour
      text: lock.meridiem
      color: lock.withAlpha(Color.foreground, 0.7)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 2.6)
      font.letterSpacing: 6
    }
  }

  Column {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: lock.margin
    anchors.bottomMargin: lock.margin
    spacing: Math.round(lock.u * 1.6)
    Text {
      text: Qt.formatDate(lock.now, "dddd").toUpperCase()
      color: lock.withAlpha(Color.foreground, 0.8)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.6)
      font.letterSpacing: 5
    }
    Text {
      text: Qt.formatDate(lock.now, "d MMMM yyyy")
      color: Color.foreground
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 2.6)
      font.weight: Font.DemiBold
    }
    PasswordField {
      id: field
      lock: lock
      width: Math.round(lock.u * 30)
      height: Math.round(lock.u * 4.4)
      color: lock.withAlpha(Color.background, 0.55)
      radius: Math.max(Style.cornerRadius, 8)
      textAlignment: TextInput.AlignLeft
      placeholder: "Enter password"
    }
  }
}

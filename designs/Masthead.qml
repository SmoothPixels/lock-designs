// name: Masthead
// description: A big clock bottom left, editorial style, the sign-in underneath
//
// SmoothPixels original. The wallpaper stays sharp behind a veil that
// deepens toward the bottom edge. Down in the corner: the date in spaced
// capitals, a hairline rule in the accent, the time set large and tight, and
// the password field beneath it, left-aligned like a caption. The greeting
// and the machine name keep to the opposite corners, small.
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

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: lock.withAlpha(Color.background, 0.0) }
      GradientStop { position: 0.45; color: lock.withAlpha(Color.background, 0.12) }
      GradientStop { position: 1.0; color: lock.withAlpha(Color.background, 0.92) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Text {
    anchors.right: parent.right
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

  Text {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: lock.margin
    text: lock.hostName.toUpperCase()
    color: lock.withAlpha(Color.foreground, 0.5)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.3)
    font.letterSpacing: 4
  }

  Column {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: lock.margin
    anchors.bottomMargin: lock.margin
    spacing: Math.round(lock.u * 1.8)

    Text {
      text: Qt.formatDate(lock.now, "dddd d MMMM").toUpperCase()
      color: lock.withAlpha(Color.foreground, 0.85)
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 1.6)
      font.letterSpacing: 5
    }
    Rectangle {
      width: Math.round(lock.u * 12)
      height: Math.max(2, Math.round(lock.u * 0.25))
      color: Color.accent
    }
    Text {
      text: lock.clock("HH:mm")
      renderType: Text.CurveRendering
      color: Color.foreground
      font.family: lock.displayFont
      font.pixelSize: Math.round(lock.u * 22)
      font.weight: Font.Bold
      font.letterSpacing: -Math.round(lock.u * 0.6)
      lineHeight: 0.8
    }
    PasswordField {
      id: field
      lock: lock
      width: Math.round(lock.u * 34)
      height: Math.round(lock.u * 4.4)
      color: lock.withAlpha(Color.background, 0.55)
      radius: Math.max(Style.cornerRadius, 8)
      textAlignment: TextInput.AlignLeft
      placeholder: "Enter password"
    }
  }
}

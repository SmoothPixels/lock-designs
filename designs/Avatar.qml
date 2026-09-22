import QtQuick
import QtQuick.Effects
import qs.Commons

// Round user picture, falling back to the user's initial on a colored disc
// when no avatar is set or the file cannot be read.
Item {
  id: avatar

  // Usually driven by a DesignBase (`lock: lock`); source and initial can
  // also be set directly.
  property var lock: null
  property string source: lock ? lock.avatarUrl : ""
  property string initial: lock ? lock.userInitial : "?"
  property color fillColor: Color.lock.borderActive
  property color textColor: Color.background
  property real fontScale: 0.5
  property int fontSize: Math.round(height * fontScale)
  property int borderWidth: 0
  property color borderColor: "transparent"
  property bool shadow: true
  property color shadowColor: Qt.rgba(0, 0, 0, 0.5)
  property int shadowOffset: 8

  readonly property bool showsImage: source.length > 0 && picture.status === Image.Ready

  width: 130
  height: width

  Item {
    anchors.fill: parent
    layer.enabled: avatar.shadow
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowColor: avatar.shadowColor
      shadowBlur: 1.0
      shadowVerticalOffset: avatar.shadowOffset
    }

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: avatar.fillColor
      antialiasing: true

      Text {
        anchors.centerIn: parent
        visible: !avatar.showsImage
        text: avatar.initial
        color: avatar.textColor
        font.family: Style.font.family
        font.pixelSize: avatar.fontSize
        font.weight: Font.Bold
      }
    }

    // The picture is clipped to the disc by masking it with a copy of the
    // disc's shape. The Image keeps loading while hidden, so the mask only
    // has to switch on once a picture is actually there.
    Image {
      id: picture
      anchors.fill: parent
      source: avatar.source
      visible: avatar.showsImage
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      smooth: true
      mipmap: true
      sourceSize.width: Math.round(avatar.width * 2)
      sourceSize.height: Math.round(avatar.height * 2)
      layer.enabled: avatar.source.length > 0
      layer.smooth: true
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: discMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.05
      }
    }

    Item {
      id: discMask
      anchors.fill: parent
      visible: false
      layer.enabled: true
      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "white"
        antialiasing: true
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: "transparent"
      antialiasing: true
      visible: avatar.borderWidth > 0
      border.width: avatar.borderWidth
      border.color: avatar.borderColor
    }
  }
}

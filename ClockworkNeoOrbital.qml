// source: qylock
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
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

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
  readonly property real secAngle: -((localMs % 60000) / 60000.0) * 360.0

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

    Repeater {
      model: 60
      delegate: Item {
        readonly property real disp: (index * 6 + lock.minAngle) * Math.PI / 180
        readonly property real tx: dial.minR * Math.cos(disp)
        readonly property real ty: dial.cy + dial.minR * Math.sin(disp)
        readonly property bool major: index % 5 === 0
        visible: tx > -40 && tx < dial.width + 40
        Rectangle {
          x: parent.tx - width / 2; y: parent.ty - height / 2
          width: major ? 2.5 : 1.2; height: major ? 18 : 10
          rotation: disp * 180 / Math.PI + 90
          color: lock.outline
          antialiasing: true
        }
        Text {
          visible: major
          readonly property real nr: dial.minR - 32
          x: nr * Math.cos(disp) - width / 2
          y: dial.cy + nr * Math.sin(disp) - height / 2
          text: String(index).padStart(2, "0")
          font.family: outfit.name
          font.pixelSize: 18
          font.bold: true
          color: lock.mainText
          rotation: disp * 180 / Math.PI
        }
      }
    }

    Repeater {
      model: 60
      delegate: Item {
        readonly property real disp: (index * 6 + lock.secAngle) * Math.PI / 180
        readonly property real tx: dial.secR * Math.cos(disp)
        readonly property real ty: dial.cy + dial.secR * Math.sin(disp)
        readonly property bool major: index % 5 === 0
        visible: tx > -40 && tx < dial.width + 40
        Rectangle {
          x: parent.tx - width / 2; y: parent.ty - height / 2
          width: major ? 1.5 : 1; height: major ? 13 : 8
          rotation: disp * 180 / Math.PI + 90
          color: Qt.rgba(lock.outline.r, lock.outline.g, lock.outline.b, 0.6)
          antialiasing: true
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
  }
}

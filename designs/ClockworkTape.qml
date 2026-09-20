// source: qylock
// Original design inspired by Darkkal44's qylock "clockwork/tape" theme
// (github.com/Darkkal44/qylock, GPL-3.0): three vertical "film reel" columns
// (hour/minute/second) with sprocket holes down the sides and a sepia/gold
// palette, as if the clock were printed on a strip of movie tape. The
// source scroll-animates each reel continuously frame-by-frame with
// sub-second easing; this rewrite keeps it to a plain neighbor-above/
// neighbor-below tick display updated on DesignBase's normal 1-second
// clock instead, which is simpler and avoids the kind of animation load
// that caused real jank in this theme's sibling designs (see
// ClockworkOrbital/ClockworkNeoOrbital). Written from scratch against
// Omarchy's DesignBase/PasswordField, not copied from qylock's GPL source,
// and drops the SDDM-only multi-user/session/power row. Only the bundled
// Outfit-Black font is reused (bundled in clockwork-tape-assets/), which
// tested clean for every letterform, so it is used throughout.
import QtQuick
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("clockwork-tape-assets/")
  property color bg: "#060504"
  property color mainText: "#e8dcc8"
  property color dimText: "#5a5040"
  property color accent: "#d4a44c"
  property color tapeBg: "#0c0b09"
  property color tapeBorder: "#2a2418"
  property color sprocketCol: "#221e15"

  FontLoader { id: outfit; source: lock.assetsUrl + "font/Outfit-Black.ttf" }

  Rectangle { anchors.fill: parent; color: lock.bg }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Faint horizontal scanline texture, echoing the source's film-grain feel.
  Item {
    anchors.fill: parent
    opacity: 0.04
    clip: true
    Repeater {
      model: Math.ceil(lock.height / 4)
      delegate: Rectangle { y: index * 4; width: lock.width; height: 1; color: "#ffffff" }
    }
  }

  component TapeReel: Item {
    id: reel
    property int value: 0
    property int maxValue: 60
    property string unitLabel: ""
    width: 110
    height: 260

    function wrap(v) { return ((v % maxValue) + maxValue) % maxValue }

    Rectangle { anchors.fill: parent; color: lock.tapeBg; border.color: lock.tapeBorder; border.width: 2 }
    Rectangle {
      anchors.fill: parent
      opacity: 0.05
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#000000" }
        GradientStop { position: 0.5; color: "#ffffff" }
        GradientStop { position: 1.0; color: "#000000" }
      }
    }

    // Sprocket holes down both edges.
    Repeater {
      model: 6
      delegate: Item {
        y: 14 + index * 40
        width: parent.width
        height: 10
        Rectangle { x: 6; width: 12; height: 9; radius: 2; color: lock.sprocketCol; border.color: lock.tapeBorder; border.width: 1 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: 6; width: 12; height: 9; radius: 2; color: lock.sprocketCol; border.color: lock.tapeBorder; border.width: 1 }
      }
    }

    Rectangle { anchors.left: parent.left; anchors.right: parent.right; y: parent.height / 2 - 32; height: 64; color: lock.accent; opacity: 0.07 }
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; y: parent.height / 2 - 32; height: 2; color: lock.accent }
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; y: parent.height / 2 + 32; height: 2; color: lock.accent }

    Column {
      anchors.centerIn: parent
      spacing: 6
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: String(reel.wrap(reel.value - 1)).padStart(2, "0")
        font.family: outfit.name; font.pixelSize: 22; color: lock.dimText; opacity: 0.45
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: String(reel.value).padStart(2, "0")
        font.family: outfit.name; font.pixelSize: 46; font.weight: Font.Black; color: lock.mainText
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: String(reel.wrap(reel.value + 1)).padStart(2, "0")
        font.family: outfit.name; font.pixelSize: 22; color: lock.dimText; opacity: 0.45
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 10
      text: unitLabel
      font.family: Style.font.family
      font.pixelSize: 10
      font.letterSpacing: 3
      font.bold: true
      color: lock.dimText
    }
  }

  component ReelDivider: Column {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 10
    Repeater { model: 5; delegate: Rectangle { width: 3; height: 3; radius: 1.5; color: lock.accent; opacity: 0.5 } }
  }

  Column {
    anchors.centerIn: parent
    spacing: 20

    Row {
      id: tapeRow
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 16
      TapeReel { value: lock.now.getHours(); maxValue: 24; unitLabel: "HR" }
      Item { width: 16; height: 260; ReelDivider { anchors.centerIn: parent } }
      TapeReel { value: lock.now.getMinutes(); maxValue: 60; unitLabel: "MIN" }
      Item { width: 16; height: 260; ReelDivider { anchors.centerIn: parent } }
      TapeReel { value: lock.now.getSeconds(); maxValue: 60; unitLabel: "SEC" }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd  ·  dd MMM yyyy").toUpperCase()
      font.family: outfit.name
      font.pixelSize: 12
      font.letterSpacing: 4
      color: lock.dimText
    }
  }

  PasswordField {
    id: field
    lock: lock
    accentColor: lock.accent
    placeholderColor: lock.dimText
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 64
    width: 340
    height: 54
    radius: 4
    color: lock.tapeBg
    placeholder: "Enter key"
  }
}

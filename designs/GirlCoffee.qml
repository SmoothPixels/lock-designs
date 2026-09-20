// source: qylock
// Original design inspired by Darkkal44's qylock "girl-coffee" theme
// (github.com/Darkkal44/qylock, GPL-3.0): a cozy illustrated background with
// a cream rounded card on the left holding a greeting, clock, date, a
// divider, and the password field, in a soft pink/teal/cream palette.
// Rewritten from scratch against Omarchy's DesignBase/PasswordField, not
// copied from qylock's GPL source, and drops the SDDM-only multi-user/
// session/power row. Only the bundled Itim-Regular font is reused (bundled
// in girl-coffee-assets/), which tested clean for every letterform, so it is
// used throughout, along with the original bg.png illustration and palette.
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("girl-coffee-assets/")
  property color cPink: "#da9ead"
  property color cPinkLt: "#f0cad5"
  property color cCream: "#fdfaf6"
  property color cCreamy: "#f2ece4"
  property color cInk: "#324746"
  property color cMuted: "#8fa8a6"

  FontLoader { id: itim; source: lock.assetsUrl + "font/Itim-Regular.ttf" }

  function greeting() {
    var h = lock.now.getHours()
    if (h < 12) return "good morning"
    if (h < 17) return "good afternoon"
    return "good evening"
  }

  Rectangle { anchors.fill: parent; color: "#6eb3ac" }
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
    id: card
    x: parent.width * 0.05
    anchors.verticalCenter: parent.verticalCenter
    width: 360
    height: cardCol.height + 80

    Rectangle {
      anchors.fill: parent
      radius: 24
      color: lock.cCream
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.6; shadowOpacity: 0.25; shadowVerticalOffset: 6 }
      border.color: Qt.rgba(0, 0, 0, 0.1)
      border.width: 1
    }

    Column {
      id: cardCol
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 40
      spacing: 0

      Row {
        spacing: 6
        Text { text: "☕"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
        Text {
          text: lock.greeting()
          color: lock.cPink
          font.family: itim.name
          font.pixelSize: 14
          font.letterSpacing: 2
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Item { width: 1; height: 6 }

      Text {
        text: lock.clock("HH:mm")
        color: lock.cInk
        font.family: itim.name
        font.pixelSize: 60
      }

      Text {
        text: Qt.formatDate(lock.now, "dddd, MMMM d").toLowerCase()
        color: lock.cMuted
        font.family: itim.name
        font.pixelSize: 13
        font.letterSpacing: 1
      }

      Item { width: 1; height: 24 }
      Rectangle { width: parent.width; height: 1; color: lock.cCreamy }
      Item { width: 1; height: 24 }

      Row {
        spacing: 10
        Rectangle { width: 3; height: 20; radius: 1.5; color: lock.cPink; anchors.verticalCenter: parent.verticalCenter }
        Text {
          text: lock.userName.toUpperCase()
          color: lock.cInk
          font.family: itim.name
          font.pixelSize: 20
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Item { width: 1; height: 20 }

      PasswordField {
        id: field
        lock: lock
      accentColor: lock.cPink
      placeholderColor: lock.cMuted
        width: parent.width
        height: 48
        radius: 14
        showLockGlyph: false
        color: lock.cCream
        placeholder: "password"
      }
      // PasswordField's own border always follows the active Omarchy theme
      // (Border.surfaceSpec looks up the theme's lock.border-active color
      // before ever considering accentColor), which is right for theme-
      // following designs but wrong here: this design has its own fixed
      // palette and the border should never clash with an unrelated theme
      // accent. Painting our own border on top, same shape, is the only way
      // to override that without touching lock-explorer's shared component.
      Rectangle {
        anchors.fill: field
        radius: field.radius
        color: "transparent"
        border.color: field.accentColor
        border.width: field.outlineThickness
      }
    }
  }
}

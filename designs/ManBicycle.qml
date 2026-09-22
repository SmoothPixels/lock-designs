// source: qylock
// name: Man Bicycle
// description: Wallpaper from MoeWalls · Itim font
// Faithful port of Darkkal44's qylock "man-bicycle" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The QML is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source, and drops the SDDM-specific multi-user/session/power row in favor
// of the shared single password field. The source's bundled Itim-Regular
// font tested clean at UI sizes (every glyph in "THE QUICK BROWN FOX
// WELCOME" unambiguous) so it is used throughout, matching the original.
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("man-bicycle-assets/")

  // Original qylock palette: teal backdrop, gold accent.
  property color pageBg: "#4da7be"
  property color gold: "#e9a820"
  property color white: "#ffffff"

  FontLoader {
    id: itimFont
    source: lock.assetsUrl + "font/Itim-Regular.ttf"
  }

  Rectangle { anchors.fill: parent; color: lock.pageBg }

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

  // Clock, top-left.
  Column {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: 64
    spacing: 10

    Text {
      text: lock.clock("HH:mm")
      color: lock.white
      font.family: itimFont.name
      font.pixelSize: 92
      font.weight: Font.Light
      font.letterSpacing: 2
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowOpacity: 0.25; shadowBlur: 0.5 }
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd, MMMM d")
      color: lock.white
      opacity: 0.7
      font.family: itimFont.name
      font.pixelSize: 20
      font.weight: Font.Light
      font.letterSpacing: 2
    }
  }

  // Login, top-right, right-aligned underline field.
  Column {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 64
    width: 260
    spacing: 0

    Text {
      anchors.right: parent.right
      text: lock.userName.toLowerCase()
      color: lock.white
      font.family: itimFont.name
      font.pixelSize: 32
      font.weight: Font.Light
      font.letterSpacing: 3
      horizontalAlignment: Text.AlignRight
    }

    Item { width: 1; height: 40 }

    Item {
      anchors.right: parent.right
      width: parent.width
      height: 54

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: parent.width
        height: passwordInput.activeFocus ? 2 : 1
        color: lock.errorState ? "#ff7070" : (passwordInput.activeFocus ? lock.gold : Qt.rgba(1, 1, 1, 0.35))
        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on height { NumberAnimation { duration: 150 } }
      }

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        anchors.bottomMargin: 4
        horizontalAlignment: TextInput.AlignRight
        verticalAlignment: TextInput.AlignVCenter
        color: lock.white
        font.family: itimFont.name
        font.pixelSize: 26
        font.letterSpacing: 6
        passwordCharacter: "•"
        selectionColor: lock.gold
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle { width: 2; color: lock.gold; visible: passwordInput.cursorVisible }
      }

      Text {
        anchors.right: passwordInput.right
        anchors.verticalCenter: passwordInput.verticalCenter
        text: lock.authenticatingPassword ? "checking…" : "password"
        color: lock.white
        opacity: passwordInput.text.length === 0 ? 0.4 : 0
        font.family: itimFont.name
        font.pixelSize: 14
        font.weight: Font.Light
        font.letterSpacing: 2
        Behavior on opacity { NumberAnimation { duration: 200 } }
      }
    }

    Item { width: 1; height: 20 }

    Text {
      anchors.right: parent.right
      visible: lock.fingerprintConfigured
      text: "touch sensor or type password"
      color: lock.white
      opacity: 0.45
      font.family: itimFont.name
      font.pixelSize: 12
      horizontalAlignment: Text.AlignRight
    }

    Text {
      anchors.right: parent.right
      visible: lock.errorState
      text: lock.failureMessage
      color: "#ff7070"
      font.family: itimFont.name
      font.pixelSize: 12
      font.letterSpacing: 1
      horizontalAlignment: Text.AlignRight
    }
  }
}

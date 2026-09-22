// source: qylock
// name: Girl Pillow
// description: Wallpaper from MoeWalls · Itim font
// Faithful port of Darkkal44's qylock "girl-pillow" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The QML is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source, and drops the SDDM-specific multi-user/session/power row in favor
// of the shared single password field. The source's bundled Itim-Regular
// font tested clean at UI sizes (every glyph in "THE QUICK BROWN FOX
// WELCOME" unambiguous) so it is used throughout, matching the original.
import QtQuick
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("girl-pillow-assets/")

  // Original qylock light palette.
  property color pageBg: "#ccd4da"
  property color textMain: "#4a4e69"
  property color textSub: "#8a8eaf"
  property color accent: "#b8a9c9"
  property color glass: Qt.rgba(1, 1, 1, 0.38)

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

  Column {
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 70
    spacing: -6

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      color: lock.textMain
      font.family: itimFont.name
      font.pixelSize: 84
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toLowerCase()
      color: lock.textSub
      font.family: itimFont.name
      font.pixelSize: 20
      font.letterSpacing: 1
    }
  }

  Column {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 80
    width: 320
    spacing: 18

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.textMain
      font.family: itimFont.name
      font.pixelSize: 16
      font.letterSpacing: 4
    }

    Item {
      width: parent.width
      height: 46

      Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: lock.glass
        border.color: lock.errorState ? "#cc4444" : (passwordInput.activeFocus ? lock.accent : "transparent")
        border.width: 1.5
        Behavior on border.color { ColorAnimation { duration: 250 } }
      }

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: lock.textMain
        font.family: itimFont.name
        font.pixelSize: 18
        font.letterSpacing: 6
        passwordCharacter: "•"
        selectionColor: lock.accent
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle { width: 2; radius: 1; color: lock.accent; visible: passwordInput.cursorVisible }
      }

      Text {
        anchors.centerIn: parent
        text: lock.authenticatingPassword ? "checking…" : "password"
        color: lock.textSub
        font.family: itimFont.name
        font.pixelSize: 14
        font.letterSpacing: 1
        opacity: passwordInput.text.length === 0 ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: lock.errorState
      text: lock.failureMessage
      color: "#cc4444"
      font.family: itimFont.name
      font.pixelSize: 12
      font.letterSpacing: 1
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "touch sensor or type password" : "type password · enter to unlock"
    color: lock.withAlpha(lock.textMain, 0.5)
    font.family: itimFont.name
    font.pixelSize: 12
  }
}

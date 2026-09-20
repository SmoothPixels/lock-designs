// source: qylock
// Original design inspired by Darkkal44's qylock "field" theme
// (github.com/Darkkal44/qylock, GPL-3.0): a quiet landscape-photo background
// with a light, shadowed clock tucked in the top-left corner and a minimal
// right-aligned, underline-only password field tucked in the bottom-right —
// no boxes, no chrome. Rewritten from scratch against Omarchy's
// DesignBase/LockInput, not copied from qylock's GPL source, and drops the
// SDDM-only multi-user/session/power row (kept only as plain non-interactive
// labels here, since Omarchy has no session switcher). Only the bundled
// Orbitron font is reused (bundled in field-assets/), which tested clean for
// every letterform, so it is used throughout, along with the original bg.png
// image and amber/steel palette.
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: pwd

  readonly property string assetsUrl: Qt.resolvedUrl("field-assets/")
  property color amber: "#e8a040"
  property color steel: "#d8eef8"
  property color cWhite: "#f0ede8"

  FontLoader { id: fieldFont; source: lock.assetsUrl + "font/Orbitron-VariableFont_wght.ttf" }

  Rectangle { anchors.fill: parent; color: "#3a6370" }
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
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 70
    anchors.topMargin: 60
    spacing: 8

    Text {
      text: lock.clock("HH:mm")
      color: lock.cWhite
      font.family: fieldFont.name
      font.pixelSize: 96
      font.weight: Font.Light
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.6; shadowOpacity: 0.5 }
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd · MMMM d").toUpperCase()
      color: lock.steel
      font.family: Style.font.family
      font.pixelSize: 12
      font.letterSpacing: 3
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.4; shadowOpacity: 0.4 }
    }
  }

  Column {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 70
    anchors.bottomMargin: 130
    spacing: 18
    width: 260

    Text {
      anchors.right: parent.right
      text: lock.userName.toLowerCase()
      color: lock.cWhite
      font.family: Style.font.family
      font.pixelSize: 22
      font.letterSpacing: 3
      horizontalAlignment: Text.AlignRight
    }

    Item {
      anchors.right: parent.right
      width: parent.width; height: 46

      Rectangle {
        anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.left: parent.left
        height: pwd.activeFocus ? 2 : 1
        color: pwd.activeFocus ? lock.amber : Qt.rgba(lock.cWhite.r, lock.cWhite.g, lock.cWhite.b, 0.35)
        Behavior on color { ColorAnimation { duration: 250 } }
      }

      LockInput {
        id: pwd
        lock: lock
        anchors.fill: parent
        anchors.bottomMargin: 4
        horizontalAlignment: TextInput.AlignRight
        verticalAlignment: TextInput.AlignVCenter
        color: lock.cWhite
        passwordCharacter: "·"
        font.family: Style.font.family
        font.pixelSize: 20
        font.letterSpacing: 8
        selectionColor: lock.amber
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle { width: 2; color: lock.amber; visible: pwd.cursorVisible }
      }

      Text {
        anchors.right: pwd.right
        anchors.verticalCenter: pwd.verticalCenter
        text: lock.authenticatingPassword ? "checking…" : (lock.errorState ? lock.failureMessage : "password")
        color: lock.cWhite
        opacity: pwd.text.length === 0 ? 0.55 : 0
        font.family: Style.font.family
        font.pixelSize: 13
        font.letterSpacing: 2
        Behavior on opacity { NumberAnimation { duration: 200 } }
      }
    }

    Text {
      anchors.right: parent.right
      text: lock.fingerprintConfigured ? "touch sensor or type password" : "type password"
      color: lock.cWhite
      opacity: 0.7
      font.family: Style.font.family
      font.pixelSize: 11
      font.letterSpacing: 2
      horizontalAlignment: Text.AlignRight
    }
  }
}

// source: qylock
// name: Minecraft
// description: Title screen with a rotating splash line
// Faithful port of Darkkal44's qylock "minecraft" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The QML is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source, and drops the SDDM-specific multi-user/session/power row in
// favor of the shared single password field (the Login button stays,
// since it's iconic to the source's chunky button styling, and just
// submits the typed password). The source ships no font (font/ is an
// empty .gitkeep placeholder — no real Minecraft font included for
// copyright reasons), so every label uses the shell's normal font,
// with the classic blocky drop-shadow duplicate-text trick standing in
// for the pixel-font look instead.
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("minecraft-assets/")

  // Original qylock Minecraft-menu palette.
  property color btnFace: "#8b8b8b"
  property color btnPress: "#585858"
  property color textWhite: "#ffffff"
  property color textShadow: "#3f3f3f"
  property color textYellow: "#ffff55"
  property color textGray: "#aaaaaa"
  property color textRed: "#ff5555"

  readonly property var splashes: ["I use Arch btw", "|||RTFM!|||", "Have you tried rebooting?", "Kernel Panic!", "Btw I use Omarchy!", "Updating 512 packages!", "chmod 777", "Segmentation Fault"]
  property string splash: splashes[Math.floor(Math.random() * splashes.length)]

  Rectangle { anchors.fill: parent; color: "#1e1e1e" }

  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "background.png" : ""
    fillMode: Image.PreserveAspectCrop
    horizontalAlignment: Image.AlignHCenter
    verticalAlignment: Image.AlignVCenter
    scale: 2.0
    transformOrigin: Item.Center
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Reusable blocky drop-shadow text (the classic MC font stand-in).
  component McText: Item {
    property string label: ""
    property int pixelSize: 16
    property color textColor: lock.textWhite
    property int halign: Text.AlignLeft
    property int shadowOffset: 2
    implicitWidth: fore.implicitWidth + 8
    implicitHeight: fore.implicitHeight + 2
    Text { x: shadowOffset; y: shadowOffset; width: parent.width; text: label; color: lock.textShadow; font.family: Style.font.family; font.bold: true; font.pixelSize: pixelSize; horizontalAlignment: parent.halign }
    Text { id: fore; width: parent.width; text: label; color: textColor; font.family: Style.font.family; font.bold: true; font.pixelSize: pixelSize; horizontalAlignment: parent.halign }
  }

  Column {
    id: mainStack
    anchors.centerIn: parent
    width: 420
    spacing: 20

    Item {
      width: parent.width
      height: 170
      Image {
        id: mainLogo
        source: lock.assetsUrl + "title.png"
        width: 420
        height: 120
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowOpacity: 0.7; shadowBlur: 0.4 }
      }
      Text {
        anchors.horizontalCenter: mainLogo.horizontalCenter
        anchors.horizontalCenterOffset: 130
        anchors.top: mainLogo.top
        anchors.topMargin: 20
        text: lock.splash
        font.family: Style.font.family
        font.bold: true
        font.pixelSize: 16
        color: lock.textYellow
        rotation: -20
        style: Text.Outline
        styleColor: "black"
        SequentialAnimation on scale {
          loops: Animation.Infinite
          NumberAnimation { from: 1.0; to: 1.18; duration: 600; easing.type: Easing.InOutQuad }
          NumberAnimation { from: 1.18; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
        }
      }
    }

    Column {
      width: parent.width
      spacing: 10
      McText { label: "Logged in as:"; pixelSize: 12; textColor: lock.textGray }
      Item {
        width: parent.width
        height: 44
        Rectangle {
          anchors.fill: parent
          color: "black"
          border.color: "#808080"
          border.width: 2
          Rectangle { anchors.fill: parent; anchors.margins: 2; color: "#0a0a0a" }
        }
        McText {
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          label: lock.userName.charAt(0).toUpperCase() + lock.userName.slice(1)
          pixelSize: 18
          textColor: lock.textWhite
        }
      }
    }

    Column {
      width: parent.width
      spacing: 10
      McText { label: "Enter Password:"; pixelSize: 12; textColor: lock.textGray }
      Item {
        width: parent.width
        height: 42
        Rectangle {
          anchors.fill: parent
          color: "black"
          border.color: "#808080"
          border.width: 2
          Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            color: "#0a0a0a"
            Rectangle {
              visible: passwordInput.activeFocus
              anchors.fill: parent
              color: "transparent"
              border.color: "#ffffff"
              border.width: 1
            }
          }
        }

        LockInput {
          id: passwordInput
          lock: lock
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          verticalAlignment: TextInput.AlignVCenter
          color: lock.textWhite
          font.family: Style.font.family
          font.pixelSize: 18
          font.letterSpacing: 4
          passwordCharacter: "*"
          selectionColor: "#9090c0"
          cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
          cursorDelegate: Rectangle { width: 2; color: lock.textWhite; visible: passwordInput.cursorVisible }
        }

        Text {
          anchors.fill: passwordInput
          verticalAlignment: Text.AlignVCenter
          anchors.leftMargin: 2
          text: lock.authenticatingPassword ? "Checking..." : "Enter password..."
          color: "#555555"
          font.family: Style.font.family
          font.pixelSize: 14
          opacity: passwordInput.text.length === 0 ? 1.0 : 0
          Behavior on opacity { NumberAnimation { duration: 400 } }
        }
      }
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      height: 15
      text: lock.errorState ? "ACCESS DENIED" : ""
      color: lock.textRed
      font.family: Style.font.family
      font.bold: true
      font.pixelSize: 14
    }

    Item { width: 1; height: 10 }

    // Login button, matching the source's chunky bevel styling.
    Item {
      id: loginBtn
      width: parent.width
      height: 48

      Rectangle {
        anchors.fill: parent
        color: "black"
        Rectangle {
          anchors.fill: parent
          anchors.margins: 2
          color: loginMa.pressed ? lock.btnPress : (loginMa.containsMouse ? "#686868" : lock.btnFace)

          Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 3; color: "white"; opacity: loginMa.pressed ? 0.1 : (loginMa.containsMouse ? 0.4 : 0.2) }
          Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.bottom: parent.bottom; width: 3; color: "white"; opacity: loginMa.pressed ? 0.1 : (loginMa.containsMouse ? 0.4 : 0.2) }
          Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 3; color: "black"; opacity: 0.4 }
          Rectangle { anchors.top: parent.top; anchors.right: parent.right; anchors.bottom: parent.bottom; width: 3; color: "black"; opacity: 0.4 }

          McText {
            anchors.centerIn: parent
            label: lock.authenticatingPassword ? "..." : "Login"
            textColor: loginMa.containsMouse ? lock.textYellow : lock.textWhite
            pixelSize: 18
          }
        }
      }
      MouseArea {
        id: loginMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          var submitted = lock.passwordText
          if (submitted.length > 0) {
            lock.passwordTextEdited("")
            lock.submitPassword(submitted)
          }
        }
      }
    }
  }

  McText {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.margins: 6
    label: "Current Time: " + lock.clock("HH:mm")
    pixelSize: 14
    textColor: lock.textWhite
  }

  McText {
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.margins: 6
    label: Qt.formatDate(lock.now, "dddd, MMMM d")
    pixelSize: 14
    textColor: lock.textWhite
  }
}

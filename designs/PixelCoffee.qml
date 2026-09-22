// source: qylock
// name: Pixel Coffee
// description: Pixel art video from MoeWalls · Pixelify Sans font
// Original design inspired by Darkkal44's qylock "pixel-coffee" theme
// (github.com/Darkkal44/qylock, GPL-3.0). Bundles the source's bg.mp4 and
// its PixelifySans-Bold font (bundled alongside this file in
// pixel-coffee-assets/) for a true-to-source look. The QML itself is
// written from scratch against Omarchy's DesignBase/LockInput, not copied
// from qylock's GPL source, and drops the SDDM-specific multi-user/
// session/reboot/shutdown row (Omarchy handles auth elsewhere) in favor of
// the shared single password field.
//
// PixelifySans-Bold's capital "C" was found to render nearly fully closed
// at UI text sizes (verified directly against the font file, independent
// of Qt) -- confirmed during the pixel-cyberpunk port -- so it stays on
// the big clock, where digits are unambiguous, and every word label below
// uses the shell's normal font instead.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-coffee-assets/")

  // Original qylock palette.
  property color background: "#16101a"
  property color latte: "#d2976b"
  property color steel: "#5c7996"
  property color textDim: "#a09088"

  FontLoader { id: pixelFont; source: lock.assetsUrl + "font/PixelifySans-Bold.ttf" }

  Rectangle { anchors.fill: parent; color: lock.background }

  MediaPlayer {
    id: bgPlayer
    source: lock.loadBackground ? lock.assetsUrl + "bg.mp4" : ""
    videoOutput: bgVideo
    loops: MediaPlayer.Infinite
    autoPlay: true
    Component.onCompleted: if (!lock.videoPlaying) pause()
  }

  // Only the grid cell actually on screen decodes video; every other
  // cell (and the many now in the Third Party tab) stays paused on
  // whatever frame it already has, so scrolling the picker doesn't
  // spin up dozens of concurrent decoders.
  Connections {
    target: lock
    function onVideoPlayingChanged() { if (lock.videoPlaying) bgPlayer.play(); else bgPlayer.pause() }
  }
  VideoOutput {
    id: bgVideo
    anchors.fill: parent
    fillMode: VideoOutput.PreserveAspectCrop
  }

  Rectangle {
    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
    height: 160
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.85) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 320
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.9) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Bottom-left clock, matching the source's corner placement.
  Column {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: 60
    spacing: 4

    Row {
      spacing: 8
      Rectangle { width: 4; height: 4; color: lock.latte; anchors.verticalCenter: parent.verticalCenter }
      Text {
        text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
        color: lock.steel
        font.family: Style.font.family
        font.pixelSize: 12
        font.letterSpacing: 4
        anchors.verticalCenter: parent.verticalCenter
      }
    }
    Text {
      text: lock.clock("HH:mm")
      color: "white"
      renderType: Text.NativeRendering
      font.family: pixelFont.name
      font.pixelSize: 76
    }
  }

  // Bottom-right login panel, matching the source's underline field.
  Item {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 60
    width: 320
    height: loginCol.implicitHeight

    Column {
      id: loginCol
      width: parent.width
      spacing: 18

      Text {
        text: lock.userName.toUpperCase()
        color: "white"
        font.family: Style.font.family
        font.pixelSize: 22
        font.letterSpacing: 4
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Item {
        width: parent.width
        height: 36

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width; height: 1
          color: lock.steel
          opacity: passwordInput.activeFocus ? 1.0 : 0.3
        }
        Rectangle {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          width: passwordInput.activeFocus ? parent.width : 0
          height: 2
          color: lock.latte
          Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        }

        LockInput {
          id: passwordInput
          lock: lock
          anchors.fill: parent
          color: lock.latte
          font.family: Style.font.family
          font.pixelSize: 18
          font.letterSpacing: 4
          passwordCharacter: "─"
          horizontalAlignment: TextInput.AlignHCenter
          verticalAlignment: TextInput.AlignVCenter
          selectionColor: lock.latte
          cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
          cursorDelegate: Rectangle { width: 2; color: lock.latte; visible: passwordInput.cursorVisible }
        }

        Text {
          anchors.centerIn: parent
          text: "password..."
          color: lock.textDim
          font.family: Style.font.family
          font.pixelSize: 14
          font.letterSpacing: 4
          opacity: passwordInput.text.length === 0 ? 0.6 : 0
          Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
        }
      }

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 140; height: 36
        Rectangle {
          anchors.fill: parent
          color: loginMouse.containsMouse ? lock.latte : "transparent"
          border.color: lock.latte
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }
        }
        Text {
          anchors.centerIn: parent
          text: lock.authenticatingPassword ? "CHECKING…" : "LOGIN"
          color: loginMouse.containsMouse ? "#000" : lock.latte
          font.family: Style.font.family
          font.pixelSize: 12
          font.letterSpacing: 4
          Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
          id: loginMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (passwordInput.text.length > 0) lock.submitPassword(passwordInput.text)
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        height: 12
        verticalAlignment: Text.AlignBottom
        text: lock.errorState ? lock.failureMessage.toUpperCase() : ""
        color: "#ff4444"
        font.family: Style.font.family
        font.pixelSize: 10
      }
    }
  }

  Text {
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 40
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha("#ffffff", 0.5)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

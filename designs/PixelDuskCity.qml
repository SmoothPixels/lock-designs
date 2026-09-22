// source: qylock
// name: Pixel Dusk City
// description: Pixel art video from Wallsflow · Pixelify Sans font
// Original design inspired by Darkkal44's qylock "pixel-dusk-city" theme
// (github.com/Darkkal44/qylock, GPL-3.0). Bundles the source's bg.mp4 and
// its PixelifySans-Bold font (bundled alongside this file in
// pixel-dusk-city-assets/) for a true-to-source look. The QML itself is
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

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-dusk-city-assets/")

  // Original qylock palette.
  property color background: "#0c0a08"
  property color amberHot: "#e8803c"
  property color amberSoft: "#c8a060"
  property color tealSign: "#4dd8c4"
  property color textWhite: "#f0ece4"

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
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.3) }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.92) }
    }
  }

  // Rising amber/teal embers, matching the source's particle field.
  Repeater {
    model: 16
    Rectangle {
      id: em
      property real sx: Math.random() * lock.width * 0.6 + lock.width * 0.2
      property real dr: (Math.random() - 0.5) * 80
      property real dur: 5500 + Math.random() * 7000
      property int ct: Math.floor(Math.random() * 3)
      x: sx; y: lock.height + 10
      width: 2 + Math.random() * 2; height: width
      radius: width / 2
      color: ct === 0 ? lock.amberHot : ct === 1 ? lock.amberSoft : lock.tealSign
      opacity: 0
      SequentialAnimation {
        running: true
        loops: Animation.Infinite
        PauseAnimation { duration: Math.random() * 10000 }
        ParallelAnimation {
          NumberAnimation { target: em; property: "y"; from: lock.height + 10; to: -20; duration: em.dur; easing.type: Easing.OutQuad }
          NumberAnimation { target: em; property: "x"; from: em.sx; to: em.sx + em.dr; duration: em.dur; easing.type: Easing.InOutSine }
          SequentialAnimation {
            NumberAnimation { target: em; property: "opacity"; to: 0.85; duration: 700 }
            PauseAnimation { duration: Math.max(0, em.dur - 1600) }
            NumberAnimation { target: em; property: "opacity"; to: 0; duration: 900 }
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Top-left clock unit.
  Column {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: 52
    spacing: 5

    Text {
      text: lock.clock("HH:mm")
      color: lock.textWhite
      renderType: Text.NativeRendering
      font.family: pixelFont.name
      font.pixelSize: 78
    }
    Row {
      spacing: 8
      Rectangle {
        width: 4; height: 4; color: lock.amberHot
        anchors.verticalCenter: parent.verticalCenter
        SequentialAnimation on opacity {
          loops: Animation.Infinite
          NumberAnimation { to: 0.2; duration: 1400; easing.type: Easing.InOutSine }
          NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
        }
      }
      Text {
        text: Qt.formatDate(lock.now, "ddd, MMM d").toUpperCase()
        color: lock.amberSoft
        font.family: Style.font.family
        font.pixelSize: 11
        font.letterSpacing: 3
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  // Centered-bottom login panel.
  Item {
    id: loginPanel
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 90
    anchors.horizontalCenter: parent.horizontalCenter
    width: 340
    height: loginCol.implicitHeight

    transform: Translate { id: shakeT }
    Connections {
      target: lock
      function onFailureMessageChanged() {
        if (lock.failureMessage.length === 0) return
        duskShake.restart()
      }
    }
    SequentialAnimation {
      id: duskShake
      NumberAnimation { target: shakeT; property: "x"; from: 0; to: 10; duration: 45 }
      NumberAnimation { target: shakeT; property: "x"; from: 10; to: -8; duration: 45 }
      NumberAnimation { target: shakeT; property: "x"; from: -8; to: 6; duration: 45 }
      NumberAnimation { target: shakeT; property: "x"; from: 6; to: -4; duration: 45 }
      NumberAnimation { target: shakeT; property: "x"; from: -4; to: 0; duration: 45 }
    }

    Column {
      id: loginCol
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      spacing: 0

      Text {
        text: lock.userName.toUpperCase()
        color: lock.textWhite
        font.family: Style.font.family
        font.pixelSize: 17
        font.letterSpacing: 4
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Item { width: 1; height: 8 }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        Rectangle { width: 44; height: 1; color: lock.amberHot; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 5; height: 5; color: lock.amberHot; opacity: 0.65; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 44; height: 1; color: lock.amberHot; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
      }

      Item { width: 1; height: 20 }

      Item {
        width: parent.width; height: 52
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
          anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
          height: 1
          color: Qt.rgba(0.91, 0.50, 0.24, 0.25)
        }
        Rectangle {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          height: 2
          color: lock.amberHot
          width: passwordInput.activeFocus ? parent.width : 0
          Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        }

        Text {
          anchors.left: parent.left; anchors.leftMargin: 2
          anchors.verticalCenter: parent.verticalCenter
          text: "password"
          color: lock.amberSoft
          font.family: Style.font.family
          font.pixelSize: 14
          font.letterSpacing: 3
          opacity: passwordInput.text.length === 0 ? 0.38 : 0
          Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
        }

        LockInput {
          id: passwordInput
          lock: lock
          anchors.left: parent.left; anchors.leftMargin: 2
          anchors.right: submitBtn.left; anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          color: lock.textWhite
          font.family: Style.font.family
          font.pixelSize: 14
          font.letterSpacing: 3
          passwordCharacter: "─"
          selectionColor: lock.amberHot
          cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
          cursorDelegate: Rectangle { width: 2; color: lock.amberHot; visible: passwordInput.cursorVisible }
        }

        Item {
          id: submitBtn
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: loginText.implicitWidth + 16
          height: 24

          Rectangle {
            anchors.fill: parent
            color: submitMouse.containsMouse ? Qt.rgba(0.91, 0.50, 0.24, 0.18) : "transparent"
            border.color: Qt.rgba(0.91, 0.50, 0.24, passwordInput.text.length > 0 ? 0.55 : 0.20)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
          }
          Text {
            id: loginText
            anchors.centerIn: parent
            text: lock.authenticatingPassword ? "…" : "LOGIN"
            color: lock.amberHot
            font.family: Style.font.family
            font.pixelSize: 9
            font.letterSpacing: 2
            opacity: passwordInput.text.length > 0 ? 1.0 : 0.30
            Behavior on opacity { NumberAnimation { duration: 200 } }
          }
          MouseArea {
            id: submitMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (passwordInput.text.length > 0) lock.submitPassword(passwordInput.text)
          }
        }
      }

      Item { width: 1; height: 10 }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: lock.errorState ? "incorrect password" : ""
        color: "#f07050"
        font.family: Style.font.family
        font.pixelSize: 10
        font.letterSpacing: 2
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 30
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.textWhite, 0.35)
    font.family: Style.font.family
    font.pixelSize: 10
    font.letterSpacing: 2
  }
}

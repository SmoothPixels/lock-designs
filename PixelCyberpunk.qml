// source: qylock
// Faithful port of Darkkal44's qylock "pixel-cyberpunk" theme
// (github.com/Darkkal44/qylock, GPL-3.0). Unlike StarryCity — an unrelated
// original design — this one deliberately keeps the source's fixed neon
// palette and its actual bg.mp4 asset (bundled alongside this file in
// pixel-cyberpunk-assets/) for a true-to-source look. The QML itself is
// written from scratch against Omarchy's DesignBase/LockInput, not copied
// from qylock's GPL source, and drops the SDDM-specific multi-user/session/
// power row (Omarchy handles that elsewhere) in favor of the shared single
// password field.
//
// The source's bundled PixelifySans-Bold renders its capital "C" almost
// fully closed at UI text sizes (verified directly against the font file,
// independent of Qt) — "WELCOME BACK" reads as "WELOOME BAOK". It stays on
// the big clock, where digits are unambiguous and the pixel look matters
// most, but every word label below uses the shell's normal font instead.
//
// To customize the colors instead of using the original palette, create
// pixel-cyberpunk-assets/colors.json next to this file with any subset of:
// { "background": "#0a0c14", "cyanWire": "#5ce5e6", "electricBlue": "#62a3f0",
//   "cleanWhite": "#ffffff", "metalDark": "#0b151f", "darkTeal": "#132c38" }
// Missing keys fall back to the original values below.
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("pixel-cyberpunk-assets/")

  // Original qylock palette, overridable via colors.json (see header).
  property color background: "#0a0c14"
  property color cyanWire: "#5ce5e6"
  property color electricBlue: "#62a3f0"
  property color cleanWhite: "#ffffff"
  property color metalDark: "#0b151f"
  property color darkTeal: "#132c38"

  FileView {
    id: colorOverrides
    path: Quickshell.env("HOME") + "/.config/omarchy/lock-designs/pixel-cyberpunk-assets/colors.json"
    printErrors: false
    onLoaded: {
      try {
        var o = JSON.parse(text() || "{}")
        if (o.background) lock.background = o.background
        if (o.cyanWire) lock.cyanWire = o.cyanWire
        if (o.electricBlue) lock.electricBlue = o.electricBlue
        if (o.cleanWhite) lock.cleanWhite = o.cleanWhite
        if (o.metalDark) lock.metalDark = o.metalDark
        if (o.darkTeal) lock.darkTeal = o.darkTeal
      } catch (e) {
        console.warn("PixelCyberpunk: invalid colors.json: " + e)
      }
    }
  }

  FontLoader {
    id: pixelFont
    source: lock.assetsUrl + "font/PixelifySans-Bold.ttf"
  }

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

  // Scanline borders, matching the source's fixed 20px inset wires.
  Rectangle { width: 2; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.leftMargin: 20; color: lock.cyanWire; opacity: 0.08 }
  Rectangle { width: 2; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.rightMargin: 20; color: lock.cyanWire; opacity: 0.08 }

  Rectangle {
    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
    height: 120
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0.03, 0.035, 0.07, 0.88) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 300
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.03, 0.08, 0.96) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Top HUD: status dot, greeting, clock, date badge.
  Item {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 60
    height: 80

    Column {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Row {
        spacing: 8
        Rectangle {
          width: 6; height: 6; color: lock.cyanWire
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
            NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
          }
        }
        Text {
          text: "WELCOME BACK, " + lock.userName.toUpperCase()
          color: lock.cyanWire
          font.family: Style.font.family
          font.pixelSize: 14
          font.letterSpacing: 2
          font.bold: true
        }
      }

      Text {
        text: lock.clock("HH:mm")
        color: lock.cleanWhite
        renderType: Text.NativeRendering
        font.family: pixelFont.name
        font.pixelSize: 40
        font.letterSpacing: 2
      }
    }

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: dateText.implicitWidth + 30
      height: 28

      Rectangle { anchors.fill: parent; color: lock.darkTeal; opacity: 0.3; border.color: lock.electricBlue; border.width: 1 }

      Text {
        id: dateText
        anchors.centerIn: parent
        text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
        color: lock.electricBlue
        font.family: Style.font.family
        font.pixelSize: 11
        font.letterSpacing: 2
        font.bold: true
      }
    }
  }

  // Password field, styled after the source's bordered login box.
  Item {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 64
    width: 320
    height: 48

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.top
      anchors.bottomMargin: 8
      visible: lock.errorState
      text: lock.failureMessage
      color: "#ff4766"
      font.family: Style.font.family
      font.pixelSize: 12
    }

    Rectangle {
      anchors.fill: parent
      color: lock.metalDark
      opacity: 0.85
      border.color: lock.errorState ? "#ff4766" : (passwordInput.activeFocus ? lock.cyanWire : lock.electricBlue)
      border.width: 1
      Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    LockInput {
      id: passwordInput
      lock: lock
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      verticalAlignment: TextInput.AlignVCenter
      color: lock.cyanWire
      passwordCharacter: "■"
      font.family: Style.font.family
      font.pixelSize: 15
      font.letterSpacing: 3
      selectionColor: lock.cyanWire
      cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
      cursorDelegate: Rectangle {
        width: 6
        color: lock.cyanWire
        visible: passwordInput.cursorVisible
      }
    }

    Text {
      anchors.left: passwordInput.left
      anchors.verticalCenter: passwordInput.verticalCenter
      text: lock.authenticatingPassword ? "Checking…" : "Password"
      color: lock.cleanWhite
      font.family: Style.font.family
      font.pixelSize: 12
      font.letterSpacing: 1
      opacity: passwordInput.text.length === 0 ? 0.5 : 0
      Behavior on opacity { NumberAnimation { duration: 150 } }
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 24
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.cleanWhite, 0.4)
    font.family: Style.font.family
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

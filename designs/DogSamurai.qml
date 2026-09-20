// source: qylock
// Original design inspired by Darkkal44's qylock "dog-samurai" theme
// (github.com/Darkkal44/qylock, GPL-3.0): a cinematic video background, an
// extra-light glowing clock in the top-left, and a glassy side panel with a
// glowing accent stripe along its left edge. Rewritten from scratch against
// Omarchy's DesignBase/PasswordField, not copied from qylock's GPL source,
// and drops the SDDM-only multi-user/session/power row in favor of the
// shared single password field. Only the bundled Orbitron font is reused
// (bundled in dog-samurai-assets/), which tested clean for every letterform,
// so it is used throughout, along with the original bg.mp4 clip and pink
// accent palette.
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("dog-samurai-assets/")
  property color textPrimary: "#f8f1e5"
  property color textSecondary: "#8b949e"
  property color accent: "#ffb7c5"
  property color glassBg: Qt.rgba(0.04, 0.05, 0.06, 0.8)

  FontLoader { id: orbitron; source: lock.assetsUrl + "font/Orbitron-VariableFont_wght.ttf" }

  Rectangle { anchors.fill: parent; color: "#0d1117" }

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
  VideoOutput { id: bgVideo; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Qt.rgba(0.04, 0.04, 0.035, 0.8) }
      GradientStop { position: 0.45; color: "transparent" }
      GradientStop { position: 1; color: Qt.rgba(0.04, 0.04, 0.035, 0.33) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Item {
    anchors.left: parent.left
    anchors.leftMargin: 100
    anchors.top: parent.top
    anchors.topMargin: 110
    width: 500
    height: 150

    Text {
      id: clockText
      text: lock.clock("HH:mm")
      color: lock.textPrimary
      font.family: orbitron.name
      font.pixelSize: 100
      font.weight: Font.ExtraLight
      font.letterSpacing: 6
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: lock.accent; shadowBlur: 1.0; shadowOpacity: 0.7 }
    }
    Text {
      anchors.top: clockText.bottom
      anchors.topMargin: -4
      text: Qt.formatDate(lock.now, "dddd // MMMM d").toUpperCase()
      color: lock.accent
      opacity: 0.8
      font.family: Style.font.family
      font.pixelSize: 15
      font.letterSpacing: 10
    }
  }

  Item {
    anchors.left: parent.left
    anchors.leftMargin: 100
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 100
    width: 420
    height: 240

    Rectangle {
      anchors.fill: parent
      color: lock.glassBg
      radius: 2
      border.color: Qt.rgba(1, 1, 1, 0.06)
      border.width: 1
    }
    Rectangle {
      width: 4
      height: parent.height
      anchors.left: parent.left
      anchors.leftMargin: -2
      color: lock.accent
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: lock.accent; shadowBlur: 1.0; shadowOpacity: 0.8 }
    }

    Column {
      anchors.fill: parent
      anchors.margins: 40
      spacing: 30

      Column {
        width: parent.width
        spacing: 10
        Text { text: "USER"; color: lock.accent; opacity: 0.8; font.family: Style.font.family; font.pixelSize: 11; font.letterSpacing: 6; font.bold: true }
        Text { text: lock.userName.toUpperCase(); color: lock.textPrimary; font.family: orbitron.name; font.pixelSize: 30; font.weight: Font.ExtraLight; font.letterSpacing: 2 }
      }

      Column {
        width: parent.width
        spacing: 10
        Text { text: "PASSWORD"; color: lock.accent; opacity: 0.8; font.family: Style.font.family; font.pixelSize: 11; font.letterSpacing: 6; font.bold: true }
        PasswordField {
          id: field
          lock: lock
      accentColor: lock.accent
      placeholderColor: lock.textSecondary
          width: parent.width
          height: 50
          radius: 4
          showLockGlyph: false
          color: Qt.rgba(0, 0, 0, 0.3)
          placeholder: "Enter password"
        }
      }
    }
  }
}

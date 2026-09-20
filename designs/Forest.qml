// source: qylock
// Original design inspired by Darkkal44's qylock "forest" theme
// (github.com/Darkkal44/qylock, GPL-3.0): a forest video background behind
// frosted "liquid glass" panels -- a rounded pebble holding the clock in the
// top-left, and a taller card in the bottom-right holding the greeting and
// password field, both with a bright rim along their top edge. The source
// achieves the glass look with a live blurred capture of the video underneath
// each panel (Qt5Compat ShaderEffectSource pipeline); that pipeline isn't
// copied here, so this rewrite approximates the same read with a translucent
// tinted panel and a soft top-rim highlight instead of a true backdrop blur.
// Written from scratch against Omarchy's DesignBase/PasswordField, dropping
// the SDDM-only multi-user/session/power row. Only the bundled Figtree-Bold
// font is reused (bundled in forest-assets/), which tested clean for every
// letterform, so it is used throughout, along with the original bg.mp4 clip
// and soft green accent.
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("forest-assets/")
  property color accent: "#d3eaad"

  FontLoader { id: forestFont; source: lock.assetsUrl + "font/Figtree-Bold.ttf" }

  Rectangle { anchors.fill: parent; color: "#010801" }

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

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  component GlassPanel: Item {
    property real glassRadius: 22
    property color tint: "#40101a10"
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.7; shadowOpacity: 0.35; shadowVerticalOffset: 8 }

    Rectangle { anchors.fill: parent; radius: parent.glassRadius; color: parent.tint }
    // A single clean border reads as "glass card" well enough on its own.
    // (A separate top-edge highlight was tried twice and kept reading as a
    // stray line rather than a rim catch-light — simpler is more correct.)
    Rectangle {
      anchors.fill: parent
      radius: parent.glassRadius
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.35)
    }
  }

  // Clock pebble, top-left.
  Item {
    x: 100; y: 100
    width: 360; height: 170
    GlassPanel { anchors.fill: parent }
    Column {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -6
      spacing: 5
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: lock.clock("HH:mm")
        font.family: forestFont.name
        font.pixelSize: 76
        font.weight: Font.Medium
        font.letterSpacing: -2
        color: "white"
        opacity: 0.95
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
        font.family: Style.font.family
        font.pixelSize: 14
        font.letterSpacing: 4
        color: lock.accent
        opacity: 0.75
      }
    }
  }

  // Main card, bottom-right.
  Item {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 100
    width: 420
    height: 230

    GlassPanel { anchors.fill: parent }

    Column {
      anchors.fill: parent
      anchors.margins: 24
      spacing: 16

      Row {
        spacing: 14
        Rectangle {
          width: 42; height: 42; radius: 21
          color: lock.accent
          anchors.verticalCenter: parent.verticalCenter
          Text { anchors.centerIn: parent; text: lock.userInitial; font.pixelSize: 17; font.bold: true; color: "#0d1b0d" }
        }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          Text { text: "WELCOME BACK"; font.family: Style.font.family; font.pixelSize: 11; color: "white"; opacity: 0.55; font.letterSpacing: 2 }
          Text { text: lock.userName.toUpperCase(); font.family: forestFont.name; font.pixelSize: 20; font.weight: Font.Bold; color: "white" }
        }
      }

      PasswordField {
        id: field
        lock: lock
      accentColor: lock.accent
      placeholderColor: Qt.rgba(1, 1, 1, 0.45)
        width: parent.width
        height: 62
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.06)
        placeholder: "Enter passcode"
      }
    }
  }
}

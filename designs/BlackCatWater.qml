// source: wallsflow
// "Black Cat Glowing Water" live wallpaper (wallsflow.com), used here as a
// lock screen background with a clock, date and the shared password field
// over it. Unlike the qylock ports elsewhere in this folder, there is no
// theme/UI to port — wallsflow only distributes the video itself — so this
// is a fresh, minimal DesignBase layout built around it, not a
// reinterpretation of someone else's screen design.
//
// The video is bundled locally (~/.config/omarchy/lock-designs/
// black-cat-water-assets/bg.mp4) rather than fetched on demand like the
// qylock designs: wallsflow's video CDN sits behind a Cloudflare bot
// challenge that blocks plain curl, so there is no URL that could actually
// go in thirdparty-assets.json. That also means this design (and its two
// siblings) only works on a machine where the video has been placed by
// hand — there is no legitimate re-download path.
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("black-cat-water-assets/")
  property color accent: "#4fd8a0"
  property color dim: Qt.rgba(1, 1, 1, 0.5)

  Rectangle { anchors.fill: parent; color: "#04120c" }

  MediaPlayer {
    id: bgPlayer
    source: lock.loadBackground ? lock.assetsUrl + "bg.mp4" : ""
    videoOutput: bgVideo
    loops: MediaPlayer.Infinite
    autoPlay: true
    Component.onCompleted: if (!lock.videoPlaying) pause()
  }
  Connections {
    target: lock
    function onVideoPlayingChanged() { if (lock.videoPlaying) bgPlayer.play(); else bgPlayer.pause() }
  }
  VideoOutput { id: bgVideo; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
      GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.05) }
      GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.1) }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Column {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 64
    spacing: 6
    Text {
      text: lock.clock("HH:mm")
      color: "white"
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.baseSize * 6.5)
      font.weight: Font.DemiBold
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.8; shadowOpacity: 0.6 }
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd, d MMMM").toUpperCase()
      color: lock.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
      font.letterSpacing: 3
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.6; shadowOpacity: 0.5 }
    }
  }

  PasswordField {
    id: field
    lock: lock
    accentColor: lock.accent
    placeholderColor: lock.dim
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 90
    width: 380
    height: 58
    color: Qt.rgba(0, 0, 0, 0.4)
    placeholder: "Enter password"
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

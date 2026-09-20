// source: wallsflow
// "Supercar Dreamscape Under Sakura Blossoms" live wallpaper
// (wallsflow.com), used as a lock screen background with a clock, date and
// the shared password field over it — see BlackCatWater.qml's header for
// why this is a fresh minimal layout rather than a ported UI, and why the
// video is bundled locally instead of fetched on demand.
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("supercar-sakura-assets/")
  property color accent: "#e0483c"
  property color dim: Qt.rgba(1, 1, 1, 0.5)

  Rectangle { anchors.fill: parent; color: "#120a0a" }

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
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
      GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.05) }
      GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.1) }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
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

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 158
    text: lock.userName.toUpperCase()
    color: "white"
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.letterSpacing: 3
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.6; shadowOpacity: 0.5 }
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
  
    // PasswordField's own border always follows the active Omarchy theme
    // (Border.surfaceSpec looks up the theme's lock.border-active color
    // before ever considering accentColor), which is right for theme-
    // following designs but wrong here: this design has its own fixed
    // palette and the border should never clash with an unrelated theme
    // accent. Painting our own border on top, same shape, is the only
    // way to override that without touching lock-explorer's shared
    // component. A child of field (not a sibling) so it still works
    // when field's parent is a Column/Row that forbids anchors on its
    // own children.
    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: "transparent"
      border.color: parent.accentColor
      border.width: parent.outlineThickness
    }
}
}

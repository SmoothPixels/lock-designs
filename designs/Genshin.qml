// source: qylock
// timebased: 1
// name: Genshin Impact
// description: Dawn, day, dusk and night clips picked by the hour
// Port of Darkkal44's qylock "Genshin" theme (github.com/Darkkal44/qylock,
// GPL-3.0). The source cycles through 4 bundled videos (dawn/day/dusk/night)
// based on the wall-clock hour; this keeps that behavior exactly, using the
// same thresholds as the source's own bgVideo property in Main.qml. The
// videos are bundled in genshin-assets/ for a true-to-source look. This QML
// is written from scratch against Omarchy's DesignBase/LockInput/
// PasswordField, dropping the SDDM-only multi-user/session/power row that
// Omarchy handles elsewhere.
//
// The source ships no real font for this theme (font/ only has a .gitkeep),
// so every label here uses the shell's normal font.
import QtQuick
import QtMultimedia
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("genshin-assets/")

  // Original qylock palette.
  readonly property color gGold: "#d3bc8e"
  readonly property color gTextMain: "#ece5d8"
  readonly property color gTextDim: "#b8c0d0"
  readonly property color gBackground: "#050a15"

  function bgVideoFor(hour) {
    if (hour >= 5 && hour < 9) return "dawn.mp4"
    if (hour >= 9 && hour < 17) return "day.mp4"
    if (hour >= 17 && hour < 20) return "dusk.mp4"
    return "night.mp4"
  }

  Rectangle { anchors.fill: parent; color: lock.gBackground }

  MediaPlayer {
    id: bgPlayer
    source: lock.loadBackground ? lock.assetsUrl + lock.bgVideoFor(lock.now.getHours()) : ""
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

  // Vignette, matching the source's dark bottom gradient so UI text stays
  // legible over any of the four videos.
  Rectangle {
    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
    height: 200
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.04, 0.08, 0.55) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 340
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.04, 0.08, 0.7) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Username, top-left, with the source's small gold diamond marker.
  Row {
    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 48
    spacing: 12

    Item {
      width: 14; height: 14
      anchors.verticalCenter: parent.verticalCenter
      Rectangle {
        anchors.centerIn: parent
        width: 14; height: 14; rotation: 45
        color: lock.gGold
        Rectangle { anchors.centerIn: parent; width: 6; height: 6; rotation: -45; color: lock.gBackground }
      }
    }
    Text {
      text: lock.userName.toUpperCase()
      color: lock.gTextMain
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.letterSpacing: 2
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  // Clock, top-right.
  Column {
    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 48
    spacing: 2

    Text {
      anchors.right: parent.right
      text: lock.clock("HH:mm")
      color: lock.gTextMain
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.baseSize * 3.2)
      font.weight: Font.Light
      font.letterSpacing: 2
    }
    Row {
      anchors.right: parent.right
      spacing: 10
      Text {
        text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
        color: lock.gTextDim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 2
        anchors.verticalCenter: parent.verticalCenter
      }
      Rectangle {
        width: 10; height: 10; rotation: 45
        color: lock.gGold
        anchors.verticalCenter: parent.verticalCenter
        Rectangle { anchors.centerIn: parent; width: 4; height: 4; rotation: -45; color: lock.gBackground }
      }
    }
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 96
    spacing: 18

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.gGold
      placeholderColor: lock.gTextDim
      anchors.horizontalCenter: parent.horizontalCenter
      width: 420
      height: 56
      radius: 6
      color: Qt.rgba(0.1, 0.14, 0.24, 0.66)
      placeholder: "Enter password"
      showLockGlyph: false
    
      // PasswordField's own border always follows the active Omarchy theme
      // (Border.surfaceSpec looks up the theme's lock.border-active color
      // before ever considering accentColor), which is right for theme-
      // following designs but wrong here: this design has its own fixed
      // palette and the border should never clash with an unrelated theme
      // accent. Painting our own border on top, same shape, is the only
      // way to override that without touching the shared
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

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
      color: lock.withAlpha(lock.gTextMain, 0.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
    }
  }
}

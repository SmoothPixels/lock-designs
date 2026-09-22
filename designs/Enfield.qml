// source: qylock
// name: Enfield
// description: Arknights: Endfield video from Wallsflow · Orbitron font
// Original design inspired by Darkkal44's qylock "enfield" theme
// (github.com/Darkkal44/qylock, GPL-3.0): a video background behind a pink
// sakura vignette with drifting cherry-blossom petals, a light clock in the
// top-left with a pulsing status dot, and a centered password field lower
// on screen. Rewritten from scratch against Omarchy's DesignBase/
// PasswordField, not copied from qylock's GPL source, and drops the
// SDDM-only multi-user/session/power row. Only the bundled Orbitron font is
// reused (bundled in enfield-assets/), which tested clean for every
// letterform, so it is used throughout, along with the original bg.mp4 clip
// and sakura-pink palette.
import QtQuick
import QtMultimedia
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("enfield-assets/")
  property color sakuraPink: "#d4849e"
  property color mistWhite: "#e8eef2"

  FontLoader { id: orbitron; source: lock.assetsUrl + "font/Orbitron-VariableFont_wght.ttf" }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#12151e" }
      GradientStop { position: 0.5; color: "#1a1f2a" }
      GradientStop { position: 1.0; color: "#0d1018" }
    }
  }

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

  // Vignette + pink tint, matching the source's mood.
  Rectangle {
    anchors.fill: parent
    opacity: 0.6
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: "#c0000000" }
    }
  }
  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 260
    opacity: 0.55
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: "#e8000000" }
    }
  }
  Rectangle { anchors.fill: parent; color: lock.sakuraPink; opacity: 0.08 }

  // Drifting petals.
  Repeater {
    model: 18
    delegate: Item {
      id: petal
      readonly property real startX: Math.random() * lock.width
      readonly property real drift: (Math.random() - 0.5) * 120
      readonly property real dur: 7000 + Math.random() * 8000
      readonly property real sz: 4 + Math.random() * 6
      x: startX; y: -20
      width: sz; height: sz * 0.6
      Rectangle { anchors.fill: parent; radius: width * 0.5; color: lock.sakuraPink; opacity: 0.7 }
      SequentialAnimation on y {
        loops: Animation.Infinite
        PauseAnimation { duration: Math.random() * 8000 }
        NumberAnimation { from: -20; to: lock.height + 20; duration: petal.dur; easing.type: Easing.Linear }
      }
      SequentialAnimation on x {
        loops: Animation.Infinite
        NumberAnimation { from: petal.startX; to: petal.startX + petal.drift; duration: petal.dur / 2; easing.type: Easing.InOutSine }
        NumberAnimation { from: petal.startX + petal.drift; to: petal.startX; duration: petal.dur / 2; easing.type: Easing.InOutSine }
      }
    }
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
    anchors.leftMargin: 64
    anchors.topMargin: 55
    spacing: 6

    Text {
      text: lock.clock("HH:mm")
      color: lock.mistWhite
      font.family: orbitron.name
      font.pixelSize: 80
      font.weight: Font.Light
    }
    Row {
      spacing: 12
      Rectangle {
        width: 6; height: 6; radius: 3
        color: lock.sakuraPink
        anchors.verticalCenter: parent.verticalCenter
        SequentialAnimation on opacity {
          loops: Animation.Infinite
          NumberAnimation { to: 0.3; duration: 1800; easing.type: Easing.InOutSine }
          NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
        }
      }
      Text {
        text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
        color: lock.sakuraPink
        font.family: Style.font.family
        font.pixelSize: 12
        font.letterSpacing: 3
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  Column {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 110
    anchors.horizontalCenter: parent.horizontalCenter
    width: 360
    spacing: 14

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.mistWhite
      font.family: orbitron.name
      font.pixelSize: 18
      font.weight: Font.Light
      font.letterSpacing: 4
    }

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.sakuraPink
      placeholderColor: Qt.rgba(1, 1, 1, 0.45)
      anchors.horizontalCenter: parent.horizontalCenter
      width: 360
      height: 54
      radius: 27
      showLockGlyph: false
      color: Qt.rgba(0, 0, 0, 0.35)
      placeholder: "password"
    
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
  }
}

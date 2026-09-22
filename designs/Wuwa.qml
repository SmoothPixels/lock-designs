// source: qylock
// name: Wuthering Waves
// description: Video from YouTube · Orbitron font
// Port of Darkkal44's qylock "wuwa" theme (github.com/Darkkal44/qylock,
// GPL-3.0). Keeps the source's looping bg.mp4 and logo.png (bundled in
// wuwa-assets/) and its cool cyan/silver palette. Written from scratch
// against Omarchy's DesignBase/LockInput/PasswordField, dropping the
// SDDM-only multi-user/session/power row that Omarchy handles elsewhere.
//
// The source bundles Orbitron (the same file used by Winter). It already
// passed the capital-A legibility check there, so it is used here too, for
// every label, not just the clock.
import QtQuick
import QtMultimedia
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("wuwa-assets/")

  readonly property color wwCyan: "#9ecfdf"
  readonly property color wwWhite: "#eaf0f6"
  readonly property color wwGhost: "#8899aa"
  readonly property color wwBackground: "#0a0e18"

  FontLoader {
    id: orbitron
    source: lock.assetsUrl + "Orbitron.ttf"
  }

  Rectangle { anchors.fill: parent; color: lock.wwBackground }

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
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.03, 0.06, 0.78) }
      GradientStop { position: 0.45; color: Qt.rgba(0.02, 0.03, 0.06, 0.25) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Image {
    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 40
    source: lock.assetsUrl + "logo.png"
    width: 150
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    opacity: 0.92
  }

  // Login panel, left side like the source's loginPanel.
  Column {
    anchors.left: parent.left; anchors.leftMargin: 52
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 60
    spacing: 18
    width: 300

    Row {
      spacing: 10
      Rectangle { width: 8; height: 8; rotation: 45; color: lock.wwCyan; anchors.verticalCenter: parent.verticalCenter }
      Text {
        text: lock.userName.toUpperCase()
        color: lock.wwWhite
        font.family: orbitron.name
        font.pixelSize: Style.font.title
        font.letterSpacing: 2
        font.bold: true
      }
    }

    Rectangle {
      width: parent.width * 0.6; height: 1
      gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: lock.wwCyan } GradientStop { position: 1.0; color: "transparent" } }
      opacity: 0.6
    }

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.wwCyan
      placeholderColor: lock.wwGhost
      width: parent.width
      height: 48
      radius: 6
      color: Qt.rgba(0, 0, 0, 0.5)
      placeholder: "Enter password..."
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
  }

  // Footer date/time, bottom-right like the source's HUD row.
  Row {
    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 40
    spacing: 12

    Text {
      text: Qt.formatDate(lock.now, "yyyy / MM / dd")
      color: lock.wwGhost
      font.family: orbitron.name
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1.5
      anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle { width: 2; height: 16; color: lock.wwCyan; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
    Text {
      text: lock.clock("HH:mm")
      color: lock.wwWhite
      font.family: orbitron.name
      font.pixelSize: Style.font.heading
      font.bold: true
      font.letterSpacing: 1.5
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 68
    anchors.left: parent.left
    anchors.leftMargin: 52
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.wwGhost, 0.8)
    font.family: orbitron.name
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
  }
}

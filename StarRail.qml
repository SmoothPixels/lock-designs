// source: qylock
// Port of Darkkal44's qylock "star-rail" theme (github.com/Darkkal44/qylock,
// GPL-3.0). Keeps the source's looping bg.mp4 (bundled in star-rail-assets/)
// and its gold/blue palette. Written from scratch against Omarchy's
// DesignBase/LockInput/PasswordField, dropping the SDDM-only multi-user/
// session/power row that Omarchy handles elsewhere.
//
// The source ships no font folder at all for this theme, so every label
// uses the shell's normal font.
import QtQuick
import QtMultimedia
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("star-rail-assets/")

  // Original qylock palette.
  readonly property color srGold: "#c8a96e"
  readonly property color srGoldLight: "#e8cfa0"
  readonly property color srWhite: "#eef2f8"
  readonly property color srGhost: "#8899bb"
  readonly property color srBackground: "#060a14"

  Rectangle { anchors.fill: parent; color: lock.srBackground }

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
      GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.04, 0.08, 0.4) }
      GradientStop { position: 0.6; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.04, 0.08, 0.75) }
    }
  }

  // Drifting stars, echoing the source's twinkle field.
  Repeater {
    model: 40
    Item {
      property real px: Math.random() * lock.width
      property real py: Math.random() * lock.height * 0.7
      x: px; y: py
      Rectangle {
        width: 1 + Math.random() * 2; height: width; radius: width / 2
        color: Math.random() > 0.5 ? lock.srWhite : lock.srGoldLight
        opacity: 0
        SequentialAnimation on opacity {
          loops: Animation.Infinite
          PauseAnimation { duration: Math.random() * 6000 }
          NumberAnimation { from: 0; to: 0.5; duration: 2200 }
          NumberAnimation { from: 0.5; to: 0; duration: 2600 }
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

  // Profile chip, top-left.
  Item {
    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 40
    width: 260; height: 56

    Rectangle { anchors.fill: parent; radius: 28; color: Qt.rgba(0.05, 0.08, 0.13, 0.75); border.color: Qt.rgba(1, 1, 1, 0.2); border.width: 1 }

    Rectangle {
      id: avatarFrame
      width: 40; height: 40; radius: 20
      anchors.left: parent.left; anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: Qt.rgba(1, 1, 1, 0.08)
      border.color: lock.srGold; border.width: 1.5
      Text { anchors.centerIn: parent; text: "✦"; color: lock.srGold; font.pixelSize: 18 }
    }

    Column {
      anchors.left: avatarFrame.right; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 2
      Text { text: lock.userName.toUpperCase(); color: lock.srWhite; font.family: Style.font.family; font.pixelSize: Style.font.title; font.bold: true }
      Text { text: "ASTRAL EXPRESS"; color: lock.srGold; opacity: 0.7; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.letterSpacing: 1.5 }
    }
  }

  // Login panel, centered.
  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 60
    spacing: 22

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.srGold
      placeholderColor: lock.srGhost
      anchors.horizontalCenter: parent.horizontalCenter
      width: 340
      height: 48
      radius: 2
      color: Qt.rgba(0, 0, 0, 0.4)
      placeholder: "Enter password"
      showLockGlyph: false
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
      color: lock.withAlpha(lock.srWhite, 0.45)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
    }
  }

  // Footer: date + clock, bottom-right, matching the source's HUD row.
  Row {
    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 32
    spacing: 14

    Text {
      text: Qt.formatDate(lock.now, "yyyy / MM / dd")
      color: lock.srWhite
      opacity: 0.5
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1.5
      anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle { width: 1; height: 16; color: lock.srGoldLight; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
    Text {
      text: lock.clock("HH:mm")
      color: lock.srGoldLight
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
      font.letterSpacing: 1.5
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}

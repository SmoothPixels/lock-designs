// source: qylock
// name: Winter
// description: Winter forest video from MoeWalls · Orbitron font
// Port of Darkkal44's qylock "winter" theme (github.com/Darkkal44/qylock,
// GPL-3.0). Keeps the source's looping bg.mp4 (bundled in winter-assets/)
// and its cool white/ice palette. Written from scratch against Omarchy's
// DesignBase/LockInput/PasswordField, dropping the SDDM-only multi-user/
// session/power row that Omarchy handles elsewhere.
//
// The source bundles Orbitron. Rendered directly against the font file
// every glyph in "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG" comes out
// unambiguous (including the capital A, the letter that broke both
// PixelCyberpunk's and Sword's bundled fonts), so it is safe to use
// everywhere here, not just the clock.
import QtQuick
import QtMultimedia
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("winter-assets/")

  readonly property color wiText: "#ffffff"
  readonly property color wiSub: "#99aab5"
  readonly property color wiAccent: "#cde4ef"
  readonly property color wiBackground: "#05080c"

  FontLoader {
    id: orbitron
    source: lock.assetsUrl + "Orbitron.ttf"
  }

  Rectangle { anchors.fill: parent; color: lock.wiBackground }

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
      GradientStop { position: 0.55; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.03, 0.05, 0.72) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, top-center, large and thin like the source.
  Column {
    anchors.top: parent.top; anchors.topMargin: 90
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 12

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.clock("HH:mm")
      color: lock.wiText
      font.family: orbitron.name
      font.pixelSize: Math.round(Style.font.baseSize * 6.5)
      font.weight: Font.Thin
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
      color: lock.wiSub
      font.family: orbitron.name
      font.pixelSize: Style.font.body
      font.letterSpacing: 6
    }
  }

  // Login area, centered lower.
  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 150
    spacing: 20

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.wiAccent
      font.family: orbitron.name
      font.pixelSize: Style.font.subtitle
      font.letterSpacing: 3
    }

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.wiAccent
      placeholderColor: lock.wiSub
      anchors.horizontalCenter: parent.horizontalCenter
      width: 320
      height: 50
      radius: 0
      color: "transparent"
      outlineThickness: 0
      showLockGlyph: false
      textAlignment: TextInput.AlignHCenter
      placeholder: "Password"
      fontScale: 0.9

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: 1
        width: field.input.activeFocus ? parent.width : parent.width * 0.3
        color: lock.errorState ? Color.lock.textError : lock.wiText
        opacity: field.input.activeFocus ? 0.8 : 0.25
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
      }
    
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

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.wiText, 0.35)
    font.family: orbitron.name
    font.pixelSize: Style.font.caption
    font.letterSpacing: 2
  }
}

// source: qylock
// name: Sword
// description: Silent katana forest video from Wallsflow · The Last Shuriken font
// Port of Darkkal44's qylock "sword" theme (github.com/Darkkal44/qylock,
// GPL-3.0). Keeps the source's looping bg.mp4 (bundled in sword-assets/) and
// its dark navy/cyan palette. Written from scratch against Omarchy's
// DesignBase/LockInput/PasswordField, dropping the SDDM-only multi-user/
// session/power row that Omarchy handles elsewhere.
//
// The source bundles "The Last Shuriken.ttf". Its capital "A" renders
// nearly identical to "R" (verified directly against the font file,
// independent of Qt) -- "SATURDAY" reads as "SRTURDRY", "JEAN" as "JERN".
// It stays on the big clock, where digits are unambiguous, but every word
// label below uses the shell's normal font instead.
import QtQuick
import QtMultimedia
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("sword-assets/")

  readonly property color swAccent: "#6090b8"
  readonly property color swWhite: "#ffffff"
  readonly property color swError: "#d06060"
  readonly property color swBackground: "#050810"

  FontLoader {
    id: shurikenFont
    source: lock.assetsUrl + "TheLastShuriken.ttf"
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#080c14" }
      GradientStop { position: 0.5; color: "#0e1420" }
      GradientStop { position: 1.0; color: lock.swBackground }
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

  VideoOutput {
    id: bgVideo
    anchors.fill: parent
    fillMode: VideoOutput.PreserveAspectCrop
    opacity: 0.9
  }

  Rectangle {
    anchors.fill: parent
    opacity: 0.6
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: "#bb000000" }
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 220; opacity: 0.6
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: "#dd000000" }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Clock, top-left, thin and large like the source.
  Column {
    anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 64
    spacing: 8

    Text {
      text: lock.clock("HH:mm")
      color: lock.swWhite
      font.family: shurikenFont.name
      font.pixelSize: Math.round(Style.font.baseSize * 5.5)
      font.weight: Font.Thin
    }
    Row {
      spacing: 10
      Rectangle { width: 22; height: 1; color: lock.swAccent; anchors.verticalCenter: parent.verticalCenter }
      Text {
        text: Qt.formatDate(lock.now, "dddd · MMMM d").toUpperCase()
        color: lock.swAccent
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.letterSpacing: 3
      }
    }
  }

  // Login panel, bottom-right, matching the source's right-aligned column.
  Column {
    anchors.right: parent.right; anchors.bottom: parent.bottom
    anchors.rightMargin: 64; anchors.bottomMargin: 120
    spacing: 14

    Text {
      anchors.right: parent.right
      text: lock.userName.toUpperCase()
      color: lock.swWhite
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.letterSpacing: 2
    }

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.swAccent
      placeholderColor: Qt.rgba(1, 1, 1, 0.45)
      anchors.right: parent.right
      width: 300
      height: 44
      radius: 0
      color: "transparent"
      outlineThickness: 0
      showLockGlyph: false
      textAlignment: TextInput.AlignRight
      placeholder: "Enter password"

      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: field.input.activeFocus ? lock.swAccent : Qt.rgba(0.4, 0.5, 0.6, 0.3)
        Behavior on color { ColorAnimation { duration: 200 } }
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

    Text {
      anchors.right: parent.right
      text: lock.errorState ? lock.failureMessage : ""
      visible: lock.errorState
      color: lock.swError
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 30
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: lock.withAlpha(lock.swWhite, 0.4)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
  }
}

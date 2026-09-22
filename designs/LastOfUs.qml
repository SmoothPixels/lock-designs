// source: qylock
// name: The Last of Us
// description: Sunset video from MoeWalls · Outfit font
// Faithful port of Darkkal44's qylock "last-of-us" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The QML is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source, and drops the SDDM-specific multi-user/session/power row and user
// directory menu in favor of the shared single password field. The
// source's bundled Outfit-Black font tested clean at UI sizes (every glyph
// in "THE QUICK BROWN FOX WELCOME" unambiguous) so it is used throughout,
// matching the original.
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("last-of-us-assets/")

  // Original qylock palette: ash-white text, dusty tan secondary, ember accent.
  property color textPrimary: "#fffdf5"
  property color textSecondary: "#a89e8d"
  property color accent: "#f7c594"

  FontLoader {
    id: outfitFont
    source: lock.assetsUrl + "font/Outfit-Black.ttf"
  }

  Rectangle { anchors.fill: parent; color: "#0a0a09" }

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
    opacity: 0.18
    gradient: Gradient {
      GradientStop { position: 0; color: "transparent" }
      GradientStop { position: 1; color: Qt.rgba(0.97, 0.77, 0.58, 0.2) }
    }
  }

  // Drifting embers/dust, matching the source's ambient mote field.
  Repeater {
    model: 24
    delegate: Item {
      id: mote
      property real sx: Math.random() * lock.width * 0.7 + lock.width * 0.1
      property real sy: Math.random() * lock.height
      property real dr: (Math.random() - 0.5) * 40
      property real dur: 14000 + Math.random() * 16000
      property real sz: 1.5 + Math.random() * 2.5
      x: sx
      y: sy
      width: sz
      height: sz
      opacity: 0
      Rectangle { anchors.fill: parent; radius: width / 2; color: "#fff0d4"; opacity: 0.12 }
      SequentialAnimation {
        running: true
        loops: Animation.Infinite
        ParallelAnimation {
          NumberAnimation { target: mote; property: "y"; to: mote.sy - 100; duration: mote.dur; easing.type: Easing.InOutSine }
          NumberAnimation { target: mote; property: "x"; to: mote.sx + mote.dr; duration: mote.dur; easing.type: Easing.InOutSine }
          SequentialAnimation {
            NumberAnimation { target: mote; property: "opacity"; to: 0.4; duration: mote.dur * 0.4 }
            NumberAnimation { target: mote; property: "opacity"; to: 0; duration: mote.dur * 0.6 }
          }
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

  Column {
    id: clockArea
    anchors.left: parent.left
    anchors.leftMargin: 160
    anchors.top: parent.top
    anchors.topMargin: 150
    spacing: 2

    Text {
      text: lock.clock("HH:mm")
      font.family: outfitFont.name
      font.pixelSize: 100
      font.weight: Font.Bold
      color: lock.textPrimary
      opacity: 0.95
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowOpacity: 0.55; shadowBlur: 0.6 }
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd / MMMM d").toUpperCase()
      font.family: outfitFont.name
      font.pixelSize: 14
      font.letterSpacing: 8
      color: lock.textSecondary
      anchors.left: parent.left
      anchors.leftMargin: 6
    }
  }

  Column {
    anchors.left: parent.left
    anchors.leftMargin: 160
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 120
    width: 380
    spacing: 40

    Column {
      spacing: 4
      width: parent.width
      Text { text: "CURRENT OPERATIVE"; font.family: outfitFont.name; font.pixelSize: 10; font.letterSpacing: 2; color: lock.textSecondary; opacity: 0.55 }
      Text {
        text: lock.userName.toUpperCase()
        font.family: outfitFont.name
        font.pixelSize: 38
        font.weight: Font.Bold
        color: lock.textPrimary
      }
    }

    Item {
      width: parent.width
      height: 50

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.03)
        radius: 4
        border.color: lock.errorState ? Qt.rgba(0.94, 0.38, 0.38, 0.3) : (passwordInput.activeFocus ? Qt.rgba(0.97, 0.77, 0.58, 0.25) : Qt.rgba(1, 1, 1, 0.05))
        border.width: 1
      }

      LockInput {
        id: passwordInput
        lock: lock
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 60
        verticalAlignment: TextInput.AlignVCenter
        color: lock.textPrimary
        font.family: outfitFont.name
        font.pixelSize: 20
        font.letterSpacing: 10
        passwordCharacter: "·"
        selectionColor: lock.accent
        cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
        cursorDelegate: Rectangle { width: 8; height: 8; radius: 4; color: lock.accent; visible: passwordInput.cursorVisible }
      }

      Text {
        anchors.left: passwordInput.left
        anchors.verticalCenter: parent.verticalCenter
        text: "ENTER ACCESS KEY"
        font.family: outfitFont.name
        font.pixelSize: 12
        font.letterSpacing: 4
        color: lock.textSecondary
        opacity: passwordInput.text.length === 0 ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        text: lock.authenticatingPassword ? "…" : "GO"
        font.family: outfitFont.name
        font.pixelSize: 11
        font.letterSpacing: 3
        font.weight: Font.Bold
        color: lock.textPrimary
        opacity: passwordInput.text.length > 0 ? 0.8 : 0
        Behavior on opacity { NumberAnimation { duration: 350 } }
      }
    }

    Text {
      width: parent.width
      visible: lock.errorState
      text: lock.failureMessage.length > 0 ? lock.failureMessage.toUpperCase() : ""
      color: "#f06060"
      font.family: outfitFont.name
      font.pixelSize: 12
      font.letterSpacing: 2
    }
  }
}

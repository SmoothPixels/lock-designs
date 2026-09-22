// source: qylock
// timebased: 1
// name: Terraria
// description: Five screenshots that follow the time of day
// Port of Darkkal44's qylock "terraria" theme (github.com/Darkkal44/qylock,
// GPL-3.0). The source picks one of 5 bundled screenshots based on the
// wall-clock hour; this keeps that behavior exactly, using the same
// thresholds as the source's own bgIndex property in Main.qml. The images
// (and the terraria_logo.png wordmark) are bundled in terraria-assets/ for a
// true-to-source look; the source's decorative avatar.png is skipped, there
// is no avatar system here. Written from scratch against Omarchy's
// DesignBase/LockInput/PasswordField, dropping the SDDM-only multi-user/
// session/power row that Omarchy handles elsewhere.
//
// The source ships no real font for this theme (font/ only has a .gitkeep),
// so every label here uses the shell's normal font.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("terraria-assets/")

  function bgIndexFor(hour) {
    if (hour >= 5 && hour < 9) return 5   // dawn — icy blue palette
    if (hour >= 9 && hour < 17) return 1  // day — forest green
    if (hour >= 17 && hour < 20) return 3 // dusk — red/orange
    return 4                              // night — purple
  }

  // Original qylock accent per time-of-day background, matching its
  // bgPalettes[0] entry for each index (the accent it uses for UI chrome).
  function accentFor(index) {
    switch (index) {
      case 1: return "#70e8a0" // forest green (day)
      case 3: return "#ff4040" // red/orange (dusk)
      case 4: return "#a060ff" // purple (night)
      case 5: return "#80e8ff" // icy blue (dawn)
      default: return "#ffffff"
    }
  }

  readonly property int bgIndex: bgIndexFor(lock.now.getHours())
  readonly property color terAccent: accentFor(bgIndex)
  readonly property color terWhite: "#ffffff"

  Rectangle { anchors.fill: parent; color: "#000000" }

  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "ter" + lock.bgIndex + ".png" : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  Rectangle {
    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
    height: 180
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.55) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
  Rectangle {
    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
    height: 320
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Image {
    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 36
    source: lock.assetsUrl + "terraria_logo.png"
    width: 160
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    opacity: 0.92
  }

  Column {
    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 40
    spacing: 4

    Text {
      anchors.right: parent.right
      text: lock.clock("HH:mm")
      color: "#ffffff"
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.baseSize * 3.0)
      font.bold: true
    }
    Text {
      anchors.right: parent.right
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toUpperCase()
      color: lock.terAccent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 2
    }
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 90
    spacing: 16

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: "#ffffff"
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.letterSpacing: 2
    }

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.terAccent
      placeholderColor: Qt.rgba(1, 1, 1, 0.45)
      anchors.horizontalCenter: parent.horizontalCenter
      width: 360
      height: 50
      radius: 4
      color: Qt.rgba(0, 0, 0, 0.55)
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
      color: lock.withAlpha(lock.terWhite, 0.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
    }
  }
}

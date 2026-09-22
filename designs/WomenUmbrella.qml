// source: qylock
// name: Women Umbrella
// description: Video from MoeWalls · Itim font
// Port of Darkkal44's qylock "women-umbrella" theme (github.com/Darkkal44/
// qylock, GPL-3.0). Keeps the source's still bg.png (bundled in
// women-umbrella-assets/) and its soft ink/pink palette. Written from
// scratch against Omarchy's DesignBase/LockInput/PasswordField, dropping
// the SDDM-only multi-user/session/power row that Omarchy handles
// elsewhere.
//
// The source bundles Itim-Regular. Rendered directly against the font file
// every glyph in "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG" comes out
// unambiguous (including the capital A, the letter that broke both
// PixelCyberpunk's and Sword's bundled fonts), so it is safe to use
// everywhere here, not just the clock.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property string assetsUrl: Qt.resolvedUrl("women-umbrella-assets/")

  readonly property color wuInk: "#4b4b4b"
  readonly property color wuSub: "#8b8b8b"
  readonly property color wuPink: "#d37785"
  readonly property color wuPaper: "#f0eee9"

  FontLoader {
    id: itim
    source: lock.assetsUrl + "Itim-Regular.ttf"
  }

  Rectangle { anchors.fill: parent; color: lock.wuPaper }

  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "bg.png" : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  // Header clock, top-left, matching the source's placement.
  Column {
    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 60
    spacing: -4

    Text {
      text: lock.clock("HH:mm")
      color: lock.wuInk
      font.family: itim.name
      font.pixelSize: Math.round(Style.font.baseSize * 4.5)
    }
    Text {
      text: Qt.formatDate(lock.now, "dddd, MMMM d").toLowerCase()
      color: lock.wuSub
      font.family: itim.name
      font.pixelSize: Style.font.subtitle
    }
  }

  // Login card, offset toward the lower-right like the source's bellyArea.
  Column {
    id: loginCol
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.horizontalCenterOffset: parent.width * 0.16
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: parent.height * 0.18
    width: 280
    spacing: 16

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: lock.userName.toUpperCase()
      color: lock.wuInk
      font.family: itim.name
      font.pixelSize: Style.font.subtitle
      font.letterSpacing: 3
    }

    PasswordField {
      id: field
      lock: lock
      accentColor: lock.wuPink
      placeholderColor: lock.wuSub
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      height: 46
      radius: 10
      color: Qt.rgba(1, 1, 1, 0.55)
      placeholder: "password"
      showLockGlyph: false
      textAlignment: TextInput.AlignHCenter
    
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
      visible: lock.errorState
      text: lock.failureMessage
      color: lock.wuPink
      font.family: itim.name
      font.pixelSize: Style.font.caption
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "touch sensor or type password" : "type password · enter to unlock"
    color: lock.withAlpha(lock.wuInk, 0.55)
    font.family: itim.name
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
  }
}

// name: Omarchy default
// description: The stock Omarchy lock screen, following your active theme
//
// Blurred wallpaper with a single centered password box in the theme's
// colors. This is also the design the lock falls back to when the selected
// one fails to load, so it stays deliberately simple.
import QtQuick
import QtQuick.Effects
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  Rectangle {
    anchors.fill: parent
    color: Color.background
  }

  Image {
    id: wallpaper
    anchors.fill: parent
    source: lock.loadBackground ? lock.fileUrl(lock.backgroundPath) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: width
    sourceSize.height: height
  }

  MultiEffect {
    anchors.fill: wallpaper
    source: wallpaper
    autoPaddingEnabled: false
    blurEnabled: lock.loadBackground && wallpaper.status === Image.Ready
    blur: 1.0
    blurMax: 128
    blurMultiplier: 1.25
    contrast: -0.08
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  PasswordField {
    id: field
    lock: lock
    anchors.centerIn: parent
    width: 381
    height: 67
    outlineThickness: 3
    radius: Style.cornerRadius
    showLockGlyph: false
    placeholder: "Enter Password"
    fontScale: 1.125
  }
}

import QtQuick
import qs.Commons
import qs.Ui

// A complete password box: lock glyph, the input, a placeholder that doubles
// as the status line, the reveal toggle, and one icon per extra factor that
// is enrolled. Colors default to the active Omarchy theme; a design with its
// own palette passes accentColor and placeholderColor instead.
BorderSurface {
  id: field

  property var lock: null
  property string placeholder: "Enter password"
  property bool showLockGlyph: true
  property bool shakeOnFail: true
  property int outlineThickness: 2
  property color accentColor: Color.lock.borderActive
  property color placeholderColor: Color.lock.placeholder
  property real fontScale: 1.0
  property int textAlignment: TextInput.AlignHCenter
  property int sidePadding: 18

  readonly property alias input: input
  readonly property bool snapshotBox: lock ? lock.snapshotMode === true : false
  readonly property bool errorState: lock ? lock.errorState : false
  readonly property bool authenticating: lock ? lock.authenticatingPassword : false
  readonly property bool fingerprint: lock ? lock.fingerprintConfigured : false
  readonly property bool face: lock ? lock.faceConfigured : false
  readonly property bool fido2: lock ? lock.fido2Configured : false
  readonly property bool fido2Active: lock ? lock.fido2Active : false
  readonly property bool revealed: lock ? lock.passwordVisible : false
  readonly property bool showToggle: lock ? (lock.showPasswordToggle && !lock.fido2Active) : true
  readonly property int fieldFontSize: Math.round(Style.font.heading * fontScale)
  readonly property int dotFontSize: Math.round(Style.font.heading * 1.25 * fontScale)
  readonly property int dotLetterSpacing: Math.round(Style.font.heading * 0.19 * fontScale)
  readonly property int iconSize: Math.round(fieldFontSize * 1.1)
  // Both sides reserve the wider of the glyph and the icon cluster, so
  // centered text stays centered in the box rather than between the icons.
  readonly property real glyphReserve: showLockGlyph ? Math.round(lockGlyph.implicitWidth + 12) : 0
  readonly property real fingerprintReserve: icons.reserve
  readonly property real sideReserve: Math.max(glyphReserve, fingerprintReserve)
  // Long passwords shrink their dots to stay inside the box instead of
  // clipping, so every keystroke stays visible.
  readonly property real dotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (input.width - 4) / dotMetrics.advanceWidth)
    : 1

  width: 400
  height: 60
  color: Color.lock.background
  radius: Math.max(Style.cornerRadius, 12)
  clip: true
  // Opacity rather than visible for the bare snapshot, so surrounding layouts
  // do not reflow between captures.
  opacity: lock && lock.snapshotBare === true ? 0 : 1
  borderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Color.lock.borderError, field.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", field.accentColor, field.outlineThickness, "border-alpha")

  function focusInput() { input.forceActiveFocus() }

  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: field.dotFontSize
    font.letterSpacing: field.dotLetterSpacing
    text: "●".repeat(input.text.length)
  }

  transform: Translate { id: nudge }
  SequentialAnimation {
    id: shake
    NumberAnimation { target: nudge; property: "x"; from: 0; to: -8; duration: 40 }
    NumberAnimation { target: nudge; property: "x"; from: -8; to: 7; duration: 65 }
    NumberAnimation { target: nudge; property: "x"; from: 7; to: -5; duration: 55 }
    NumberAnimation { target: nudge; property: "x"; from: -5; to: 3; duration: 45 }
    NumberAnimation { target: nudge; property: "x"; from: 3; to: 0; duration: 40 }
  }
  Connections {
    target: field.lock
    ignoreUnknownSignals: true
    function onFailureMessageChanged() {
      if (field.shakeOnFail && field.lock.failureMessage.length > 0) shake.restart()
    }
  }

  Text {
    id: lockGlyph
    anchors.left: parent.left
    anchors.leftMargin: field.borderLeft + field.sidePadding
    anchors.verticalCenter: parent.verticalCenter
    visible: field.showLockGlyph && !field.snapshotBox
    text: field.authenticating ? "󰔟" : (field.errorState ? "󰍁" : "󰌾")
    color: field.errorState ? Color.lock.textError : field.placeholderColor
    font.family: Style.font.family
    font.pixelSize: field.iconSize
  }

  LockInput {
    id: input
    lock: field.lock
    anchors.fill: parent
    anchors.topMargin: field.borderTop
    anchors.bottomMargin: field.borderBottom
    anchors.leftMargin: field.borderLeft + field.sidePadding + field.sideReserve
    anchors.rightMargin: field.borderRight + field.sidePadding + field.sideReserve
    verticalAlignment: TextInput.AlignVCenter
    horizontalAlignment: field.textAlignment
    // The typed dots and cursor take the design's accent, not the theme text
    // color, so a fixed-palette design never shows an unrelated theme color.
    color: field.accentColor
    selectionColor: field.accentColor
    selectedTextColor: field.color
    font.pixelSize: text.length > 0 && !field.revealed ? Math.max(1, Math.floor(field.dotFontSize * field.dotScale)) : field.fieldFontSize
    font.letterSpacing: text.length > 0 && !field.revealed ? field.dotLetterSpacing * field.dotScale : 0
    cursorVisible: activeFocus && text.length > 0 && !field.authenticating && !field.errorState
    cursorDelegate: Rectangle {
      width: 2
      color: field.accentColor
      visible: input.cursorVisible
    }
  }

  Text {
    anchors.fill: input
    visible: input.text.length === 0 && !field.snapshotBox
    text: {
      if (field.authenticating) return "Checking…"
      if (field.errorState) return field.lock.failureMessage
      if (field.fido2Active) return field.lock.fido2Status.length > 0 ? field.lock.fido2Status : "Waiting for your key…"
      return field.placeholder
    }
    textFormat: Text.PlainText
    color: field.authenticating ? Color.lock.text : (field.errorState ? Color.lock.textError : field.placeholderColor)
    font.family: Style.font.family
    font.pixelSize: field.fieldFontSize
    font.italic: field.errorState && !field.authenticating
    horizontalAlignment: field.textAlignment
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }

  // Reveal toggle plus one icon per enrolled factor, packed against the right
  // edge. A Row does the spacing, so an extra factor never shifts the others
  // by hand-tuned margins.
  Row {
    id: icons
    anchors.right: parent.right
    anchors.rightMargin: field.borderRight + field.sidePadding
    anchors.verticalCenter: parent.verticalCenter
    spacing: 10
    visible: !field.snapshotBox
    readonly property real reserve: visible && width > 0 ? Math.round(width + 12) : 0

    Text {
      visible: field.showToggle
      text: field.revealed ? "󰈉" : "󰈈"
      color: field.revealed ? field.accentColor : field.placeholderColor
      font.family: Style.font.family
      font.pixelSize: field.iconSize
      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (field.lock) field.lock.togglePasswordVisible()
          input.forceActiveFocus()
        }
      }
    }

    Text {
      visible: field.fingerprint
      text: "󰈷"
      color: field.placeholderColor
      font.family: Style.font.family
      font.pixelSize: field.iconSize
    }

    Text {
      visible: field.face
      text: "󰱻"
      color: field.placeholderColor
      font.family: Style.font.family
      font.pixelSize: field.iconSize
    }

    // Lit while the key is the active factor, dim while merely enrolled.
    // Click switches to the key, or asks it to try again.
    Text {
      visible: field.fido2
      text: ""
      color: field.fido2Active ? Color.lock.text : field.placeholderColor
      font.family: Style.font.family
      font.pixelSize: field.iconSize
      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        enabled: field.lock ? field.lock.inputEnabled : false
        onClicked: {
          field.lock.wakeRequested()
          field.lock.fido2Requested()
          input.forceActiveFocus()
        }
      }
    }
  }
}

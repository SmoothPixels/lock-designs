import QtQuick
import qs.Commons

// The bare password input. Designs that draw their own field chrome use this
// directly; PasswordField wraps it with a box, placeholder and icons.
//
// Text flows both ways. Keystrokes go up to the host through
// lock.passwordTextEdited(), and the host's passwordText comes back down, so a
// failed attempt clears the input on every screen at once.
TextInput {
  id: input

  property var lock: null

  visible: !(lock && lock.snapshotMode === true)
  echoMode: lock && lock.passwordVisible && !lock.fido2Active ? TextInput.Normal : TextInput.Password
  passwordCharacter: "●"
  passwordMaskDelay: 0
  activeFocusOnPress: true
  clip: true
  enabled: lock ? (lock.inputEnabled && !lock.authenticatingPassword) : false
  // Read-only rather than disabled while a security key holds the field: a
  // disabled item drops focus and stops delivering key presses, and Tab has
  // to keep working to switch factors.
  readOnly: lock ? (lock.authenticatingPassword || (lock.fido2Active && lock.fido2Authenticating && !lock.fido2NeedsPin)) : true
  color: Color.lock.text
  selectionColor: Color.lock.selection
  selectedTextColor: Color.lock.text
  font.family: Style.font.family
  font.pixelSize: Style.font.heading

  // Guards the round trip: pulling the host's text into the field must not
  // echo straight back up as an edit.
  property bool pulling: false

  function pull() {
    if (!lock || input.text === lock.passwordText) return
    pulling = true
    input.text = lock.passwordText
    pulling = false
  }

  Connections {
    target: input.lock
    ignoreUnknownSignals: true
    function onPasswordTextChanged() { input.pull() }
  }
  onLockChanged: pull()
  Component.onCompleted: pull()

  onTextChanged: {
    if (!lock || pulling) return
    lock.passwordTextEdited(text)
    if (text.length > 0) {
      lock.wakeRequested()
      if (lock.failureMessage.length > 0) lock.clearFailureRequested()
    }
  }

  onAccepted: {
    if (!lock) return
    var typed = lock.passwordText
    lock.passwordTextEdited("")
    if (lock.fido2Active && lock.fido2Authenticating) {
      // Typed text is a PIN only while the key is asking for one; an empty
      // Enter asks the key to try again.
      if (typed.length > 0) lock.submitFido2Pin(typed)
      else lock.fido2Requested()
      return
    }
    if (typed.length > 0) lock.submitPassword(typed)
    else if (lock.fido2Active) lock.fido2Requested()
    else if (lock.faceConfigured) lock.faceRequested()
  }

  Keys.onPressed: function(event) {
    if (!lock) return
    lock.wakeRequested()
    var ctrl = (event.modifiers & Qt.ControlModifier) !== 0

    if (lock.fido2Configured && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
      if (lock.fido2Active) lock.passwordRequested()
      else lock.fido2Requested()
      event.accepted = true
    } else if (lock.fido2Active && lock.fido2Authenticating && !lock.fido2NeedsPin
               && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      lock.fido2Requested()
      event.accepted = true
    } else if (event.key === Qt.Key_Escape || (ctrl && event.key === Qt.Key_U)) {
      lock.passwordTextEdited("")
      event.accepted = true
    } else if (ctrl && event.key === Qt.Key_E) {
      if (lock.showPasswordToggle && !lock.fido2Active) lock.togglePasswordVisible()
      event.accepted = true
    }
  }
}

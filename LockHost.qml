import QtQuick
import Quickshell.Io
import qs.Commons

// Puts one design on screen and wires it to the authentication state.
//
// The design is compiled from its file contents each time it is loaded, so an
// edited or freshly updated design file is picked up without restarting the
// shell (the QML engine would otherwise keep serving its cached copy).
//
// Three tiers keep a locked screen unlockable no matter what: the selected
// design; the shipped Classic design if that fails; and a bare input built
// from nothing but QtQuick if even Classic cannot load.
Item {
  id: host

  // Absolute paths. `revision` is bumped to recompile from disk.
  property string designPath: ""
  property string fallbackPath: ""
  property int revision: 0

  // The DesignBase contract, bound onto whichever design is live.
  property string backgroundPath: ""
  property int backgroundVersion: 0
  property string avatarPath: ""
  property int avatarVersion: 0
  property bool fingerprintConfigured: false
  property bool faceConfigured: false
  property bool fido2Configured: false
  property bool fido2Active: false
  property bool fido2Authenticating: false
  property bool fido2NeedsPin: false
  property string fido2Status: ""
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property string videoPath: ""
  property bool videoPlaying: true
  property bool twelveHour: false
  property string displayFont: Style.font.family

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()
  signal faceRequested()
  signal fido2Requested()
  signal passwordRequested()
  signal submitFido2Pin(string pin)
  signal unlockFinished()

  property Item item: null
  property bool usingFallback: false
  property string loadError: ""
  readonly property bool ready: item !== null
  readonly property string livePath: usingFallback ? fallbackPath : designPath

  function forcePasswordFocus() {
    if (item && typeof item.forcePasswordFocus === "function") item.forcePasswordFocus()
    else if (!ready) emergencyInput.forceActiveFocus()
  }

  // Each name is looked up on the instance first, so a design that leaves one
  // out (an older base, a hand-rolled root item) still gets everything else.
  function bind(target) {
    var names = ["backgroundPath", "backgroundVersion", "avatarPath", "avatarVersion",
      "fingerprintConfigured", "faceConfigured", "fido2Configured", "fido2Active",
      "fido2Authenticating", "fido2NeedsPin", "fido2Status", "authenticatingPassword",
      "failureMessage", "failedAttempts", "inputEnabled", "loadBackground", "passwordText",
      "videoPath", "videoPlaying", "twelveHour", "displayFont"]
    names.forEach(function(name) {
      if (target[name] === undefined) return
      target[name] = Qt.binding(function() { return host[name] })
    })
  }

  function fileUrl(path) {
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
  }

  FileView {
    id: source
    path: host.livePath
    printErrors: false
    onLoaded: host.rebuild()
    onLoadFailed: host.fail("Cannot read " + host.livePath)
  }

  onDesignPathChanged: {
    usingFallback = false
    loadError = ""
  }
  onRevisionChanged: if (livePath.length > 0) source.reload()

  property double tStart: 0
  onLivePathChanged: tStart = Date.now()
  function rebuild() {
    var t0 = Date.now()
    if (item) { item.destroy(); item = null }
    var code = ""
    try { code = String(source.text() || "") } catch (e) { code = "" }
    if (code.trim().length === 0) { fail("Empty design file " + livePath); return }
    try {
      var created = Qt.createQmlObject(code, stage, fileUrl(livePath))
      created.anchors.fill = stage
      bind(created)
      item = created
      var t1 = Date.now()
      console.log("lock-designs timing: read " + (t0 - tStart) + " ms, compile+create " + (t1 - t0) + " ms, total " + (t1 - tStart) + " ms for " + livePath.split("/").pop())
      if (!usingFallback) loadError = ""
      if (inputEnabled) Qt.callLater(forcePasswordFocus)
    } catch (e) {
      var detail = String(e)
      if (e.qmlErrors && e.qmlErrors.length) {
        detail = e.qmlErrors.map(function(err) {
          return String(err.fileName).split("/").pop() + ":" + err.lineNumber + ": " + err.message
        }).join("\n")
      }
      fail(detail)
    }
  }

  function fail(detail) {
    console.warn("lock-designs: design failed to load (" + livePath + "): " + detail)
    if (!usingFallback) loadError = detail
    // One step down, never a loop: Classic failing too leaves the bare input.
    if (!usingFallback && fallbackPath.length > 0 && fallbackPath !== designPath) usingFallback = true
    else if (!ready && inputEnabled) emergencyInput.forceActiveFocus()
  }

  Connections {
    target: host.item
    ignoreUnknownSignals: true
    function onSubmitPassword(password) { host.submitPassword(password) }
    function onPasswordTextEdited(password) { host.passwordTextEdited(password) }
    function onClearFailureRequested() { host.clearFailureRequested() }
    function onWakeRequested() { host.wakeRequested() }
    function onFaceRequested() { host.faceRequested() }
    function onFido2Requested() { host.fido2Requested() }
    function onPasswordRequested() { host.passwordRequested() }
    function onSubmitFido2Pin(pin) { host.submitFido2Pin(pin) }
    function onUnlockFinished() { host.unlockFinished() }
  }

  Item {
    id: stage
    anchors.fill: parent
  }

  // Last line of defense, QtQuick only: still takes the password when both
  // the selected design and Classic failed to load.
  Rectangle {
    visible: !host.ready
    anchors.fill: parent
    color: "#14161a"
    onVisibleChanged: if (visible && host.inputEnabled) emergencyInput.forceActiveFocus()

    Column {
      anchors.centerIn: parent
      width: 440
      spacing: 14

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "This lock screen design could not be loaded"
        color: "#e6e6e6"
        font.pixelSize: 18
      }

      Rectangle {
        width: parent.width
        height: 52
        radius: 8
        color: "#22252b"
        border.width: 1
        border.color: host.failureMessage.length > 0 ? "#c96a6a" : "#5a606a"

        TextInput {
          id: emergencyInput
          property bool pulling: false
          anchors.fill: parent
          anchors.margins: 14
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          passwordCharacter: "●"
          color: "#f0f0f0"
          font.pixelSize: 18
          enabled: host.inputEnabled && !host.authenticatingPassword
          onTextChanged: if (!pulling) host.passwordTextEdited(text)
          onAccepted: {
            var typed = text
            host.passwordTextEdited("")
            if (typed.length > 0) host.submitPassword(typed)
          }
        }
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        text: host.failureMessage.length > 0 ? host.failureMessage
          : (host.authenticatingPassword ? "Checking…"
          : "Type your password and press Enter." + (host.loadError.length > 0 ? "\n\n" + host.loadError : ""))
        color: host.failureMessage.length > 0 ? "#c96a6a" : "#8a9099"
        font.pixelSize: 12
      }
    }

    Connections {
      target: host
      function onPasswordTextChanged() {
        if (emergencyInput.text === host.passwordText) return
        emergencyInput.pulling = true
        emergencyInput.text = host.passwordText
        emergencyInput.pulling = false
      }
    }
  }
}

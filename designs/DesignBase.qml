import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Root item every lock design derives from. The host (LockHost.qml) binds the
// authentication state onto these properties and listens to the signals; a
// design only draws itself, places a PasswordField or LockInput, and points
// `inputItem` at that input so keyboard focus lands in the right place.
//
// The property and signal names are the contract between a design and its
// host; a design written against this file needs nothing else.
Item {
  id: base

  // State pushed down by the host.
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

  // A user-picked video wallpaper, when the host offers one. videoPlaying
  // drops to false while the display is blanked so no decoder keeps working
  // behind a dark panel; designs with their own clips honour it too.
  property string videoPath: ""
  property bool videoPlaying: true

  // For designs whose unlock is a clip that plays through before the screen
  // is handed back. This host never raises it, the property exists so such
  // designs still load.
  property bool unlockPlayback: false
  property real clipSpeed: 1
  property bool twelveHour: false
  // Family the theme-following originals use for clocks and captions. Set
  // from the picker's Font dropdown; defaults to the theme's font.
  property string displayFont: Style.font.family

  // Some hosts render a design to a still image for boot splashes and want
  // the input chrome hidden (snapshotMode) or gone entirely (snapshotBare).
  property bool snapshotMode: false
  property bool snapshotBare: false

  // Raised by the input and relayed to the host.
  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()
  signal faceRequested()
  signal fido2Requested()
  signal passwordRequested()
  signal submitFido2Pin(string pin)
  signal unlockFinished()

  // What a design tells the base about itself.
  property Item inputItem: null
  property bool shakeOnFail: false
  property bool flashOnFail: true
  property bool showPasswordToggle: true
  property bool passwordVisible: false

  readonly property bool errorState: failureMessage.length > 0
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user"
  readonly property string userInitial: userName.length > 0 ? userName.charAt(0).toUpperCase() : "?"
  readonly property bool hasAvatar: avatarPath.length > 0
  readonly property string avatarUrl: hasAvatar ? fileUrl(avatarPath, avatarVersion) : ""
  readonly property bool hasVideo: videoPath.length > 0
  readonly property string videoUrl: hasVideo ? fileUrl(videoPath, -1) : ""

  property string hostName: Quickshell.env("HOSTNAME") || Quickshell.env("HOST") || "omarchy"
  FileView {
    path: "/etc/hostname"
    printErrors: false
    onLoaded: {
      var name = String(text() || "").trim()
      if (name.length > 0) base.hostName = name
    }
  }

  // One tick a second shared by every clock in the design, so they all
  // advance on the same frame.
  property date now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: base.now = new Date()
  }

  readonly property string meridiem: twelveHour ? Qt.formatDateTime(now, "AP") : ""

  // Formats `now` with an ordinary 24-hour Qt format string. With the 12-hour
  // setting on, the hour tokens are swapped for the 12-hour value and an AM/PM
  // marker is appended to any format that also shows minutes or seconds. A
  // lone hour (flip tiles, poster numerals) just counts 1 to 12.
  function clock(spec) {
    var s = String(spec)
    if (!twelveHour || s.indexOf("H") === -1) return Qt.formatDateTime(now, s)
    var hour = now.getHours() % 12
    if (hour === 0) hour = 12
    var padded = hour < 10 ? "0" + hour : String(hour)
    var out = s.replace(/HH/g, padded).replace(/H/g, String(hour))
    if (/[ms]/.test(s) && !/AP|ap/.test(out)) out += " AP"
    return Qt.formatDateTime(now, out)
  }

  function greeting() {
    var h = now.getHours()
    if (h < 5) return "Good night"
    if (h < 12) return "Good morning"
    if (h < 18) return "Good afternoon"
    return "Good evening"
  }

  // file:// URL for a local path. The version rides along as a query string
  // so an Image reloads when the file behind an unchanged path is swapped;
  // pass -1 for none. Defaults to the background version.
  function fileUrl(path, version) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    var v = version === undefined ? backgroundVersion : version
    return "file://" + encoded + (v >= 0 ? "?v=" + v : "")
  }

  function withAlpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  // Theme-aware shading for designs that build depth from the theme colors.
  // Panels and backdrops need to move away from the text color: darker on a
  // dark theme, lighter on a light one. deepen() does that; raise() goes the
  // other way, toward the foreground, for highlights that must stay visible.
  readonly property bool lightTheme: (0.2126 * Color.background.r + 0.7152 * Color.background.g + 0.0722 * Color.background.b) > 0.5
  function deepen(c, factor) { return lightTheme ? Qt.lighter(c, factor) : Qt.darker(c, factor) }
  function raise(c, factor) { return lightTheme ? Qt.darker(c, factor) : Qt.lighter(c, factor) }

  // The reveal toggle belongs to the password. A security-key PIN shares the
  // field, so it refuses while a key is active and a reveal left on from
  // before is dropped when key mode takes over.
  function togglePasswordVisible() {
    if (!fido2Active) passwordVisible = !passwordVisible
  }
  onFido2ActiveChanged: if (fido2Active) passwordVisible = false
  onPasswordTextChanged: if (passwordText.length === 0) passwordVisible = false

  function forcePasswordFocus() {
    if (inputEnabled && inputItem) inputItem.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  onInputEnabledChanged: if (inputEnabled) Qt.callLater(forcePasswordFocus)
  onFido2NeedsPinChanged: if (fido2NeedsPin && inputEnabled) Qt.callLater(forcePasswordFocus)
  Component.onCompleted: if (inputEnabled) Qt.callLater(forcePasswordFocus)

  // Item focus can be lost without the surface losing keyboard focus (a
  // suspend/resume cycle does it). Take it back whenever the input drops it
  // while the lock is live, or the keyboard goes dead until the user clicks.
  Connections {
    target: base.inputItem
    ignoreUnknownSignals: true
    function onActiveFocusChanged() {
      if (base.inputEnabled && base.inputItem && !base.inputItem.activeFocus) Qt.callLater(base.forcePasswordFocus)
    }
  }

  // Failure feedback: a brief red wash over the whole design and, when the
  // design asks for it, a sideways shake of everything.
  transform: Translate { id: nudge }
  SequentialAnimation {
    id: shake
    NumberAnimation { target: nudge; property: "x"; from: 0; to: -12; duration: 45 }
    NumberAnimation { target: nudge; property: "x"; from: -12; to: 10; duration: 65 }
    NumberAnimation { target: nudge; property: "x"; from: 10; to: -6; duration: 55 }
    NumberAnimation { target: nudge; property: "x"; from: -6; to: 3; duration: 45 }
    NumberAnimation { target: nudge; property: "x"; from: 3; to: 0; duration: 40 }
  }
  Rectangle {
    id: flash
    anchors.fill: parent
    z: 1000
    color: Color.lock.textError
    opacity: 0
    visible: opacity > 0
  }
  SequentialAnimation {
    id: flashAnim
    NumberAnimation { target: flash; property: "opacity"; from: 0; to: 0.2; duration: 70 }
    NumberAnimation { target: flash; property: "opacity"; from: 0.2; to: 0; duration: 400; easing.type: Easing.OutCubic }
  }
  onFailureMessageChanged: {
    if (failureMessage.length === 0) return
    passwordVisible = false
    if (flashOnFail) flashAnim.restart()
    if (shakeOnFail) shake.restart()
  }
}

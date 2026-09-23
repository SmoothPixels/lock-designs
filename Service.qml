import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import "Bridge.js" as Bridge

// Lock Designs: the lock screen itself. A clone of Omarchy's omarchy.lock, so
// the session lock, the PAM password and fingerprint flows and display
// blanking are the stock ones. What changes is that the lock surface shows
// one of the designs in ~/.config/omarchy/lock-designs instead of a fixed
// view, and this service also owns the design list, the saved selection, the
// preview window, and the verified on-demand asset downloads that
// Picker.qml drives.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: ""

  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "io.github.smoothpixels.lock-designs"
  readonly property string home: Quickshell.env("HOME")
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
  readonly property string pluginDir: decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, ""))

  // Everything a design needs lives in one folder: the design files, the
  // base components they build on, previews, the asset catalog, downloaded
  // assets and this plugin's settings. Users drop their own designs in too.
  readonly property string designsDir: home + "/.config/omarchy/lock-designs"
  readonly property string previewsDir: designsDir + "/thirdparty-previews"
  readonly property string settingsPath: designsDir + "/settings.json"
  readonly property string catalogPath: designsDir + "/thirdparty-assets.json"
  readonly property string fallbackDesignPath: designsDir + "/Classic.qml"
  readonly property string defaultDesignId: "my-classic"
  readonly property string currentBackgroundLink: home + "/.local/state/omarchy/current/background"
  // Name of the active Omarchy theme, shown in the picker header. Omarchy
  // writes it lower-case with dashes; shown as words.
  readonly property string themeNamePath: home + "/.local/state/omarchy/current/theme.name"
  property string themeName: ""
  function titleCase(s) {
    return String(s).split(/[-_ ]+/).filter(function(w) { return w.length > 0 })
      .map(function(w) { return w.charAt(0).toUpperCase() + w.slice(1) }).join(" ")
  }
  FileView {
    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onLoaded: root.themeName = root.titleCase(String(text() || "").trim())
    onFileChanged: reload()
  }

  // ---------------------------------------------------------------------
  // Lock state. Same shape as omarchy.lock so the behaviour users know
  // (stranded-lock recovery, blanking, fingerprint retry) is unchanged.
  // ---------------------------------------------------------------------
  property bool lockRequested: false
  property bool pendingSessionLock: false
  property bool authenticatingPassword: false
  property bool fingerprintAuthenticating: false
  property bool passwordPamConfigured: false
  property bool fingerprintConfigured: false
  property bool previewVisible: false
  property bool displayBlanked: false
  property string enteredPassword: ""
  property string pendingPassword: ""
  property string failureMessage: ""
  property int failedAttempts: 0
  property string backgroundPath: ""
  property int backgroundVersion: 0
  property string lastEvent: "init"
  property string lastEventAt: ""
  property bool strandedLock: false
  property bool strandedLockResolved: false

  readonly property bool locked: lockRequested || sessionLock.locked || sessionLock.secure
  readonly property bool authenticating: authenticatingPassword || fingerprintAuthenticating

  function realScreenCount() {
    var screens = Quickshell.screens || []
    var count = 0
    for (var i = 0; i < screens.length; i++) {
      var screen = screens[i]
      if (screen && screen.name && screen.width > 0 && screen.height > 0) count += 1
    }
    return count
  }

  function hasRealScreen() { return realScreenCount() > 0 }

  function queueSessionLock() {
    pendingSessionLock = true
    if (!sessionLockStabilizeTimer.running) logEvent("lock-pending: screen-stabilizing")
    sessionLockStabilizeTimer.restart()
    if (!pendingSessionLockTimer.running) pendingSessionLockTimer.start()
  }

  function requestSessionLock() {
    if (!lockRequested || sessionLock.locked || sessionLock.secure) return
    if (sessionLockStabilizeTimer.running) return
    if (!hasRealScreen()) {
      if (!pendingSessionLock || lastEvent !== "lock-pending: no-real-screen") logEvent("lock-pending: no-real-screen")
      pendingSessionLock = true
      if (!pendingSessionLockTimer.running) pendingSessionLockTimer.start()
      return
    }
    pendingSessionLock = false
    pendingSessionLockTimer.stop()
    sessionLock.locked = true
  }

  // ext-session-lock outlives its client and a shell restart carries no lock
  // over, so a session found locked this early is an orphan behind Hyprland's
  // failsafe. Outputs are often still absent here, so ask until the answer
  // means something.
  function checkStrandedLock() {
    if (strandedLockResolved || strandedLockCheckProc.running) return
    if (locked || lockRequested) { strandedLockResolved = true; return }
    strandedLockCheckProc.running = true
  }

  function recoverStrandedLock() {
    if (!strandedLock || locked || !passwordPamConfigured) return
    strandedLock = false
    logEvent("lock-stranded: recovering")
    beginLock()
  }

  function refreshBackground() { if (!readlinkProc.running) readlinkProc.running = true }
  function refreshFingerprintStatus() { if (!fingerprintCheckProc.running) fingerprintCheckProc.running = true }

  function logEvent(event) {
    lastEvent = event
    lastEventAt = new Date().toISOString()
    console.log("lock-designs " + lastEventAt + " " + event)
  }

  function resetAuthenticationState() {
    enteredPassword = ""
    pendingPassword = ""
    failureMessage = ""
    failedAttempts = 0
    authenticatingPassword = false
    fingerprintAuthenticating = false
    fingerprintRetryTimer.stop()
    if (passwordPam.active) passwordPam.abort()
    if (fingerprintPam.active) fingerprintPam.abort()
  }

  function beginLock() {
    if (!passwordPamConfigured) { logEvent("lock-denied: missing-pam"); return false }
    resetAuthenticationState()
    lockRequested = true
    displayBlanked = false
    armBlankTimer()
    logEvent("lock-requested")
    queueSessionLock()
    Qt.callLater(function() {
      root.refreshBackground()
      root.refreshFingerprintStatus()
    })
    return true
  }

  function finishUnlock() {
    if (!root.locked && !lockRequested) return
    lockRequested = false
    pendingSessionLock = false
    sessionLockStabilizeTimer.stop()
    pendingSessionLockTimer.stop()
    resetAuthenticationState()
    idleBlankTimer.stop()
    sessionLock.locked = false
    logEvent("unlocked")
    runWake()
  }

  function armBlankTimer() {
    idleBlankTimer.armedAt = Date.now()
    idleBlankTimer.restart()
  }

  function runWake() {
    displayBlanked = false
    if (!wakeProcess.running) wakeProcess.running = true
    if (lockRequested) armBlankTimer()
  }

  function runBlank() {
    displayBlanked = true
    if (!blankProcess.running) blankProcess.running = true
  }

  function submitPassword(value) {
    var password = String(value || "")
    if (!lockRequested || authenticatingPassword || password.length === 0) return
    runWake()
    pendingPassword = password
    failureMessage = ""
    authenticatingPassword = true
    if (!passwordPam.start()) { handlePasswordFailure(); return }
    Qt.callLater(respondToPasswordPrompt)
  }

  function respondToPasswordPrompt() {
    if (!authenticatingPassword || !passwordPam.active || !passwordPam.responseRequired) return
    passwordPam.respond(pendingPassword)
  }

  function handlePasswordFailure() {
    if (!lockRequested) return
    authenticatingPassword = false
    enteredPassword = ""
    pendingPassword = ""
    failedAttempts += 1
    failureMessage = "Authentication failed (" + failedAttempts + ")"
    runWake()
  }

  function startFingerprint() {
    if (!lockRequested || !sessionLock.secure || !fingerprintConfigured) return
    if (fingerprintPam.active || fingerprintAuthenticating) return
    fingerprintAuthenticating = true
    if (!fingerprintPam.start()) fingerprintAuthenticating = false
  }

  function handleFingerprintFinished(result) {
    fingerprintAuthenticating = false
    if (!lockRequested) return
    if (result === PamResult.Success) finishUnlock()
    else if (fingerprintConfigured) fingerprintRetryTimer.restart()
  }

  // ---------------------------------------------------------------------
  // Designs: shipped ones are synced into designsDir on load, then the folder
  // is scanned so user-added files show up alongside them.
  // ---------------------------------------------------------------------
  property var designs: []
  property int designsRevision: 0
  property bool synced: false

  function designById(id) {
    var key = String(id || "")
    if (key.length === 0) return null
    for (var i = 0; i < designs.length; i++) if (designs[i].id === key) return designs[i]
    return null
  }

  function rescanDesigns() {
    if (!scanProc.running) scanProc.running = true
  }

  // A design that fetches assets is only usable once every file is on disk;
  // otherwise it would render with a missing video or font.
  function designUsable(d) {
    if (!d) return false
    if (!catalog[d.id]) return true
    return installedAssets[d.id] === true
  }

  // ---------------------------------------------------------------------
  // Settings: a small JSON file next to the designs. The first run adopts a
  // design a previously installed lock plugin had saved in shell.json, if
  // there is one, so switching over keeps the lock screen the user picked.
  // ---------------------------------------------------------------------
  property var settings: ({})
  property bool settingsLoaded: false
  property string legacyDesignId: ""
  readonly property string selectedDesignId: settings && settings.design ? String(settings.design) : legacyDesignId
  readonly property bool twelveHour: settings && settings.twelveHour === true
  // Empty means "follow the theme font".
  readonly property string fontSetting: settings && settings.font ? String(settings.font) : ""
  readonly property string displayFont: fontSetting.length > 0 ? fontSetting : Style.font.family
  readonly property var activeDesign: {
    var d = designById(selectedDesignId)
    if (!designUsable(d)) d = designById(defaultDesignId)
    return d
  }
  readonly property string activeDesignId: activeDesign ? activeDesign.id : ""
  readonly property string activeDesignPath: activeDesign ? activeDesign.path : fallbackDesignPath

  // Runs after each of the three async loads (sync, settings, shell.json);
  // whichever lands last completes the adoption.
  function adoptLegacyDesign() {
    if (!synced || !settingsLoaded || legacyDesignId.length === 0) return
    if (settings && settings.design) return
    if (!designById(legacyDesignId)) return
    saveSettings({ design: legacyDesignId })
    logEvent("adopted-design: " + legacyDesignId)
  }

  function saveSettings(patch) {
    var next = {}
    for (var k in settings) next[k] = settings[k]
    for (var p in patch) next[p] = patch[p]
    settings = next
    if (!synced) return
    settingsFile.setText(JSON.stringify(next, null, 2) + "\n")
  }

  function setDesign(id) {
    var d = designById(id)
    if (!d) return "unknown-design"
    if (!designUsable(d)) return "assets-missing"
    saveSettings({ design: d.id })
    return "ok"
  }

  function setTwelveHour(on) {
    saveSettings({ twelveHour: on === true })
  }

  function setDisplayFont(family) {
    saveSettings({ font: String(family || "") })
  }

  // ---------------------------------------------------------------------
  // Asset catalog and verified downloads.
  // ---------------------------------------------------------------------
  property var catalog: ({})
  property var installedAssets: ({})
  // id -> { phase: queued|downloading|verifying|failed, fileIndex, fileCount,
  //         bytes, doneBytes, totalBytes, error }
  property var downloads: ({})
  property var downloadQueue: []

  function scanInstalled() {
    if (!installedScanProc.running) installedScanProc.running = true
  }

  function patchDownload(id, patch) {
    var current = downloads[id] || {}
    var next = {}
    for (var k in current) next[k] = current[k]
    for (var p in patch) next[p] = patch[p]
    var copy = {}
    for (var c in downloads) copy[c] = downloads[c]
    copy[id] = next
    downloads = copy
  }

  function clearDownload(id) {
    var copy = {}
    for (var c in downloads) if (c !== id) copy[c] = downloads[c]
    downloads = copy
  }

  // Catalog paths are relative and stay inside designsDir, whatever a hand-
  // edited catalog says.
  function safeRelativePath(p) {
    var s = String(p || "")
    return s.length > 0 && s.indexOf("..") === -1 && s.charAt(0) !== "/" && s.indexOf("\\") === -1
  }

  function safeAssetsDir(d) {
    return /^[a-z0-9][a-z0-9._-]*-assets$/.test(String(d || ""))
  }

  function downloadAssets(id) {
    var entry = catalog[id]
    if (!entry || !Array.isArray(entry.files) || entry.files.length === 0) return "no-catalog-entry"
    if (installedAssets[id] === true) return "installed"
    var state = downloads[id]
    if (state && state.phase !== "failed") return "busy"
    if (!safeAssetsDir(entry.assetsDir)) {
      patchDownload(id, { phase: "failed", error: "Refusing the catalog's asset folder name: " + entry.assetsDir })
      return "bad-catalog"
    }
    var total = 0
    for (var i = 0; i < entry.files.length; i++) {
      var f = entry.files[i]
      if (!safeRelativePath(f.path) || !f.url) {
        patchDownload(id, { phase: "failed", error: "Refusing a malformed catalog entry for " + id })
        return "bad-catalog"
      }
      // No digest, no download: this is the whole point of the catalog.
      if (!/^[0-9a-fA-F]{64}$/.test(String(f.sha256 || ""))) {
        patchDownload(id, { phase: "failed", error: "The catalog has no SHA-256 digest for " + f.path + ", refusing to download it." })
        return "unpinned"
      }
      total += Number(f.size) > 0 ? Number(f.size) : 0
    }
    patchDownload(id, { phase: "queued", fileIndex: 0, fileCount: entry.files.length, bytes: 0, doneBytes: 0, totalBytes: total, error: "" })
    downloadQueue.push(id)
    pumpDownloads()
    return "ok"
  }

  function cancelDownload(id) {
    var i = downloadQueue.indexOf(id)
    if (i !== -1) downloadQueue.splice(i, 1)
    if (fetchProc.running && fetchProc.currentId === id) {
      fetchProc.cancelled = true
      fetchProc.running = false
    }
    clearDownload(id)
  }

  // One file at a time across the whole queue. Each file is fetched to a
  // .part file, hashed, and only moved into place when the digest matches;
  // mirrors listed in the catalog are tried in order.
  function pumpDownloads() {
    if (fetchProc.running || downloadQueue.length === 0) return
    var id = downloadQueue[0]
    var entry = catalog[id]
    var state = downloads[id]
    if (!entry || !state || state.phase === "failed") { downloadQueue.shift(); pumpDownloads(); return }
    if (state.fileIndex >= entry.files.length) {
      downloadQueue.shift()
      clearDownload(id)
      scanInstalled()
      logEvent("assets-installed: " + id)
      pumpDownloads()
      return
    }
    var f = entry.files[state.fileIndex]
    var dest = designsDir + "/" + entry.assetsDir + "/" + f.path
    var urls = [String(f.url)]
    if (Array.isArray(f.mirrors)) for (var m = 0; m < f.mirrors.length; m++) urls.push(String(f.mirrors[m]))
    patchDownload(id, { phase: "downloading", bytes: 0 })
    fetchProc.currentId = id
    fetchProc.cancelled = false
    fetchProc.lastError = ""
    fetchProc.command = ["bash", "-c", root.fetchScript, "lock-designs-fetch", dest, String(f.sha256).toLowerCase()].concat(urls)
    fetchProc.running = true
  }

  readonly property string fetchScript: '
    dest="$1"; want="$2"; shift 2
    part="$dest.part"
    mkdir -p "$(dirname "$dest")" || { echo "FAIL:cannot create $(dirname "$dest")"; exit 1; }
    for url in "$@"; do
      rm -f "$part"
      echo "SOURCE:$url"
      curl -fsSL --retry 2 --retry-delay 1 --connect-timeout 20 --max-time 7200 -o "$part" "$url" &
      cpid=$!
      while kill -0 "$cpid" 2>/dev/null; do
        sz=$(stat -c%s "$part" 2>/dev/null || echo 0)
        echo "BYTES:$sz"
        sleep 0.25
      done
      if ! wait "$cpid" || [ ! -f "$part" ]; then echo "FAIL:download failed from $url"; continue; fi
      echo "VERIFY"
      got=$(sha256sum "$part" | cut -d" " -f1)
      if [ "$got" = "$want" ]; then mv -f "$part" "$dest"; echo "OK"; exit 0; fi
      echo "FAIL:digest mismatch from $url"
      rm -f "$part"
    done
    rm -f "$part"
    exit 1
  '

  function removeAssets(id) {
    var entry = catalog[id]
    if (!entry || !safeAssetsDir(entry.assetsDir)) return "no-catalog-entry"
    if (downloads[id] && downloads[id].phase !== "failed") return "busy"
    removeAssetsProc.command = ["rm", "-rf", "--", designsDir + "/" + entry.assetsDir]
    removeAssetsProc.running = true
    return "ok"
  }

  function designAssetsDir(d) {
    if (!d) return ""
    if (d.assetsDir && d.assetsDir.length > 0) return d.assetsDir
    return catalog[d.id] ? String(catalog[d.id].assetsDir || "") : ""
  }

  onActiveDesignIdChanged: prefetchTimer.restart()

  // ---------------------------------------------------------------------
  // Preview: the design full screen on a layer above everything, without
  // locking. Enter adopts the previewed design, Esc or a click closes.
  // ---------------------------------------------------------------------
  property string previewDesignId: ""
  readonly property var previewDesign: designById(previewDesignId) || activeDesign

  property var previewScreen: null

  // The screen Hyprland says has focus, so the window opens where the user
  // is looking on a multi-monitor desk; falls back to the first screen.
  function focusedScreen() {
    var name = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) if (screens[i].name === name) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }

  // Optional screen name (as `hyprctl monitors` lists them) puts the preview
  // on that output instead of the focused one.
  // The hint pill in the preview fades a few seconds after the last key or
  // wheel step, so a design can be looked at (or captured) without it.
  property bool previewHintShown: true
  Timer {
    interval: 4000
    running: root.previewVisible && root.previewHintShown
    onTriggered: root.previewHintShown = false
  }

  function showPreview(id, screenName) {
    previewHintShown = true
    var wanted = String(screenName || "")
    var chosen = null
    if (wanted.length > 0) {
      var screens = Quickshell.screens || []
      for (var i = 0; i < screens.length; i++) if (screens[i].name === wanted) chosen = screens[i]
    }
    previewScreen = chosen || focusedScreen()
    previewDesignId = String(id || "")
    refreshBackground()
    refreshFingerprintStatus()
    previewVisible = true
  }

  // Designs worth browsing full screen: every one whose assets are present.
  readonly property var browsable: designs.filter(function(d) { return root.designUsable(d) })

  // Arrow keys and the wheel step through them while the preview is up.
  function previewStep(delta) {
    var list = browsable
    if (list.length === 0) return
    var currentId = previewDesign ? previewDesign.id : activeDesignId
    var index = -1
    for (var i = 0; i < list.length; i++) if (list[i].id === currentId) { index = i; break }
    index = index < 0 ? 0 : (index + delta + list.length) % list.length
    previewDesignId = list[index].id
  }

  function hidePreview() { previewVisible = false }

  // ---------------------------------------------------------------------
  // Windows
  // ---------------------------------------------------------------------
  WlSessionLock {
    id: sessionLock
    locked: false

    onSecureStateChanged: {
      root.logEvent("secure=" + secure)
      if (secure) {
        root.pendingSessionLock = false
        sessionLockStabilizeTimer.stop()
        pendingSessionLockTimer.stop()
        root.startFingerprint()
      }
    }

    onLockStateChanged: {
      root.logEvent("session-locked=" + locked)
      if (locked) {
        root.pendingSessionLock = false
        sessionLockStabilizeTimer.stop()
        pendingSessionLockTimer.stop()
      }
      if (!locked && root.lockRequested) {
        root.lockRequested = false
        root.pendingSessionLock = false
        sessionLockStabilizeTimer.stop()
        pendingSessionLockTimer.stop()
        root.resetAuthenticationState()
        root.runWake()
      }
    }

    WlSessionLockSurface {
      color: Color.background

      LockHost {
        anchors.fill: parent
        designPath: root.activeDesignPath
        fallbackPath: root.fallbackDesignPath
        backgroundPath: root.backgroundPath
        backgroundVersion: root.backgroundVersion
        fingerprintConfigured: root.fingerprintConfigured
        authenticatingPassword: root.authenticatingPassword
        failureMessage: root.failureMessage
        failedAttempts: root.failedAttempts
        inputEnabled: root.lockRequested
        loadBackground: root.locked
        passwordText: root.enteredPassword
        videoPlaying: !root.displayBlanked
        twelveHour: root.twelveHour
        displayFont: root.displayFont
        onPasswordTextEdited: function(password) { root.enteredPassword = password }
        onSubmitPassword: function(password) { root.submitPassword(password) }
        onClearFailureRequested: root.failureMessage = ""
        onWakeRequested: root.runWake()
      }
    }
  }

  PanelWindow {
    id: previewWindow
    screen: root.previewScreen
    visible: root.previewVisible
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-lock-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Only instantiated while showing, so no design (or its video) lives in
    // memory between previews.
    Loader {
      anchors.fill: parent
      active: root.previewVisible
      sourceComponent: LockHost {
        designPath: root.previewDesign ? root.previewDesign.path : root.fallbackDesignPath
        fallbackPath: root.fallbackDesignPath
        backgroundPath: root.backgroundPath
        backgroundVersion: root.backgroundVersion
        fingerprintConfigured: root.fingerprintConfigured
        inputEnabled: false
        loadBackground: true
        videoPlaying: root.previewVisible
        twelveHour: root.twelveHour
        displayFont: root.displayFont
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: root.previewVisible = false
    }

    Item {
      id: previewKeys
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(event) {
        root.previewHintShown = true
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
          root.previewVisible = false
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (root.previewDesign) root.setDesign(root.previewDesign.id)
          root.previewVisible = false
          event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_PageUp || event.key === Qt.Key_Backspace) {
          root.previewStep(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_PageDown || event.key === Qt.Key_Space || event.key === Qt.Key_Tab) {
          root.previewStep(1)
          event.accepted = true
        }
      }

      // Wheel in any direction browses too. Touchpads send many small
      // deltas, so they are summed and a step is taken per notch's worth.
      property real wheelAccum: 0
      WheelHandler {
        onWheel: function(event) {
          root.previewHintShown = true
          var d = event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x
          previewKeys.wheelAccum += d
          if (Math.abs(previewKeys.wheelAccum) >= 100) {
            root.previewStep(previewKeys.wheelAccum < 0 ? 1 : -1)
            previewKeys.wheelAccum = 0
          }
        }
      }
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(28)
      width: hint.implicitWidth + Style.space(28)
      height: hint.implicitHeight + Style.space(14)
      radius: height / 2
      color: Qt.rgba(0, 0, 0, 0.55)
      opacity: root.previewHintShown ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 350 } }
      Text {
        id: hint
        anchors.centerIn: parent
        text: (root.previewDesign ? root.previewDesign.name : "Preview")
          + (root.previewDesign && root.previewDesign.id === root.activeDesignId ? "  ·  in use" : "  ·  Enter to use it")
          + "  ·  ← → to browse  ·  Esc to close"
        color: "#f2f2f2"
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }
    }

    onVisibleChanged: if (visible) Qt.callLater(function() { previewKeys.forceActiveFocus() })
  }

  // ---------------------------------------------------------------------
  // PAM
  // ---------------------------------------------------------------------
  PamContext {
    id: passwordPam
    config: "omarchy-lock-password"
    user: root.userName
    onResponseRequiredChanged: root.respondToPasswordPrompt()
    onPamMessage: root.respondToPasswordPrompt()
    onCompleted: function(result) {
      root.authenticatingPassword = false
      root.pendingPassword = ""
      if (!root.lockRequested) return
      if (result === PamResult.Success) root.finishUnlock()
      else root.handlePasswordFailure()
    }
    onError: function(error) { root.handlePasswordFailure() }
  }

  PamContext {
    id: fingerprintPam
    config: "omarchy-lock-fingerprint"
    user: root.userName
    onCompleted: function(result) { root.handleFingerprintFinished(result) }
    onError: function(error) {
      root.fingerprintAuthenticating = false
      if (root.lockRequested && root.fingerprintConfigured) fingerprintRetryTimer.restart()
    }
  }

  Timer {
    id: fingerprintRetryTimer
    interval: 250
    repeat: false
    onTriggered: root.startFingerprint()
  }

  // ---------------------------------------------------------------------
  // Processes
  // ---------------------------------------------------------------------
  Process {
    id: readlinkProc
    command: ["readlink", "-f", root.currentBackgroundLink]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = String(text || "").trim()
        var changed = next !== root.backgroundPath
        if (changed) {
          root.backgroundPath = next
          root.backgroundVersion += 1
        }
      }
    }
  }

  Process {
    id: fingerprintCheckProc
    command: ["bash", "-c", "if [[ -f /etc/pam.d/omarchy-lock-fingerprint ]] && command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$USER\" 2>/dev/null | grep -qi finger; then echo yes; else echo no; fi"]
    stdout: StdioCollector { id: fingerprintCheckStdout; waitForEnd: true }
    onExited: {
      root.fingerprintConfigured = String(fingerprintCheckStdout.text || "").trim() === "yes"
      if (root.lockRequested && root.fingerprintConfigured) root.startFingerprint()
      else if (!root.fingerprintConfigured && fingerprintPam.active) fingerprintPam.abort()
    }
  }

  Process {
    id: strandedLockCheckProc
    command: ["bash", "-c", "omarchy-hyprland-session-locked"]
    onExited: function(exitCode) {
      // No output to read the lock off yet.
      if (exitCode === 2) return
      root.strandedLockResolved = true
      root.strandedLock = exitCode === 0 && !root.locked && !root.lockRequested
      root.recoverStrandedLock()
    }
  }

  Process {
    id: wakeProcess
    command: ["bash", "-c", "omarchy-system-wake"]
  }

  Process {
    id: blankProcess
    command: ["bash", "-c", "omarchy-brightness-keyboard off; omarchy-brightness-display off"]
  }

  // Shipped designs, base components, previews and the catalog are mirrored
  // into designsDir. rsync only touches what changed, so a shell restart is
  // cheap; nothing else in that folder is deleted.
  Process {
    id: syncProc
    command: ["bash", "-c", "set -e; mkdir -p \"$1\"; rsync -a --exclude settings.json \"$0/designs/\" \"$1/\"", root.pluginDir, root.designsDir]
    stderr: StdioCollector { onStreamFinished: if (text) console.warn("lock-designs sync:", String(text).trim()) }
    onExited: function(exitCode) {
      root.synced = true
      if (exitCode !== 0) console.warn("lock-designs: syncing designs into " + root.designsDir + " failed (" + exitCode + ")")
      root.rescanDesigns()
      catalogFile.reload()
      settingsFile.reload()
      Qt.callLater(root.adoptLegacyDesign)
    }
  }

  // Every *.qml in designsDir whose root is a DesignBase is a design. Marker
  // comments in the first lines describe it: `// source: qylock` puts it in
  // the third-party group, `// timebased: true` flags it, `// name:` and
  // `// description:` override the name derived from the file name.
  Process {
    id: scanProc
    command: ["bash", "-c", root.scanScript, "lock-designs-scan", root.designsDir, root.pluginDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n").filter(function(l) { return l.length > 0 })
        var list = lines.map(function(line) {
          var p = line.split("\t")
          var file = p[0]
          var stem = file.replace(/\.qml$/, "")
          var id = "my-" + stem.toLowerCase().replace(/[^a-z0-9]+/g, "-")
          var derived = stem.replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/[-_]+/g, " ")
          var source = p[1] || ""
          return {
            id: id,
            file: file,
            path: root.designsDir + "/" + file,
            name: p[3] && p[3].length > 0 ? p[3] : derived,
            description: p[4] || "",
            source: source,
            thirdParty: source.length > 0,
            timeBased: (p[2] || "").length > 0 && p[2] !== "false",
            video: p[5] === "1",
            hasPreview: p[6] === "1",
            shipped: p[7] === "1",
            assetsDir: p[8] || ""
          }
        })
        // Classic, then the shipped originals, then the user's own files,
        // then the third-party ports; alphabetical inside each group.
        function rank(d) {
          if (d.id === root.defaultDesignId) return 0
          if (d.thirdParty) return 3
          return d.shipped ? 1 : 2
        }
        list.sort(function(a, b) {
          var ra = rank(a), rb = rank(b)
          if (ra !== rb) return ra - rb
          return a.name.localeCompare(b.name)
        })
        var before = JSON.stringify(root.designs)
        root.designs = list
        if (JSON.stringify(list) !== before) root.designsRevision += 1
        root.scanInstalled()
        Qt.callLater(root.adoptLegacyDesign)
      }
    }
  }

  readonly property string scanScript: '
    cd "$1" 2>/dev/null || exit 0
    shopt -s nullglob
    for f in *.qml; do
      grep -q "^DesignBase {" "$f" || continue
      head=$(head -n 16 "$f")
      src=$(printf "%s\\n" "$head" | sed -n "s#^// source: *##p" | head -1)
      tb=$(printf "%s\\n" "$head" | sed -n "s#^// timebased: *##p" | head -1)
      nm=$(printf "%s\\n" "$head" | sed -n "s#^// name: *##p" | head -1)
      ds=$(printf "%s\\n" "$head" | sed -n "s#^// description: *##p" | head -1)
      if grep -q -E "MediaPlayer|VideoOutput" "$f"; then vid=1; else vid=0; fi
      stem="${f%.qml}"
      id="my-$(printf "%s" "$stem" | tr "[:upper:]" "[:lower:]" | sed -E "s/[^a-z0-9]+/-/g")"
      if [ -f "thirdparty-previews/$id.jpg" ]; then pv=1; else pv=0; fi
      if [ -f "$2/designs/$f" ]; then sh=1; else sh=0; fi
      as=$(grep -o -m1 -E \'resolvedUrl\\("[A-Za-z0-9._-]+-assets/?"\\)\' "$f" | sed -E \'s/.*"([^"]+-assets)\\/?".*/\\1/\')
      printf "%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n" "$f" "$src" "$tb" "$nm" "$ds" "$vid" "$pv" "$sh" "$as"
    done
  '

  // Which catalog designs have every file on disk.
  Process {
    id: installedScanProc
    command: ["bash", "-c", "cd \"$0\" 2>/dev/null || exit 0; find . -path './*-assets/*' -type f -printf '%P\\n'", root.designsDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var present = {}
        String(text || "").split("\n").forEach(function(l) { if (l.length > 0) present[l] = true })
        var installed = {}
        for (var id in root.catalog) {
          var entry = root.catalog[id]
          if (!entry || !Array.isArray(entry.files) || entry.files.length === 0) continue
          var complete = true
          for (var i = 0; i < entry.files.length; i++) {
            if (!present[entry.assetsDir + "/" + entry.files[i].path]) { complete = false; break }
          }
          if (complete) installed[id] = true
        }
        root.installedAssets = installed
      }
    }
  }

  Process {
    id: fetchProc
    property string currentId: ""
    property string lastError: ""
    property bool cancelled: false
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line)
        if (s.indexOf("BYTES:") === 0) root.patchDownload(fetchProc.currentId, { bytes: parseInt(s.substring(6)) || 0 })
        else if (s === "VERIFY") root.patchDownload(fetchProc.currentId, { phase: "verifying" })
        else if (s.indexOf("FAIL:") === 0) fetchProc.lastError = s.substring(5)
      }
    }
    onExited: function(exitCode) {
      var id = fetchProc.currentId
      if (fetchProc.cancelled) {
        fetchProc.cancelled = false
        root.pumpDownloads()
        return
      }
      if (exitCode !== 0) {
        var i = root.downloadQueue.indexOf(id)
        if (i !== -1) root.downloadQueue.splice(i, 1)
        root.patchDownload(id, { phase: "failed", error: fetchProc.lastError || "Download failed" })
        console.warn("lock-designs: assets for " + id + " failed: " + (fetchProc.lastError || "exit " + exitCode))
        root.pumpDownloads()
        return
      }
      var state = root.downloads[id] || {}
      var entry = root.catalog[id]
      var file = entry && entry.files ? entry.files[state.fileIndex || 0] : null
      var size = file && Number(file.size) > 0 ? Number(file.size) : (state.bytes || 0)
      root.patchDownload(id, { fileIndex: (state.fileIndex || 0) + 1, doneBytes: (state.doneBytes || 0) + size, bytes: 0 })
      root.pumpDownloads()
    }
  }

  Process {
    id: removeAssetsProc
    onExited: root.scanInstalled()
  }

  // ---------------------------------------------------------------------
  // Files
  // ---------------------------------------------------------------------
  FileView {
    id: settingsFile
    path: root.settingsPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var parsed = JSON.parse(String(text() || "") || "{}")
        root.settings = parsed && typeof parsed === "object" ? parsed : {}
      } catch (e) {
        console.warn("lock-designs: settings.json is not valid JSON, keeping the last known settings")
      }
      root.settingsLoaded = true
      Qt.callLater(root.adoptLegacyDesign)
    }
    onLoadFailed: {
      root.settingsLoaded = true
      Qt.callLater(root.adoptLegacyDesign)
    }
  }

  FileView {
    id: catalogFile
    path: root.catalogPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.catalog = JSON.parse(String(text() || "") || "{}") } catch (e) { root.catalog = {} }
      root.scanInstalled()
    }
    onLoadFailed: root.catalog = {}
  }

  FileView {
    id: legacySettingsFile
    path: root.home + "/.config/omarchy/shell.json"
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(String(text() || "") || "{}")
        var list = parsed && Array.isArray(parsed.plugins) ? parsed.plugins : []
        for (var i = 0; i < list.length; i++) {
          var entry = list[i]
          if (entry && String(entry.id || "") === "io.github.sirjul1337.lock-explorer" && entry.design) {
            root.legacyDesignId = String(entry.design)
            break
          }
        }
      } catch (e) {}
      Qt.callLater(root.adoptLegacyDesign)
    }
  }

  FileView {
    path: "/etc/pam.d/omarchy-lock-password"
    watchChanges: true
    printErrors: false
    onLoaded: root.passwordPamConfigured = true
    onLoadFailed: root.passwordPamConfigured = false
    onFileChanged: reload()
  }

  // ---------------------------------------------------------------------
  // Timers
  // ---------------------------------------------------------------------
  Timer {
    id: idleBlankTimer
    interval: 5000
    repeat: false
    property double armedAt: 0
    onTriggered: {
      // A countdown frozen by suspend fires right after resume, which would
      // blank the freshly woken unlock screen under the user. Wall-clock time
      // exposes the gap: take a fresh run-up instead of blanking.
      if (Date.now() - armedAt > interval + 2000) { root.armBlankTimer(); return }
      // Only a password check in flight holds the display up; the fingerprint
      // PAM stays armed for the whole lock.
      if (root.lockRequested && !root.authenticatingPassword) root.runBlank()
    }
  }

  Timer {
    id: sessionLockStabilizeTimer
    interval: 500
    repeat: false
    onTriggered: root.requestSessionLock()
  }

  Timer {
    id: pendingSessionLockTimer
    interval: 100
    repeat: true
    onTriggered: root.requestSessionLock()
  }

  Timer {
    id: strandedLockRetryTimer
    interval: 500
    repeat: true
    readonly property int budget: 20
    property int remaining: 20
    running: !root.strandedLockResolved && remaining > 0
    function rearm() { if (!root.strandedLockResolved) remaining = budget }
    onTriggered: {
      remaining -= 1
      root.checkStrandedLock()
    }
  }

  Connections {
    target: Quickshell
    function onScreensChanged() {
      root.requestSessionLock()
      strandedLockRetryTimer.rearm()
      root.checkStrandedLock()
    }
  }

  onAuthenticatingPasswordChanged: {
    if (!lockRequested) return
    if (authenticatingPassword) idleBlankTimer.stop()
    else armBlankTimer()
  }

  // No lock before PAM is known good. An answer from before then may be
  // stale (the failsafe can be cleared from a TTY), so re-ask.
  onPasswordPamConfiguredChanged: {
    if (!passwordPamConfigured) return
    strandedLock = false
    strandedLockResolved = false
    strandedLockRetryTimer.rearm()
    checkStrandedLock()
  }

  // ---------------------------------------------------------------------
  // IPC: `omarchy-shell lock <method>`
  // ---------------------------------------------------------------------
  IpcHandler {
    target: "lock"

    function lock(): string {
      if (!root.passwordPamConfigured) return "missing-pam"
      if (!root.locked && !root.beginLock()) return "failed"
      return "ok"
    }

    function isLocked(): string { return root.locked ? "true" : "false" }

    function status(): string {
      return JSON.stringify({
        locked: root.locked,
        requested: root.lockRequested,
        pending: root.pendingSessionLock,
        sessionLocked: sessionLock.locked,
        secure: sessionLock.secure,
        realScreens: root.realScreenCount(),
        passwordPam: root.passwordPamConfigured,
        fingerprint: root.fingerprintConfigured,
        authenticating: root.authenticating,
        design: root.activeDesignId,
        selectedDesign: root.selectedDesignId,
        designs: root.designs.length,
        lastEvent: root.lastEvent,
        lastEventAt: root.lastEventAt
      })
    }

    function preview(): string { root.showPreview(""); return "ok" }
    function previewDesign(id: string): string {
      if (!root.designById(id)) return "unknown-design"
      root.showPreview(id)
      return "ok"
    }
    function previewDesignOn(id: string, screen: string): string {
      if (!root.designById(id)) return "unknown-design"
      root.showPreview(id, screen)
      return "ok"
    }
    function hidePreview(): string { root.previewVisible = false; return "ok" }
    function previewStep(delta: string): string {
      if (!root.previewVisible) root.showPreview("")
      root.previewStep(parseInt(delta) || 1)
      return root.previewDesign ? root.previewDesign.id : ""
    }

    function design(): string { return root.activeDesignId }
    function designs(): string {
      return JSON.stringify(root.designs.map(function(d) {
        return { id: d.id, name: d.name, file: d.file, ready: root.designUsable(d), source: d.source, assets: root.designAssetsDir(d) }
      }))
    }
    function setDesign(id: string): string { return root.setDesign(id) }
    function rescanDesigns(): string { root.rescanDesigns(); return "ok" }
    function download(id: string): string { return root.downloadAssets(id) }
    function removeAssets(id: string): string { return root.removeAssets(id) }
    function font(): string { return root.displayFont }
    function setFont(family: string): string { root.setDisplayFont(family); return "ok" }
    function setClockFormat(value: string): string {
      root.setTwelveHour(String(value) === "12" || String(value) === "true")
      return "ok"
    }

    // Opens (or closes) the picker. `explore` is the name earlier menu rows
    // used for a lock screen picker, so those rows keep working.
    function explore(): string { root.togglePicker(); return "ok" }
    function picker(): string { root.togglePicker(); return "ok" }
  }

  // The picker is this plugin's overlay entry; the host toggles it by plugin
  // id. Going through the CLI keeps this independent of which functions the
  // host hands a service.
  function togglePicker() {
    if (!pickerToggleProc.running) pickerToggleProc.running = true
  }

  Process {
    id: pickerToggleProc
    command: ["omarchy-shell", "shell", "toggle", root.pluginId, "{}"]
  }

  // ---------------------------------------------------------------------
  // What the picker sees. Bound properties, so its bindings update; no PAM
  // state and never the typed password.
  // ---------------------------------------------------------------------
  QtObject {
    id: facade
    readonly property var designs: root.designs
    readonly property int designsRevision: root.designsRevision
    readonly property string selectedDesignId: root.selectedDesignId
    readonly property string activeDesignId: root.activeDesignId
    readonly property var catalog: root.catalog
    readonly property var installedAssets: root.installedAssets
    readonly property var downloads: root.downloads
    readonly property string designsDir: root.designsDir
    readonly property string previewsDir: root.previewsDir
    readonly property string fallbackDesignPath: root.fallbackDesignPath
    readonly property string backgroundPath: root.backgroundPath
    readonly property int backgroundVersion: root.backgroundVersion
    readonly property bool fingerprintConfigured: root.fingerprintConfigured
    readonly property bool twelveHour: root.twelveHour
    readonly property string fontSetting: root.fontSetting
    readonly property string displayFont: root.displayFont
    readonly property string themeName: root.themeName
    readonly property bool previewVisible: root.previewVisible
    readonly property bool locked: root.locked
    function designUsable(d) { return root.designUsable(d) }
    function setDesign(id) { return root.setDesign(id) }
    function setTwelveHour(on) { root.setTwelveHour(on) }
    function setDisplayFont(family) { root.setDisplayFont(family) }
    function rescanDesigns() { root.rescanDesigns(); root.refreshBackground(); root.refreshFingerprintStatus() }
    function downloadAssets(id) { return root.downloadAssets(id) }
    function cancelDownload(id) { root.cancelDownload(id) }
    function removeAssets(id) { return root.removeAssets(id) }
    function showPreview(id) { root.showPreview(id) }
    function hidePreview() { root.hidePreview() }
    function lockNow() { return root.beginLock() }
  }

  // Video designs pay ~700 ms the first time QtMultimedia loads; take that
  // hit at an idle moment after startup instead of at the first lock.
  Timer {
    interval: 6000
    running: true
    onTriggered: { warmup.active = true; root.prefetchActiveMedia() }
  }

  // Reads the active design's media once so the first lock after a boot
  // finds it in the page cache rather than on disk. Low priority, no output.
  function prefetchActiveMedia() {
    var d = activeDesign
    var dir = designAssetsDir(d)
    if (!d || dir.length === 0 || prefetchProc.running) return
    prefetchProc.command = ["nice", "-n", "19", "bash", "-c", "cat -- \"$0\"/*.mp4 \"$0\"/*.webm \"$0\"/*.png \"$0\"/*.jpg > /dev/null 2>&1; true", designsDir + "/" + dir]
    prefetchProc.running = true
  }
  Process { id: prefetchProc }
  Timer { id: prefetchTimer; interval: 1500; onTriggered: root.prefetchActiveMedia() }
  Loader {
    id: warmup
    active: false
    source: Qt.resolvedUrl("Warmup.qml")
  }

  Component.onCompleted: {
    Bridge.publish(facade)
    refreshBackground()
    refreshFingerprintStatus()
    checkStrandedLock()
    syncProc.running = true
  }
  Component.onDestruction: Bridge.retract(facade)
}

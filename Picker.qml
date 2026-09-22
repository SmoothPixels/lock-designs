import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Bridge.js" as Bridge

// The design picker. Summoned with
//   omarchy-shell shell toggle io.github.smoothpixels.lock-designs '{}'
//
// It never touches the lock: everything goes through the facade Service.qml
// publishes on Bridge.js, because Omarchy hands the overlay of an
// authentication service `service = null`.
//
// Kept light on purpose. Cards show a small JPEG where one is shipped, so
// browsing never spins up a video decoder; only designs without a still
// (Classic, Starry City, your own files) are rendered live, and those with
// their video paused. One design at most plays for real, in the preview.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  property bool opened: false

  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "io.github.smoothpixels.lock-designs"
  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color muted: Util.alpha(foreground, 0.55)
  readonly property color faint: Util.alpha(foreground, 0.08)
  readonly property color accent: Color.accent
  readonly property string fontFamily: Style.font.family

  function adopt() {
    if (!root.service) root.service = Bridge.current()
  }
  property var unwatch: null
  Component.onCompleted: {
    root.unwatch = Bridge.watch(function() { Qt.callLater(root.adopt) })
    adopt()
  }
  Component.onDestruction: if (root.unwatch) root.unwatch()
  onServiceChanged: if (!service) Qt.callLater(adopt)

  property var targetScreen: null

  // The screen Hyprland says has focus, so the window opens where the user
  // is looking on a multi-monitor desk; falls back to the first screen.
  function focusedScreen() {
    var name = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) if (screens[i].name === name) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }

  function open(payload) {
    adopt()
    root.targetScreen = focusedScreen()
    // `omarchy-shell shell toggle <id> '{"tab":"login"}'` opens straight on a tab.
    try {
      var p = typeof payload === "string" && payload.length > 0 ? JSON.parse(payload) : payload
      if (p && (p.tab === "lock" || p.tab === "login")) root.tab = p.tab
    } catch (e) {}
    if (root.service) {
      root.service.rescanDesigns()
      root.service.checkLoginTheme()
    }
    root.opened = true
    Qt.callLater(function() { keys.forceActiveFocus() })
  }

  function close() { root.opened = false }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
  }

  // ---- view state -------------------------------------------------------
  property string query: ""
  property string filter: "all"
  property int currentIndex: 0
  // "lock" shows the design grid; "login" the SDDM login screen choices.
  property string tab: "lock"

  readonly property var designs: service ? (service.designs || []) : []
  readonly property var catalog: service ? (service.catalog || ({})) : ({})
  readonly property var installed: service ? (service.installedAssets || ({})) : ({})
  readonly property var downloads: service ? (service.downloads || ({})) : ({})
  readonly property string activeId: service ? String(service.activeDesignId || "") : ""
  readonly property var activeDesign: {
    for (var i = 0; i < designs.length; i++) if (designs[i].id === activeId) return designs[i]
    return null
  }

  function needsAssets(d) { return !!(d && root.catalog[d.id]) }
  function isReady(d) { return !!d && (!needsAssets(d) || root.installed[d.id] === true) }
  function downloadOf(d) { return d ? (root.downloads[d.id] || null) : null }

  readonly property var shown: {
    var q = query.trim().toLowerCase()
    var out = []
    for (var i = 0; i < designs.length; i++) {
      var d = designs[i]
      if (filter === "original" && (d.thirdParty || !d.shipped)) continue
      if (filter === "third" && !d.thirdParty) continue
      if (filter === "missing" && isReady(d)) continue
      if (filter === "video" && !d.video) continue
      if (q.length > 0 && (d.name + " " + d.description + " " + d.source).toLowerCase().indexOf(q) === -1) continue
      out.push(d)
    }
    return out
  }
  onShownChanged: if (currentIndex >= shown.length) currentIndex = Math.max(0, shown.length - 1)
  readonly property var current: currentIndex >= 0 && currentIndex < shown.length ? shown[currentIndex] : null

  function sizeLabel(d) {
    var entry = root.catalog[d.id]
    if (!entry || !Array.isArray(entry.files)) return ""
    var total = 0
    for (var i = 0; i < entry.files.length; i++) total += Number(entry.files[i].size) > 0 ? Number(entry.files[i].size) : 0
    if (total <= 0) return ""
    return total >= 1e6 ? Math.round(total / 1e6) + " MB" : Math.max(1, Math.round(total / 1e3)) + " kB"
  }

  function progressOf(dl) {
    if (!dl) return 0
    var frac = dl.totalBytes > 0 ? (dl.doneBytes + dl.bytes) / dl.totalBytes
      : (dl.fileCount > 0 ? dl.fileIndex / dl.fileCount : 0)
    return Math.max(0, Math.min(1, frac))
  }

  function stateLabel(d) {
    var dl = downloadOf(d)
    if (dl) {
      if (dl.phase === "failed") return "Failed"
      if (dl.phase === "verifying") return "Verifying"
      if (dl.phase === "queued") return "Queued"
      return Math.round(progressOf(dl) * 100) + "%"
    }
    if (d.id === root.activeId) return "In use"
    if (!isReady(d)) return "Download " + sizeLabel(d)
    return ""
  }

  function sourceLabel(d) {
    if (d.source === "qylock") return "qylock port"
    if (d.source === "wallsflow") return "wallsflow"
    if (d.source.length > 0) return d.source
    return d.shipped ? "original" : "yours"
  }

  // Click, Enter: use a ready design, otherwise start its download.
  function activate(d) {
    if (!d || !root.service) return
    var dl = downloadOf(d)
    if (isReady(d)) { root.service.setDesign(d.id); return }
    if (dl && dl.phase !== "failed") return
    root.service.downloadAssets(d.id)
  }

  function preview(d) {
    if (d && root.service) root.service.showPreview(d.id)
  }

  function toggleAssets(d) {
    if (!d || !root.service || !needsAssets(d)) return
    var dl = downloadOf(d)
    if (dl && dl.phase !== "failed") { root.service.cancelDownload(d.id); return }
    if (isReady(d)) root.service.removeAssets(d.id)
    else root.service.downloadAssets(d.id)
  }

  function move(delta) {
    if (shown.length === 0) return
    var next = Math.max(0, Math.min(shown.length - 1, currentIndex + delta))
    currentIndex = next
    grid.positionViewAtIndex(next, GridView.Contain)
  }

  PanelWindow {
    id: window
    screen: root.targetScreen
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-lock-designs"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: Math.min(Style.space(1260), parent.width - Style.gapsOut * 4)
      height: Math.min(Style.space(820), parent.height - Style.gapsOut * 4)
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: root.background
      borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
      padding: Style.spacing.panelPadding

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keys
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        focus: true

        Keys.onPressed: function(event) {
          var ctrl = (event.modifiers & Qt.ControlModifier) !== 0
          if (event.key === Qt.Key_Escape) { root.dismiss(); event.accepted = true; return }
          if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { root.tab = root.tab === "lock" ? "login" : "lock"; event.accepted = true; return }
          if (root.tab === "login") {
            var picks = { }
            picks[Qt.Key_1] = "omarchy"; picks[Qt.Key_2] = "omarchy-theme"; picks[Qt.Key_3] = "lock"
            if (picks[event.key] && root.service && root.service.loginInstalled) { root.service.setLoginSource(picks[event.key]); event.accepted = true }
            return
          }
          if (event.key === Qt.Key_Left) { root.move(-1); event.accepted = true; return }
          if (event.key === Qt.Key_Right) { root.move(1); event.accepted = true; return }
          if (event.key === Qt.Key_Up) { root.move(-grid.columns); event.accepted = true; return }
          if (event.key === Qt.Key_Down) { root.move(grid.columns); event.accepted = true; return }
          if (event.key === Qt.Key_PageUp) { root.move(-grid.columns * 2); event.accepted = true; return }
          if (event.key === Qt.Key_PageDown) { root.move(grid.columns * 2); event.accepted = true; return }
          if (event.key === Qt.Key_Home) { root.move(-root.shown.length); event.accepted = true; return }
          if (event.key === Qt.Key_End) { root.move(root.shown.length); event.accepted = true; return }
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.activate(root.current); event.accepted = true; return }
          if (event.key === Qt.Key_Space || (event.key === Qt.Key_P && !ctrl)) { root.preview(root.current); event.accepted = true; return }
          if (event.key === Qt.Key_D && !ctrl) { root.toggleAssets(root.current); event.accepted = true; return }
          if (event.key === Qt.Key_L && !ctrl) { if (root.service) root.service.lockNow(); root.dismiss(); event.accepted = true; return }
          if (event.key === Qt.Key_Slash || (ctrl && event.key === Qt.Key_F)) { search.forceActiveFocus(); search.selectAll(); event.accepted = true; return }
          // Typing anywhere starts a search.
          if (!ctrl && event.text.length === 1 && /[\w\d]/.test(event.text)) {
            search.forceActiveFocus()
            search.text = search.text + event.text
            search.cursorPosition = search.text.length
            event.accepted = true
          }
        }

        // ---- header -----------------------------------------------------
        Item {
          id: header
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: Style.space(44)

          Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)
            Text {
              text: "Lock Designs"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              font.weight: Font.Bold
            }
            Text {
              text: root.designs.length + " designs · " + (root.activeDesign ? "using " + root.activeDesign.name : "")
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          // Every family Qt knows about, with "follow the theme" first. Built
          // once when the picker opens; installing a font mid-session needs a
          // reopen.
          readonly property var fontOptions: {
            var opened = root.opened
            var list = Qt.fontFamilies().filter(function(f) { return f.length > 0 && f.charAt(0) !== "." })
            list.sort(function(a, b) { return a.localeCompare(b) })
            var out = [{ value: "", label: "Theme font", description: Style.font.family }]
            for (var i = 0; i < list.length; i++) out.push({ value: list[i], label: list[i] })
            return out
          }

          SearchableDropdown {
            id: fontPicker
            visible: root.tab === "lock"
            anchors.right: search.left
            anchors.rightMargin: Style.spacing.controlGap
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(260)
            showLabel: false
            options: header.fontOptions
            value: root.service ? root.service.fontSetting : ""
            triggerLabel: "Font: " + (root.service && root.service.fontSetting.length > 0 ? root.service.fontSetting : "theme")
            placeholderText: "Search installed fonts"
            fontFamily: root.fontFamily
            foreground: root.foreground
            accent: root.accent
            onChanged: function(next) {
              if (root.service) root.service.setDisplayFont(next)
              keys.forceActiveFocus()
            }
          }

          TextField {
            id: search
            visible: root.tab === "lock"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(280)
            placeholderText: "Search designs"
            font.family: root.fontFamily
            onTextChanged: root.query = text
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                if (text.length > 0) { text = ""; keys.forceActiveFocus() } else root.dismiss()
                event.accepted = true
              } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                keys.forceActiveFocus()
                if (event.key !== Qt.Key_Down) root.activate(root.current)
                event.accepted = true
              }
            }
          }
        }

        // ---- tabs -------------------------------------------------------
        Row {
          id: tabs
          anchors.top: header.bottom
          anchors.topMargin: Style.space(10)
          anchors.left: parent.left
          spacing: Style.spacing.controlGap
          Button {
            text: "Lock screen"
            iconText: "󰌾"
            selected: root.tab === "lock"
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            onClicked: { root.tab = "lock"; keys.forceActiveFocus() }
          }
          Button {
            text: "Login screen"
            iconText: "󰍹"
            selected: root.tab === "login"
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            onClicked: { root.tab = "login"; if (root.service) root.service.checkLoginTheme(); keys.forceActiveFocus() }
          }
        }
        Text {
          anchors.right: parent.right
          anchors.verticalCenter: tabs.verticalCenter
          text: "Tab switches"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        // ================= Lock screen tab =================
        Item {
          id: lockTab
          visible: root.tab === "lock"
          anchors.top: tabs.bottom
          anchors.topMargin: Style.space(12)
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom

        // ---- filters ----------------------------------------------------
        Row {
          id: chips
          anchors.top: parent.top
          anchors.left: parent.left
          spacing: Style.spacing.controlGap

          Repeater {
            model: [
              { id: "all", label: "All" },
              { id: "original", label: "Originals" },
              { id: "third", label: "Third party" },
              { id: "video", label: "Video" },
              { id: "missing", label: "Not downloaded" }
            ]
            delegate: Button {
              required property var modelData
              text: modelData.label
              selected: root.filter === modelData.id
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onClicked: { root.filter = modelData.id; root.currentIndex = 0; keys.forceActiveFocus() }
            }
          }
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: chips.verticalCenter
          text: "Click selects · Enter or double-click uses · Space previews · D downloads or removes · L locks · Esc closes"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        // ---- grid -------------------------------------------------------
        GridView {
          id: grid
          anchors.top: chips.bottom
          anchors.topMargin: Style.space(12)
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: footer.top
          anchors.bottomMargin: Style.space(12)
          clip: true
          // GridView counts columns against the width minus its margins, so
          // the cell width has to be derived from that same span or the last
          // column falls off and the row leaves a gap.
          readonly property real span: width - leftMargin - rightMargin
          readonly property int columns: Math.max(2, Math.floor(span / Style.space(300)))
          cellWidth: Math.floor(span / columns)
          cellHeight: Math.round((cellWidth - Style.space(12)) * 9 / 16) + Style.space(70)
          model: root.shown
          currentIndex: root.currentIndex
          cacheBuffer: cellHeight
          boundsBehavior: Flickable.StopAtBounds
          flickDeceleration: 4000
          maximumFlickVelocity: 3500
          rightMargin: Style.space(14)

          Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: vbar
            policy: Controls.ScrollBar.AsNeeded
            minimumSize: 0.08
            contentItem: Rectangle {
              implicitWidth: Style.space(6)
              radius: width / 2
              color: Util.alpha(root.foreground, vbar.pressed ? 0.5 : (vbar.hovered ? 0.4 : 0.26))
            }
            background: Rectangle {
              implicitWidth: Style.space(6)
              radius: width / 2
              color: Util.alpha(root.foreground, 0.06)
            }
          }

          Text {
            anchors.centerIn: parent
            visible: root.shown.length === 0
            text: root.designs.length === 0 ? "Loading designs…" : "Nothing matches"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
          }

          delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property var d: modelData
            readonly property bool ready: root.isReady(d)
            readonly property bool needs: root.needsAssets(d)
            readonly property var dl: root.downloadOf(d)
            readonly property bool active: d.id === root.activeId
            readonly property bool current: index === root.currentIndex
            // HoverHandler, not MouseArea.containsMouse: the pointer moving onto
            // one of the action buttons must not count as leaving the card.
            readonly property bool hot: cardHover.hovered || current
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
              id: frame
              anchors.fill: parent
              anchors.margins: Style.space(6)
              radius: Math.max(Style.cornerRadius, 8)
              color: cell.hot ? Color.menu.selectedBackground : "transparent"
              border.width: cell.current ? 2 : (cell.active ? 2 : 0)
              border.color: cell.current ? Util.alpha(root.foreground, 0.8) : Util.alpha(root.accent, 0.7)

              HoverHandler { id: cardHover }

              // A click only selects. Applying is explicit: the Use button,
              // Enter, or a double-click.
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.currentIndex = cell.index; keys.forceActiveFocus() }
                onDoubleClicked: { root.currentIndex = cell.index; root.activate(cell.d) }
              }

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(8)
                spacing: Style.space(6)

                Item {
                  id: shot
                  width: parent.width
                  height: Math.round(width * 9 / 16)

                  Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Util.alpha(root.foreground, 0.06)
                  }

                  Image {
                    anchors.fill: parent
                    visible: cell.d.hasPreview
                    source: cell.d.hasPreview && root.service ? "file://" + root.service.previewsDir + "/" + cell.d.id + ".jpg" : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 480
                    sourceSize.height: 270
                  }

                  // Live, paused render for designs without a shipped still.
                  Loader {
                    anchors.fill: parent
                    active: !cell.d.hasPreview && cell.ready && root.opened
                    sourceComponent: Item {
                      clip: true
                      LockHost {
                        width: 1920
                        height: 1080
                        scale: shot.width / 1920
                        transformOrigin: Item.TopLeft
                        designPath: cell.d.path
                        fallbackPath: root.service ? root.service.fallbackDesignPath : ""
                        backgroundPath: root.service ? root.service.backgroundPath : ""
                        backgroundVersion: root.service ? root.service.backgroundVersion : 0
                        fingerprintConfigured: root.service ? root.service.fingerprintConfigured : false
                        inputEnabled: false
                        loadBackground: true
                        videoPlaying: false
                        twelveHour: root.service ? root.service.twelveHour : false
                        displayFont: root.service ? root.service.displayFont : Style.font.family
                      }
                    }
                  }

                  Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.5)
                    visible: !cell.ready
                  }

                  // Source badge, top left. Gives way to the state badge on
                  // narrow cards instead of running underneath it.
                  Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: Style.space(6)
                    width: Math.min(sourceText.implicitWidth + Style.space(12), shot.width - Style.space(12) - (stateBadge.visible ? stateBadge.width + Style.space(6) : 0))
                    height: sourceText.implicitHeight + Style.space(6)
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.55)
                    clip: true
                    Text {
                      id: sourceText
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.left: parent.left
                      anchors.leftMargin: Style.space(6)
                      width: parent.width - Style.space(12)
                      elide: Text.ElideRight
                      text: root.sourceLabel(cell.d) + (cell.d.timeBased ? " · time-based" : "") + (cell.d.video ? " · video" : "")
                      color: "#f0f0f0"
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }

                  // State badge, top right.
                  Rectangle {
                    id: stateBadge
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Style.space(6)
                    visible: stateText.text.length > 0
                    width: stateText.implicitWidth + Style.space(12)
                    height: stateText.implicitHeight + Style.space(6)
                    radius: height / 2
                    color: cell.active ? root.accent : (cell.dl && cell.dl.phase === "failed" ? Color.urgent : Qt.rgba(0, 0, 0, 0.55))
                    Text {
                      id: stateText
                      anchors.centerIn: parent
                      text: root.stateLabel(cell.d)
                      color: cell.active ? Color.background : "#f0f0f0"
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.weight: cell.active ? Font.Bold : Font.Normal
                    }
                  }

                  // Progress bar along the bottom edge while downloading.
                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 4
                    radius: 2
                    visible: cell.dl !== null && cell.dl.phase !== "failed"
                    color: Qt.rgba(0, 0, 0, 0.5)
                    Rectangle {
                      anchors.left: parent.left
                      anchors.top: parent.top
                      anchors.bottom: parent.bottom
                      width: parent.width * root.progressOf(cell.dl)
                      radius: 2
                      color: root.accent
                      Behavior on width { NumberAnimation { duration: 200 } }
                    }
                  }
                }

                Row {
                  width: parent.width
                  spacing: Style.space(8)
                  Text {
                    width: parent.width - actions.width - parent.spacing
                    text: cell.d.name
                    color: root.foreground
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.subtitle
                    font.weight: Font.Bold
                  }
                  Row {
                    id: actions
                    spacing: Style.space(4)
                    opacity: cell.hot ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Button {
                      visible: cell.ready && !cell.active
                      iconText: "󰄬"
                      tooltipText: "Use this design"
                      foreground: root.foreground
                      accent: root.accent
                      verticalPadding: 2
                      horizontalPadding: 6
                      onClicked: { root.currentIndex = cell.index; root.activate(cell.d) }
                    }
                    Button {
                      iconText: "󰈈"
                      tooltipText: "Preview"
                      foreground: root.foreground
                      accent: root.accent
                      verticalPadding: 2
                      horizontalPadding: 6
                      onClicked: root.preview(cell.d)
                    }
                    Button {
                      visible: cell.needs
                      iconText: cell.dl && cell.dl.phase !== "failed" ? "󰜺" : (cell.ready ? "󰆴" : "󰇚")
                      tooltipText: cell.dl && cell.dl.phase !== "failed" ? "Cancel download" : (cell.ready ? "Remove downloaded assets" : "Download assets")
                      foreground: root.foreground
                      accent: root.accent
                      verticalPadding: 2
                      horizontalPadding: 6
                      onClicked: root.toggleAssets(cell.d)
                    }
                  }
                }

                Text {
                  width: parent.width
                  text: cell.dl && cell.dl.phase === "failed" && cell.dl.error
                    ? cell.dl.error
                    : (cell.d.description.length > 0 ? cell.d.description
                      : (cell.needs && !cell.ready ? "Click to download " + root.sizeLabel(cell.d) + ", verified against the catalog's SHA-256" : "Ready to use"))
                  color: cell.dl && cell.dl.phase === "failed" ? Color.urgent : root.muted
                  elide: Text.ElideRight
                  maximumLineCount: 1
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }

        // ---- footer -----------------------------------------------------
        Item {
          id: footer
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: Style.space(36)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.current ? root.current.name + (root.current.description.length > 0 ? "  ·  " + root.current.description : "") : ""
            color: root.muted
            elide: Text.ElideRight
            width: parent.width - buttons.width - Style.space(16)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            id: buttons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.controlGap

            Button {
              text: root.service && root.service.twelveHour ? "12-hour clock" : "24-hour clock"
              iconText: "󰥔"
              tooltipText: "Switch how designs show the time"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onClicked: if (root.service) root.service.setTwelveHour(!root.service.twelveHour)
            }
            Button {
              readonly property var d: root.current
              readonly property bool inUse: d !== null && d.id === root.activeId
              readonly property bool ready: root.isReady(d)
              readonly property var dl: root.downloadOf(d)
              text: d === null ? "Use design"
                : inUse ? "In use"
                : (dl && dl.phase !== "failed") ? root.stateLabel(d)
                : ready ? "Use design" : "Download " + root.sizeLabel(d)
              iconText: inUse ? "󰄬" : (ready ? "󰄬" : "󰇚")
              selected: !inUse && d !== null
              opacity: inUse || d === null ? 0.55 : 1
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onClicked: if (!inUse) root.activate(d)
            }
            Button {
              text: "Preview"
              iconText: "󰈈"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onClicked: root.preview(root.current || root.activeDesign)
            }
            Button {
              text: "Lock now"
              iconText: "󰌾"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onClicked: { if (root.service) root.service.lockNow(); root.dismiss() }
            }
            Button {
              text: "Close"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onClicked: root.dismiss()
            }
          }
        }
        }

        // ================= Login screen tab =================
        Item {
          id: loginTab
          visible: root.tab === "login"
          anchors.top: tabs.bottom
          anchors.topMargin: Style.space(16)
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          readonly property bool installed: root.service ? root.service.loginInstalled : false
          readonly property bool stale: root.service ? root.service.loginStale : false
          readonly property string source: root.service ? root.service.loginSource : ""

          // One selectable choice for what the login screen shows.
          component Choice: Rectangle {
            id: choice
            property string value: ""
            property string title: ""
            property string detail: ""
            property string glyph: ""
            readonly property bool picked: loginTab.source === value
            width: Math.min(parent.width, Style.space(720))
            height: Style.space(64)
            radius: Math.max(Style.cornerRadius, 8)
            color: picked ? Color.menu.selectedBackground : (choiceHover.hovered ? Util.alpha(root.foreground, 0.04) : "transparent")
            border.width: picked ? 2 : 1
            border.color: picked ? root.accent : Util.alpha(root.foreground, 0.15)
            HoverHandler { id: choiceHover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              enabled: loginTab.installed
              onClicked: { if (root.service) root.service.setLoginSource(choice.value); keys.forceActiveFocus() }
            }
            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(16)
              anchors.rightMargin: Style.space(16)
              spacing: Style.space(14)
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(16)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: choice.picked ? root.accent : Util.alpha(root.foreground, 0.4)
                Rectangle {
                  anchors.centerIn: parent
                  width: parent.width * 0.5
                  height: width
                  radius: width / 2
                  color: root.accent
                  visible: choice.picked
                }
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: choice.glyph
                color: choice.picked ? root.accent : root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
              Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(3)
                Text {
                  text: choice.title
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.weight: Font.Bold
                }
                Text {
                  text: choice.detail
                  color: root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }

          Column {
            anchors.left: parent.left
            anchors.top: parent.top
            width: parent.width
            spacing: Style.space(12)

            Text {
              width: Math.min(parent.width, Style.space(720))
              wrapMode: Text.Wrap
              text: loginTab.installed
                ? "What SDDM shows before you sign in. It updates on its own when your theme, wallpaper, font or lock design change, and applies from the next login."
                : "The login screen (SDDM) can follow your theme or show your lock design. Setting it up needs your password once, in a terminal; after that nothing here asks for privileges."
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            Rectangle {
              visible: loginTab.installed && loginTab.stale
              width: Math.min(parent.width, Style.space(720))
              height: staleText.implicitHeight + Style.space(20)
              radius: Math.max(Style.cornerRadius, 8)
              color: Util.alpha(root.accent, 0.10)
              border.width: 1
              border.color: Util.alpha(root.accent, 0.5)
              Text {
                id: staleText
                anchors.fill: parent
                anchors.margins: Style.space(10)
                wrapMode: Text.Wrap
                text: "The lock screen files on disk have changed since the login screen was last set up. Press Update login screen files below to bring the login screen in line with them."
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
            }

            Button {
              visible: !loginTab.installed
              text: "Set up login screen"
              iconText: "󰍹"
              selected: true
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              onClicked: {
                if (!root.service) return
                root.dismiss()
                root.service.installLoginTheme()
              }
            }

            Choice {
              visible: loginTab.installed
              value: "omarchy"
              glyph: ""
              title: "Omarchy default"
              detail: "Omarchy's stock login screen, exactly as it ships"
            }
            Choice {
              visible: loginTab.installed
              value: "omarchy-theme"
              glyph: "󰏘"
              title: "Omarchy default, theme colors"
              detail: "The same layout, recolored with your active theme"
            }
            Choice {
              visible: loginTab.installed
              value: "lock"
              glyph: "󰌾"
              title: "Same as the lock screen"
              detail: "Your lock design, live on the login screen" + (root.activeDesign ? " (currently " + root.activeDesign.name + ")" : "")
            }

            Row {
              visible: loginTab.installed
              spacing: Style.spacing.controlGap
              Button {
                text: "Preview login screen"
                iconText: "󰈈"
                tooltipText: "Opens the greeter in a window, without logging out"
                foreground: root.foreground
                accent: root.accent
                fontFamily: root.fontFamily
                onClicked: if (root.service) root.service.previewLogin()
              }
              Button {
                text: "Update login screen files"
                iconText: "󰑐"
                selected: loginTab.stale
                tooltipText: "Re-run the installer so the login screen gets the designs from the current plugin version. Asks for your password in a terminal."
                foreground: root.foreground
                accent: root.accent
                fontFamily: root.fontFamily
                onClicked: {
                  if (!root.service) return
                  root.dismiss()
                  root.service.installLoginTheme()
                }
              }
              Button {
                text: "Remove login screen"
                iconText: "󰆴"
                tooltipText: "Puts SDDM back on Omarchy's own login screen and deletes the installed theme. Asks for your password in a terminal."
                foreground: root.foreground
                accent: root.accent
                fontFamily: root.fontFamily
                onClicked: {
                  if (!root.service) return
                  root.dismiss()
                  root.service.removeLoginTheme()
                }
              }
            }

            Text {
              visible: loginTab.installed
              width: Math.min(parent.width, Style.space(720))
              wrapMode: Text.Wrap
              text: "New designs reach the login screen when you run the installer again after a plugin update. Removing the login screen leaves the lock screen as it is."
              color: Util.alpha(root.foreground, 0.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}

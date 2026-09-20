import QtQuick
import Quickshell.Io

// No UI: this plugin only supplies content for Lock Screen Explorer
// (io.github.sirjul1337.lock-explorer), which auto-discovers any design
// dropped into ~/.config/omarchy/lock-designs/. This service copies this
// plugin's own designs/ folder there once when the shell (re)loads the
// plugin, so a fresh install or `omarchy plugin update` picks up new or
// fixed designs without a manual step.
Item {
  id: root

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "")

  Component.onCompleted: syncProcess.running = true

  Process {
    id: syncProcess
    running: false
    command: ["bash", "-c", `
      set -e
      designs_dir="$HOME/.config/omarchy/lock-designs"
      mkdir -p "$designs_dir"
      rsync -a '` + root.pluginDir + `designs/' "$designs_dir/"
      if [[ ! -d "$HOME/.config/omarchy/plugins/io.github.sirjul1337.lock-explorer" ]]; then
        echo "Lock Screen Explorer is not installed. These designs will not show up until you run: omarchy plugin add https://github.com/SirJul1337/omarchy-lock-explorer.git --enable"
      fi
      omarchy-shell lock rescanDesigns >/dev/null 2>&1 || true
    `]
    stdout: StdioCollector { onStreamFinished: if (text) console.log("lock-designs:", text.trim()) }
    stderr: StdioCollector { onStreamFinished: if (text) console.warn("lock-designs:", text.trim()) }
  }
}

// Stand-in for the Omarchy shell's Color singleton inside the SDDM greeter.
// The greeter's Main.qml sets the five base colors from theme.conf.user; the
// lock palette is derived from them the way the shell derives it.
pragma Singleton
import QtQuick

QtObject {
  id: root
  property color background: "#101315"
  property color foreground: "#cacccc"
  property color accent: "#cacccc"
  property color urgent: "#a55555"
  property color muted: "#707880"

  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  readonly property QtObject lock: QtObject {
    readonly property color background: root.alpha(root.background, 0.8)
    readonly property color text: root.foreground
    readonly property color placeholder: root.alpha(root.foreground, 0.66)
    readonly property color textError: root.urgent
    readonly property color border: root.foreground
    readonly property color borderActive: root.accent
    readonly property color borderError: root.urgent
    readonly property color selection: root.alpha(root.accent, 0.45)
  }
  readonly property QtObject menu: QtObject {
    readonly property color background: root.background
    readonly property color text: root.foreground
    readonly property color border: root.foreground
    readonly property color scrim: root.alpha(root.background, 0.5)
    readonly property color selectedBackground: root.alpha(root.foreground, 0.08)
    readonly property color selectedText: root.accent
  }
}

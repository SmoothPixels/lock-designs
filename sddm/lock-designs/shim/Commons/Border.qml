// Stand-in for the shell's Border helpers. Specs are plain width and color;
// the shell's per-theme border tokens do not exist in the greeter.
pragma Singleton
import QtQuick

QtObject {
  function surfaceSpec(section, token, fallbackColor, fallbackWidth, alphaKey) {
    return { width: fallbackWidth === undefined ? 1 : fallbackWidth, color: fallbackColor }
  }
  function localOrSurfaceSpec(section, token, color, fallbackColor, width) {
    return { width: width === undefined ? 1 : width, color: color }
  }
  function controlSpec(state, foreground, accent) {
    return { width: 1, color: state === "focus" ? accent : foreground }
  }
  function none() { return { width: 0, color: "transparent" } }
  function top(spec) { return spec && spec.width ? spec.width : 0 }
  function right(spec) { return top(spec) }
  function bottom(spec) { return top(spec) }
  function left(spec) { return top(spec) }
  function needsOverlay(spec) { return false }
}

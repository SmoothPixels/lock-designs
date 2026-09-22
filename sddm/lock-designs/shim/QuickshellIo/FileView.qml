// Stand-in for Quickshell.Io's FileView: the greeter reads no files on a
// design's behalf, so every load fails quietly and text() is empty. Designs
// only use it for optional extras (host name, color overrides).
import QtQuick

QtObject {
  property string path: ""
  property bool printErrors: true
  property bool watchChanges: false
  property bool blockLoading: false
  property bool blockWrites: false
  signal loaded()
  signal loadFailed()
  signal fileChanged()
  function text() { return "" }
  function reload() { loadFailed() }
  function setText(value) {}
  function waitForJob() {}
}

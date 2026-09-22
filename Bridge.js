// In-process link between Service.qml and Picker.qml.
//
// Omarchy keeps authentication services (which a clone of omarchy.lock is)
// away from their own overlay and injects `service = null` into the picker.
// Both files import this library; `.pragma library` makes it a single
// instance per QML engine, so the service can hand the picker a facade here.
// The facade is a QtObject with bound properties (so the picker's bindings
// stay live) and carries no PAM state and never the typed password.
.pragma library

var facade = null
var watchers = []

function publish(object) {
  facade = object || null
  broadcast()
}

function retract(object) {
  if (facade !== object) return
  facade = null
  broadcast()
}

function current() {
  return facade
}

// Returns a function that removes the watcher again.
function watch(fn) {
  if (typeof fn !== "function") return function() {}
  watchers.push(fn)
  return function() {
    var i = watchers.indexOf(fn)
    if (i !== -1) watchers.splice(i, 1)
  }
}

function broadcast() {
  var list = watchers.slice()
  for (var i = 0; i < list.length; i++) {
    try { list[i](facade) } catch (e) { console.warn("lock-designs bridge: " + e) }
  }
}

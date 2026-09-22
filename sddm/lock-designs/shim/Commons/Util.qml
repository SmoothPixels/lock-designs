pragma Singleton
import QtQuick

QtObject {
  function alpha(c, opacity) { return Qt.rgba(c.r, c.g, c.b, opacity) }
  function isPlainObject(v) { return v !== null && typeof v === "object" && !Array.isArray(v) }
  function cloneJson(v) { return JSON.parse(JSON.stringify(v)) }
}

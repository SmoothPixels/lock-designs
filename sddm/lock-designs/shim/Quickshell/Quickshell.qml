// Stand-in for the Quickshell singleton. Designs only ask it for a few
// environment names; the greeter's Main.qml fills these in.
pragma Singleton
import QtQuick

QtObject {
  property string userName: ""
  property string hostName: ""
  property string home: ""
  property var screens: []

  function env(name) {
    switch (String(name)) {
      case "USER":
      case "LOGNAME": return userName
      case "HOSTNAME":
      case "HOST": return hostName
      case "HOME": return home
      default: return ""
    }
  }
}

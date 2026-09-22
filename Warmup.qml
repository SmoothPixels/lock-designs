import QtQuick
import QtMultimedia

// Loaded a few seconds after the shell starts, purely so Qt's multimedia
// module is already in memory when the first video design locks the screen.
// Measured: the first import costs about 700 ms; every later one, a few ms.
Item {
  MediaPlayer { }
}

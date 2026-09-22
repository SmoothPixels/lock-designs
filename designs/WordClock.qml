// name: Word Clock
// description: The time spelled out, lit letter by letter in a grid
//
// SmoothPixels original. An eleven by ten grid of letters; the ones that
// spell the current time to the nearest five minutes light up in the theme
// foreground, four small dots below count the minutes in between. The grid
// layout is this plugin's own.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color lit: lock.errorState ? Color.lock.textError : Color.foreground
  readonly property color dim: lock.withAlpha(Color.foreground, 0.13)

  // Row, first column, length of every word the clock can say.
  readonly property var rows: [
    "ITRISQHALFB",
    "QUARTERTENY",
    "TWENTYFIVEX",
    "PASTKTOMINU",
    "ONETWOTHREE",
    "FOURFIVESIX",
    "SEVENEIGHTW",
    "NINEELEVENK",
    "TENTWELVEXO",
    "OCLOCKBSMPX"
  ]
  readonly property var words: ({
    it: [0, 0, 2], is: [0, 3, 2], half: [0, 6, 4],
    quarter: [1, 0, 7], mten: [1, 7, 3],
    twenty: [2, 0, 6], mfive: [2, 6, 4],
    past: [3, 0, 4], to: [3, 5, 2],
    one: [4, 0, 3], two: [4, 3, 3], three: [4, 6, 5],
    four: [5, 0, 4], five: [5, 4, 4], six: [5, 8, 3],
    seven: [6, 0, 5], eight: [6, 5, 5],
    nine: [7, 0, 4], eleven: [7, 4, 6],
    ten: [8, 0, 3], twelve: [8, 3, 6],
    oclock: [9, 0, 6]
  })
  readonly property var hourWords: ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]

  // Which words are on right now.
  readonly property var active: {
    var h = now.getHours(), m = now.getMinutes()
    var step = Math.round(m / 5) * 5
    if (step === 60) { step = 0; h += 1 }
    var on = ["it", "is"]
    var hourIndex = h % 12
    if (step === 0) on.push(hourWords[hourIndex], "oclock")
    else {
      if (step === 5 || step === 55) on.push("mfive")
      else if (step === 10 || step === 50) on.push("mten")
      else if (step === 15 || step === 45) on.push("quarter")
      else if (step === 20 || step === 40) on.push("twenty")
      else if (step === 25 || step === 35) on.push("twenty", "mfive")
      else if (step === 30) on.push("half")
      if (step <= 30) on.push("past", hourWords[hourIndex])
      else on.push("to", hourWords[(hourIndex + 1) % 12])
    }
    var set = {}
    for (var i = 0; i < on.length; i++) {
      var w = words[on[i]]
      for (var c = 0; c < w[2]; c++) set[w[0] + ":" + (w[1] + c)] = true
    }
    return set
  }
  readonly property int extraMinutes: now.getMinutes() % 5
  readonly property real cell: u * 5.2

  Rectangle { anchors.fill: parent; color: lock.deepen(Color.background, 1.2) }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Column {
    id: board
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.5 - height / 2 - lock.u * 6)
    spacing: 0

    Repeater {
      model: lock.rows
      delegate: Row {
        id: line
        required property string modelData
        required property int index
        Repeater {
          model: line.modelData.length
          delegate: Item {
            required property int index
            readonly property bool on: lock.active[line.index + ":" + index] === true
            width: lock.cell
            height: lock.cell
            Text {
              anchors.centerIn: parent
              text: line.modelData.charAt(parent.index)
              color: parent.on ? lock.lit : lock.dim
              font.family: lock.displayFont
              font.pixelSize: Math.round(lock.cell * 0.56)
              font.weight: parent.on ? Font.DemiBold : Font.Normal
              renderType: Text.CurveRendering
              Behavior on color { ColorAnimation { duration: 500 } }
            }
          }
        }
      }
    }
  }

  // The minutes between the five-minute steps.
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: board.bottom
    anchors.topMargin: Math.round(lock.u * 1.5)
    spacing: Math.round(lock.u * 1.4)
    Repeater {
      model: 4
      delegate: Rectangle {
        required property int index
        width: Math.round(lock.u * 0.9)
        height: width
        radius: width / 2
        color: index < lock.extraMinutes ? lock.lit : lock.dim
        Behavior on color { ColorAnimation { duration: 500 } }
      }
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: field.top
    anchors.bottomMargin: Math.round(lock.u * 2.2)
    text: lock.clock("HH:mm") + "  ·  " + Qt.formatDate(lock.now, "dddd d MMMM")
    color: lock.withAlpha(Color.foreground, 0.5)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.5)
    font.letterSpacing: 2
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.86 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.withAlpha(lock.deepen(Color.background, 1.2), 0.92)
  }
}

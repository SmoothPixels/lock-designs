// name: Binary
// description: The time in binary-coded decimal, one column of dots per digit
//
// SmoothPixels original. Six columns for HH MM SS, four bits each, lit in the
// theme accent; the decimal digit sits under every column for anyone not in
// the mood to add up powers of two. Bits a column can never reach are left
// out rather than drawn dark.
import QtQuick
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color lit: lock.errorState ? Color.lock.textError : Color.accent
  readonly property color unlit: lock.withAlpha(Color.foreground, 0.10)
  readonly property real dot: u * 3.4
  readonly property real gap: u * 1.5

  readonly property string hhmmss: {
    var h = twelveHour ? ((now.getHours() % 12) || 12) : now.getHours()
    return (h < 10 ? "0" + h : String(h)) + Qt.formatDateTime(now, "mmss")
  }
  // Largest value each column can hold: tens of hours 2 (or 1 in 12-hour), tens of minutes and seconds 5.
  readonly property var maxima: [twelveHour ? 1 : 2, 9, 5, 9, 5, 9]

  Rectangle { anchors.fill: parent; color: lock.deepen(Color.background, 1.25) }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Row {
    id: board
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.42 - height / 2)
    spacing: lock.gap

    // Bit weights down the left.
    Column {
      spacing: lock.gap
      Repeater {
        model: [8, 4, 2, 1]
        delegate: Item {
          required property int modelData
          width: lock.dot * 0.9
          height: lock.dot
          Text {
            anchors.centerIn: parent
            text: modelData
            color: lock.withAlpha(Color.foreground, 0.35)
            font.family: lock.displayFont
            font.pixelSize: Math.round(lock.u * 1.6)
          }
        }
      }
    }

    Repeater {
      model: 6
      delegate: Column {
        id: column
        required property int index
        readonly property int value: parseInt(lock.hhmmss.charAt(index))
        readonly property int maxValue: lock.maxima[index]
        spacing: lock.gap
        // Extra room between the pairs.
        leftPadding: index > 0 && index % 2 === 0 ? lock.gap * 1.8 : 0

        Repeater {
          model: [8, 4, 2, 1]
          delegate: Item {
            required property int modelData
            readonly property bool possible: modelData <= column.maxValue
            readonly property bool on: (column.value & modelData) !== 0
            width: lock.dot
            height: lock.dot
            Rectangle {
              anchors.fill: parent
              radius: width / 2
              visible: parent.possible
              color: parent.on ? lock.lit : lock.unlit
              Behavior on color { ColorAnimation { duration: 160 } }
              // A brighter center gives a lit dot depth without a halo that
              // would spill onto its neighbours.
              Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.45
                height: width
                radius: width / 2
                color: lock.raise(lock.lit, 1.35)
                opacity: parent.parent.on ? 0.9 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.horizontalCenterOffset: column.leftPadding / 2
          text: column.value
          color: lock.withAlpha(Color.foreground, 0.55)
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.9)
          topPadding: lock.gap * 0.6
        }
      }
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: board.bottom
    anchors.topMargin: Math.round(lock.u * 3)
    text: Qt.formatDate(lock.now, "dddd  ·  d MMMM").toUpperCase() + (lock.meridiem.length > 0 ? "  ·  " + lock.meridiem : "")
    color: lock.withAlpha(Color.foreground, 0.5)
    font.family: lock.displayFont
    font.pixelSize: Math.round(lock.u * 1.5)
    font.letterSpacing: 3
  }

  PasswordField {
    id: field
    lock: lock
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(lock.height * 0.78 - height / 2)
    width: Math.round(lock.u * 30)
    height: Math.round(lock.u * 4.4)
    color: lock.withAlpha(lock.deepen(Color.background, 1.25), 0.92)
    accentColor: Color.accent
  }
}

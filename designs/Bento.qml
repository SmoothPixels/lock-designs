// name: Bento
// description: A frosted grid of clock, date, greeting and week tiles over your wallpaper
//
// SmoothPixels original. Your wallpaper, blurred, under a bento box of tiles
// in the theme's lock colors: a big clock, the date, a greeting with your
// avatar, the week at a glance, and the password field as the bottom row.
import QtQuick
import QtQuick.Effects
import qs.Commons

DesignBase {
  id: lock
  inputItem: field.input

  readonly property real u: Math.min(width, height) / 100
  readonly property color tile: lock.withAlpha(Color.lock.background, 0.78)
  readonly property color edge: lock.withAlpha(Color.lock.border, 0.14)
  readonly property color ink: Color.lock.text
  readonly property color dim: lock.withAlpha(Color.lock.text, 0.55)
  readonly property int corner: Math.max(Style.cornerRadius, 14)

  Rectangle { anchors.fill: parent; color: Color.background }

  Image {
    id: wallpaper
    anchors.fill: parent
    source: lock.loadBackground ? lock.fileUrl(lock.backgroundPath) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: width
    sourceSize.height: height
  }
  MultiEffect {
    anchors.fill: wallpaper
    source: wallpaper
    autoPaddingEnabled: false
    blurEnabled: lock.loadBackground && wallpaper.status === Image.Ready
    blur: 0.7
    blurMax: 96
    brightness: -0.08
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  component Tile: Rectangle {
    radius: lock.corner
    color: lock.tile
    border.width: 1
    border.color: lock.edge
  }

  Item {
    id: board
    width: Math.round(Math.min(lock.width * 0.6, lock.u * 82))
    height: Math.round(width * 0.58)
    anchors.centerIn: parent
    readonly property real gap: Math.round(lock.u * 1.3)
    readonly property real col: (width - gap * 2) / 3
    readonly property real row: (height - gap * 2) / 3

    // Clock, two columns by two rows.
    Tile {
      x: 0; y: 0
      width: board.col * 2 + board.gap
      height: board.row * 2 + board.gap
      Column {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: lock.u * 2.4
        spacing: 0
        Text {
          text: lock.clock("HH:mm")
          renderType: Text.CurveRendering
          color: lock.ink
          font.family: lock.displayFont
          font.pixelSize: Math.round(board.row * 1.15)
          font.weight: Font.DemiBold
          lineHeight: 0.9
        }
        Text {
          text: (lock.meridiem.length > 0 ? lock.meridiem + "  ·  " : "") + lock.hostName
          color: lock.dim
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.4)
          font.letterSpacing: 2
        }
      }
      // Seconds as a thin bar along the bottom edge of the tile.
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: lock.u * 1.4
        height: Math.max(2, Math.round(lock.u * 0.35))
        radius: height / 2
        color: lock.withAlpha(lock.ink, 0.12)
        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: parent.width * lock.now.getSeconds() / 59
          radius: parent.radius
          color: Color.lock.borderActive
          Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
      }
    }

    // Date.
    Tile {
      x: (board.col + board.gap) * 2; y: 0
      width: board.col
      height: board.row
      Column {
        anchors.centerIn: parent
        spacing: 0
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(lock.now, "d")
          color: Color.lock.borderActive
          font.family: lock.displayFont
          font.pixelSize: Math.round(board.row * 0.5)
          font.weight: Font.Bold
          lineHeight: 0.95
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(lock.now, "dddd").toUpperCase()
          color: lock.ink
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.35)
          font.letterSpacing: 2
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(lock.now, "MMMM yyyy")
          color: lock.dim
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.2)
        }
      }
    }

    // Greeting with avatar.
    Tile {
      x: (board.col + board.gap) * 2; y: board.row + board.gap
      width: board.col
      height: board.row
      Column {
        anchors.centerIn: parent
        spacing: lock.u * 0.9
        Avatar {
          anchors.horizontalCenter: parent.horizontalCenter
          lock: lock
          width: Math.round(board.row * 0.42)
          shadow: false
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: lock.greeting()
          color: lock.dim
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.25)
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: lock.userName
          color: lock.ink
          font.family: lock.displayFont
          font.pixelSize: Math.round(lock.u * 1.6)
          font.weight: Font.DemiBold
        }
      }
    }

    // The week: today lit in the accent.
    Tile {
      x: 0; y: (board.row + board.gap) * 2
      width: board.col
      height: board.row
      Row {
        anchors.centerIn: parent
        spacing: Math.round(lock.u * 1.35)
        Repeater {
          model: ["M", "T", "W", "T", "F", "S", "S"]
          delegate: Column {
            required property string modelData
            required property int index
            readonly property bool today: index === (lock.now.getDay() + 6) % 7
            spacing: lock.u * 0.9
            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: Math.round(lock.u * 1.7)
              height: width
              radius: width / 2
              color: today ? Color.lock.borderActive : lock.withAlpha(lock.ink, 0.18)
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: modelData
              color: today ? lock.ink : lock.dim
              font.family: lock.displayFont
              font.pixelSize: Math.round(lock.u * 1.5)
              font.weight: today ? Font.Bold : Font.Normal
            }
          }
        }
      }
    }

    // The sign-in, two columns wide.
    Tile {
      x: board.col + board.gap; y: (board.row + board.gap) * 2
      width: board.col * 2 + board.gap
      height: board.row
      PasswordField {
        id: field
        lock: lock
        anchors.centerIn: parent
        width: parent.width - lock.u * 3
        height: Math.min(parent.height - lock.u * 3, lock.u * 4.6)
        color: lock.withAlpha(Color.background, 0.35)
        radius: lock.corner - 4
        placeholder: "Enter password"
      }
    }
  }
}

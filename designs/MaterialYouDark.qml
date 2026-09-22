// source: qylock
// name: Material You Dark
// description: Dark Material palette · Google Sans font
// Faithful port of Darkkal44's qylock "material-you-dark" theme
// (github.com/Darkkal44/qylock, GPL-3.0). The QML is written from scratch
// against Omarchy's DesignBase/LockInput, not copied from qylock's GPL
// source, and drops the SDDM-specific power/session/reboot/sleep tile grid
// and multi-user switcher in favor of the shared single password field.
// The source's bundled Google Sans variable font tested clean at UI sizes
// (every glyph in "THE QUICK BROWN FOX WELCOME" unambiguous) so it is used
// throughout, matching the original.
import QtQuick
import Quickshell
import qs.Commons

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("material-you-dark-assets/")

  // Original qylock Material You dark palette (purple/lavender).
  property color hourColor: "#E6E1E5"
  property color minuteColor: "#CBC2DB"
  property color datePillBg: "#3A3247"
  property color cardBg: "#1C1B20"
  property color fieldBg: "#2B2930"
  property color textDark: "#E6E1E5"
  property color textMuted: "#958DA5"
  property color errorRed: "#FFB4AB"
  property color pillBg: "#2B2930"
  property color unlockBg: "#3A3247"
  property color unlockText: "#E6E1E5"
  property color focusBorder: "#D0BCFF"

  FontLoader {
    id: gsansFont
    source: lock.assetsUrl + "font/GoogleSans.ttf"
  }
  readonly property string sansFont: gsansFont.name.length > 0 ? gsansFont.name : Style.font.family

  Rectangle { anchors.fill: parent; color: "#131218" }

  Image {
    anchors.fill: parent
    source: lock.loadBackground ? lock.assetsUrl + "bg.png" : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Row {
    anchors.centerIn: parent
    spacing: 96

    // Left: stacked hour/minute clock + date pill.
    Column {
      spacing: 24
      anchors.verticalCenter: parent.verticalCenter

      Column {
        spacing: -24
        Text {
          text: lock.clock("hh")
          font.family: lock.sansFont
          font.pixelSize: 130
          font.weight: Font.Bold
          color: lock.hourColor
        }
        Text {
          text: lock.clock("mm")
          font.family: lock.sansFont
          font.pixelSize: 130
          font.weight: Font.Bold
          color: lock.minuteColor
        }
      }

      Rectangle {
        width: datePillText.implicitWidth + 32
        height: 44
        radius: 22
        color: lock.datePillBg
        Text {
          id: datePillText
          anchors.centerIn: parent
          text: Qt.formatDate(lock.now, "dddd, MMM d").toUpperCase()
          font.family: lock.sansFont
          font.pixelSize: 11
          font.bold: true
          font.letterSpacing: 1
          color: lock.hourColor
        }
      }
    }

    // Right: notification-style login card.
    Rectangle {
      width: 376
      height: 176
      radius: 32
      color: lock.cardBg
      anchors.verticalCenter: parent.verticalCenter

      Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Row {
          width: parent.width
          spacing: 8
          Text {
            text: "󰌾"
            font.family: Style.font.family
            font.pixelSize: 12
            color: lock.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: "SYSTEM UI"
            font.family: lock.sansFont
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
            color: lock.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: "•  now"
            font.family: lock.sansFont
            font.pixelSize: 10
            color: lock.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Rectangle {
          width: parent.width
          height: 52
          radius: 26
          color: lock.fieldBg
          border.color: lock.errorState ? lock.errorRed : (passwordInput.activeFocus ? lock.focusBorder : "transparent")
          border.width: 2
          Behavior on border.color { ColorAnimation { duration: 150 } }

          LockInput {
            id: passwordInput
            lock: lock
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            color: lock.textDark
            font.family: lock.sansFont
            font.pixelSize: 18
            font.letterSpacing: 6
            passwordCharacter: "•"
            selectionColor: "#4F4461"
            cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
            cursorDelegate: Rectangle { width: 2; color: lock.focusBorder; visible: passwordInput.cursorVisible }
          }

          Text {
            anchors.centerIn: parent
            text: lock.errorState ? lock.failureMessage.toUpperCase() : (lock.authenticatingPassword ? "CHECKING…" : "PASSWORD REQUIRED")
            font.family: lock.sansFont
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.5
            color: lock.errorState ? lock.errorRed : lock.textMuted
            opacity: passwordInput.text.length === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
        }

        Row {
          width: parent.width
          spacing: 12

          Rectangle {
            width: userText.implicitWidth + 32
            height: 38
            radius: 19
            color: lock.pillBg
            Text {
              id: userText
              anchors.centerIn: parent
              text: lock.userName.toUpperCase()
              font.family: lock.sansFont
              font.pixelSize: 10
              font.bold: true
              font.letterSpacing: 1
              color: lock.textDark
            }
          }

          Item {
            width: parent.width - (userText.implicitWidth + 32) - 12
            height: 38

            Rectangle {
              anchors.right: parent.right
              width: parent.width
              height: 38
              radius: 19
              color: unlockMa.pressed ? "#2B2238" : (unlockMa.containsMouse ? "#4F4461" : lock.unlockBg)
              Behavior on color { ColorAnimation { duration: 150 } }

              Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                  text: lock.authenticatingPassword ? "…" : "UNLOCK"
                  font.family: lock.sansFont
                  font.pixelSize: 10
                  font.bold: true
                  font.letterSpacing: 1.5
                  color: lock.unlockText
                  anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                  text: "➔"
                  font.family: lock.sansFont
                  font.pixelSize: 11
                  color: lock.unlockText
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: unlockMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var submitted = lock.passwordText
                  if (submitted.length > 0) {
                    lock.passwordTextEdited("")
                    lock.submitPassword(submitted)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

// source: qylock
// Original design inspired by Darkkal44's qylock "nothing" theme
// (github.com/Darkkal44/qylock, GPL-3.0), styled after Nothing OS's
// dot-matrix/glyph look. Bundles the source's NDot55 and NType82 fonts
// (bundled alongside this file in nothing-assets/font/) for a true-to-
// source feel. The QML itself is written from scratch against Omarchy's
// DesignBase/LockInput, not copied from qylock's GPL source, and drops the
// SDDM-specific multi-user/session/power grid (Omarchy handles auth
// elsewhere) in favor of the shared single password field.
//
// Both bundled fonts were rendered directly (independent of Qt) against
// the full "THE QUICK BROWN FOX JUMPS OVER LAZY DOG" pangram and every
// glyph came back unambiguous, including NDot55's dot-matrix capital C/O
// pair, so both are safe to use for word labels as well as digits. This
// design still keeps NDot55 for the big clock/glyphs and NType82 for
// everything else, matching the source's own split.
import QtQuick
import Quickshell
import qs.Commons
import "../plugins/io.github.sirjul1337.lock-explorer/designs"

DesignBase {
  id: lock
  inputItem: passwordInput

  readonly property string assetsUrl: Qt.resolvedUrl("nothing-assets/")

  // Original qylock "nothing" palette.
  property color panel: "#111111"
  property color panelBorder: "#2a2a2a"
  property color red: "#ea1821"
  property color textDim: "#888888"

  FontLoader { id: dotFont; source: lock.assetsUrl + "font/NDot55.otf" }
  FontLoader { id: typeFont; source: lock.assetsUrl + "font/NType82.otf" }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#e8ebed" }
      GradientStop { position: 1.0; color: "#d2d6d9" }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { lock.wakeRequested(); lock.forcePasswordFocus() }
    onPositionChanged: lock.wakeRequested()
  }

  Row {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: 40
    spacing: 8
    Rectangle { width: 8; height: 8; radius: 4; color: "#111111"; anchors.verticalCenter: parent.verticalCenter }
    Text {
      text: "AUTHENTICATE"
      font.family: dotFont.name
      font.pixelSize: 20
      font.letterSpacing: 2
      color: "#111111"
    }
  }

  Row {
    anchors.centerIn: parent
    spacing: 24

    // Clock card
    Rectangle {
      width: 280; height: 280
      radius: 40
      color: lock.panel

      Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -16
        spacing: 2
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: lock.clock("HH")
          font.family: dotFont.name
          font.pixelSize: 92
          font.letterSpacing: 4
          color: "#ffffff"
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(lock.now, "mm")
          font.family: dotFont.name
          font.pixelSize: 92
          font.letterSpacing: 4
          color: lock.red
        }
      }

      Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        Text {
          text: Qt.formatDate(lock.now, "dddd").toUpperCase()
          font.family: typeFont.name
          font.pixelSize: 11
          font.letterSpacing: 1
          font.bold: true
          color: lock.textDim
        }
        Text {
          text: Qt.formatDate(lock.now, "MMM d").toUpperCase()
          font.family: typeFont.name
          font.pixelSize: 11
          font.letterSpacing: 1
          font.bold: true
          color: "#ffffff"
        }
      }
    }

    // Login card
    Rectangle {
      id: loginCard
      width: 320; height: 280
      radius: 40
      color: lock.panel

      transform: Translate { id: shakeT }
      Connections {
        target: lock
        function onFailureMessageChanged() {
          if (lock.failureMessage.length === 0) return
          nothingShake.restart()
        }
      }
      SequentialAnimation {
        id: nothingShake
        NumberAnimation { target: shakeT; property: "x"; from: 0; to: 12; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; from: 12; to: -12; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; from: -12; to: 8; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; from: 8; to: 0; duration: 45 }
      }

      Column {
        anchors.centerIn: parent
        spacing: 24
        width: 250

        // Username pill
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: userText.implicitWidth + 48
          height: 40
          radius: 20
          color: "#222222"
          border.color: "#2a2a2a"
          border.width: 1
          Row {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "•"; color: lock.red; font.family: typeFont.name; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
            Text {
              id: userText
              text: lock.userName.toUpperCase()
              color: "#ffffff"
              font.family: typeFont.name
              font.pixelSize: 16
              font.letterSpacing: 1
              anchors.verticalCenter: parent.verticalCenter
            }
            Text { text: "•"; color: lock.red; font.family: typeFont.name; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
          }
        }

        // Password field
        Rectangle {
          width: parent.width
          height: 52
          radius: 26
          color: passwordInput.activeFocus ? "#1a1a1a" : "#222222"
          border.color: lock.errorState ? lock.red : (passwordInput.activeFocus ? "#ffffff" : "#2a2a2a")
          border.width: 1.5
          Behavior on border.color { ColorAnimation { duration: 150 } }

          LockInput {
            id: passwordInput
            lock: lock
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            font.family: typeFont.name
            font.pixelSize: 16
            font.letterSpacing: 4
            color: "#ffffff"
            passwordCharacter: "•"
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            selectionColor: "#d0d4d8"
            cursorVisible: activeFocus && text.length > 0 && !lock.authenticatingPassword && !lock.errorState
            cursorDelegate: Rectangle { width: 2; color: lock.red; visible: passwordInput.cursorVisible }
          }

          Text {
            anchors.centerIn: parent
            text: lock.errorState ? lock.failureMessage : (lock.authenticatingPassword ? "CHECKING…" : "PASSWORD")
            font.family: typeFont.name
            font.pixelSize: 11
            font.letterSpacing: 1
            color: lock.errorState ? lock.red : lock.textDim
            opacity: passwordInput.text.length === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
        }

        // Unlock button
        Rectangle {
          id: unlockBtn
          width: parent.width
          height: 52
          radius: 26
          color: unlockMouse.pressed ? "#e0e0e0" : (unlockMouse.containsMouse ? "#ffffff" : "#ffffff")
          scale: unlockMouse.pressed ? 0.97 : 1.0
          Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

          Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
              text: "UNLOCK"
              font.family: typeFont.name
              font.pixelSize: 14
              font.letterSpacing: 2
              font.bold: true
              color: "#111111"
            }
            Text { text: "→"; font.family: typeFont.name; font.pixelSize: 16; color: "#111111" }
          }
          MouseArea {
            id: unlockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (passwordInput.text.length > 0) lock.submitPassword(passwordInput.text)
          }
        }
      }
    }
  }

  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 28
    anchors.horizontalCenter: parent.horizontalCenter
    text: lock.fingerprintConfigured ? "Touch sensor or type password" : "Type password · Enter to unlock"
    color: "#666666"
    font.family: typeFont.name
    font.pixelSize: 11
    font.letterSpacing: 1
  }
}

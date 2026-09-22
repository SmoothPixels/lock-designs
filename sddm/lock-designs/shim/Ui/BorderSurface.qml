// Stand-in for the shell's BorderSurface: a rectangle whose border follows a
// Border spec, with the same inset properties the components read.
import QtQuick
import "../Commons"

Rectangle {
  id: root
  property var borderSpec: Border.none()
  property real padding: 0
  property real topPadding: padding
  property real rightPadding: padding
  property real bottomPadding: padding
  property real leftPadding: padding

  readonly property real borderTop: Border.top(borderSpec)
  readonly property real borderRight: Border.right(borderSpec)
  readonly property real borderBottom: Border.bottom(borderSpec)
  readonly property real borderLeft: Border.left(borderSpec)
  readonly property real contentTopInset: borderTop + topPadding
  readonly property real contentRightInset: borderRight + rightPadding
  readonly property real contentBottomInset: borderBottom + bottomPadding
  readonly property real contentLeftInset: borderLeft + leftPadding
  readonly property bool usesOverlayBorder: false

  border.width: borderSpec && borderSpec.width ? borderSpec.width : 0
  border.color: borderSpec && borderSpec.color ? borderSpec.color : "transparent"
}

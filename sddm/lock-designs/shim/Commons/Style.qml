// Stand-in for the shell's Style singleton: the font tokens and corner radius
// the designs read. The family comes from theme.conf.user.
pragma Singleton
import QtQuick

QtObject {
  id: root
  property string fontFamily: "monospace"
  property int fontBaseSize: 12
  property int cornerRadius: 8
  property int gapsOut: 5

  function space(px) { return px }

  readonly property QtObject font: QtObject {
    readonly property string family: root.fontFamily
    readonly property string resolvedFamily: root.fontFamily
    readonly property string menuFamily: root.fontFamily
    readonly property int baseSize: root.fontBaseSize
    readonly property int caption: Math.round(root.fontBaseSize * 0.833)
    readonly property int bodySmall: Math.round(root.fontBaseSize * 0.917)
    readonly property int body: root.fontBaseSize
    readonly property int subtitle: Math.round(root.fontBaseSize * 1.083)
    readonly property int title: Math.round(root.fontBaseSize * 1.167)
    readonly property int heading: Math.round(root.fontBaseSize * 1.333)
    readonly property int display: root.fontBaseSize * 2
    readonly property int icon: Math.round(root.fontBaseSize * 1.167)
  }
  readonly property QtObject spacing: QtObject {
    readonly property int sm: 4
    readonly property int md: 6
    readonly property int lg: 8
    readonly property int xl: 10
    readonly property int controlGap: 8
    readonly property int panelPadding: 18
  }
}

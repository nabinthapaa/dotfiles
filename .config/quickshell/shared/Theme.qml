import QtQml
import QtQuick
import "../theme"

QtObject {
  readonly property int barHeight: 44
  readonly property int barPadding: 10
  readonly property int gap: 8
  readonly property int iconSize: 18
  readonly property int controlSize: 28
  readonly property int panelWidth: 360
  readonly property int radius: 12
  readonly property int radiusSmall: 8
  readonly property int radiusLarge: 18

  readonly property color background: Matugen.background
  readonly property color surface: Matugen.surfaceContainer
  readonly property color surfaceHover: Matugen.surfaceContainerHigh
  readonly property color surfaceHigh: Matugen.surfaceContainerHighest
  readonly property color panel: Matugen.surface
  readonly property color foreground: Matugen.onSurfaceColor
  readonly property color muted: Matugen.onSurfaceVariantColor
  readonly property color accent: Matugen.primary
  readonly property color accentForeground: Matugen.onPrimaryColor
  readonly property color accentContainer: Matugen.primaryContainer
  readonly property color accentContainerForeground: Matugen.onPrimaryContainerColor
  readonly property color secondary: Matugen.secondary
  readonly property color secondaryContainer: Matugen.secondaryContainer
  readonly property color border: Matugen.outlineVariant
  readonly property color outline: Matugen.outline
  readonly property color urgent: Matugen.errorColor
  readonly property color warning: Matugen.warning
}

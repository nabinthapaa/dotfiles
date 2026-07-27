import QtQml
import QtQuick
import "../theme"

QtObject {
  // ── Bar geometry ──────────────────────────────────────────────────
  readonly property int barHeight: 48          // exclusiveZone + window height
  readonly property int islandHeight: 34       // visible pill height
  readonly property int islandPaddingH: 10     // left/right padding inside an island
  readonly property int islandPaddingV: 4      // top/bottom padding inside an island
  readonly property int islandGap: 6           // spacing between top-level bar sections
  readonly property int gap: 6                 // spacing between items inside an island

  // ── Radii ─────────────────────────────────────────────────────────
  readonly property int radius: 10
  readonly property int radiusSmall: 6
  readonly property int radiusLarge: 18       // popup cards, large containers
  readonly property int radiusPill: 999       // buttons, islands, chips

  // ── Sizes ─────────────────────────────────────────────────────────
  readonly property int iconSize: 16
  readonly property int controlSize: 26
  readonly property int panelWidth: 360

  // ── Colors (mapped from Matugen Material You roles) ───────────────
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

  // ── Island background (92% opaque surface container) ─────────────
  readonly property color islandBg: Qt.rgba(surface.r, surface.g, surface.b, 0.92)
  readonly property color islandBorder: border
}

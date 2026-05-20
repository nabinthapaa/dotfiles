pragma Singleton

import QtQuick

QtObject {
    readonly property string background: "{{colors.background.default.hex}}"
    readonly property string surface: "{{colors.surface.default.hex}}"
    readonly property string surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property string surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    readonly property string surfaceContainerHighest: "{{colors.surface_container_highest.default.hex}}"
    readonly property string primary: "{{colors.primary.default.hex}}"
    readonly property string onPrimaryColor: "{{colors.on_primary.default.hex}}"
    readonly property string primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property string onPrimaryContainerColor: "{{colors.on_primary_container.default.hex}}"
    readonly property string secondary: "{{colors.secondary.default.hex}}"
    readonly property string secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property string onSurfaceColor: "{{colors.on_surface.default.hex}}"
    readonly property string onSurfaceVariantColor: "{{colors.on_surface_variant.default.hex}}"
    readonly property string outline: "{{colors.outline.default.hex}}"
    readonly property string outlineVariant: "{{colors.outline_variant.default.hex}}"
    readonly property string errorColor: "{{colors.error.default.hex}}"
    readonly property string warning: "{{colors.tertiary.default.hex}}"
}

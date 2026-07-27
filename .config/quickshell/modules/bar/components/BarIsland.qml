// BarIsland.qml — Pill-shaped floating container for bar groups.
// Consumers set implicitWidth from outside. Children anchor inside the island.
import QtQuick
import "../../../shared"

Rectangle {
  id: root

  implicitHeight: theme.islandHeight
  radius: theme.radiusPill
  color: theme.islandBg
  border.width: 1
  border.color: Qt.rgba(theme.islandBorder.r,
                        theme.islandBorder.g,
                        theme.islandBorder.b,
                        0.30)

  Theme { id: theme }
}

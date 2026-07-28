import QtQuick
import "../../../shared"

Row {
  id: root

  required property var menu
  required property var sourceFilters
  signal triggerSearch()

  width: parent.width
  height: 30
  spacing: 8

  Theme { id: theme }

  Repeater {
    model: root.sourceFilters

    Rectangle {
      required property var modelData
      readonly property bool active: menu.sourceFilter === modelData.key

      width: Math.max(78, filterLabel.implicitWidth + 24)
      height: parent.height
      radius: theme.radiusLarge
      color: active ? theme.accentContainer : filterArea.containsMouse ? theme.surfaceHover : theme.surface
      border.width: 1
      border.color: active ? theme.accent : theme.border

      Text {
        id: filterLabel
        anchors.centerIn: parent
        text: parent.modelData.label
        color: parent.active ? theme.accentContainerForeground : theme.foreground
        font.pixelSize: 11
        font.weight: Font.DemiBold
      }

      MouseArea {
        id: filterArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          menu.sourceFilter = parent.modelData.key;
          menu.searchToken += 1;
          root.triggerSearch();
        }
      }
    }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: menu.hasAurHelper ? "AUR helper: " + menu.aurHelper : "AUR install disabled: paru/yay missing"
    color: menu.hasAurHelper ? theme.muted : theme.warning
    font.pixelSize: 11
    font.weight: Font.Medium
  }
}

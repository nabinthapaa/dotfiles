import QtQuick
import "../../../shared"

Rectangle {
  id: root

  required property var menu

  radius: theme.radiusLarge
  color: theme.surface
  border.width: 1
  border.color: theme.border
  clip: true

  Theme { id: theme }

  Text {
    anchors.centerIn: parent
    width: parent.width - 32
    text: menu.loading ? "Searching packages" : menu.errorMessage.length > 0 ? menu.errorMessage : menu.sourceFilter === "installed" && menu.query.trim().length === 0 ? "Installed packages" : "No packages found"
    color: menu.errorMessage.length > 0 ? theme.urgent : theme.muted
    horizontalAlignment: Text.AlignHCenter
    font.pixelSize: 13
    visible: menu.results.length === 0
  }

  ListView {
    id: resultList
    anchors.fill: parent
    anchors.margins: 8
    model: menu.results
    clip: true
    spacing: 6
    visible: menu.results.length > 0
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: menu.selectedIndex

    delegate: Rectangle {
      id: resultRow
      required property var modelData
      required property int index
      readonly property bool selected: menu.selectedIndex === index

      width: resultList.width
      height: 76
      radius: theme.radiusLarge
      color: selected ? theme.accentContainer : rowArea.containsMouse ? theme.surfaceHover : "transparent"

      Column {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Row {
          width: parent.width
          height: 18
          spacing: 8

          Text {
            width: parent.width - sourceBadge.width - installedText.implicitWidth - 24
            text: resultRow.modelData.name || ""
            color: resultRow.selected ? theme.accentContainerForeground : theme.foreground
            elide: Text.ElideRight
            font.pixelSize: 13
            font.weight: Font.DemiBold
          }

          Rectangle {
            id: sourceBadge
            width: sourceText.implicitWidth + 14
            height: 18
            radius: theme.radiusSmall
            color: resultRow.selected ? theme.accent : theme.surfaceHigh

            Text {
              id: sourceText
              anchors.centerIn: parent
              text: menu.sourceLabel(resultRow.modelData)
              color: resultRow.selected ? theme.accentForeground : theme.muted
              font.pixelSize: 9
              font.weight: Font.DemiBold
            }
          }

          Text {
            id: installedText
            text: menu.installedLabel(resultRow.modelData)
            color: resultRow.selected ? theme.accentContainerForeground : theme.accent
            visible: text.length > 0
            font.pixelSize: 10
            font.weight: Font.DemiBold
          }
        }

        Text {
          width: parent.width
          text: (resultRow.modelData.version || "") + (resultRow.modelData.description ? "  " + resultRow.modelData.description : "")
          color: resultRow.selected ? theme.accentContainerForeground : theme.muted
          elide: Text.ElideRight
          font.pixelSize: 11
        }
      }

      MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: menu.selectedIndex = index
        onClicked: {
          menu.selectedIndex = index;
          menu.fetchSelectedDetails();
        }
      }
    }
  }
}

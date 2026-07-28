import QtQuick
import "../../../shared"

Rectangle {
  id: root

  required property var menu

  radius: theme.radiusLarge
  color: theme.surfaceHigh
  border.width: 1
  border.color: theme.border
  clip: true

  Theme { id: theme }

  Text {
    anchors.centerIn: parent
    width: parent.width - 32
    text: menu.detailLoading ? "Loading package details" : menu.detailError.length > 0 ? menu.detailError : "Select a package"
    color: menu.detailError.length > 0 ? theme.urgent : theme.muted
    horizontalAlignment: Text.AlignHCenter
    font.pixelSize: 13
    visible: !menu.detail
  }

  Flickable {
    anchors.fill: parent
    anchors.margins: 14
    clip: true
    contentWidth: width
    contentHeight: detailColumn.height
    visible: !!menu.detail
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: detailColumn
      width: parent.width
      spacing: 12

      Row {
        width: parent.width
        spacing: 10

        Column {
          width: parent.width - actionColumn.width - parent.spacing
          spacing: 5

          Text {
            width: parent.width
            text: menu.detail ? menu.detail.name : ""
            color: theme.foreground
            elide: Text.ElideRight
            font.pixelSize: 21
            font.weight: Font.DemiBold
          }

          Text {
            width: parent.width
            text: menu.detail ? [menu.detail.version || "unknown", menu.sourceLabel(menu.detail), menu.detail.installed ? "installed" : "not installed"].join("  ") : ""
            color: theme.muted
            elide: Text.ElideRight
            font.pixelSize: 12
            font.weight: Font.Medium
          }
        }

        Column {
          id: actionColumn
          width: 154
          spacing: 6

          Repeater {
            model: [
              { label: "Install", action: "install", visible: menu.detail && !menu.detail.installed },
              { label: "Remove", action: "remove", visible: menu.detail && menu.detail.installed },
              { label: menu.detail && menu.detail.installed ? "Update/Reinstall" : "Reinstall", action: "update", visible: menu.detail && menu.detail.installed },
              { label: "View PKGBUILD", action: "pkgbuild", visible: menu.detail && menu.detail.source === "aur" },
              { label: "Open AUR", action: "aur-page", visible: menu.detail && menu.detail.source === "aur" },
              { label: "Copy name", action: "copy-name", visible: !!menu.detail }
            ]

            Rectangle {
              required property var modelData
              readonly property bool allowed: menu.actionAllowed(modelData.action, menu.detail)

              width: parent.width
              height: modelData.visible ? 30 : 0
              radius: theme.radiusLarge
              visible: modelData.visible
              color: allowed ? actionArea.containsMouse ? theme.accent : theme.accentContainer : theme.surface
              border.width: 1
              border.color: allowed ? theme.accent : theme.border

              Text {
                anchors.centerIn: parent
                text: parent.modelData.label
                color: parent.allowed ? theme.accentContainerForeground : theme.muted
                elide: Text.ElideRight
                font.pixelSize: 11
                font.weight: Font.DemiBold
              }

              MouseArea {
                id: actionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.allowed ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: menu.runAction(parent.modelData.action)
              }
            }
          }
        }
      }

      Text {
        width: parent.width
        text: menu.detail ? (menu.detail.description || "No description available.") : ""
        color: theme.foreground
        wrapMode: Text.WordWrap
        font.pixelSize: 13
      }

      Repeater {
        model: menu.detail ? [
          { label: "Maintainer", value: menu.detail.maintainer || "Unknown", visible: menu.detail.source === "aur" },
          { label: "Votes", value: (menu.detail.votes || 0).toString(), visible: menu.detail.source === "aur" },
          { label: "Popularity", value: (menu.detail.popularity || 0).toString(), visible: menu.detail.source === "aur" },
          { label: "Out of date", value: menu.detail.outOfDate ? "Yes" : "No", visible: menu.detail.source === "aur" },
          { label: "Last updated", value: menu.dateText(menu.detail.lastModified), visible: menu.detail.source === "aur" },
          { label: "License", value: menu.arrayText(menu.detail.license), visible: true },
          { label: "Dependencies", value: menu.arrayText(menu.detail.depends), visible: true },
          { label: "Optional dependencies", value: menu.arrayText(menu.detail.optDepends), visible: true },
          { label: "Provides", value: menu.arrayText(menu.detail.provides), visible: true },
          { label: "Conflicts", value: menu.arrayText(menu.detail.conflicts), visible: true }
        ] : []

        Column {
          required property var modelData
          width: parent.width
          spacing: 3
          visible: modelData.visible

          Text {
            width: parent.width
            text: parent.modelData.label
            color: theme.muted
            font.pixelSize: 10
            font.weight: Font.DemiBold
          }

          Text {
            width: parent.width
            text: parent.modelData.value
            color: theme.foreground
            wrapMode: Text.WordWrap
            font.pixelSize: 12
          }
        }
      }
    }
  }
}

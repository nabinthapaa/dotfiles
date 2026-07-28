import Quickshell
import QtQuick
import "../../../../shared"

Item {
  id: root

  required property var modelData
  required property int index
  required property int selectedIndex
  required property bool popupOpen

  signal hoverEntered(int index)
  signal launchClicked(var entry)

  readonly property bool selected: root.selectedIndex === root.index

  Theme { id: theme }

  function iconSource(entry) {
    if (!entry || !entry.icon || entry.icon.length === 0) {
      return "";
    }
    if (entry.icon.indexOf("/") >= 0 || entry.icon.indexOf(":") >= 0) {
      return entry.icon;
    }
    const resolved = Quickshell.iconPath(entry.icon, true);
    return resolved.length > 0 ? resolved : "";
  }

  Item {
    anchors.fill: parent
    opacity: root.popupOpen ? 1 : 0
    y: root.popupOpen ? 0 : 20

    Behavior on opacity {
      SequentialAnimation {
        PauseAnimation { duration: root.popupOpen ? Math.min(root.index * 15, 300) : 0 }
        NumberAnimation { duration: 150 }
      }
    }

    Behavior on y {
      SequentialAnimation {
        PauseAnimation { duration: root.popupOpen ? Math.min(root.index * 15, 300) : 0 }
        NumberAnimation {
          duration: 350
          easing.type: Easing.OutExpo
        }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: parent.width - 12
      height: parent.height - 12
      radius: theme.radiusLarge
      color: root.selected
        ? theme.accentContainer
        : appArea.containsMouse ? theme.surfaceHover : "transparent"

      Column {
        anchors.centerIn: parent
        spacing: 12
        visible: !root.modelData.isCalculatorResult

        Image {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 52
          height: 52
          source: root.iconSource(root.modelData)
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
          visible: source.toString().length > 0
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "󰣆"
          color: root.selected ? theme.accentContainerForeground : theme.muted
          font.pixelSize: 32
          visible: root.iconSource(root.modelData).length === 0
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.parent.width - 16
          text: root.modelData.name
          color: root.selected ? theme.accentContainerForeground : theme.foreground
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
          maximumLineCount: 1
          font.pixelSize: 12
          font.weight: root.selected ? Font.DemiBold : Font.Medium
        }
      }

      Text {
        anchors.centerIn: parent
        width: parent.width - 16
        text: root.modelData.name
        color: root.selected ? theme.accentContainerForeground : theme.foreground
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 2
        wrapMode: Text.Wrap
        font.pixelSize: 22
        font.weight: root.selected ? Font.Bold : Font.DemiBold
        visible: !!root.modelData.isCalculatorResult
      }

      MouseArea {
        id: appArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hoverEntered(root.index)
        onClicked: root.launchClicked(root.modelData)
      }
    }
  }
}

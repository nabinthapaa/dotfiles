import QtQuick
import Quickshell
import "../../shared"

Item {
  id: root
  
  required property var workspace
  required property var allClients
  required property int selectedWorkspaceId
  required property real targetWidth
  required property real targetHeight
  property var gridRoot

  signal workspaceClicked(int id)
  
  Theme { id: theme }

  readonly property bool isSelected: root.selectedWorkspaceId === root.workspace.id
  readonly property bool isHovered: mouseArea.containsMouse
  
  property real monitorWidth: 1920
  property real monitorHeight: 1080
  property real monitorX: 0
  property real monitorY: 0

  // Calculate scale factor: how much to shrink the monitor to fit the card
  readonly property real scaleX: root.targetWidth / root.monitorWidth
  readonly property real scaleY: root.targetHeight / root.monitorHeight
  readonly property real scaleFactor: Math.min(scaleX, scaleY)

  width: root.targetWidth
  height: root.targetHeight
  
  scale: isSelected ? 1.05 : (isHovered ? 1.02 : 1.0)
  Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
  
  // Glow for selected
  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: theme.radiusLarge + 4
    color: "transparent"
    border.color: theme.accent
    border.width: 3
    opacity: root.isSelected ? 0.6 : 0
    Behavior on opacity { NumberAnimation { duration: 250 } }
  }

  Rectangle {
    id: cardBackground
    anchors.fill: parent
    radius: theme.radiusLarge
    color: root.isSelected ? theme.accentContainer : (root.isHovered ? theme.surfaceHover : theme.surface)
    border.color: root.isSelected ? theme.accent : theme.border
    border.width: root.isSelected ? 2 : 1
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    clip: true

    property var filteredClients: root.workspace ? root.allClients.filter(c => c && c.workspace && c.workspace.id === root.workspace.id) : []

    Repeater {
      model: cardBackground.filteredClients.length
      delegate: WindowPreview {
        required property int index
        client: cardBackground.filteredClients[index]
        scaleFactor: root.scaleFactor
        monitorX: root.monitorX
        monitorY: root.monitorY
        gridRoot: root.gridRoot
      }
    }
    
    // Empty state placeholder
    Text {
      anchors.centerIn: parent
      text: "󰇄" // Some icon
      font.pixelSize: 48
      color: theme.muted
      opacity: root.workspace.exists ? 0 : 0.3
      visible: opacity > 0
    }
  }

  // Massive workspace number in background
  Text {
    anchors.centerIn: parent
    text: root.workspace.name
    color: theme.foreground
    opacity: 0.15
    font.pixelSize: Math.min(root.height, root.width) * 0.4
    font.weight: Font.Bold
    z: -1
  }

  // Workspace Number (small top-left)
  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 12
    width: 32
    height: 32
    radius: 16
    color: root.isSelected ? theme.accent : theme.background
    visible: cardBackground.filteredClients.length > 0 || root.isSelected // hide if empty, unless selected
    
    Text {
      anchors.centerIn: parent
      text: root.workspace.name
      color: root.isSelected ? theme.accentForeground : theme.foreground
      font.pixelSize: 14
      font.weight: Font.Bold
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.workspaceClicked(root.workspace.id);
    }
  }

  DropArea {
    anchors.fill: parent
    onEntered: {
      console.log("DROP AREA ENTERED for workspace", root.workspace ? root.workspace.id : "null", "gridRoot is:", root.gridRoot);
      if (root.gridRoot && root.workspace) {
        root.gridRoot.draggingTargetWorkspace = root.workspace.id;
        console.log("SET draggingTargetWorkspace to", root.workspace.id);
      }
    }
    onExited: {
      console.log("DROP AREA EXITED for workspace", root.workspace ? root.workspace.id : "null");
      if (root.gridRoot && root.workspace && root.gridRoot.draggingTargetWorkspace === root.workspace.id) {
        root.gridRoot.draggingTargetWorkspace = -1;
      }
    }
  }
}

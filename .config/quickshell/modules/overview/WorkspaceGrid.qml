import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../shared"

Item {
  id: workspaceGridRoot
  
  property int draggingTargetWorkspace: -1
  property alias dragLayer: dragLayerItem
  
  focus: true
  Keys.onRightPressed: {
    if (workspaceGridRoot.selectedIndex < workspaceGridRoot.workspaces.length - 1) {
      workspaceGridRoot.selectedIndex++;
    }
  }
  Keys.onLeftPressed: {
    if (workspaceGridRoot.selectedIndex > 0) {
      workspaceGridRoot.selectedIndex--;
    }
  }
  Keys.onReturnPressed: {
    let ws = workspaceGridRoot.workspaces[workspaceGridRoot.selectedIndex];
    if (ws) {
      if (ws.hw) {
        ws.hw.activate();
      } else {
        Hyprland.dispatch("workspace " + ws.id.toString());
      }
      workspaceGridRoot.closeRequested();
    }
  }
  Keys.onEscapePressed: {
    workspaceGridRoot.closeRequested();
  }
  Keys.onPressed: (event) => {
    if (event.modifiers & Qt.ControlModifier) {
      if (event.key === Qt.Key_N) {
        if (workspaceGridRoot.selectedIndex < workspaceGridRoot.workspaces.length - 1) workspaceGridRoot.selectedIndex++;
        event.accepted = true;
      } else if (event.key === Qt.Key_P) {
        if (workspaceGridRoot.selectedIndex > 0) workspaceGridRoot.selectedIndex--;
        event.accepted = true;
      }
    }
  }
  
  required property var workspaces
  required property var allClients
  property var activeMonitor
  property int selectedIndex: 0
  
  signal closeRequested()

  Theme { id: theme }

  onVisibleChanged: {
    if (visible) {
      let focusIdx = workspaceGridRoot.workspaces.findIndex(w => w.isFocused);
      if (focusIdx >= 0) {
        workspaceGridRoot.selectedIndex = focusIdx;
      }
    }
  }

  readonly property var activeWorkspace: workspaceGridRoot.workspaces[workspaceGridRoot.selectedIndex]
  readonly property var activeWorkspaceClients: activeWorkspace ? workspaceGridRoot.allClients.filter(c => c && c.lastIpcObject && c.lastIpcObject.workspace && c.lastIpcObject.workspace.id === activeWorkspace.id) : []

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    spacing: 16

    GridView {
      id: spacesBar
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.margins: 24
    
    // Fit 5 columns, calculate width based on that
    cellWidth: Math.floor(width / 5)
    // 16:9 aspect ratio relative to cellWidth, plus some padding
    cellHeight: Math.floor(cellWidth * (9/16)) + 24
    
    interactive: true
    clip: true

    model: workspaceGridRoot.workspaces.length
    delegate: Item {
      width: spacesBar.cellWidth
      height: spacesBar.cellHeight

      WorkspaceCard {
        anchors.centerIn: parent
        workspace: workspaceGridRoot.workspaces[index]
        allClients: workspaceGridRoot.allClients
        selectedWorkspaceId: workspaceGridRoot.activeWorkspace ? workspaceGridRoot.activeWorkspace.id : -1
        
        // Large thumbnails filling the cell, minus some padding
        targetWidth: parent.width - 24
        targetHeight: parent.height - 24
        gridRoot: workspaceGridRoot
        
        monitorWidth: workspaceGridRoot.workspaces[index].monitorWidth || 1920
        monitorHeight: workspaceGridRoot.workspaces[index].monitorHeight || 1080
        monitorX: workspaceGridRoot.workspaces[index].monitorX || 0
        monitorY: workspaceGridRoot.workspaces[index].monitorY || 0

        onWorkspaceClicked: {
          workspaceGridRoot.selectedIndex = index;
          if (workspaceGridRoot.workspaces[index].hw) {
            workspaceGridRoot.workspaces[index].hw.activate();
          } else {
            Hyprland.dispatch("workspace", workspaceGridRoot.workspaces[index].id.toString());
          }
          workspaceGridRoot.closeRequested();
        }
      }
      }
    }
    
    Rectangle {
      id: activeWindowsStrip
      Layout.fillWidth: true
      Layout.preferredHeight: 180
      Layout.margins: 24
      color: theme.surface
      radius: 12
      border.color: theme.surfaceHover
      border.width: 1
      clip: true

      // If no windows, show placeholder
      Text {
        anchors.centerIn: parent
        text: "No windows in this workspace"
        color: theme.muted
        font.pixelSize: 16
        visible: activeWorkspaceClients.length === 0
      }

      Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: row.implicitWidth
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        
        Row {
          id: row
          spacing: 16
          height: parent.height
          
          Repeater {
            model: activeWorkspaceClients.length
            
            Item {
              property var ipc: activeWorkspaceClients[index] ? activeWorkspaceClients[index].lastIpcObject : null
              property var s: ipc ? (ipc.size || [16, 9]) : [16, 9]
              property real aspectRatio: s[1] > 0 ? (s[0] / s[1]) : (16/9)
              
              width: Math.max(100, Math.round(height * aspectRatio))
              height: row.height
              
              WindowPreview {
                client: activeWorkspaceClients[index]
                gridRoot: workspaceGridRoot
                absolutePositioning: false
                radius: 8
                width: parent.width
                height: parent.height
              }
            }
          }
        }
      }
    }
  }
  
  Item {
    id: dragLayerItem
    anchors.fill: parent
    z: 1000
  }
}

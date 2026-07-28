import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../shared"

PanelWindow {
  id: root
  
  // Span the entire screen
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  

  
  WlrLayershell.layer: WlrLayer.Overlay
  HyprlandFocusGrab {
    active: controller.open
    windows: [ root ]
    onCleared: closeOverview()
  }
  
  // Make it fully transparent base
  color: "transparent"
  
  // Don't show if closed
  visible: controller.open || opacity > 0.01

  Theme { id: theme }

  OverviewController {
    id: controller
  }

  // A function the children can call to close the overview
  function closeOverview() {
    controller.open = false;
  }

  // The blurred background
  Rectangle {
    id: background
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.4) // fallback dimming
    opacity: controller.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 250 } }
    
    // We would use a blur component if Quickshell exposes one (e.g. WlrLayerShell blur),
    // but a dimming rectangle works great for a glassmorphism feel without intense GPU cost.
    // Let's add a subtle gradient to make it look premium.
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.7) }
      GradientStop { position: 1.0; color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.9) }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: closeOverview()
    }
  }

  WorkspaceGrid {
    id: grid
    anchors.fill: parent
    workspaces: controller.workspaces
    allClients: controller.clients
    activeMonitor: root.screen
    property bool isOpen: controller.open
    
    opacity: controller.open ? 1 : 0
    
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    onCloseRequested: closeOverview()
  }

  // Handle focus when toggled
  onVisibleChanged: {
    if (visible) {
      grid.forceActiveFocus();
    }
  }
}

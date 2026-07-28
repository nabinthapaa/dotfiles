import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../shared"

Rectangle {
  id: root
  
  required property var client
  property real scaleFactor: 1.0
  property real monitorX: 0
  property real monitorY: 0
  
  property bool absolutePositioning: true
  property var gridRoot

  Theme { id: theme }

  readonly property var ipc: client ? client.lastIpcObject : null
  readonly property var at: ipc ? (ipc.at || [0, 0]) : [0, 0]
  readonly property var size: ipc ? (ipc.size || [0, 0]) : [0, 0]

  x: absolutePositioning ? (at[0] - monitorX) * scaleFactor : 0
  y: absolutePositioning ? (at[1] - monitorY) * scaleFactor : 0
  width: absolutePositioning ? (size[0] * scaleFactor) : parent.width
  height: absolutePositioning ? (size[1] * scaleFactor) : parent.height
  
  radius: theme.radiusMedium * (absolutePositioning ? scaleFactor : 1)
  color: theme.surface
  border.color: theme.surfaceHover
  border.width: 1

  // Small shadow for windows
  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: "transparent"
    border.color: "#33000000"
    border.width: 2
    z: -1
  }

  // Smooth animations for moving windows, but disable during drag to avoid fighting the mouse
  Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
  Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
  Behavior on width { enabled: !dragArea.drag.active; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
  Behavior on height { enabled: !dragArea.drag.active; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

  ScreencopyView {
    anchors.fill: parent
    anchors.margins: 2
    captureSource: root.client ? root.client.wayland : null
    live: true
    
    // Dim the screencopy slightly so the icon pops
    Rectangle {
      anchors.fill: parent
      color: "black"
      opacity: 0.3
      radius: parent.radius
    }
  }

  Image {
    anchors.centerIn: parent
    width: Math.min(64 * (root.absolutePositioning ? root.scaleFactor : 1), root.width * 0.5)
    height: width
    function getIcon() {
      if (!root.ipc) return Quickshell.iconPath("application-x-executable", "image-missing");
      let cls = root.ipc["class"] || root.ipc["initialClass"] || "";
      
      let entry = DesktopEntries.heuristicLookup(cls);
      
      let raw = entry ? (entry.icon || "").trim() : "";
      let withoutProviderPrefix = raw.replace(/^image:\/\/icon\//, "");
      let withoutQuery = withoutProviderPrefix.split("?")[0].trim();
      
      let iconName = withoutQuery.length > 0 ? withoutQuery : cls;
      if (iconName.length === 0) {
          iconName = "application-x-executable";
      }
      
      if (iconName.indexOf("/") >= 0 || iconName.indexOf(":") >= 0) {
          if (iconName.startsWith("/")) return "file://" + iconName;
          return iconName;
      }

      return Quickshell.iconPath(iconName, "image-missing");
    }
    source: getIcon()
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
  }

  property var homeParent
  Component.onCompleted: homeParent = parent

  MouseArea {
    id: dragArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    drag.target: parent
    preventStealing: true
    
    onPressed: (mouse) => {
      console.log("DRAG PRESSED");
      let dragL = root.gridRoot ? root.gridRoot.dragLayer : null;
      if (!dragL) {
        console.log("NO DRAG LAYER FOUND! gridRoot:", root.gridRoot);
        return;
      }
      let mapped = root.mapToItem(dragL, 0, 0);
      let w = root.width;
      let h = root.height;
      root.parent = dragL;
      root.x = mapped.x;
      root.y = mapped.y;
      root.width = w;
      root.height = h;
      root.Drag.active = true;
      root.Drag.source = root;
      root.Drag.hotSpot.x = mouse.x;
      root.Drag.hotSpot.y = mouse.y;
      console.log("DRAG STARTED on", root.ipc ? root.ipc.class : "unknown");
    }
    
    onReleased: {
      console.log("DRAG RELEASED");
      let target = root.gridRoot ? root.gridRoot.draggingTargetWorkspace : -1;
      console.log("TARGET WORKSPACE IS:", target);
      root.Drag.active = false;
      
      root.parent = homeParent;
      root.x = Qt.binding(() => absolutePositioning ? (root.at[0] - root.monitorX) * root.scaleFactor : 0);
      root.y = Qt.binding(() => absolutePositioning ? (root.at[1] - root.monitorY) * root.scaleFactor : 0);
      root.width = Qt.binding(() => absolutePositioning ? (root.size[0] * root.scaleFactor) : (homeParent ? homeParent.width : 100));
      root.height = Qt.binding(() => absolutePositioning ? (root.size[1] * root.scaleFactor) : (homeParent ? homeParent.height : 100));
      
      if (target !== -1 && root.ipc && root.ipc.workspace && target !== root.ipc.workspace.id) {
         console.log("MOVING WINDOW TO", target);
         Hyprland.dispatch("movetoworkspacesilent " + target.toString() + ",address:" + root.ipc.address);
      } else if (!dragArea.drag.active) {
         console.log("DRAG FAILED, FALLING BACK TO FOCUS");
         if (client && root.ipc) {
           Hyprland.dispatch("focuswindow address:" + root.ipc.address);
         }
         let p = root.parent;
         while(p && !p.closeRequested) p = p.parent;
         if (p && p.closeRequested) p.closeRequested();
      }
      if (root.gridRoot) {
        root.gridRoot.draggingTargetWorkspace = -1;
        console.log("RESET draggingTargetWorkspace to -1");
      }
    }
  }
}

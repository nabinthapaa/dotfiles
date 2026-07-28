import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
  id: root
  property bool open: false
  property var activeMonitor: Hyprland.monitors.values[0]
  property var workspaces: []
  property var clients: []

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() { root.updateModel() }
  }
  
  Connections {
    target: Hyprland.toplevels
    function onValuesChanged() { root.updateModel() }
  }

  Component.onCompleted: updateModel()

  function updateModel() {
    let rawWorkspaces = Hyprland.workspaces.values;
    let rawMonitors = Hyprland.monitors.values;
    let rawToplevels = Hyprland.toplevels.values;
    
    // Parse clients from toplevels
    let modeledClients = [];
    for (let i = 0; i < rawToplevels.length; i++) {
      let tl = rawToplevels[i];
      let ipc = tl.lastIpcObject;
      if (ipc && ipc.mapped && !ipc.hidden && ipc.workspace) {
        modeledClients.push(tl);
      }
    }
    root.clients = modeledClients;
    
    let wss = rawWorkspaces.slice().sort((a, b) => a.id - b.id);
    
    let monMap = {};
    for (let i = 0; i < rawMonitors.length; i++) {
      let m = rawMonitors[i];
      monMap[m.name] = m;
    }

    let maxWorkspaces = 10;
    
    let hwMap = {};
    for (let i = 0; i < wss.length; i++) {
        if (wss[i].id >= 1) hwMap[wss[i].id] = wss[i];
    }
    
    let modeledWorkspaces = [];
    for (let i = 1; i <= maxWorkspaces; i++) {
        let hw = hwMap[i];
        
        let mon = null;
        if (hw) {
            let monName = hw.lastIpcObject ? hw.lastIpcObject.monitor : null;
            mon = monName ? monMap[monName] : null;
            if (!mon && hw.monitor) mon = hw.monitor;
        }
        if (!mon && rawMonitors.length > 0) mon = rawMonitors[0];
        
        let monWidth = mon ? (mon.lastIpcObject ? mon.lastIpcObject.width / mon.lastIpcObject.scale : 1920) : 1920;
        let monHeight = mon ? (mon.lastIpcObject ? mon.lastIpcObject.height / mon.lastIpcObject.scale : 1080) : 1080;
        let monX = mon ? (mon.lastIpcObject ? mon.lastIpcObject.x : 0) : 0;
        let monY = mon ? (mon.lastIpcObject ? mon.lastIpcObject.y : 0) : 0;
        
        modeledWorkspaces.push({
            id: i,
            name: hw ? hw.name : i.toString(),
            isFocused: hw ? hw.focused : false,
            hasFullscreen: hw ? hw.hasFullscreen : false,
            exists: hw ? true : false,
            hw: hw ? hw : null,
            monitorWidth: Math.round(monWidth),
            monitorHeight: Math.round(monHeight),
            monitorX: monX,
            monitorY: monY,
        });
    }
    
    root.workspaces = modeledWorkspaces;
  }

  function refresh() {
    Hyprland.refreshMonitors();
    Hyprland.refreshWorkspaces();
    Hyprland.refreshToplevels();
    updateModel();
  }

  IpcHandler {
    target: "overview." + (root.activeMonitor ? root.activeMonitor.name : "all")

    function open(): void {
      root.refresh();
      root.open = true;
    }

    function close(): void {
      root.open = false;
    }

    function toggle(): void {
      if (!root.open) {
        root.refresh();
      }
      root.open = !root.open;
    }
    
    function isOpen(): bool {
      return root.open;
    }
  }
}

import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property real level: 0

  Component.onCompleted: {
    refresh();
  }

  function refresh() {
    brightnessProc.running = false;
    brightnessProc.running = true;
  }

  function setLevel(newLevel) {
    const clampLevel = Math.max(0, Math.min(1, newLevel));
    level = clampLevel;
    Quickshell.execDetached(["brightnessctl", "set", Math.round(clampLevel * 100) + "%"]);
    refreshTimer.restart();
  }

  Timer {
    id: refreshTimer
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: brightnessProc
    command: ["brightnessctl", "-m"]
    stdout: StdioCollector {
      onStreamFinished: {
        const fields = text.trim().split(",");
        if (fields.length < 4) return;
        
        let percentStr = "";
        for (let i = 0; i < fields.length; i++) {
          if (fields[i].indexOf("%") >= 0) {
            percentStr = fields[i];
            break;
          }
        }
        
        if (percentStr === "") return;
        
        const value = Number(percentStr.replace("%", ""));
        if (!Number.isNaN(value)) {
          root.level = Math.max(0, Math.min(1, value / 100));
        }
      }
    }
  }
}

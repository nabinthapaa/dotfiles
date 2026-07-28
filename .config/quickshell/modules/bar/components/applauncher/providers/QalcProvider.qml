import QtQuick
import Quickshell
import Quickshell.Io

BannerProvider {
  id: root
  
  property string currentQuery: ""

  Process {
    id: qalcProc
    stdout: StdioCollector {
      onStreamFinished: {
        const res = text.trim();
        if (res.length > 0 && res.toLowerCase() !== root.currentQuery.trim().toLowerCase()) {
          root.text = res;
          root.active = true;
        } else {
          root.text = "";
          root.active = false;
        }
      }
    }
  }

  function search(query) {
    const q = query.trim();
    root.currentQuery = q;

    if (q.match(/[0-9+\-*/^=]/) || q.toLowerCase().match(/\bto\b/)) {
      qalcProc.exec(["bash", "-c", "qalc -t '" + q.replace(/'/g, "'\\''") + "' 2>/dev/null || true"]);
    } else {
      root.text = "";
      root.active = false;
    }
  }

  function launch() {
    if (root.active) {
      Quickshell.execDetached(["bash", "-c", "echo -n '" + root.text.replace(/'/g, "'\\''") + "' | wl-copy"]);
    }
  }
}

import QtQuick
import Quickshell
import Quickshell.Io

SearchProvider {
  id: root
  prefix: "f:"
  name: "Files"

  property string currentQuery: ""

  Process {
    id: fdProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.loading = false;
        const lines = text.trim().split("\n").filter(line => line.length > 0);
        
        root.results = lines.map(line => {
          const isDir = line.endsWith("/");
          const cleanPath = isDir ? line.substring(0, line.length - 1) : line;
          const segments = cleanPath.split("/");
          const filename = segments[segments.length - 1];
          
          return {
            name: filename,
            genericName: cleanPath.replace(Quickshell.env("HOME"), "~"),
            comment: "File Search Result",
            icon: isDir ? "folder" : "text-x-generic",
            noDisplay: false,
            path: line,
            isCalculatorResult: false,
          };
        });
      }
    }
  }

  function search(query) {
    const q = query.trim();
    root.currentQuery = q;
    
    if (q.length === 0) {
      root.results = [];
      root.loading = false;
      return;
    }

    root.loading = true;
    fdProc.exec(["bash", "-c", "fd --max-results 30 -t f -t d -p -i '" + q.replace(/'/g, "'\\''") + "' " + Quickshell.env("HOME")]);
  }

  function launch(entry) {
    if (entry && entry.path) {
      Quickshell.execDetached(["xdg-open", entry.path]);
    }
  }
}

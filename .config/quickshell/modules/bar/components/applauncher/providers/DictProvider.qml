import QtQuick
import Quickshell
import Quickshell.Io

BannerProvider {
  id: root

  property string currentQuery: ""

  Process {
    id: dictProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const payload = JSON.parse(text.trim());
          if (payload && payload.length > 0 && payload[0].meanings && payload[0].meanings[0].definitions) {
            root.text = payload[0].meanings[0].definitions[0].definition;
            root.active = true;
          } else {
            root.text = "No definition found.";
            root.active = true;
          }
        } catch (e) {
          root.text = "No definition found.";
          root.active = true;
        }
      }
    }
  }

  function search(query) {
    const q = query.trim();
    root.currentQuery = q;

    if (q.startsWith("def: ") || q.startsWith("dict: ")) {
      const word = q.replace(/^(def|dict):\s*/, "");
      if (word.length > 0) {
        dictProc.exec(["bash", "-c", "curl -s https://api.dictionaryapi.dev/api/v2/entries/en/" + encodeURIComponent(word)]);
      } else {
        root.text = "";
        root.active = false;
      }
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

import QtQuick
import Quickshell

SearchProvider {
  id: root
  prefix: ""
  name: "Applications"

  readonly property var applications: DesktopEntries.applications.values

  function search(query) {
    const searchStr = query.trim().toLowerCase();
    const apps = applications.filter(app => app && !app.noDisplay);

    if (searchStr.length === 0) {
      root.results = apps.sort((a, b) => a.name.localeCompare(b.name));
      return;
    }

    const searchTokens = searchStr.split(/\s+/);

    const scoredApps = apps.map(app => {
      const name = (app.name || "").toLowerCase();
      const generic = (app.genericName || "").toLowerCase();
      const comment = (app.comment || "").toLowerCase();
      const keywords = app.keywords ? app.keywords.join(" ").toLowerCase() : "";
      const categories = app.categories ? app.categories.join(" ").toLowerCase() : "";
      
      let score = 0;
      let matchedAll = true;
      
      for (let i = 0; i < searchTokens.length; i++) {
        const token = searchTokens[i];
        let tokenScore = 0;
        
        if (name === token) tokenScore += 100;
        else if (name.startsWith(token)) tokenScore += 50;
        else if (name.includes(" " + token) || name.includes("-" + token)) tokenScore += 40;
        else if (name.includes(token)) tokenScore += 20;
        
        if (generic === token) tokenScore += 30;
        else if (generic.includes(token)) tokenScore += 15;
        
        if (keywords.includes(token)) tokenScore += 10;
        if (categories.includes(token)) tokenScore += 5;
        if (comment.includes(token)) tokenScore += 2;
        
        if (tokenScore === 0) {
          let searchIdx = 0;
          for (let j = 0; j < name.length && searchIdx < token.length; j++) {
             if (name[j] === token[searchIdx]) searchIdx++;
          }
          if (searchIdx === token.length) {
            tokenScore += 1;
          } else {
            matchedAll = false;
            break;
          }
        }
        score += tokenScore;
      }
      
      return { app: app, score: score, matchedAll: matchedAll };
    });

    root.results = scoredApps
      .filter(item => item.matchedAll && item.score > 0)
      .sort((a, b) => {
        if (b.score !== a.score) return b.score - a.score;
        return a.app.name.localeCompare(b.app.name);
      })
      .map(item => item.app);
  }

  function launch(entry) {
    if (entry) {
      entry.execute();
    }
  }
}

import QtQuick

Item {
  id: root
  
  QalcProvider { id: qalcProvider }
  DictProvider { id: dictProvider }

  property var activeBanner: {
    if (dictProvider.active) return dictProvider;
    if (qalcProvider.active) return qalcProvider;
    return null;
  }

  readonly property bool hasBanner: activeBanner !== null
  readonly property string bannerText: activeBanner ? activeBanner.text : ""

  function search(query) {
    qalcProvider.search(query);
    dictProvider.search(query);
  }

  function launch() {
    if (activeBanner) {
      activeBanner.launch();
    }
  }
}

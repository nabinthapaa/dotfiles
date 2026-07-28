import QtQuick

Item {
  id: root
  property string prefix: ""
  property string name: ""
  property var results: []
  property bool loading: false

  // Overridden by subclasses to perform a search.
  // The query string passed here has the prefix already stripped.
  function search(query) {
    // Default implementation does nothing
  }

  // Overridden by subclasses to handle launching an entry.
  function launch(entry) {
    // Default implementation does nothing
  }
}

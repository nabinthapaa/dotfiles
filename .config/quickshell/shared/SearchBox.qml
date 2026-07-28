import QtQuick

Rectangle {
  id: root

  property string text: ""
  property string icon: "󰍉"
  property alias searchFocus: searchInput.activeFocus

  signal searchTextChanged(string newText)
  signal accepted()
  signal escapePressed()
  signal moveSelection(int direction)

  width: 300
  height: 42
  radius: theme.radiusLarge
  color: theme.surface
  border.width: 1
  border.color: searchInput.activeFocus ? theme.accent : theme.border

  Theme { id: theme }

  function forceActiveFocus() {
    searchInput.forceActiveFocus();
  }

  Row {
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 10

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      color: theme.muted
      font.pixelSize: 15
    }

    TextInput {
      id: searchInput

      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 25
      height: parent.height
      text: root.text
      color: theme.foreground
      selectionColor: theme.accentContainer
      selectedTextColor: theme.accentContainerForeground
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      font.pixelSize: 14

      onTextChanged: {
        root.text = text;
        root.searchTextChanged(text);
      }

      onAccepted: root.accepted()

      Keys.onEscapePressed: root.escapePressed()
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
          root.moveSelection(4);
          event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
          root.moveSelection(-4);
          event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
          root.moveSelection(1);
          event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
          root.moveSelection(-1);
          event.accepted = true;
        }
      }
    }
  }
}

import QtQuick
import "../../shared"

Item {
  id: root

  property bool busy: false
  property bool error: false
  property bool reveal: false
  signal accepted(string password)

  height: 94

  function forceInputFocus() {
    input.forceActiveFocus();
  }

  function clear() {
    input.text = "";
  }

  Theme {
    id: theme
  }

  Rectangle {
    id: field

    width: parent.width
    height: 56
    radius: 28
    color: input.activeFocus ? theme.surfaceHover : theme.surface
    border.width: input.activeFocus ? 2 : 1
    border.color: root.error ? theme.urgent : input.activeFocus ? theme.accent : theme.border

    Behavior on border.color {
      ColorAnimation { duration: 140 }
    }

    TextInput {
      id: input

      anchors.left: parent.left
      anchors.right: revealButton.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.leftMargin: 18
      anchors.rightMargin: 8
      verticalAlignment: TextInput.AlignVCenter
      color: theme.foreground
      selectionColor: theme.accentContainer
      selectedTextColor: theme.accentContainerForeground
      echoMode: root.reveal ? TextInput.Normal : TextInput.Password
      passwordCharacter: "•"
      font.pixelSize: 18
      enabled: !root.busy
      focus: true

      Keys.onEscapePressed: event => event.accepted = true
      onAccepted: {
        const submitted = text;
        text = "";
        root.accepted(submitted);
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length === 0 && !input.activeFocus
        text: "Password"
        color: theme.muted
        font.pixelSize: 14
      }
    }

    Rectangle {
      id: revealButton

      width: 44
      height: 44
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      radius: 22
      color: revealArea.containsMouse ? theme.surfaceHover : "transparent"

      Text {
        anchors.centerIn: parent
        text: root.reveal ? "󰈈" : "󰈉"
        color: theme.muted
        font.pixelSize: 16
      }

      MouseArea {
        id: revealArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.reveal = true
        onReleased: root.reveal = false
        onCanceled: root.reveal = false
      }
    }
  }

  Rectangle {
    anchors.top: field.bottom
    anchors.topMargin: 12
    anchors.horizontalCenter: field.horizontalCenter
    width: 136
    height: 40
    radius: 20
    color: input.text.length > 0 && !root.busy ? theme.accent : theme.surfaceHigh
    opacity: input.text.length > 0 && !root.busy ? 1 : 0.56

    Behavior on color {
      ColorAnimation { duration: 140 }
    }

    Text {
      anchors.centerIn: parent
      text: root.busy ? "Checking" : "Unlock"
      color: input.text.length > 0 && !root.busy ? theme.accentForeground : theme.muted
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }

    MouseArea {
      anchors.fill: parent
      enabled: input.text.length > 0 && !root.busy
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        const submitted = input.text;
        input.text = "";
        root.accepted(submitted);
      }
    }
  }
}

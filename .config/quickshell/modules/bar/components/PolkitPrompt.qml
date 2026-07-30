import QtQuick
import Quickshell
import "../../../shared"

Item {
  id: root
  property var flow: null
  property alias inputFocus: passwordInput.focus

  Theme { id: theme }

  function submitPassword() {
    if (flow && passwordInput.text.length > 0) {
      flow.submit(passwordInput.text);
      Qt.callLater(function() { passwordInput.text = ""; });
    }
  }

  Column {
    anchors.centerIn: parent
    width: parent.width - 48
    spacing: 16

    Column {
      width: parent.width
      spacing: 6

      Text {
        width: parent.width
        text: flow ? flow.message : "Authentication Required"
        color: flow && flow.failed ? theme.urgent : theme.foreground
        font.pixelSize: 15
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }

      Text {
        width: parent.width
        text: flow ? flow.inputPrompt : ""
        color: flow && flow.failed ? theme.urgent : theme.muted
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        visible: text.length > 0
        wrapMode: Text.WordWrap
      }
    }

    Rectangle {
      id: inputRect
      width: parent.width
      height: 42
      color: theme.surfaceHover
      radius: theme.radiusSmall
      border.width: 1
      border.color: passwordInput.activeFocus ? theme.accent : theme.border

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        color: theme.foreground
        font.pixelSize: 15
        echoMode: (flow && !flow.responseVisible) ? TextInput.Password : TextInput.Normal
        clip: true

        onAccepted: root.submitPassword()
      }
    }

    Rectangle {
      id: confirmBtn
      width: parent.width
      height: 42
      color: confirmMouse.pressed ? Qt.darker(theme.accent, 1.2) : theme.accent
      radius: theme.radiusSmall

      Text {
        anchors.centerIn: parent
        text: "Authenticate"
        color: theme.accentForeground
        font.pixelSize: 14
        font.weight: Font.DemiBold
      }

      MouseArea {
        id: confirmMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.submitPassword()
      }
    }
  }

  onVisibleChanged: {
    if (visible && flow && flow.isResponseRequired) {
      passwordInput.text = "";
      passwordInput.forceActiveFocus();
    }
  }

  Connections {
    target: flow
    function onIsResponseRequiredChanged() {
      if (flow && flow.isResponseRequired) {
        passwordInput.text = "";
        passwordInput.forceActiveFocus();
      }
    }
  }
}

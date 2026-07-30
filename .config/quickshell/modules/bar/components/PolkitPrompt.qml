import QtQuick
import Quickshell
import "../../../shared"

Item {
  id: root
  property var flow: null
  property alias inputFocus: passwordInput.focus
  property bool passwordVisible: false

  signal requestWindowFocus()

  Theme { id: theme }

  function submitPassword() {
    if (flow && passwordInput.text.length > 0) {
      flow.submit(passwordInput.text);
      Qt.callLater(function() { passwordInput.text = ""; });
    }
  }

  SequentialAnimation {
    id: shakeAnim
    NumberAnimation { target: mainColumn; property: "anchors.horizontalCenterOffset"; from: 0; to: -10; duration: 40 }
    NumberAnimation { target: mainColumn; property: "anchors.horizontalCenterOffset"; from: -10; to: 10; duration: 40 }
    NumberAnimation { target: mainColumn; property: "anchors.horizontalCenterOffset"; from: 10; to: -10; duration: 40 }
    NumberAnimation { target: mainColumn; property: "anchors.horizontalCenterOffset"; from: -10; to: 10; duration: 40 }
    NumberAnimation { target: mainColumn; property: "anchors.horizontalCenterOffset"; from: 10; to: 0; duration: 40 }
  }

  Column {
    id: mainColumn
    anchors.centerIn: parent
    width: parent.width - 48
    spacing: 12

    // Header Row (App Icon & Close Button)
    Item {
      width: parent.width
      height: 24
      
      Image {
        id: appIcon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        source: flow && flow.iconName ? Quickshell.iconPath(flow.iconName) : ""
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(48, 48)
        visible: source != ""
      }

      Rectangle {
        width: 24
        height: 24
        radius: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: closeMouse.pressed ? theme.surfaceHigh : "transparent"

        Text {
          anchors.centerIn: parent
          text: ""
          color: theme.muted
          font.pixelSize: 14
        }

        MouseArea {
          id: closeMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (flow) {
              flow.cancelAuthenticationRequest();
            }
          }
        }
      }
    }

    // Text Content
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
    }

    // Identity Selection (Only visible if > 1 identity)
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12
      visible: flow && flow.identities && flow.identities.length > 1
      
      Repeater {
        model: flow ? flow.identities : []
        delegate: Rectangle {
          width: 32
          height: 32
          radius: 16
          color: flow && flow.selectedIdentity === modelData ? theme.accent : theme.surfaceHover
          border.width: 1
          border.color: flow && flow.selectedIdentity === modelData ? theme.accent : theme.border

          Text {
            anchors.centerIn: parent
            text: ""
            color: flow && flow.selectedIdentity === modelData ? theme.accentForeground : theme.foreground
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (flow) {
                flow.selectedIdentity = modelData;
              }
            }
          }
        }
      }
    }

    // Input Box with Eye Icon
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
        anchors.rightMargin: 40 // space for eye icon
        verticalAlignment: TextInput.AlignVCenter
        color: theme.foreground
        font.pixelSize: 15
        echoMode: passwordVisible ? TextInput.Normal : ((flow && !flow.responseVisible) ? TextInput.Password : TextInput.Normal)
        clip: true

        onAccepted: root.submitPassword()
        Keys.onEscapePressed: {
          if (flow) flow.cancelAuthenticationRequest();
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.IBeamCursor
          onPressed: {
            root.requestWindowFocus();
            passwordInput.forceActiveFocus();
            mouse.accepted = false;
          }
        }
      }

      // Visibility Toggle
      Item {
        width: 32
        height: 32
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4

        Text {
          anchors.centerIn: parent
          text: root.passwordVisible ? "" : ""
          color: theme.muted
          font.pixelSize: 14
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.passwordVisible = !root.passwordVisible;
            passwordInput.forceActiveFocus();
          }
        }
      }
    }

    // Confirm Button
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
      root.passwordVisible = false;
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
    function onFailedChanged() {
      if (flow && flow.failed) {
        shakeAnim.restart();
        passwordInput.text = "";
      }
    }
  }
}

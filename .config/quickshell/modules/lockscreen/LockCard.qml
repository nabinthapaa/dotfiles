import Quickshell
import QtQuick
import "../../shared"

Item {
  id: root

  required property var controller
  required property var notificationServer

  height: card.height

  Theme {
    id: theme
  }

  property real shakeOffset: 0

  onVisibleChanged: {
    if (visible) {
      appear.restart();
      Qt.callLater(() => passwordField.forceInputFocus());
    }
  }

  Connections {
    target: root.controller

    function onFailureNonceChanged() {
      failureShake.restart();
      passwordField.clear();
      passwordField.forceInputFocus();
    }
  }

  SequentialAnimation {
    id: failureShake
    running: false
    NumberAnimation { target: root; property: "shakeOffset"; to: -10; duration: 45; easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "shakeOffset"; to: 10; duration: 70; easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "shakeOffset"; to: -6; duration: 55; easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 80; easing.type: Easing.OutCubic }
  }

  ParallelAnimation {
    id: appear
    NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
    NumberAnimation { target: card; property: "scale"; from: 0.9; to: 1; duration: 350; easing.type: Easing.OutBack }
    NumberAnimation { target: card; property: "anchors.verticalCenterOffset"; from: 40; to: 0; duration: 350; easing.type: Easing.OutBack }
  }

  Rectangle {
    id: card

    x: root.shakeOffset
    width: parent.width
    height: content.height + 64
    radius: 32
    color: Qt.rgba(theme.surfaceHigh.r, theme.surfaceHigh.g, theme.surfaceHigh.b, 0.78)
    border.width: 1
    border.color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.58)
    clip: true

    Column {
      id: content

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 32
      spacing: 18

      Text {
        width: parent.width
        text: Qt.formatTime(root.controller.currentTime, "HH:mm")
        color: theme.foreground
        font.pixelSize: Math.min(104, root.width * 0.22)
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width
        text: Qt.formatDate(root.controller.currentTime, "dddd, MMMM dd")
        color: theme.muted
        font.pixelSize: 16
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
      }

      Item {
        width: parent.width
        height: 112

        Rectangle {
          id: avatar

          width: 96
          height: 96
          radius: 48
          anchors.horizontalCenter: parent.horizontalCenter
          color: theme.accentContainer
          border.width: 3
          border.color: theme.accent
          clip: true

          Image {
            anchors.fill: parent
            anchors.margins: 3
            source: "file://" + Quickshell.env("HOME") + "/.face"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            text: (Quickshell.env("USER") || "?").slice(0, 1).toUpperCase()
            color: theme.accentContainerForeground
            font.pixelSize: 28
            font.weight: Font.DemiBold
          }
        }

        Text {
          anchors.top: avatar.bottom
          anchors.topMargin: 10
          anchors.horizontalCenter: parent.horizontalCenter
          text: Quickshell.env("USER")
          color: theme.foreground
          font.pixelSize: 15
          font.weight: Font.DemiBold
        }
      }

      PasswordField {
        id: passwordField

        width: Math.min(parent.width, 360)
        anchors.horizontalCenter: parent.horizontalCenter
        busy: root.controller.authInProgress
        error: root.controller.statusText === "Authentication failed" || root.controller.statusText === "Authentication error"
        onAccepted: password => root.controller.submit(password)
      }

      Rectangle {
        width: parent.width
        height: 28
        color: "transparent"

        Text {
          anchors.centerIn: parent
          width: parent.width
          text: root.controller.statusText + (root.controller.attempts > 0 && root.controller.statusText !== "Enter password" ? " (" + root.controller.attempts + ")" : "")
          color: passwordField.error ? theme.urgent : theme.muted
          font.pixelSize: 13
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }
      }

      StatusChips {
        width: parent.width
        lockedSeconds: root.controller.lockedSeconds
      }

      MediaWidget {
        width: parent.width
      }

      Text {
        width: parent.width
        text: root.notificationServer && root.notificationServer.trackedNotifications.values.length > 0
          ? root.notificationServer.trackedNotifications.values.length + " new notifications"
          : ""
        visible: text.length > 0
        color: theme.muted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}

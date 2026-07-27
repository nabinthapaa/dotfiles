import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../../shared"

Scope {
  id: root

  property alias server: notificationServer
  property var toastNotifications: []

  function pushToast(notification) {
    toastNotifications = [notification].concat(toastNotifications).slice(0, 4);
  }

  function removeToast(notification) {
    toastNotifications = toastNotifications.filter(item => item !== notification);
  }

  function notificationIconSource(notification) {
    let icon = notification.appIcon || notification.desktopEntry || "";
    if (icon.length === 0) {
      return "";
    }
    icon = icon.replace(/\.desktop$/, "");

    if (icon.indexOf("/") >= 0 || icon.indexOf(":") >= 0) {
      return icon;
    }

    const resolved = Quickshell.iconPath(icon, true);
    return resolved.length > 0 ? resolved : "";
  }

  function hasActions(notification) {
    return notification.actions && notification.actions.length > 0;
  }

  Theme {
    id: theme
  }

  property string soundPath: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/audio/notification.wav"

  Process {
    id: notificationSound

    command: ["sh", "-c", "if command -v pw-play >/dev/null 2>&1; then exec pw-play \"$1\"; elif command -v paplay >/dev/null 2>&1; then exec paplay \"$1\"; elif command -v canberra-gtk-play >/dev/null 2>&1; then exec canberra-gtk-play -f \"$1\"; fi", "notification-sound", root.soundPath]
  }

  NotificationServer {
    id: notificationServer

    keepOnReload: true
    actionsSupported: true
    actionIconsSupported: true
    imageSupported: true
    bodySupported: true
    persistenceSupported: true

    onNotification: notification => {
      notification.tracked = true;

      if (!notification.lastGeneration) {
        root.pushToast(notification);
        notificationSound.running = false;
        notificationSound.running = true;
      }

      notification.closed.connect(() => root.removeToast(notification));
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: toastWindow

      required property var modelData

      screen: modelData
      implicitWidth: Math.min(theme.panelWidth, Math.max(260, modelData.width - theme.islandPaddingH * 2))
      implicitHeight: toastColumn.height
      color: "transparent"
      visible: root.toastNotifications.length > 0
      aboveWindows: true
      exclusionMode: ExclusionMode.Ignore

      anchors {
        top: true
        right: true
      }

      margins {
        top: theme.barHeight + theme.islandPaddingH
        right: theme.islandPaddingH
      }

      Column {
        id: toastColumn

        width: parent.width
        spacing: theme.gap

        Repeater {
          model: root.toastNotifications

          delegate: Rectangle {
            id: toast

            required property var modelData

            width: parent.width
            height: Math.max(74, toastContent.height + 24)
            radius: theme.radiusLarge
            color: theme.surface
            border.width: 1
            border.color: theme.border

            Timer {
              interval: Math.max(3500, toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : 5000)
              running: true
              repeat: false
              onTriggered: root.removeToast(toast.modelData)
            }

            Image {
              id: appIcon

              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.top: parent.top
              anchors.topMargin: 14
              width: 24
              height: 24
              source: root.notificationIconSource(toast.modelData)
              sourceSize.width: width
              sourceSize.height: height
              visible: String(source).length > 0
              fillMode: Image.PreserveAspectFit
            }

            Column {
              id: toastContent

              anchors.left: parent.left
              anchors.leftMargin: appIcon.visible ? 48 : 12
              anchors.right: dismissButton.left
              anchors.rightMargin: 8
              anchors.top: parent.top
              anchors.topMargin: 12
              spacing: 4

              Text {
                width: parent.width
                text: toast.modelData.summary || toast.modelData.appName || "Notification"
                color: theme.foreground
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: 13
                font.weight: Font.DemiBold
              }

              Text {
                width: parent.width
                text: toast.modelData.body || toast.modelData.appName || ""
                visible: text.length > 0
                color: theme.muted
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: 11
                lineHeight: 1.18
              }

              Column {
                width: parent.width
                height: visible ? implicitHeight : 0
                spacing: 6
                visible: root.hasActions(toast.modelData)

                Repeater {
                  model: toast.modelData.actions

                  delegate: Rectangle {
                    required property var modelData

                    width: parent.width
                    height: 26
                    radius: theme.radiusLarge
                    color: actionArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
                    border.width: 1
                    border.color: theme.border

                    Text {
                      id: actionText

                      anchors.centerIn: parent
                      width: parent.width - 12
                      text: modelData.text
                      color: theme.foreground
                      elide: Text.ElideRight
                      horizontalAlignment: Text.AlignHCenter
                      font.pixelSize: 11
                      font.weight: Font.Medium
                    }

                    MouseArea {
                      id: actionArea

                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        modelData.invoke();
                        root.removeToast(toast.modelData);
                      }
                    }
                  }
                }
              }
            }

            Rectangle {
              id: dismissButton

              anchors.right: parent.right
              anchors.rightMargin: 8
              anchors.top: parent.top
              anchors.topMargin: 8
              width: 24
              height: 24
              radius: theme.radiusLarge
              color: dismissArea.containsMouse ? theme.surfaceHover : "transparent"

              Text {
                anchors.centerIn: parent
                text: "x"
                color: theme.muted
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }

              MouseArea {
                id: dismissArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: toast.modelData.dismiss()
              }
            }

            MouseArea {
              anchors.fill: parent
              anchors.rightMargin: dismissButton.width + 8
              cursorShape: Qt.PointingHandCursor
              onClicked: root.removeToast(toast.modelData)
            }
          }
        }
      }
    }
  }
}

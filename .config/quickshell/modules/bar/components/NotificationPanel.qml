import Quickshell
import QtQuick
import "../../../shared"

Item {
  id: root
  
  required property var notificationServer
  required property var notificationCenter
  
  Theme { id: theme }
  
  Column {
    id: notifColumn
    anchors.fill: parent
    spacing: 12

    Row {
      width: parent.width
      
      Text {
        text: "Notifications"
        color: theme.foreground
        font.pixelSize: 14
        font.weight: Font.DemiBold
      }

      Item {
        width: parent.width - parent.children[0].width - clearAllBtn.width
        height: 1
      }

      Text {
        id: clearAllBtn
        text: "Clear All"
        color: theme.accent
        font.pixelSize: 12
        font.weight: Font.Medium

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const notifs = root.notificationServer.trackedNotifications.values;
            for (let i = 0; i < notifs.length; i++) {
              notifs[i].dismiss();
            }
          }
        }
      }
    }

    ListView {
      width: parent.width
      height: parent.height - 26
      spacing: 8
      clip: true
      
      model: root.notificationServer.trackedNotifications

      delegate: Rectangle {
        required property var modelData
        width: parent.width
        height: Math.max(64, notifItemCol.height + 24)
        radius: theme.radiusLarge
        color: theme.surfaceHover
        border.width: 1
        border.color: theme.border

        Image {
          id: notifIcon
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.top: parent.top
          anchors.topMargin: 12
          width: 24
          height: 24
          source: root.notificationCenter.notificationIconSource(modelData)
          sourceSize.width: width
          sourceSize.height: height
          visible: String(source).length > 0
          fillMode: Image.PreserveAspectFit
        }

        Column {
          id: notifItemCol
          anchors.left: parent.left
          anchors.leftMargin: notifIcon.visible ? 48 : 12
          anchors.right: parent.right
          anchors.rightMargin: 36
          anchors.top: parent.top
          anchors.topMargin: 12
          spacing: 4

          Text {
            width: parent.width
            text: modelData.summary || modelData.appName || "Notification"
            color: theme.foreground
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: modelData.body || ""
            visible: text.length > 0
            color: theme.muted
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            lineHeight: 1.2
          }
        }

        Text {
          id: dismissBtn
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.top: parent.top
          anchors.topMargin: 12
          text: "x"
          color: theme.muted
          font.pixelSize: 14
          font.weight: Font.Bold
          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: modelData.dismiss()
          }
        }

        MouseArea {
          anchors.fill: parent
          anchors.rightMargin: 30
          cursorShape: Qt.PointingHandCursor
          onClicked: modelData.dismiss()
        }
      }
      
      Text {
        anchors.centerIn: parent
        text: "No new notifications"
        color: theme.muted
        font.pixelSize: 13
        font.weight: Font.Medium
        visible: parent.count === 0
      }
    }
  }
}

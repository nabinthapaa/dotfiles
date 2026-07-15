import Quickshell
import QtQuick
import "../../shared"
import "LockActions.js" as LockActions

Item {
  id: root

  property var pendingAction: null
  property bool confirming: pendingAction !== null

  width: confirming ? 280 : actionsRow.width
  height: confirming ? 120 : 44

  Theme {
    id: theme
  }

  Row {
    id: actionsRow

    visible: !root.confirming
    spacing: 8
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    Repeater {
      model: LockActions.actions()

      Rectangle {
        required property var modelData

        width: 44
        height: 44
        radius: 22
        color: actionArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
        border.width: 1
        border.color: theme.border

        Text {
          anchors.centerIn: parent
          text: modelData.icon
          color: theme.foreground
          font.pixelSize: 16
        }

        MouseArea {
          id: actionArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.pendingAction = modelData
        }
      }
    }
  }

  Rectangle {
    id: confirmCard

    visible: root.confirming
    opacity: visible ? 1 : 0
    scale: visible ? 1 : 0.96
    anchors.fill: parent
    radius: 24
    color: theme.surfaceHigh
    border.width: 1
    border.color: theme.border

    Behavior on opacity {
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Column {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 14

      Text {
        width: parent.width
        text: root.pendingAction ? root.pendingAction.label + "?" : ""
        color: theme.foreground
        font.pixelSize: 15
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Rectangle {
          width: 100
          height: 38
          radius: 19
          color: cancelArea.containsMouse ? theme.surfaceHover : theme.surface

          Text {
            anchors.centerIn: parent
            text: "Cancel"
            color: theme.foreground
            font.pixelSize: 12
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: cancelArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pendingAction = null
          }
        }

        Rectangle {
          width: 112
          height: 38
          radius: 19
          color: confirmArea.containsMouse ? theme.accentContainer : theme.accent

          Text {
            anchors.centerIn: parent
            text: "Confirm"
            color: confirmArea.containsMouse ? theme.accentContainerForeground : theme.accentForeground
            font.pixelSize: 12
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: confirmArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              const command = LockActions.commandFor(root.pendingAction.key);
              root.pendingAction = null;
              if (command.length > 0) {
                Quickshell.execDetached(command);
              }
            }
          }
        }
      }
    }
  }
}

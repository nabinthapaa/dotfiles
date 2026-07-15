import Quickshell.Services.Mpris
import QtQuick
import "../../shared"

Rectangle {
  id: root

  readonly property int playerCount: Mpris.players.values.length
  readonly property var player: playerCount > 0 ? Mpris.players.values[0] : null

  visible: player !== null
  height: visible ? 72 : 0
  radius: theme.radiusLarge
  color: theme.surface
  border.width: 1
  border.color: theme.border
  opacity: visible ? 1 : 0

  Theme {
    id: theme
  }

  Behavior on opacity {
    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
  }

  Row {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 10

    Rectangle {
      width: 52
      height: 52
      radius: 14
      color: theme.surfaceHigh
      clip: true

      Image {
        anchors.fill: parent
        source: root.player ? root.player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: String(source).length > 0
      }

      Text {
        anchors.centerIn: parent
        visible: !parent.children[0].visible
        text: "󰎆"
        color: theme.muted
        font.pixelSize: 20
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 52 - controls.width - parent.spacing * 2
      spacing: 4

      Text {
        width: parent.width
        text: root.player ? (root.player.trackTitle || root.player.identity || "Unknown Title") : ""
        color: theme.foreground
        elide: Text.ElideRight
        font.pixelSize: 12
        font.weight: Font.DemiBold
      }

      Text {
        width: parent.width
        text: root.player ? (root.player.trackArtist || root.player.identity || "Unknown Artist") : ""
        color: theme.muted
        elide: Text.ElideRight
        font.pixelSize: 11
      }
    }

    Row {
      id: controls

      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Repeater {
        model: [
          { icon: "󰒮", enabled: root.player && root.player.canGoPrevious, action: "previous" },
          { icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊", enabled: root.player && root.player.canTogglePlaying, action: "toggle" },
          { icon: "󰒭", enabled: root.player && root.player.canGoNext, action: "next" }
        ]

        Rectangle {
          required property var modelData

          width: 28
          height: 28
          radius: 14
          color: mediaArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
          opacity: modelData.enabled ? 1 : 0.42

          Text {
            anchors.centerIn: parent
            text: modelData.icon
            color: theme.foreground
            font.pixelSize: 14
          }

          MouseArea {
            id: mediaArea
            anchors.fill: parent
            enabled: modelData.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (modelData.action === "previous") {
                root.player.previous();
              } else if (modelData.action === "next") {
                root.player.next();
              } else {
                root.player.togglePlaying();
              }
            }
          }
        }
      }
    }
  }
}

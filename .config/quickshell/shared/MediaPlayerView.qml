import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris

Item {
  id: root

  required property var player
  property bool showBlurBackground: false

  implicitHeight: 72

  Theme {
    id: theme
  }

  Image {
    id: bgImg
    anchors.fill: parent
    source: root.player ? (root.player.trackArtUrl || "") : ""
    fillMode: Image.PreserveAspectCrop
    visible: false
  }

  FastBlur {
    anchors.fill: parent
    source: bgImg
    radius: 32
    visible: root.showBlurBackground && String(bgImg.source).length > 0
  }

  Rectangle {
    anchors.fill: parent
    color: root.showBlurBackground 
      ? Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.75) 
      : "transparent"
  }

  Row {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 12

    Rectangle {
      width: 52
      height: 52
      anchors.verticalCenter: parent.verticalCenter
      radius: 14
      color: theme.surfaceHover
      clip: true

      Image {
        anchors.fill: parent
        source: root.player ? (root.player.trackArtUrl || "") : ""
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
        text: root.player ? (root.player.trackTitle || root.player.identity || "Unknown Title") : "Unknown Title"
        color: theme.foreground
        elide: Text.ElideRight
        font.pixelSize: 13
        font.weight: Font.DemiBold
      }

      Text {
        width: parent.width
        text: root.player ? (root.player.trackArtist || root.player.identity || "Unknown Artist") : "Unknown Artist"
        color: theme.muted
        elide: Text.ElideRight
        font.pixelSize: 11
        font.weight: Font.Medium
      }
    }

    Row {
      id: controls
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      Repeater {
        model: [
          { icon: "󰒮", enabled: root.player && root.player.canGoPrevious, action: "previous" },
          { icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊", enabled: root.player && root.player.canTogglePlaying, action: "toggle" },
          { icon: "󰒭", enabled: root.player && root.player.canGoNext, action: "next" }
        ]

        Rectangle {
          required property var modelData

          width: 32
          height: 32
          radius: 16
          color: mediaArea.containsMouse ? theme.surfaceHover : "transparent"
          opacity: modelData.enabled ? 1 : 0.42

          Text {
            anchors.centerIn: parent
            text: modelData.icon
            color: modelData.action === "toggle" && modelData.enabled ? theme.accent : theme.foreground
            font.pixelSize: modelData.action === "toggle" ? 20 : 16
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

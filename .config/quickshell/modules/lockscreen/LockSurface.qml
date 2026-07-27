import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../shared"

WlSessionLockSurface {
  id: surface

  required property var controller
  required property var notificationServer
  property bool fullCard: true

  color: theme.background

  Theme {
    id: theme
  }

  Image {
    anchors.fill: parent
    source: "file://" + Quickshell.env("HOME") + "/.cache/wal/blurred_wallpaper.png"
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.48)
  }

  Rectangle {
    width: Math.min(surface.width * 0.64, 720)
    height: width
    radius: width / 2
    anchors.centerIn: fullCard ? card : compactClock
    color: theme.accent
    opacity: 0.10
  }

  LockCard {
    id: card

    controller: surface.controller
    notificationServer: surface.notificationServer
    visible: surface.fullCard
    opacity: visible ? 1 : 0
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.horizontalCenterOffset: surface.width >= 1100 ? -Math.min(180, surface.width * 0.10) : 0
    width: Math.min(Math.max(420, surface.width * 0.32), 520)
  }

  Column {
    id: compactClock

    visible: !surface.fullCard
    anchors.centerIn: parent
    spacing: 10

    Text {
      width: Math.min(surface.width - 64, 520)
      text: Qt.formatTime(surface.controller.currentTime, "HH:mm")
      color: theme.foreground
      font.pixelSize: Math.min(120, surface.width * 0.15)
      font.weight: Font.Bold
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      width: parent.width
      text: Qt.formatDate(surface.controller.currentTime, "dddd, MMMM dd")
      color: theme.muted
      font.pixelSize: 17
      font.weight: Font.Medium
      horizontalAlignment: Text.AlignHCenter
    }
  }

  PowerActions {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 28
    anchors.bottomMargin: 28
  }

  Row {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 28
    anchors.bottomMargin: 30
    spacing: 8
    opacity: 0.72

    Text {
      text: Quickshell.env("HOSTNAME") || "localhost"
      color: theme.muted
      font.pixelSize: 12
      font.weight: Font.Medium
    }

    Text {
      text: "Hyprland"
      color: theme.muted
      font.pixelSize: 12
      font.weight: Font.Medium
    }
  }
}

import Quickshell.Networking
import Quickshell.Services.UPower
import QtQuick
import "../../shared"

Row {
  id: root

  property int lockedSeconds: 0

  height: 30
  spacing: 8
  layoutDirection: Qt.LeftToRight

  Theme {
    id: theme
  }

  function laptopBattery() {
    const devices = UPower.devices.values;
    for (let index = 0; index < devices.length; index++) {
      if (devices[index].isLaptopBattery) {
        return devices[index];
      }
    }

    return UPower.displayDevice && UPower.displayDevice.ready && UPower.displayDevice.isPresent
      ? UPower.displayDevice
      : null;
  }

  function batteryText() {
    const battery = laptopBattery();
    if (!battery || !battery.ready || !battery.isPresent) {
      return "";
    }

    const percent = battery.percentage <= 1 ? Math.round(battery.percentage * 100) : Math.round(battery.percentage);
    return percent + "%";
  }

  function wifiText() {
    const devices = Networking.devices.values;
    for (let deviceIndex = 0; deviceIndex < devices.length; deviceIndex++) {
      const device = devices[deviceIndex];
      if (!device.networks) {
        continue;
      }

      const networks = device.networks.values;
      for (let networkIndex = 0; networkIndex < networks.length; networkIndex++) {
        if (networks[networkIndex].connected) {
          return networks[networkIndex].name;
        }
      }
    }

    return Networking.wifiEnabled ? "Wi-Fi" : "Offline";
  }

  function lockedText() {
    if (lockedSeconds < 60) {
      return "Just locked";
    }

    return Math.floor(lockedSeconds / 60) + "m locked";
  }

  Repeater {
    model: [
      { icon: "󰖩", label: root.wifiText() },
      { icon: "󰁹", label: root.batteryText() },
      { icon: "󰌌", label: root.lockedText() }
    ].filter(chip => chip.label.length > 0)

    Rectangle {
      required property var modelData

      width: chipRow.implicitWidth + 20
      height: 30
      radius: 15
      color: theme.surface
      border.width: 1
      border.color: theme.border

      Row {
        id: chipRow

        anchors.centerIn: parent
        spacing: 6

        Text {
          text: modelData.icon
          color: theme.muted
          font.pixelSize: 13
        }

        Text {
          text: modelData.label
          color: theme.muted
          font.pixelSize: 11
          font.weight: Font.Medium
        }
      }
    }
  }
}

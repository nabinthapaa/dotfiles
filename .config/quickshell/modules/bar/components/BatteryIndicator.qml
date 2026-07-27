// BatteryIndicator.qml — Compact icon + percentage label, hidden when absent.
import Quickshell.Services.UPower
import QtQuick
import "../../../shared"

Row {
  id: root

  spacing: 4
  visible: available

  Theme { id: theme }

  readonly property var battery: findLaptopBattery()
  readonly property bool available: battery !== null && battery.ready && battery.isPresent
  readonly property int percent: available ? normalized(battery.percentage) : 0
  readonly property string state: available ? UPowerDeviceState.toString(battery.state) : "Unknown"
  readonly property bool charging: state === "Charging" || state === "PendingCharge"
  readonly property bool full: state === "FullyCharged" || percent >= 100
  readonly property bool low: !charging && percent <= 15

  function findLaptopBattery() {
    const devices = UPower.devices.values;
    for (let i = 0; i < devices.length; i++) {
      if (devices[i].isLaptopBattery) return devices[i];
    }
    if (UPower.displayDevice && UPower.displayDevice.ready && UPower.displayDevice.isPresent) {
      return UPower.displayDevice;
    }
    return null;
  }

  function normalized(v) {
    return Math.max(0, Math.min(100, Math.round(v <= 1 ? v * 100 : v)));
  }

  function icon() {
    if (charging || full) return "󰂄";
    if (percent <= 10) return "󰁺";
    if (percent <= 20) return "󰁻";
    if (percent <= 30) return "󰁼";
    if (percent <= 40) return "󰁽";
    if (percent <= 50) return "󰁾";
    if (percent <= 60) return "󰁿";
    if (percent <= 70) return "󰂀";
    if (percent <= 80) return "󰂁";
    if (percent <= 90) return "󰂂";
    return "󰁹";
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.icon()
    font.pixelSize: 14
    font.family: "Symbols Nerd Font"
    color: root.low ? theme.urgent : root.charging ? theme.accent : theme.foreground
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.percent + "%"
    font.pixelSize: 11
    font.weight: Font.Medium
    color: root.low ? theme.urgent : theme.foreground
  }
}

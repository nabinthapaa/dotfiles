import Quickshell.Services.UPower
import QtQuick
import "../../../shared"

Item {
  id: root

  readonly property var battery: laptopBattery()
  readonly property bool available: battery !== null && battery.ready && battery.isPresent
  readonly property int percent: available ? normalizePercentage(battery.percentage) : 0
  readonly property string state: available ? UPowerDeviceState.toString(battery.state) : "Unknown"
  readonly property bool charging: state === "Charging" || state === "PendingCharge"
  readonly property bool full: state === "FullyCharged" || percent >= 100
  readonly property bool low: !charging && percent <= 15

  width: visible ? batteryRow.implicitWidth : 0
  height: theme.controlSize
  visible: available

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

  function normalizePercentage(value) {
    if (value <= 1) {
      value = value * 100;
    }

    return Math.max(0, Math.min(100, Math.round(value)));
  }

  function batteryIcon() {
    if (charging) {
      return "󰂄";
    }
    if (full) {
      return "󰁹";
    }
    if (percent <= 10) {
      return "󰁺";
    }
    if (percent <= 20) {
      return "󰁻";
    }
    if (percent <= 30) {
      return "󰁼";
    }
    if (percent <= 40) {
      return "󰁽";
    }
    if (percent <= 50) {
      return "󰁾";
    }
    if (percent <= 60) {
      return "󰁿";
    }
    if (percent <= 70) {
      return "󰂀";
    }
    if (percent <= 80) {
      return "󰂁";
    }
    if (percent <= 90) {
      return "󰂂";
    }
    return "󰁹";
  }

  Theme {
    id: theme
  }

  Row {
    id: batteryRow

    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.batteryIcon()
      color: root.low ? theme.warning : theme.foreground
      font.pixelSize: 15
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.percent + "%"
      color: root.low ? theme.warning : theme.foreground
      font.pixelSize: 12
      font.weight: Font.Medium
    }
  }
}

.pragma library

function actions() {
  return [
    { key: "suspend", label: "Suspend", icon: "󰤄" },
    { key: "reboot", label: "Restart", icon: "󰜉" },
    { key: "shutdown", label: "Shutdown", icon: "⏻" },
    { key: "logout", label: "Logout", icon: "󰍃" }
  ];
}

function commandFor(key) {
  if (key === "suspend") {
    return ["systemctl", "suspend"];
  }
  if (key === "reboot") {
    return ["systemctl", "reboot"];
  }
  if (key === "shutdown") {
    return ["systemctl", "poweroff"];
  }
  if (key === "logout") {
    return ["hyprctl", "dispatch", "exit"];
  }

  return [];
}

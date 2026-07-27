import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import "../../../shared"

PanelWindow {
  id: root

  required property var panelScreen
  required property var notificationServer
  required property var osd
  property bool open: false
  property bool powerPageOpen: false
  property bool animatePages: true
  property bool nightLightEnabled: false
  property bool dndEnabled: false
  property string lowerTab: "notifications"
  property real brightnessLevel: 0
  property int currentPlayerIndex: 0

  readonly property int panelLeft: width - panel.width
  readonly property int panelClosedX: width
  readonly property int playerCount: Mpris.players.values.length
  readonly property var currentPlayer: playerCount > 0
    ? Mpris.players.values[Math.max(0, Math.min(currentPlayerIndex, playerCount - 1))]
    : null

  onWidthChanged: {
    if (!open && !closeAnimation.running) {
      panel.x = panelClosedX;
    }
  }

  screen: panelScreen
  visible: open || closeAnimation.running
  color: "transparent"
  focusable: true
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
    right: true
    bottom: true
    left: true
  }

  Theme {
    id: theme
  }

  IpcHandler {
    target: "controlPanel." + root.panelScreen.name

    function open(): void {
      root.open = true;
    }

    function close(): void {
      root.open = false;
    }

    function toggle(): void {
      root.open = !root.open;
    }

    function isOpen(): bool {
      return root.open;
    }

    function screen(): string {
      return root.panelScreen.name;
    }
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  Component.onCompleted: refreshBrightness()

  onOpenChanged: {
    if (open) {
      closeAnimation.stop();
      powerPageOpen = false;
      resetPages();
      panel.x = panelClosedX;
      panel.forceActiveFocus();
      openStartTimer.restart();
    } else {
      openStartTimer.stop();
      openAnimation.stop();
      closeAnimation.restart();
    }
  }

  function togglePowerPage() {
    setPowerPage(!powerPageOpen);
  }

  function interactiveSurface(active, hovered) {
    return active
      ? theme.accentContainer
      : hovered ? theme.surfaceHover : theme.surfaceHigh;
  }

  function interactiveForeground(active) {
    return active ? theme.accentContainerForeground : theme.foreground;
  }

  function interactiveSupport(active) {
    return active ? theme.accentContainerForeground : theme.muted;
  }

  function resetPages() {
    animatePages = false;
    controlsGrid.x = 0;
    powerPage.x = controlsSwitchViewport.width;
    animatePages = true;
  }

  function setPowerPage(showPower) {
    if (showPower === powerPageOpen) {
      return;
    }

    powerPageOpen = showPower;

    if (showPower) {
      controlsGrid.x = -controlsSwitchViewport.width;
      powerPage.x = 0;
    } else {
      powerPage.x = controlsSwitchViewport.width;
      controlsGrid.x = 0;
    }
  }

  function connectedWifiName() {
    const devices = Networking.devices.values;
    for (let deviceIndex = 0; deviceIndex < devices.length; deviceIndex++) {
      const device = devices[deviceIndex];
      if (!device.networks) {
        continue;
      }

      const networks = device.networks.values;
      for (let networkIndex = 0; networkIndex < networks.length; networkIndex++) {
        const network = networks[networkIndex];
        if (network.connected) {
          return network.name;
        }
      }
    }

    return "";
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

  function notificationHasActions(notification) {
    return notification.actions && notification.actions.length > 0;
  }

  function connectedBluetoothName() {
    if (!Bluetooth.defaultAdapter) {
      return "";
    }

    const devices = Bluetooth.defaultAdapter.devices.values.filter(device => device.connected);
    if (devices.length === 0) {
      return "";
    }

    return devices.map(device => device.deviceName || device.name).join(", ");
  }

  function controlActive(kind) {
    if (kind === "wifi") {
      return Networking.wifiEnabled;
    }
    if (kind === "bluetooth") {
      return Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled;
    }
    if (kind === "night") {
      return nightLightEnabled;
    }
    if (kind === "dnd") {
      return dndEnabled;
    }
    return false;
  }

  function controlStatus(kind) {
    if (kind === "wifi") {
      const name = connectedWifiName();
      return name === "" ? "Not connected" : name;
    }
    if (kind === "bluetooth") {
      const name = connectedBluetoothName();
      return name === "" ? "Not connected" : name;
    }
    if (kind === "night") {
      return nightLightEnabled ? "On" : "Off";
    }
    if (kind === "dnd") {
      return dndEnabled ? "On" : "Off";
    }
    return "";
  }

  function toggleControl(kind) {
    if (kind === "wifi") {
      Networking.wifiEnabled = !Networking.wifiEnabled;
      osd.showAirplane(!Networking.wifiEnabled);
    } else if (kind === "bluetooth" && Bluetooth.defaultAdapter) {
      Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    } else if (kind === "night") {
      setNightLight(!nightLightEnabled);
    } else if (kind === "dnd") {
      dndEnabled = !dndEnabled;
      osd.showSilent(dndEnabled);
    } else if (kind === "screenshot") {
      root.open = false;
      screenshotMenuTimer.restart();
    } else {
      console.log("Control action requested:", kind);
    }
  }

  function clampLevel(level) {
    return Math.max(0, Math.min(1, level));
  }

  function sliderLevel(kind) {
    if (kind === "mic") {
      return Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio
        ? clampLevel(Pipewire.defaultAudioSource.audio.volume)
        : 0;
    }
    if (kind === "audio") {
      return Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? clampLevel(Pipewire.defaultAudioSink.audio.volume)
        : 0;
    }
    if (kind === "brightness") {
      return clampLevel(brightnessLevel);
    }
    return 0;
  }

  function setSliderLevel(kind, level) {
    const nextLevel = clampLevel(level);

    if (kind === "mic" && Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
      Pipewire.defaultAudioSource.audio.volume = nextLevel;
      Pipewire.defaultAudioSource.audio.muted = nextLevel === 0;
      osd.showMic(nextLevel, Pipewire.defaultAudioSource.audio.muted);
    } else if (kind === "audio" && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
      Pipewire.defaultAudioSink.audio.volume = nextLevel;
      Pipewire.defaultAudioSink.audio.muted = nextLevel === 0;
      osd.showVolume(nextLevel, Pipewire.defaultAudioSink.audio.muted);
    } else if (kind === "brightness") {
      brightnessLevel = nextLevel;
      Quickshell.execDetached(["brightnessctl", "set", Math.round(nextLevel * 100) + "%"]);
      brightnessRefreshTimer.restart();
      osd.showBrightness(nextLevel);
    }
  }

  function setPowerProfile(profile) {
    if (profile === "performance" && PowerProfiles.hasPerformanceProfile) {
      PowerProfiles.profile = PowerProfile.Performance;
    } else if (profile === "power-saver") {
      PowerProfiles.profile = PowerProfile.PowerSaver;
    } else {
      PowerProfiles.profile = PowerProfile.Balanced;
      profile = "balanced";
    }

    osd.showPowerProfile(profile);
  }

  function showPreviousPlayer() {
    if (playerCount <= 1) {
      return;
    }

    currentPlayerIndex = (currentPlayerIndex + playerCount - 1) % playerCount;
  }

  function showNextPlayer() {
    if (playerCount <= 1) {
      return;
    }

    currentPlayerIndex = (currentPlayerIndex + 1) % playerCount;
  }

  function setNightLight(enabled) {
    if (enabled) {
      Quickshell.execDetached(["sh", "-c", "hyprctl hyprsunset temperature 4500 || hyprsunset -t 4500"]);
      nightLightEnabled = true;
    } else {
      Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
      nightLightEnabled = false;
    }

    nightStatusTimer.restart();
  }

  function refreshNightLightStatus() {
    nightStatusProc.exec(["sh", "-c", "hyprctl -j hyprsunset 2>/dev/null || true"]);
  }

  Timer {
    id: nightStatusTimer
    interval: 800
    running: true
    repeat: true
    onTriggered: root.refreshNightLightStatus()
  }

  Timer {
    id: screenshotMenuTimer
    interval: 220
    repeat: false
    onTriggered: {
      const monitor = Hyprland.monitorFor(root.panelScreen);
      if (monitor) {
        Quickshell.execDetached([
          "qs",
          "-p",
          "~/dotfiles/.config/quickshell/",
          "ipc",
          "call",
          "screenshotMenu." + monitor.name,
          "open"
        ]);
      }
    }
  }

  Process {
    id: nightStatusProc

    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        if (output.length === 0) {
          root.nightLightEnabled = false;
          return;
        }

        try {
          const status = JSON.parse(output);
          root.nightLightEnabled = status.identity === false
            || (typeof status.temperature === "number" && status.temperature < 6500);
        } catch (error) {}
      }
    }
  }

  function refreshBrightness() {
    brightnessProc.exec(["brightnessctl", "-m"]);
  }

  Timer {
    id: brightnessRefreshTimer
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refreshBrightness()
  }

  Timer {
    id: openStartTimer
    interval: 16
    repeat: false
    onTriggered: {
      panel.x = root.panelClosedX;
      openAnimation.restart();
    }
  }

  Process {
    id: brightnessProc

    stdout: StdioCollector {
      onStreamFinished: {
        const fields = text.trim().split(",");
        if (fields.length < 5) {
          return;
        }

        const percentField = fields.find(field => field.indexOf("%") >= 0);
        if (!percentField) {
          return;
        }

        const value = Number(percentField.replace("%", ""));
        if (!Number.isNaN(value)) {
          root.brightnessLevel = root.clampLevel(value / 100);
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.open
    onClicked: root.open = false
  }

  Rectangle {
    id: panel

    x: root.panelClosedX
    y: theme.barHeight
    width: Math.min(theme.panelWidth, root.width)
    height: root.height - theme.barHeight
    radius: 0
    color: theme.panel
    border.width: 0
    focus: root.visible

    Keys.onEscapePressed: root.open = false

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    NumberAnimation {
      id: openAnimation
      target: panel
      property: "x"
      to: root.panelLeft
      duration: 190
      easing.type: Easing.OutCubic
      onStopped: panel.forceActiveFocus()
    }

    NumberAnimation {
      id: closeAnimation
      target: panel
      property: "x"
      to: root.panelClosedX
      duration: 170
      easing.type: Easing.OutCubic
    }

    Column {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      anchors.topMargin: 18
      anchors.bottomMargin: 16
      spacing: 16

      Row {
        width: parent.width
        height: 54
        spacing: 12

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - powerButton.width - parent.spacing
          spacing: 2

          SystemClock {
            id: panelClock
            precision: SystemClock.Minutes
          }

          Text {
            width: parent.width
            text: Qt.formatDateTime(panelClock.date, "HH:mm")
            color: theme.foreground
            elide: Text.ElideRight
            font.pixelSize: 22
            font.weight: Font.DemiBold
          }

          Text {
            width: parent.width
            text: Qt.formatDateTime(panelClock.date, "dddd, MMMM d")
            color: theme.muted
            elide: Text.ElideRight
            font.pixelSize: 12
            font.weight: Font.Medium
          }
        }

        Rectangle {
          id: powerButton

          width: 44
          height: 44
          radius: height / 2
          color: root.powerPageOpen ? theme.accent : closeArea.containsMouse ? theme.accentContainer : theme.surfaceHigh

          Text {
            anchors.centerIn: parent
            text: "⏻"
            color: root.powerPageOpen ? theme.accentForeground : closeArea.containsMouse ? theme.accentContainerForeground : theme.foreground
            font.pixelSize: 18
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.togglePowerPage()
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: theme.border
      }

      Item {
        id: pageViewport

        width: parent.width
        height: parent.height - y
        clip: true

        Column {
          id: controlsPage

          x: 0
          width: parent.width
          height: parent.height
          spacing: theme.gap
          readonly property int switchHeight: 68 * 3 + theme.gap * 2

          readonly property int lowerContentHeight: Math.max(
            180,
            height - controlsSwitchViewport.height - tabDivider.height - tabRow.height - spacing * 3
          )

          Item {
            id: controlsSwitchViewport
            width: parent.width
            height: controlsPage.switchHeight
            clip: true

            Grid {
              id: controlsGrid

              x: 0
              width: parent.width
              height: controlsPage.switchHeight
              columns: 2
              columnSpacing: theme.gap
              rowSpacing: theme.gap

              Behavior on x {
                enabled: root.animatePages
                NumberAnimation {
                  duration: 180
                  easing.type: Easing.OutCubic
                }
              }

              Repeater {
                model: [
                  { key: "wifi", label: "Wi-Fi", icon: "󰖩" },
                  { key: "bluetooth", label: "Bluetooth", icon: "󰂯" },
                  { key: "night", label: "Night Light", icon: "󰖔" },
                  { key: "dnd", label: "Do Not Disturb", icon: "󰂛" },
                  { key: "screenshot", label: "Screenshot", icon: "󰄀" }
                ]

                delegate: Rectangle {
                  required property var modelData

                  width: (parent.width - parent.columnSpacing * (parent.columns - 1)) / parent.columns
                  height: 68
                  radius: theme.radiusLarge
                  color: root.interactiveSurface(root.controlActive(modelData.key), controlArea.containsMouse)
                  border.width: 0
                  border.color: "transparent"

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 18
                      text: modelData.icon
                      color: root.interactiveForeground(root.controlActive(modelData.key))
                      font.pixelSize: 16
                      horizontalAlignment: Text.AlignHCenter
                    }

                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width - 18 - parent.spacing
                      spacing: 3

                      Text {
                        width: parent.width
                        text: modelData.label
                        color: root.interactiveForeground(root.controlActive(modelData.key))
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                      }

                      Text {
                        width: parent.width
                        text: root.controlStatus(modelData.key)
                        visible: text.length > 0
                        color: root.interactiveSupport(root.controlActive(modelData.key))
                        opacity: root.controlActive(modelData.key) ? 0.82 : 1
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                      }
                    }
                  }

                  MouseArea {
                    id: controlArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleControl(modelData.key)
                  }
                }
              }
            }

            Grid {
              id: powerPage

              x: parent.width
              width: parent.width
              height: controlsPage.switchHeight
              columns: 2
              columnSpacing: theme.gap
              rowSpacing: theme.gap

              Behavior on x {
                enabled: root.animatePages
                NumberAnimation {
                  duration: 180
                  easing.type: Easing.OutCubic
                }
              }

              Repeater {
                model: [
                  { key: "lock", label: "Lock", icon: "", command: ["hyprlock"] },
                  { key: "exit", label: "Exit", icon: "󰍃", command: ["hyprctl", "dispatch", "exit"] },
                  { key: "hibernate", label: "Hibernate", icon: "󰒲", command: ["systemctl", "hibernate"] },
                  { key: "suspend", label: "Suspend", icon: "󰤄", command: ["systemctl", "suspend"] },
                  { key: "reboot", label: "Reboot", icon: "󰜉", command: ["systemctl", "reboot"] },
                  { key: "shutdown", label: "Shutdown", icon: "⏻", command: ["shutdown", "now"] }
                ]

                delegate: Rectangle {
                  required property var modelData

                  width: (parent.width - parent.columnSpacing * (parent.columns - 1)) / parent.columns
                  height: 58
                  radius: theme.radiusLarge
                  color: powerArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
                  border.width: 0
                  border.color: "transparent"

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 9

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 18
                      text: modelData.icon
                      color: theme.foreground
                      font.pixelSize: 15
                      horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width - 18 - parent.spacing
                      text: modelData.label
                      color: theme.foreground
                      font.pixelSize: 12
                      font.weight: Font.Medium
                      horizontalAlignment: Text.AlignLeft
                      elide: Text.ElideRight
                    }
                  }

                  MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerPage.runAction(modelData.command)
                  }
                }
              }
            }
          }

          Rectangle {
            id: tabDivider

            width: parent.width
            height: 1
            color: theme.border
          }

          Row {
            id: tabRow

            width: parent.width
            height: 42
            spacing: 0

            Repeater {
              model: [
                { key: "notifications", label: "Notifications" },
                { key: "controls", label: "Controls" }
              ]

              delegate: Rectangle {
                required property var modelData

                readonly property bool active: root.lowerTab === modelData.key

                width: parent.width / 2
                height: parent.height
                radius: theme.radius
                color: active ? "transparent" : tabArea.containsMouse ? theme.surfaceHover : "transparent"
                border.width: 0
                border.color: "transparent"

                Text {
                  anchors.centerIn: parent
                  width: parent.width - 12
                  text: modelData.label
                  color: parent.active ? theme.accent : theme.muted
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignHCenter
                  font.pixelSize: 12
                  font.weight: parent.active ? Font.DemiBold : Font.Medium
                }

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.bottom
                  width: parent.active ? Math.min(56, parent.width - 24) : 0
                  height: 3
                  radius: height / 2
                  color: theme.accent

                  Behavior on width {
                    NumberAnimation {
                      duration: 140
                      easing.type: Easing.OutCubic
                    }
                  }
                }

                MouseArea {
                  id: tabArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.lowerTab = modelData.key
                }
              }
            }
          }

          Rectangle {
            id: tabContent

            width: parent.width
            height: controlsPage.lowerContentHeight
            radius: theme.radiusLarge
            color: "transparent"

            Column {
              anchors.fill: parent
              spacing: theme.gap
              visible: root.lowerTab === "notifications"

              Rectangle {
                id: notificationList

                width: parent.width
                height: parent.height - mprisCard.height - parent.spacing
                radius: theme.radiusLarge
                color: theme.surfaceHigh
                border.width: 1
                border.color: theme.border
                clip: true

                Text {
                  anchors.centerIn: parent
                  width: parent.width - 24
                  text: "No notifications"
                  visible: notificationServer.trackedNotifications.values.length === 0
                  color: theme.muted
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignHCenter
                  font.pixelSize: 12
                  font.weight: Font.Medium
                }

                Flickable {
                  anchors.fill: parent
                  anchors.margins: 8
                  clip: true
                  contentWidth: width
                  contentHeight: notificationsColumn.height
                  visible: notificationServer.trackedNotifications.values.length > 0

                  Column {
                    id: notificationsColumn

                    width: parent.width
                    spacing: 8

                    Repeater {
                      model: notificationServer.trackedNotifications

                      delegate: Rectangle {
                        id: notificationCard

                        required property var modelData

                        width: parent.width
                        height: Math.max(64, notificationText.height + 22)
                        radius: theme.radius
                        color: theme.surface
                        border.width: 0
                        border.color: theme.border

                        Image {
                          id: notificationIcon

                          anchors.left: parent.left
                          anchors.leftMargin: 10
                          anchors.top: parent.top
                          anchors.topMargin: 12
                          width: 22
                          height: 22
		                          source: root.notificationIconSource(modelData)
	                          sourceSize.width: width
	                          sourceSize.height: height
	                          visible: String(source).length > 0
                          fillMode: Image.PreserveAspectFit
                        }

                        Column {
                          id: notificationText

                          anchors.left: parent.left
                          anchors.leftMargin: notificationIcon.visible ? 42 : 10
                          anchors.right: dismissButton.left
                          anchors.rightMargin: 8
                          anchors.top: parent.top
                          anchors.topMargin: 10
                          spacing: 3

                          Text {
                            width: parent.width
                            text: modelData.summary || modelData.appName || "Notification"
                            color: theme.foreground
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                          }

                          Text {
                            width: parent.width
                            text: modelData.body || modelData.appName || ""
                            visible: text.length > 0
                            color: theme.muted
                            textFormat: Text.PlainText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            lineHeight: 1.15
                          }

                          Column {
                            width: parent.width
                            height: visible ? implicitHeight : 0
                            spacing: 6
                            visible: root.notificationHasActions(notificationCard.modelData)

                            Repeater {
                              model: notificationCard.modelData.actions

                              delegate: Rectangle {
                                required property var modelData

                                width: parent.width
                                height: 26
                                radius: theme.radiusLarge
                                color: actionArea.containsMouse ? theme.accentContainer : theme.surfaceHigh
                                border.width: 0
                                border.color: "transparent"

                                Text {
                                  id: actionText

                                  anchors.centerIn: parent
                                  width: parent.width - 12
                                  text: modelData.text
                                  color: actionArea.containsMouse ? theme.accentContainerForeground : theme.foreground
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
                                  onClicked: modelData.invoke()
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
                          width: 22
                          height: 22
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
                            onClicked: modelData.dismiss()
                          }
                        }
                      }
                    }
                  }
                }
              }

              Rectangle {
                id: mprisCard

                width: parent.width
	                height: 94
                radius: theme.radiusLarge
                color: theme.surface

                Text {
                  anchors.centerIn: parent
	                  width: parent.width - 24
	                  text: "No media playing"
	                  visible: root.currentPlayer === null
	                  color: theme.muted
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignHCenter
                  font.pixelSize: 12
                  font.weight: Font.Medium
                }

                Row {
	                  anchors.fill: parent
	                  anchors.margins: 10
	                  spacing: 10
	                  visible: root.currentPlayer !== null

	                  Rectangle {
	                    id: previousPlayerButton

	                    width: 24
	                    height: 52
	                    anchors.verticalCenter: parent.verticalCenter
	                    radius: theme.radiusLarge
	                    color: previousPlayerArea.containsMouse ? theme.surfaceHover : "transparent"
	                    opacity: root.playerCount > 1 ? 1 : 0.35

	                    Text {
	                      anchors.centerIn: parent
	                      text: "‹"
	                      color: theme.foreground
	                      font.pixelSize: 20
	                      font.weight: Font.DemiBold
	                    }

	                    MouseArea {
	                      id: previousPlayerArea
	                      anchors.fill: parent
	                      enabled: root.playerCount > 1
	                      hoverEnabled: true
	                      cursorShape: Qt.PointingHandCursor
	                      onClicked: root.showPreviousPlayer()
	                    }
	                  }

	                  Item {
	                    id: artSlot

                    width: 52
                    height: 52
                    anchors.verticalCenter: parent.verticalCenter

	                    Image {
	                      anchors.fill: parent
	                      source: root.currentPlayer ? root.currentPlayer.trackArtUrl : ""
	                      sourceSize.width: width
	                      sourceSize.height: height
	                      fillMode: Image.PreserveAspectCrop
                      visible: String(source).length > 0
                    }

                    Rectangle {
	                      anchors.fill: parent
	                      radius: theme.radiusLarge
	                      color: theme.surfaceHigh
	                      visible: root.currentPlayer === null || String(root.currentPlayer.trackArtUrl).length === 0

                      Text {
                        anchors.centerIn: parent
                        text: "󰎆"
                        color: theme.muted
                        font.pixelSize: 20
                      }
                    }
                  }

	                  Column {
	                    anchors.verticalCenter: parent.verticalCenter
	                    width: parent.width - previousPlayerButton.width - nextPlayerButton.width - artSlot.width - controls.width - parent.spacing * 4
	                    spacing: 3

	                    Text {
	                      width: parent.width
	                      text: root.currentPlayer ? (root.currentPlayer.trackTitle || root.currentPlayer.identity || "Unknown Title") : ""
	                      color: theme.foreground
                      elide: Text.ElideRight
                      font.pixelSize: 12
                      font.weight: Font.DemiBold
                    }

	                    Text {
	                      width: parent.width
	                      text: root.currentPlayer ? (root.currentPlayer.trackArtist || root.currentPlayer.identity || "Unknown Artist") : ""
	                      color: theme.muted
                      elide: Text.ElideRight
                      font.pixelSize: 11
                      font.weight: Font.Medium
                    }
                  }

                  Row {
                    id: controls

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

	                    Rectangle {
	                      width: 26
	                      height: 26
	                      radius: theme.radiusLarge
	                      color: previousArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
	                      opacity: root.currentPlayer && root.currentPlayer.canGoPrevious ? 1 : 0.45

                      Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: theme.foreground
                        font.pixelSize: 14
                      }

                      MouseArea {
	                        id: previousArea
	                        anchors.fill: parent
	                        enabled: root.currentPlayer && root.currentPlayer.canGoPrevious
	                        hoverEnabled: true
	                        cursorShape: Qt.PointingHandCursor
	                        onClicked: root.currentPlayer.previous()
	                      }
                    }

                    Rectangle {
	                      width: 30
	                      height: 30
	                      radius: theme.radiusLarge
	                      color: playArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
	                      opacity: root.currentPlayer && root.currentPlayer.canTogglePlaying ? 1 : 0.45

	                      Text {
	                        anchors.centerIn: parent
	                        text: root.currentPlayer && root.currentPlayer.isPlaying ? "󰏤" : "󰐊"
                        color: theme.foreground
                        font.pixelSize: 15
                      }

                      MouseArea {
	                        id: playArea
	                        anchors.fill: parent
	                        enabled: root.currentPlayer && root.currentPlayer.canTogglePlaying
	                        hoverEnabled: true
	                        cursorShape: Qt.PointingHandCursor
	                        onClicked: root.currentPlayer.togglePlaying()
	                      }
                    }

                    Rectangle {
	                      width: 26
	                      height: 26
	                      radius: theme.radiusLarge
	                      color: nextArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
	                      opacity: root.currentPlayer && root.currentPlayer.canGoNext ? 1 : 0.45

                      Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: theme.foreground
                        font.pixelSize: 14
                      }

                      MouseArea {
	                        id: nextArea
	                        anchors.fill: parent
	                        enabled: root.currentPlayer && root.currentPlayer.canGoNext
	                        hoverEnabled: true
	                        cursorShape: Qt.PointingHandCursor
	                        onClicked: root.currentPlayer.next()
	                      }
	                    }
	                  }

	                  Rectangle {
	                    id: nextPlayerButton

	                    width: 24
	                    height: 52
	                    anchors.verticalCenter: parent.verticalCenter
	                    radius: theme.radiusLarge
	                    color: nextPlayerArea.containsMouse ? theme.surfaceHover : "transparent"
	                    opacity: root.playerCount > 1 ? 1 : 0.35

	                    Text {
	                      anchors.centerIn: parent
	                      text: "›"
	                      color: theme.foreground
	                      font.pixelSize: 20
	                      font.weight: Font.DemiBold
	                    }

	                    MouseArea {
	                      id: nextPlayerArea
	                      anchors.fill: parent
	                      enabled: root.playerCount > 1
	                      hoverEnabled: true
	                      cursorShape: Qt.PointingHandCursor
	                      onClicked: root.showNextPlayer()
	                    }
	                  }
	                }

	                Row {
	                  anchors.horizontalCenter: parent.horizontalCenter
	                  anchors.bottom: parent.bottom
	                  anchors.bottomMargin: 6
	                  spacing: 5
	                  visible: root.playerCount > 1

	                  Repeater {
	                    model: root.playerCount

	                    Rectangle {
	                      width: index === root.currentPlayerIndex ? 14 : 5
	                      height: 5
	                      radius: 3
	                      color: index === root.currentPlayerIndex ? theme.accent : theme.muted
	                      opacity: index === root.currentPlayerIndex ? 1 : 0.55

	                      Behavior on width {
	                        NumberAnimation {
	                          duration: 140
	                          easing.type: Easing.OutCubic
	                        }
	                      }

	                      MouseArea {
	                        anchors.fill: parent
	                        cursorShape: Qt.PointingHandCursor
	                        onClicked: root.currentPlayerIndex = index
	                      }
	                    }
	                  }
	                }
	              }
            }

            Rectangle {
              anchors.fill: parent
              radius: theme.radiusLarge
              color: theme.surfaceHigh
              border.width: 1
              border.color: theme.border
              visible: root.lowerTab === "controls"

              Column {
                id: controlsSliders

                anchors.fill: parent
                anchors.margins: 14
                spacing: 20

                Repeater {
                  model: [
                    { key: "mic", label: "Mic", icon: "󰍬" },
                    { key: "audio", label: "Audio", icon: "󰕾" },
                    { key: "brightness", label: "Brightness", icon: "󰃠" }
                  ]

                  delegate: Column {
                    required property var modelData

                    width: controlsSliders.width
                    spacing: 7

                    Row {
                      width: parent.width
                      height: 18
                      spacing: 8

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: modelData.icon
                        color: theme.foreground
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                      }

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 18 - valueText.width - parent.spacing * 2
                        text: modelData.label
                        color: theme.foreground
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        font.weight: Font.Medium
                      }

                      Text {
                        id: valueText

                        anchors.verticalCenter: parent.verticalCenter
                        width: 38
                        text: Math.round(root.sliderLevel(modelData.key) * 100) + "%"
                        color: theme.muted
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: 11
                        font.weight: Font.Medium
                      }
                    }

                    Item {
                      id: sliderTrack

                      width: parent.width
                      height: 36

                      Rectangle {
                        id: inactiveTrack

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 16
                        radius: 8
                        color: theme.surfaceHigh
                      }

                      Rectangle {
                        anchors.left: inactiveTrack.left
                        anchors.verticalCenter: inactiveTrack.verticalCenter
                        width: Math.max(inactiveTrack.height, inactiveTrack.width * root.sliderLevel(modelData.key))
                        height: inactiveTrack.height
                        radius: inactiveTrack.radius
                        color: theme.accent
                      }

                      Rectangle {
                        x: Math.max(0, Math.min(parent.width - width, parent.width * root.sliderLevel(modelData.key) - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: sliderArea.pressed ? 8 : 6
                        height: sliderArea.pressed ? 30 : 26
                        radius: width / 2
                        color: theme.accent

                        Behavior on width {
                          NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                          }
                        }

                        Behavior on height {
                          NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                          }
                        }
                      }

                      MouseArea {
                        id: sliderArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function setLevel(mouseX) {
                          root.setSliderLevel(modelData.key, mouseX / sliderTrack.width);
                        }

                        onPressed: mouse => setLevel(mouse.x)
                        onPositionChanged: mouse => {
                          if (pressed) {
                            setLevel(mouse.x);
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

      }
    }
  }
}

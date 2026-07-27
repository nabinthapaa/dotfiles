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

Item {
  id: root

  required property var panelScreen
  required property var notificationServer
  required property var osd
  required property var notificationCenter
  property bool open: false
  property bool powerPageOpen: false
  property bool nightLightEnabled: false
  property real brightnessLevel: 0
  property int currentPlayerIndex: 0

  readonly property int playerCount: Mpris.players.values.length
  readonly property var currentPlayer: playerCount > 0
    ? Mpris.players.values[Math.max(0, Math.min(currentPlayerIndex, playerCount - 1))]
    : null

  implicitWidth: 380
  implicitHeight: contentColumn.implicitHeight + 28

  Theme {
    id: theme
  }

  IpcHandler {
    target: "controlPanel." + root.panelScreen.name
    function open(): void { root.open = true; }
    function close(): void { root.open = false; }
    function toggle(): void { root.open = !root.open; }
    function isOpen(): bool { return root.open; }
    function screen(): string { return root.panelScreen.name; }
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  Component.onCompleted: refreshBrightness()

  onOpenChanged: {
    if (open) {
      powerPageOpen = false;
      panel.forceActiveFocus();
    }
  }

  function togglePowerPage() { powerPageOpen = !powerPageOpen; }

  function interactiveSurface(active, hovered) {
    return active ? theme.accentContainer : hovered ? theme.surfaceHover : theme.surfaceHigh;
  }

  function interactiveForeground(active) {
    return active ? theme.accentContainerForeground : theme.foreground;
  }

  function interactiveSupport(active) {
    return active ? theme.accentContainerForeground : theme.muted;
  }

  function connectedWifiName() {
    const devices = Networking.devices.values;
    for (let i = 0; i < devices.length; i++) {
      const device = devices[i];
      if (!device.networks) continue;
      const networks = device.networks.values;
      for (let j = 0; j < networks.length; j++) {
        if (networks[j].connected) return networks[j].name;
      }
    }
    return "";
  }

  function notificationIconSource(notification) {
    let icon = notification.appIcon || notification.desktopEntry || "";
    if (icon.length === 0) return "";
    icon = icon.replace(/\.desktop$/, "");
    if (icon.indexOf("/") >= 0 || icon.indexOf(":") >= 0) return icon;
    const resolved = Quickshell.iconPath(icon, true);
    return resolved.length > 0 ? resolved : "";
  }

  function notificationHasActions(notification) {
    return notification.actions && notification.actions.length > 0;
  }

  function connectedBluetoothName() {
    if (!Bluetooth.defaultAdapter) return "";
    const devices = Bluetooth.defaultAdapter.devices.values.filter(d => d.connected);
    if (devices.length === 0) return "";
    return devices.map(d => d.deviceName || d.name).join(", ");
  }

  function controlActive(kind) {
    if (kind === "wifi") return Networking.wifiEnabled;
    if (kind === "bluetooth") return Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled;
    if (kind === "night") return nightLightEnabled;
    if (kind === "dnd") return notificationCenter.dndEnabled;
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
    if (kind === "night") return nightLightEnabled ? "On" : "Off";
    if (kind === "dnd") return notificationCenter.dndEnabled ? "On" : "Off";
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
      notificationCenter.dndEnabled = !notificationCenter.dndEnabled;
      osd.showSilent(notificationCenter.dndEnabled);
    } else if (kind === "screenshot") {
      root.open = false;
      screenshotMenuTimer.restart();
    }
  }

  function clampLevel(level) { return Math.max(0, Math.min(1, level)); }

  function sliderLevel(kind) {
    if (kind === "mic") return Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? clampLevel(Pipewire.defaultAudioSource.audio.volume) : 0;
    if (kind === "audio") return Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? clampLevel(Pipewire.defaultAudioSink.audio.volume) : 0;
    if (kind === "brightness") return clampLevel(brightnessLevel);
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

  function showPreviousPlayer() { if (playerCount > 1) currentPlayerIndex = (currentPlayerIndex + playerCount - 1) % playerCount; }
  function showNextPlayer() { if (playerCount > 1) currentPlayerIndex = (currentPlayerIndex + 1) % playerCount; }

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
    nightStatusProc.running = false;
    nightStatusProc.running = true;
  }

  Timer { id: nightStatusTimer; interval: 800; running: true; repeat: true; onTriggered: root.refreshNightLightStatus() }
  Timer {
    id: screenshotMenuTimer; interval: 220; repeat: false;
    onTriggered: {
      const monitor = Hyprland.monitorFor(root.panelScreen);
      if (monitor) { Quickshell.execDetached(["qs", "-p", "~/dotfiles/.config/quickshell/", "ipc", "call", "screenshotMenu." + monitor.name, "open"]); }
    }
  }

  Process {
    id: nightStatusProc
    command: ["sh", "-c", "hyprctl -j hyprsunset 2>/dev/null || true"]
    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        if (output.length === 0) { root.nightLightEnabled = false; return; }
        try {
          const status = JSON.parse(output);
          root.nightLightEnabled = status.identity === false || (typeof status.temperature === "number" && status.temperature < 6500);
        } catch (error) {}
      }
    }
  }

  function refreshBrightness() {
    brightnessProc.running = false;
    brightnessProc.running = true;
  }

  Timer { id: brightnessRefreshTimer; interval: 2000; running: true; repeat: true; onTriggered: root.refreshBrightness() }

  Process {
    id: brightnessProc
    command: ["brightnessctl", "-m"]
    stdout: StdioCollector {
      onStreamFinished: {
        const fields = text.trim().split(",");
        if (fields.length < 5) return;
        const percentField = fields.find(f => f.indexOf("%") >= 0);
        if (!percentField) return;
        const value = Number(percentField.replace("%", ""));
        if (!Number.isNaN(value)) root.brightnessLevel = root.clampLevel(value / 100);
      }
    }
  }



  property string weatherCondition: "Loading..."
  property string weatherTemp: ""
  property string weatherFeelsLike: ""
  property string weatherChance: ""
  property string weatherAqi: ""

  Process {
    id: weatherProc
    command: ["sh", "-c", Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/weather-full.sh || echo 'Unknown|--°C|--°C|--%|-- AQI'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split("|");
        if (parts.length >= 5) {
           root.weatherCondition = parts[0];
           root.weatherTemp = parts[1].replace("+", "");
           root.weatherFeelsLike = parts[2].replace("+", "");
           root.weatherChance = parts[3];
           root.weatherAqi = parts[4];
        } else {
           root.weatherCondition = "Offline";
           root.weatherTemp = "--°C";
           root.weatherFeelsLike = "--°C";
           root.weatherChance = "--%";
           root.weatherAqi = "--";
        }
      }
    }
  }

  Timer {
    interval: 1800000 // 30 mins
    running: true
    repeat: true
    onTriggered: {
      weatherProc.running = false;
      weatherProc.running = true;
    }
  }

  Item {
    id: panel
    anchors.fill: parent
    
    // Smooth opacity fade
    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Keys.onEscapePressed: root.open = false

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Column {
      id: contentColumn
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 14
      spacing: 14

      // Top Row: Weather
      Rectangle {
        width: parent.width
        height: 64
        radius: theme.radiusLarge
        color: theme.surfaceHigh

        Row {
          anchors.centerIn: parent
          spacing: 20

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.weatherCondition
            color: theme.foreground
            font.pixelSize: 32
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              text: root.weatherTemp || "..."
              color: theme.foreground
              font.pixelSize: 18
              font.weight: Font.DemiBold
            }

            Text {
              text: "Feels like " + root.weatherFeelsLike
              color: theme.muted
              font.pixelSize: 11
              font.weight: Font.Medium
            }
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 28
            color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.6)
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              text: "AQI " + root.weatherAqi
              color: Number(root.weatherAqi) > 100 ? theme.urgent : (Number(root.weatherAqi) > 50 ? theme.warning : theme.accent)
              font.pixelSize: 12
              font.weight: Font.DemiBold
            }

            Text {
              text: root.weatherChance + " Rain"
              color: theme.muted
              font.pixelSize: 11
              font.weight: Font.Medium
            }
          }
        }
      }
      
      // Quick Toggles (Bento Grid)
      Grid {
        width: parent.width
        columns: 2
        columnSpacing: 12
        rowSpacing: 12
        
        Repeater {
          model: [
            { key: "wifi", label: "Wi-Fi", icon: "󰖩" },
            { key: "bluetooth", label: "Bluetooth", icon: "󰂯" },
            { key: "night", label: "Night Light", icon: "󰖔" },
            { key: "dnd", label: "Do Not Disturb", icon: "󰂛" }
          ]

          delegate: Rectangle {
            required property var modelData
            width: (parent.width - 12) / 2
            height: 64
            radius: theme.radiusLarge
            color: root.interactiveSurface(root.controlActive(modelData.key), controlArea.containsMouse)
            
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 10
              spacing: 12

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.icon
                color: root.interactiveForeground(root.controlActive(modelData.key))
                font.pixelSize: 20
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32
                spacing: 2

                Text {
                  width: parent.width
                  text: modelData.label
                  color: root.interactiveForeground(root.controlActive(modelData.key))
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: root.controlStatus(modelData.key)
                  visible: text.length > 0
                  color: root.interactiveSupport(root.controlActive(modelData.key))
                  font.pixelSize: 10
                  font.weight: Font.Medium
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
      
      // Sliders Block
      Rectangle {
        width: parent.width
        height: slidersCol.implicitHeight + 24
        radius: theme.radiusLarge
        color: theme.surfaceHigh
        
        Column {
          id: slidersCol
          anchors.fill: parent
          anchors.margins: 12
          spacing: 16
          
          Repeater {
            model: [
              { key: "audio", icon: "󰕾" },
              { key: "mic", icon: "󰍬" },
              { key: "brightness", icon: "󰃠" }
            ]
            
            delegate: Row {
              required property var modelData
              width: parent.width
              spacing: 10
              
              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                text: modelData.icon
                color: theme.foreground
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
              }
              
              Item {
                id: sliderTrack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 30
                height: 24
                
                Rectangle {
                  anchors.centerIn: parent
                  width: parent.width
                  height: 16
                  radius: 8
                  color: theme.surfaceHover
                  
                  Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(height, parent.width * root.sliderLevel(modelData.key))
                    radius: parent.radius
                    color: theme.accent
                    
                    Behavior on width { NumberAnimation { duration: 100 } }
                  }
                }
                
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  function setLevel(mouseX) { root.setSliderLevel(modelData.key, mouseX / width); }
                  onPressed: mouse => setLevel(mouse.x)
                  onPositionChanged: mouse => { if (pressed) setLevel(mouse.x); }
                }
              }
            }
          }
        }
      }
      
      // Media Player Carousel
      Rectangle {
        width: parent.width
        height: 80
        radius: theme.radiusLarge
        color: theme.surfaceHigh
        visible: playerCount > 0
        clip: true
        
        ListView {
          id: playerCarousel
          anchors.fill: parent
          orientation: ListView.Horizontal
          snapMode: ListView.SnapOneItem
          highlightRangeMode: ListView.StrictlyEnforceRange
          boundsBehavior: Flickable.StopAtBounds
          clip: true
          
          model: Mpris.players.values
          
          delegate: Item {
            required property var modelData
            width: playerCarousel.width
            height: playerCarousel.height
            
            Row {
              anchors.fill: parent
              anchors.margins: 10
              spacing: 12
              
              Rectangle {
                width: 60
                height: 60
                radius: theme.radius
                color: theme.surfaceHover
                clip: true
                
                Image {
                  anchors.fill: parent
                  source: modelData.trackArtUrl || ""
                  sourceSize.width: width
                  sourceSize.height: height
                  fillMode: Image.PreserveAspectCrop
                  visible: String(source).length > 0
                }
                Text {
                  anchors.centerIn: parent
                  text: "󰎆"
                  color: theme.muted
                  font.pixelSize: 20
                  visible: String(modelData.trackArtUrl || "").length === 0
                }
              }
              
              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 60 - 12 - mediaControls.width - 12
                spacing: 2
                
                Text {
                  width: parent.width
                  text: modelData.trackTitle || modelData.identity || "Unknown Title"
                  color: theme.foreground
                  elide: Text.ElideRight
                  font.pixelSize: 13
                  font.weight: Font.DemiBold
                }
                Text {
                  width: parent.width
                  text: modelData.trackArtist || modelData.identity || "Unknown Artist"
                  color: theme.muted
                  elide: Text.ElideRight
                  font.pixelSize: 11
                  font.weight: Font.Medium
                }
              }
              
              Row {
                id: mediaControls
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                
                Text {
                  text: "󰒮"
                  color: modelData.canGoPrevious ? theme.foreground : theme.muted
                  font.pixelSize: 18
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (modelData.canGoPrevious) modelData.previous(); }
                  }
                }
                Text {
                  text: modelData.isPlaying ? "󰏤" : "󰐊"
                  color: modelData.canTogglePlaying ? theme.accent : theme.muted
                  font.pixelSize: 20
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (modelData.canTogglePlaying) modelData.togglePlaying(); }
                  }
                }
                Text {
                  text: "󰒭"
                  color: modelData.canGoNext ? theme.foreground : theme.muted
                  font.pixelSize: 18
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (modelData.canGoNext) modelData.next(); }
                  }
                }
              }
            }
          }
        }
        
        // Carousel Indicators
        Row {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 4
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 4
          visible: playerCount > 1
          
          Repeater {
            model: playerCount
            delegate: Rectangle {
              width: playerCarousel.currentIndex === index ? 12 : 6
              height: 4
              radius: 2
              color: playerCarousel.currentIndex === index ? theme.accent : theme.muted
              opacity: 0.8
              Behavior on width { NumberAnimation { duration: 150 } }
              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }
        }
      }
    }
  }
}

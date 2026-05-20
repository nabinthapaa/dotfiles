import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import "../../../shared"

Row {
  id: root

  required property var parentWindow

  property bool wifiPopupOpen: false
  property bool bluetoothPopupOpen: false
  property bool passwordPromptOpen: false
  property var selectedNetwork: null
  property string password: ""
  property string passwordError: ""
  readonly property var networkDevices: Networking.devices.values
  readonly property var activeWifiDevice: findWifiDevice()
  readonly property var wifiNetworks: activeWifiDevice && activeWifiDevice.networks ? activeWifiDevice.networks.values : []
  readonly property int wifiNetworkCount: wifiNetworks.length
  readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
  readonly property var bluetoothDevices: knownBluetoothDevices()
  readonly property int bluetoothDeviceCount: bluetoothDevices.length

  spacing: theme.gap / 2

  onWifiPopupOpenChanged: updateScanner()
  onBluetoothPopupOpenChanged: {
    if (bluetoothPopupOpen) {
      wifiPopupOpen = false;
    }
  }
  onActiveWifiDeviceChanged: updateScanner()

  function updateScanner() {
    const device = findWifiDevice();
    if (device) {
      device.scannerEnabled = wifiPopupOpen && Networking.wifiEnabled;
    }

    if (!wifiPopupOpen) {
      passwordPromptOpen = false;
      selectedNetwork = null;
      password = "";
      passwordError = "";
    }
  }

  function scanWifi() {
    const device = findWifiDevice();
    if (!device || !Networking.wifiEnabled) {
      return;
    }

    device.scannerEnabled = false;
    wifiScanRestartTimer.restart();
  }

  function findWifiDevice() {
    const devices = networkDevices;
    for (let index = 0; index < devices.length; index++) {
      const device = devices[index];
      if (device.type === DeviceType.Wifi) {
        return device;
      }
    }
    return null;
  }

  function connectedWifiName() {
    const networks = wifiNetworks;
    for (let index = 0; index < networks.length; index++) {
      if (networks[index].connected) {
        return networks[index].name;
      }
    }
    return "";
  }

  function connectedBluetoothName() {
    if (!bluetoothAdapter) {
      return "";
    }

    const devices = bluetoothAdapter.devices.values.filter(device => device.connected);
    if (devices.length === 0) {
      return "";
    }

    return devices.map(device => device.deviceName || device.name).join(", ");
  }

  function wifiStatusText() {
    const name = connectedWifiName();
    return name === "" ? "Not connected" : name;
  }

  function bluetoothStatusText() {
    const name = connectedBluetoothName();
    return name === "" ? "Not connected" : name;
  }

  function knownBluetoothDevices() {
    if (!bluetoothAdapter) {
      return [];
    }

    return bluetoothAdapter.devices.values.filter(device => device.paired || device.bonded || device.trusted || device.connected);
  }

  function bluetoothDeviceName(device) {
    return device.name || device.deviceName || device.address;
  }

  function bluetoothDeviceStatus(device) {
    if (device.connected && device.batteryAvailable) {
      return "Connected, " + Math.round(device.battery * 100) + "%";
    }
    if (device.connected) {
      return "Connected";
    }
    if (device.pairing) {
      return "Pairing...";
    }
    if (device.paired || device.bonded) {
      return "Paired";
    }
    if (device.trusted) {
      return "Trusted";
    }
    return "Known";
  }

  function toggleBluetoothDevice(device) {
    if (device.connected) {
      device.disconnect();
    } else if (device.paired || device.bonded || device.trusted) {
      device.connect();
    } else {
      device.pair();
    }
  }

  function wifiSignalIcon(strength) {
    if (strength >= 0.75) {
      return "󰤨";
    }
    if (strength >= 0.5) {
      return "󰤥";
    }
    if (strength >= 0.25) {
      return "󰤢";
    }
    return "󰤟";
  }

  function securityLabel(network) {
    if (!network || network.security === WifiSecurityType.Open) {
      return "Open";
    }
    if (network.known) {
      return "Saved";
    }
    return "Secured";
  }

  function networkNeedsPassword(network) {
    if (!network || network.known || network.security === WifiSecurityType.Open) {
      return false;
    }

    const type = WifiSecurityType.toString(network.security);
    return type === "WpaPsk" || type === "Wpa2Psk" || type === "Sae";
  }

  function selectNetwork(network) {
    passwordError = "";
    selectedNetwork = network;

    if (network.connected) {
      network.disconnect();
      return;
    }

    if (networkNeedsPassword(network)) {
      passwordPromptOpen = true;
      password = "";
      passwordFocusTimer.restart();
      return;
    }

    network.connect();
  }

  function submitPassword() {
    if (!selectedNetwork || password.length === 0) {
      passwordError = "Enter the network password.";
      return;
    }

    selectedNetwork.connectWithPsk(password);
    passwordError = "Connecting...";
  }

  Theme {
    id: theme
  }

  Timer {
    id: passwordFocusTimer
    interval: 40
    repeat: false
    onTriggered: passwordInput.forceActiveFocus()
  }

  Timer {
    id: wifiScanRestartTimer
    interval: 80
    repeat: false
    onTriggered: {
      const device = root.findWifiDevice();
      if (device && root.wifiPopupOpen && Networking.wifiEnabled) {
        device.scannerEnabled = true;
      }
    }
  }

  Connections {
    target: Networking

    function onWifiEnabledChanged() {
      root.updateScanner();
    }
  }

  Rectangle {
    id: wifiButton

    width: wifiIcon.implicitWidth + wifiLabel.width + wifiButtonContent.spacing
    height: theme.controlSize
    radius: theme.radiusLarge
    color: "transparent"

    Row {
      id: wifiButtonContent

      anchors.fill: parent
      anchors.leftMargin: 0
      anchors.rightMargin: 0
      spacing: 8

      Text {
        id: wifiIcon

        anchors.verticalCenter: parent.verticalCenter
        text: Networking.wifiEnabled ? "󰖩" : "󰖪"
        color: root.wifiPopupOpen || wifiArea.containsMouse ? theme.accent : theme.foreground
        font.pixelSize: 15
      }

      Text {
        id: wifiLabel

        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(96, implicitWidth)
        text: root.wifiStatusText()
        color: root.wifiPopupOpen || wifiArea.containsMouse ? theme.accent : theme.foreground
        elide: Text.ElideRight
        font.pixelSize: 12
        font.weight: Font.Medium
      }
    }

    MouseArea {
      id: wifiArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.bluetoothPopupOpen = false;
        root.wifiPopupOpen = !root.wifiPopupOpen;
      }
    }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: "|"
    color: theme.muted
    font.pixelSize: 13
    font.weight: Font.Medium
  }

  Rectangle {
    id: bluetoothButton

    width: bluetoothIcon.implicitWidth + bluetoothLabel.width + bluetoothButtonContent.spacing
    height: theme.controlSize
    radius: theme.radiusLarge
    color: "transparent"

    Row {
      id: bluetoothButtonContent

      anchors.fill: parent
      anchors.leftMargin: 0
      anchors.rightMargin: 0
      spacing: 8

      Text {
        id: bluetoothIcon

        anchors.verticalCenter: parent.verticalCenter
        text: "󰂯"
        color: root.bluetoothPopupOpen || bluetoothArea.containsMouse ? theme.accent : theme.foreground
        font.pixelSize: 15
      }

      Text {
        id: bluetoothLabel

        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(96, implicitWidth)
        text: root.bluetoothStatusText()
        color: root.bluetoothPopupOpen || bluetoothArea.containsMouse ? theme.accent : theme.foreground
        elide: Text.ElideRight
        font.pixelSize: 12
        font.weight: Font.Medium
      }
    }

    MouseArea {
      id: bluetoothArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.wifiPopupOpen = false;
        root.bluetoothPopupOpen = !root.bluetoothPopupOpen;
      }
    }
  }

  PopupWindow {
    id: wifiPopup

    anchor.window: root.parentWindow
    anchor.rect.x: Math.max(theme.barPadding, Math.min(root.parentWindow.width - width - theme.barPadding, wifiButton.mapToItem(null, 0, 0).x + wifiButton.width - width))
    anchor.rect.y: theme.barHeight + 6
    implicitWidth: 336
    implicitHeight: 384
    visible: root.wifiPopupOpen
    grabFocus: true
    color: "transparent"

    onVisibleChanged: {
      if (!visible) {
        root.wifiPopupOpen = false;
      }
    }

    Rectangle {
      id: popupCard

      anchors.fill: parent
      radius: theme.radiusLarge
      color: theme.panel
      border.width: 1
      border.color: theme.border
      opacity: root.wifiPopupOpen ? 1 : 0
      scale: root.wifiPopupOpen ? 1 : 0.96
      transformOrigin: Item.Top

      Behavior on scale {
        NumberAnimation {
          duration: 150
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 120
          easing.type: Easing.OutCubic
        }
      }

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Row {
          width: parent.width
          height: 30
          spacing: 10

          Column {
            width: parent.width - wifiHeaderActions.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              width: parent.width
              text: "Wi-Fi"
              color: theme.foreground
              elide: Text.ElideRight
              font.pixelSize: 14
              font.weight: Font.DemiBold
            }

            Text {
              width: parent.width
              text: Networking.wifiEnabled ? root.wifiStatusText() : "Disabled"
              color: theme.muted
              elide: Text.ElideRight
              font.pixelSize: 11
            }
          }

          Row {
            id: wifiHeaderActions

            width: wifiToggle.width + scanButton.width + spacing
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Rectangle {
              id: scanButton

              width: Networking.wifiEnabled ? 32 : 0
              height: 30
              anchors.verticalCenter: parent.verticalCenter
              radius: theme.radius
              color: scanArea.containsMouse ? theme.surfaceHover : theme.surface
              visible: Networking.wifiEnabled
              clip: true

              Text {
                anchors.centerIn: parent
                text: "󰑓"
                color: scanArea.containsMouse ? theme.foreground : theme.muted
                font.pixelSize: 15
              }

              MouseArea {
                id: scanArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.scanWifi()
              }
            }

            Rectangle {
              id: wifiToggle

              width: 38
              height: 24
              anchors.verticalCenter: parent.verticalCenter
              radius: 12
              color: Networking.wifiEnabled ? theme.accentContainer : theme.surfaceHigh

              Rectangle {
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter
                x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                radius: 9
                color: Networking.wifiEnabled ? theme.accentContainerForeground : theme.muted

                Behavior on x {
                  NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Networking.wifiEnabled = !Networking.wifiEnabled;
                  root.updateScanner();
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: theme.border
        }

        Item {
          width: parent.width
          height: parent.height - y

          Text {
            anchors.centerIn: parent
            width: parent.width - 20
            text: !Networking.wifiEnabled ? "Wi-Fi is disabled" : root.activeWifiDevice ? "No networks found" : "No Wi-Fi device"
            color: theme.muted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            visible: !Networking.wifiEnabled || !root.activeWifiDevice || root.wifiNetworkCount === 0
          }

          Flickable {
            anchors.fill: parent
            contentHeight: networkColumn.height
            clip: true
            visible: Networking.wifiEnabled && root.activeWifiDevice && root.wifiNetworkCount > 0

            Column {
              id: networkColumn
              width: parent.width
              spacing: 6

              Repeater {
                model: root.wifiNetworks

                Rectangle {
                  id: networkRow

                  required property var modelData

                  width: networkColumn.width
                  height: 54
                  radius: theme.radius
                  color: modelData.connected ? theme.accentContainer : networkArea.containsMouse ? theme.surfaceHover : theme.surface
                  border.width: modelData.stateChanging ? 1 : 0
                  border.color: theme.outline

                  Connections {
                    target: networkRow.modelData

                    function onConnectionFailed(reason) {
                      root.selectedNetwork = networkRow.modelData;
                      root.passwordPromptOpen = true;
                      root.password = "";
                      root.passwordError = "Password required or incorrect.";
                      passwordFocusTimer.restart();
                    }
                  }

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 18
                      text: root.wifiSignalIcon(networkRow.modelData.signalStrength)
                      color: networkRow.modelData.connected ? theme.accentContainerForeground : theme.foreground
                      font.pixelSize: 16
                    }

                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width - 72
                      spacing: 3

                      Text {
                        width: parent.width
                        text: networkRow.modelData.name
                        color: networkRow.modelData.connected ? theme.accentContainerForeground : theme.foreground
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        font.weight: Font.Medium
                      }

                      Text {
                        width: parent.width
                        text: networkRow.modelData.stateChanging ? "Connecting..." : networkRow.modelData.connected ? "Connected" : root.securityLabel(networkRow.modelData)
                        color: networkRow.modelData.connected ? theme.accentContainerForeground : theme.muted
                        elide: Text.ElideRight
                        font.pixelSize: 11
                      }
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 24
                      text: networkRow.modelData.connected ? "󰄬" : root.networkNeedsPassword(networkRow.modelData) ? "󰌾" : "󰐕"
                      color: networkRow.modelData.connected ? theme.accentContainerForeground : theme.muted
                      horizontalAlignment: Text.AlignRight
                      font.pixelSize: 15
                    }
                  }

                  MouseArea {
                    id: networkArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectNetwork(networkRow.modelData)
                  }
                }
              }
            }
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: theme.panel
        border.width: 1
        border.color: theme.border
        visible: root.passwordPromptOpen

        Column {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 12

          Row {
            width: parent.width
            height: 28

            Text {
              width: parent.width - 30
              anchors.verticalCenter: parent.verticalCenter
              text: root.selectedNetwork ? root.selectedNetwork.name : "Network"
              color: theme.foreground
              elide: Text.ElideRight
              font.pixelSize: 14
              font.weight: Font.DemiBold
            }

            Text {
              width: 24
              anchors.verticalCenter: parent.verticalCenter
              text: "󰅖"
              color: closePasswordArea.containsMouse ? theme.foreground : theme.muted
              horizontalAlignment: Text.AlignRight
              font.pixelSize: 16

              MouseArea {
                id: closePasswordArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.passwordPromptOpen = false;
                  root.password = "";
                  root.passwordError = "";
                }
              }
            }
          }

          Text {
            width: parent.width
            text: "Enter password"
            color: theme.muted
            font.pixelSize: 12
          }

          Rectangle {
            width: parent.width
            height: 42
            radius: theme.radius
            color: theme.surface
            border.width: 1
            border.color: passwordInput.activeFocus ? theme.accent : theme.border

            TextInput {
              id: passwordInput
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              verticalAlignment: TextInput.AlignVCenter
              text: root.password
              color: theme.foreground
              echoMode: TextInput.Password
              clip: true
              font.pixelSize: 13
              onTextChanged: root.password = text
              onAccepted: root.submitPassword()
            }
          }

          Text {
            width: parent.width
            text: root.passwordError
            color: root.passwordError === "Connecting..." ? theme.muted : theme.urgent
            wrapMode: Text.WordWrap
            font.pixelSize: 11
            visible: root.passwordError.length > 0
          }

          Item {
            width: parent.width
            height: 1
          }

          Row {
            width: parent.width
            height: 34
            spacing: 8

            Rectangle {
              width: (parent.width - parent.spacing) / 2
              height: parent.height
              radius: theme.radius
              color: cancelArea.containsMouse ? theme.surfaceHover : theme.surface

              Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: theme.foreground
                font.pixelSize: 12
                font.weight: Font.Medium
              }

              MouseArea {
                id: cancelArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.passwordPromptOpen = false;
                  root.password = "";
                  root.passwordError = "";
                }
              }
            }

            Rectangle {
              width: (parent.width - parent.spacing) / 2
              height: parent.height
              radius: theme.radius
              color: connectArea.containsMouse ? theme.accent : theme.accentContainer

              Text {
                anchors.centerIn: parent
                text: "Connect"
                color: theme.accentContainerForeground
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }

              MouseArea {
                id: connectArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submitPassword()
              }
            }
          }
        }
      }
    }
  }

  PopupWindow {
    id: bluetoothPopup

    anchor.window: root.parentWindow
    anchor.rect.x: Math.max(theme.barPadding, Math.min(root.parentWindow.width - width - theme.barPadding, bluetoothButton.mapToItem(null, 0, 0).x + bluetoothButton.width - width))
    anchor.rect.y: theme.barHeight + 6
    implicitWidth: 320
    implicitHeight: 340
    visible: root.bluetoothPopupOpen
    grabFocus: true
    color: "transparent"

    onVisibleChanged: {
      if (!visible) {
        root.bluetoothPopupOpen = false;
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: theme.radiusLarge
      color: theme.panel
      border.width: 1
      border.color: theme.border
      opacity: root.bluetoothPopupOpen ? 1 : 0
      scale: root.bluetoothPopupOpen ? 1 : 0.96
      transformOrigin: Item.Top

      Behavior on scale {
        NumberAnimation {
          duration: 150
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 120
          easing.type: Easing.OutCubic
        }
      }

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Row {
          width: parent.width
          height: 30

          Column {
            width: parent.width - 44
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              width: parent.width
              text: "Bluetooth"
              color: theme.foreground
              elide: Text.ElideRight
              font.pixelSize: 14
              font.weight: Font.DemiBold
            }

            Text {
              width: parent.width
              text: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? root.bluetoothStatusText() : root.bluetoothAdapter ? "Disabled" : "No adapter"
              color: theme.muted
              elide: Text.ElideRight
              font.pixelSize: 11
            }
          }

          Rectangle {
            width: 38
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            radius: 12
            color: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? theme.accentContainer : theme.surfaceHigh
            opacity: root.bluetoothAdapter ? 1 : 0.5

            Rectangle {
              width: 18
              height: 18
              anchors.verticalCenter: parent.verticalCenter
              x: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? parent.width - width - 3 : 3
              radius: 9
              color: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? theme.accentContainerForeground : theme.muted

              Behavior on x {
                NumberAnimation {
                  duration: 120
                  easing.type: Easing.OutCubic
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              enabled: root.bluetoothAdapter !== null
              cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: theme.border
        }

        Item {
          width: parent.width
          height: parent.height - y

          Text {
            anchors.centerIn: parent
            width: parent.width - 20
            text: !root.bluetoothAdapter ? "No Bluetooth adapter" : !root.bluetoothAdapter.enabled ? "Bluetooth is disabled" : "No known devices"
            color: theme.muted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            visible: !root.bluetoothAdapter || !root.bluetoothAdapter.enabled || root.bluetoothDeviceCount === 0
          }

          Flickable {
            anchors.fill: parent
            contentHeight: bluetoothDeviceColumn.height
            clip: true
            visible: root.bluetoothAdapter && root.bluetoothAdapter.enabled && root.bluetoothDeviceCount > 0

            Column {
              id: bluetoothDeviceColumn
              width: parent.width
              spacing: 6

              Repeater {
                model: root.bluetoothDevices

                Rectangle {
                  id: bluetoothDeviceRow

                  required property var modelData

                  width: bluetoothDeviceColumn.width
                  height: 54
                  radius: theme.radius
                  color: modelData.connected ? theme.accentContainer : bluetoothDeviceArea.containsMouse ? theme.surfaceHover : theme.surface

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 18
                      text: "󰂯"
                      color: bluetoothDeviceRow.modelData.connected ? theme.accentContainerForeground : theme.foreground
                      font.pixelSize: 16
                    }

                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width - 72
                      spacing: 3

                      Text {
                        width: parent.width
                        text: root.bluetoothDeviceName(bluetoothDeviceRow.modelData)
                        color: bluetoothDeviceRow.modelData.connected ? theme.accentContainerForeground : theme.foreground
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        font.weight: Font.Medium
                      }

                      Text {
                        width: parent.width
                        text: root.bluetoothDeviceStatus(bluetoothDeviceRow.modelData)
                        color: bluetoothDeviceRow.modelData.connected ? theme.accentContainerForeground : theme.muted
                        elide: Text.ElideRight
                        font.pixelSize: 11
                      }
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 24
                      text: bluetoothDeviceRow.modelData.connected ? "󰄬" : bluetoothDeviceRow.modelData.pairing ? "󰔟" : "󰐕"
                      color: bluetoothDeviceRow.modelData.connected ? theme.accentContainerForeground : theme.muted
                      horizontalAlignment: Text.AlignRight
                      font.pixelSize: 15
                    }
                  }

                  MouseArea {
                    id: bluetoothDeviceArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleBluetoothDevice(bluetoothDeviceRow.modelData)
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

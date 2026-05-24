import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../shared"

Scope {
  id: root

  readonly property string snapshotScript: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/system-monitor-snapshot.sh"
  readonly property string killScript: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/system-monitor-kill.sh"
  readonly property var tabs: [
    { key: "system", label: "System" },
    { key: "programs", label: "Programs" }
  ]

  Theme {
    id: theme
  }

  component StatBar: Item {
    required property string label
    required property real value
    property string detail: ""
    property color fillColor: theme.accent
    property int labelWidth: 76

    width: parent ? parent.width : 0
    height: 24

    Text {
      id: statLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: parent.labelWidth
      text: parent.label
      color: theme.muted
      elide: Text.ElideRight
      font.pixelSize: 11
      font.weight: Font.Medium
    }

    Rectangle {
      anchors.left: statLabel.right
      anchors.right: valueText.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      height: 8
      radius: 999
      color: theme.surfaceHigh

      Rectangle {
        width: Math.max(4, parent.width * Math.max(0, Math.min(100, value)) / 100)
        height: parent.height
        radius: parent.radius
        color: fillColor
      }
    }

    Text {
      id: valueText
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 66
      text: detail.length > 0 ? detail : Math.round(value) + "%"
      color: theme.foreground
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
      font.pixelSize: 11
      font.weight: Font.DemiBold
    }
  }

  component Section: Rectangle {
    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    radius: theme.radiusLarge
    color: theme.surface
    border.width: 1
    border.color: theme.border
    clip: true

    Column {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      Row {
        width: parent.width
        height: 24
        spacing: 8

        Text {
          width: parent.width - subtitleText.width - parent.spacing
          text: title
          color: theme.foreground
          elide: Text.ElideRight
          font.pixelSize: 14
          font.weight: Font.DemiBold
        }

        Text {
          id: subtitleText
          anchors.verticalCenter: parent.verticalCenter
          text: subtitle
          color: theme.muted
          font.pixelSize: 11
          font.weight: Font.Medium
        }
      }

      Column {
        id: body
        width: parent.width
        spacing: 8
      }
    }
  }

  component ProgramRow: Rectangle {
    required property var process
    required property bool selected
    signal selectedRequested()
    signal killRequested()

    width: parent ? parent.width : 0
    height: 42
    radius: theme.radius
    color: selected ? theme.accentContainer : rowArea.containsMouse ? theme.surfaceHover : "transparent"

    Row {
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 8
      spacing: 10

      Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - pidText.width - cpuText.width - memText.width - killButton.width - parent.spacing * 4
        spacing: 3

        Text {
          width: parent.width
          text: process.name || "unknown"
          color: selected ? theme.accentContainerForeground : theme.foreground
          elide: Text.ElideRight
          font.pixelSize: 12
          font.weight: Font.DemiBold
        }

        Text {
          width: parent.width
          text: process.command || process.user || ""
          color: selected ? theme.accentContainerForeground : theme.muted
          elide: Text.ElideRight
          font.pixelSize: 10
        }
      }

      Text {
        id: pidText
        anchors.verticalCenter: parent.verticalCenter
        width: 66
        text: "pid " + (process.pid || 0)
        color: selected ? theme.accentContainerForeground : theme.muted
        horizontalAlignment: Text.AlignRight
        font.pixelSize: 10
      }

      Text {
        id: cpuText
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        text: (process.cpu || 0).toFixed(1) + "%"
        color: selected ? theme.accentContainerForeground : theme.foreground
        horizontalAlignment: Text.AlignRight
        font.pixelSize: 11
        font.weight: Font.DemiBold
      }

      Text {
        id: memText
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        text: (process.mem || 0).toFixed(1) + "%"
        color: selected ? theme.accentContainerForeground : theme.muted
        horizontalAlignment: Text.AlignRight
        font.pixelSize: 11
      }

      Rectangle {
        id: killButton
        anchors.verticalCenter: parent.verticalCenter
        width: 54
        height: 26
        radius: theme.radius
        color: killArea.containsMouse ? theme.urgent : theme.surfaceHigh
        border.width: 1
        border.color: killArea.containsMouse ? theme.urgent : theme.border

        Text {
          anchors.centerIn: parent
          text: "Kill"
          color: killArea.containsMouse ? theme.accentForeground : theme.foreground
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }

        MouseArea {
          id: killArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: killRequested()
        }
      }
    }

    MouseArea {
      id: rowArea
      anchors.fill: parent
      anchors.rightMargin: 62
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: selectedRequested()
      onClicked: selectedRequested()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: menu

      required property var modelData
      property bool open: false
      property bool loading: false
      property bool dataReady: false
      property string activeTab: "system"
      property string programQuery: ""
      property int selectedProcessIndex: 0
      property string errorMessage: ""
      property string actionMessage: ""
      property var snapshot: ({
        uptime: 0,
        cpu: { usage: 0, cores: [], load: [0, 0, 0], temperature: null },
        memory: { total: 0, used: 0, percent: 0 },
        swap: { total: 0, used: 0, percent: 0 },
        network: { interface: "", rxRate: 0, txRate: 0 },
        gpus: [],
        disks: [],
        processes: []
      })
      property var cpuHistory: []
      property var memHistory: []
      readonly property var hyprMonitor: Hyprland.monitorFor(screen)
      readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : screen.name
      readonly property bool hasData: dataReady
      readonly property var filteredProcesses: filterProcesses()
      readonly property var selectedProcess: filteredProcesses.length > 0
        ? filteredProcesses[Math.max(0, Math.min(selectedProcessIndex, filteredProcesses.length - 1))]
        : null

      screen: modelData
      visible: open
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

      onOpenChanged: {
        if (open) {
          errorMessage = "";
          actionMessage = "";
          activeTab = "system";
          loading = true;
          pollSnapshot();
          pollTimer.restart();
          Qt.callLater(() => overlay.forceActiveFocus());
        } else {
          pollTimer.stop();
        }
      }

      onProgramQueryChanged: selectedProcessIndex = 0

      function pollSnapshot() {
        if (!open) {
          return;
        }
        snapshotProc.exec([root.snapshotScript]);
      }

      function filterProcesses() {
        const source = snapshot.processes || [];
        const query = programQuery.trim().toLowerCase();
        if (query.length === 0) {
          return source;
        }

        return source.filter(process => {
          const haystack = [
            process.pid,
            process.user,
            process.name,
            process.command
          ].join(" ").toLowerCase();
          return haystack.indexOf(query) >= 0;
        });
      }

      function cycleProcess(direction) {
        const count = filteredProcesses.length;
        if (count === 0) {
          selectedProcessIndex = 0;
          return;
        }
        selectedProcessIndex = (selectedProcessIndex + direction + count) % count;
        if (programList) {
          programList.positionViewAtIndex(selectedProcessIndex, ListView.Contain);
        }
      }

      function killProcess(process) {
        if (!process || !process.pid) {
          return;
        }
        actionMessage = "Sending TERM to pid " + process.pid;
        killProc.exec([root.killScript, String(process.pid), "TERM"]);
      }

      function pushHistory(values, next) {
        const copy = values.slice();
        copy.push(Math.max(0, Math.min(100, next || 0)));
        while (copy.length > 24) {
          copy.shift();
        }
        return copy;
      }

      function formatBytes(bytes) {
        const value = Number(bytes || 0);
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let next = value;
        let index = 0;
        while (next >= 1024 && index < units.length - 1) {
          next = next / 1024;
          index += 1;
        }
        return (index === 0 ? next.toFixed(0) : next.toFixed(1)) + " " + units[index];
      }

      function uptimeText(seconds) {
        const total = Number(seconds || 0);
        const days = Math.floor(total / 86400);
        const hours = Math.floor((total % 86400) / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        if (days > 0) {
          return days + "d " + hours + "h";
        }
        if (hours > 0) {
          return hours + "h " + minutes + "m";
        }
        return minutes + "m";
      }

      function rateText(bytes) {
        return formatBytes(bytes) + "/s";
      }

      function tempText(value) {
        return value === null || value === undefined ? "n/a" : Number(value).toFixed(1) + " C";
      }

      IpcHandler {
        target: "systemMonitor." + menu.ipcTargetName

        function open(): void {
          menu.open = true;
        }

        function close(): void {
          menu.open = false;
        }

        function toggle(): void {
          menu.open = !menu.open;
        }

        function isOpen(): bool {
          return menu.open;
        }
      }

      Timer {
        id: pollTimer
        interval: 1500
        repeat: true
        running: false
        onTriggered: menu.pollSnapshot()
      }

      Process {
        id: snapshotProc
        stdout: StdioCollector {
          onStreamFinished: {
            menu.loading = false;
            try {
              const payload = JSON.parse(text);
              if (!payload.ok) {
                menu.errorMessage = payload.error || "System monitor returned an error.";
                return;
              }
              menu.snapshot = payload;
              menu.dataReady = true;
              menu.cpuHistory = menu.pushHistory(menu.cpuHistory, payload.cpu ? payload.cpu.usage : 0);
              menu.memHistory = menu.pushHistory(menu.memHistory, payload.memory ? payload.memory.percent : 0);
              if (menu.selectedProcessIndex >= menu.filteredProcesses.length) {
                menu.selectedProcessIndex = Math.max(0, menu.filteredProcesses.length - 1);
              }
              menu.errorMessage = "";
            } catch (error) {
              menu.errorMessage = "System monitor returned malformed data.";
            }
          }
        }
      }

      Process {
        id: killProc
        stdout: StdioCollector {
          onStreamFinished: {
            try {
              const payload = JSON.parse(text);
              menu.actionMessage = payload.ok ? "Process signaled." : (payload.error || "Could not signal process.");
            } catch (error) {
              menu.actionMessage = "Could not read process action result.";
            }
            menu.pollSnapshot();
          }
        }
      }

      Item {
        id: overlay
        anchors.fill: parent
        focus: menu.open
        Keys.onEscapePressed: menu.open = false
        Keys.onPressed: event => {
          if (event.key === Qt.Key_R) {
            menu.pollSnapshot();
            event.accepted = true;
          } else if (menu.activeTab === "programs" && event.key === Qt.Key_Down) {
            menu.cycleProcess(1);
            event.accepted = true;
          } else if (menu.activeTab === "programs" && event.key === Qt.Key_Up) {
            menu.cycleProcess(-1);
            event.accepted = true;
          }
        }

        Rectangle {
          anchors.fill: parent
          color: theme.background
          opacity: 0.72
        }

        MouseArea {
          anchors.fill: parent
          onClicked: menu.open = false
        }

        Rectangle {
          id: panel
          anchors.centerIn: parent
          width: Math.min(parent.width - 64, 1060)
          height: Math.min(parent.height - 80, 660)
          radius: theme.radiusLarge
          color: theme.panel
          border.width: 1
          border.color: theme.border
          opacity: menu.open ? 1 : 0
          scale: menu.open ? 1 : 0.97
          transformOrigin: Item.Center

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

          MouseArea {
            anchors.fill: parent
          }

          Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Row {
              width: parent.width
              height: 44
              spacing: 12

              Rectangle {
                width: 40
                height: 40
                radius: 999
                color: theme.accentContainer

                Text {
                  anchors.centerIn: parent
                  text: "󰍛"
                  color: theme.accentContainerForeground
                  font.pixelSize: 18
                }
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40 - statusPill.width - parent.spacing * 2
                spacing: 3

                Text {
                  width: parent.width
                  text: "System Monitor"
                  color: theme.foreground
                  elide: Text.ElideRight
                  font.pixelSize: 16
                  font.weight: Font.DemiBold
                }

                Text {
                  width: parent.width
                  text: menu.hasData
                    ? "Uptime " + menu.uptimeText(menu.snapshot.uptime) + "  |  Load " + menu.snapshot.cpu.load.map(v => Number(v).toFixed(2)).join("  ")
                    : menu.loading ? "Collecting system data" : "Waiting for system data"
                  color: theme.muted
                  elide: Text.ElideRight
                  font.pixelSize: 11
                  font.weight: Font.Medium
                }
              }

              Rectangle {
                id: statusPill
                anchors.verticalCenter: parent.verticalCenter
                width: statusText.implicitWidth + 22
                height: 28
                radius: 999
                color: menu.errorMessage.length > 0 ? theme.surfaceHigh : theme.surface
                border.width: 1
                border.color: menu.errorMessage.length > 0 ? theme.urgent : theme.border

                Text {
                  id: statusText
                  anchors.centerIn: parent
                  text: menu.errorMessage.length > 0 ? "Error" : "Live"
                  color: menu.errorMessage.length > 0 ? theme.urgent : theme.accent
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                }
              }
            }

            Row {
              width: parent.width
              height: 32
              spacing: 8

              Repeater {
                model: root.tabs

                Rectangle {
                  required property var modelData
                  readonly property bool active: menu.activeTab === modelData.key

                  width: Math.max(104, tabText.implicitWidth + 28)
                  height: parent.height
                  radius: theme.radiusLarge
                  color: active ? theme.accentContainer : tabArea.containsMouse ? theme.surfaceHover : theme.surface
                  border.width: 1
                  border.color: active ? theme.accent : theme.border

                  Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.active ? theme.accentContainerForeground : theme.foreground
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                  }

                  MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      menu.activeTab = parent.modelData.key;
                      if (menu.activeTab === "programs") {
                        Qt.callLater(() => programSearch.forceActiveFocus());
                      }
                    }
                  }
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: menu.actionMessage
                color: menu.actionMessage.indexOf("Could") === 0 ? theme.urgent : theme.muted
                elide: Text.ElideRight
                font.pixelSize: 11
                visible: text.length > 0
              }
            }

            Text {
              width: parent.width
              height: visible ? 24 : 0
              visible: menu.errorMessage.length > 0
              text: menu.errorMessage
              color: theme.urgent
              elide: Text.ElideRight
              font.pixelSize: 12
            }

            Row {
              width: parent.width
              height: parent.height - y
              spacing: 12
              visible: menu.hasData && menu.activeTab === "system"

              Column {
                id: leftColumn
                width: Math.round(parent.width * 0.52)
                height: parent.height
                spacing: 12

                Rectangle {
                  width: parent.width
                  height: 250
                  radius: theme.radiusLarge
                  color: theme.surface
                  border.width: 1
                  border.color: theme.border
                  clip: true

                  Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Row {
                      width: parent.width
                      height: 24
                      spacing: 8

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - tempPill.width - parent.spacing
                        text: "Processor"
                        color: theme.foreground
                        elide: Text.ElideRight
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                      }

                      Rectangle {
                        id: tempPill
                        anchors.verticalCenter: parent.verticalCenter
                        width: tempText.implicitWidth + 18
                        height: 24
                        radius: 999
                        color: theme.surfaceHigh
                        border.width: 1
                        border.color: theme.border

                        Text {
                          id: tempText
                          anchors.centerIn: parent
                          text: menu.tempText(menu.snapshot.cpu.temperature)
                          color: theme.warning
                          font.pixelSize: 11
                          font.weight: Font.DemiBold
                        }
                      }
                    }

                    StatBar {
                      width: parent.width
                      label: "Total"
                      value: menu.snapshot.cpu.usage || 0
                      fillColor: theme.accent
                      detail: Math.round(menu.snapshot.cpu.usage || 0) + "%"
                    }

                    Row {
                      width: parent.width
                      height: 26
                      spacing: 8

                      Repeater {
                        model: menu.cpuHistory

                        Rectangle {
                          required property real modelData
                          width: Math.max(5, (parent.width - parent.spacing * 23) / 24)
                          height: parent.height
                          radius: 999
                          color: theme.surfaceHigh

                          Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(3, parent.height * Math.max(0, Math.min(100, modelData)) / 100)
                            radius: parent.radius
                            color: theme.accentContainer
                          }
                        }
                      }
                    }

                    Grid {
                      width: parent.width
                      columns: 2
                      columnSpacing: 12
                      rowSpacing: 4

                      Repeater {
                        model: menu.snapshot.cpu.cores || []

                        StatBar {
                          required property var modelData
                          width: (parent.width - parent.columnSpacing) / 2
                          label: "CPU " + modelData.core
                          value: modelData.usage || 0
                          labelWidth: 48
                          detail: Math.round(modelData.usage || 0) + "%"
                          fillColor: theme.secondary
                        }
                      }
                    }
                  }
                }

                Section {
                  width: parent.width
                  height: parent.height - 262
                  title: "GPU"
                  subtitle: (menu.snapshot.gpus || []).length + " detected"

                  Text {
                    width: parent.width
                    text: "No GPU data available"
                    color: theme.muted
                    font.pixelSize: 12
                    visible: (menu.snapshot.gpus || []).length === 0
                  }

                  Repeater {
                    model: menu.snapshot.gpus || []

                    Column {
                      required property var modelData
                      width: parent.width
                      spacing: 4

                      Row {
                        width: parent.width
                        height: 20

                        Text {
                          width: parent.width - gpuTemp.width
                          text: modelData.name || "GPU"
                          color: theme.foreground
                          elide: Text.ElideRight
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                        }

                        Text {
                          id: gpuTemp
                          width: 64
                          text: modelData.temperature === null ? "" : Number(modelData.temperature).toFixed(0) + " C"
                          color: theme.warning
                          horizontalAlignment: Text.AlignRight
                          font.pixelSize: 11
                          font.weight: Font.DemiBold
                        }
                      }

                      StatBar {
                        width: parent.width
                        label: "Usage"
                        value: modelData.usage === null ? 0 : modelData.usage
                        detail: modelData.usage === null ? "n/a" : Math.round(modelData.usage) + "%"
                        fillColor: theme.accent
                      }

                      StatBar {
                        width: parent.width
                        label: "VRAM"
                        value: modelData.memoryTotal ? modelData.memoryUsed * 100 / modelData.memoryTotal : 0
                        detail: modelData.memoryTotal ? menu.formatBytes(modelData.memoryUsed) + " / " + menu.formatBytes(modelData.memoryTotal) : "n/a"
                        fillColor: theme.secondary
                      }
                    }
                  }
                }
              }

              Column {
                width: parent.width - leftColumn.width - parent.spacing
                height: parent.height
                spacing: 12

                Section {
                  width: parent.width
                  height: 154
                  title: "Memory"
                  subtitle: menu.formatBytes(menu.snapshot.memory.used) + " / " + menu.formatBytes(menu.snapshot.memory.total)

                  StatBar {
                    width: parent.width
                    label: "RAM"
                    value: menu.snapshot.memory.percent || 0
                    detail: Math.round(menu.snapshot.memory.percent || 0) + "%"
                    fillColor: theme.accent
                  }

                  StatBar {
                    width: parent.width
                    label: "Swap"
                    value: menu.snapshot.swap.percent || 0
                    detail: menu.snapshot.swap.total > 0 ? Math.round(menu.snapshot.swap.percent || 0) + "%" : "Off"
                    fillColor: theme.secondary
                  }

                  Row {
                    width: parent.width
                    height: 24
                    spacing: 8

                    Repeater {
                      model: menu.memHistory

                      Rectangle {
                        required property real modelData
                        width: Math.max(5, (parent.width - parent.spacing * 23) / 24)
                        height: parent.height
                        radius: 999
                        color: theme.surfaceHigh

                        Rectangle {
                          anchors.bottom: parent.bottom
                          width: parent.width
                          height: Math.max(3, parent.height * Math.max(0, Math.min(100, modelData)) / 100)
                          radius: parent.radius
                          color: theme.accentContainer
                        }
                      }
                    }
                  }
                }

                Section {
                  width: parent.width
                  height: 136
                  title: "Network"
                  subtitle: menu.snapshot.network.interface || "offline"

                  Row {
                    width: parent.width
                    height: 38
                    spacing: 10

                    Rectangle {
                      width: (parent.width - parent.spacing) / 2
                      height: parent.height
                      radius: theme.radius
                      color: theme.surfaceHigh

                      Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Down"
                        color: theme.muted
                        font.pixelSize: 11
                        font.weight: Font.Medium
                      }

                      Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: menu.rateText(menu.snapshot.network.rxRate)
                        color: theme.foreground
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                      }
                    }

                    Rectangle {
                      width: (parent.width - parent.spacing) / 2
                      height: parent.height
                      radius: theme.radius
                      color: theme.surfaceHigh

                      Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Up"
                        color: theme.muted
                        font.pixelSize: 11
                        font.weight: Font.Medium
                      }

                      Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: menu.rateText(menu.snapshot.network.txRate)
                        color: theme.foreground
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                      }
                    }
                  }

                  StatBar {
                    width: parent.width
                    label: "Processes"
                    value: Math.min(100, (menu.snapshot.processes || []).length)
                    detail: (menu.snapshot.processes || []).length + " shown"
                    fillColor: theme.secondary
                  }
                }

                Section {
                  width: parent.width
                  height: parent.height - 314
                  title: "Storage"
                  subtitle: "Mounted"

                  Repeater {
                    model: menu.snapshot.disks || []

                    Column {
                      required property var modelData
                      width: parent.width
                      spacing: 3

                      Row {
                        width: parent.width
                        height: 18

                        Text {
                          width: parent.width / 2
                          text: modelData.mount || ""
                          color: theme.foreground
                          elide: Text.ElideRight
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                        }

                        Text {
                          width: parent.width / 2
                          text: menu.formatBytes(modelData.used) + " / " + menu.formatBytes(modelData.size)
                          color: theme.muted
                          horizontalAlignment: Text.AlignRight
                          elide: Text.ElideRight
                          font.pixelSize: 11
                        }
                      }

                      StatBar {
                        width: parent.width
                        label: ""
                        labelWidth: 0
                        value: modelData.percent || 0
                        detail: Math.round(modelData.percent || 0) + "%"
                        fillColor: theme.secondary
                      }
                    }
                  }
                }
              }
            }

            Column {
              width: parent.width
              height: parent.height - y
              spacing: 12
              visible: menu.hasData && menu.activeTab === "programs"

              Rectangle {
                width: parent.width
                height: 42
                radius: theme.radiusLarge
                color: theme.surface
                border.width: 1
                border.color: programSearch.activeFocus ? theme.accent : theme.border

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  anchors.rightMargin: 12
                  spacing: 10

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    color: theme.muted
                    font.pixelSize: 15
                  }

                  TextInput {
                    id: programSearch
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 25
                    height: parent.height
                    text: menu.programQuery
                    color: theme.foreground
                    selectionColor: theme.accentContainer
                    selectedTextColor: theme.accentContainerForeground
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    font.pixelSize: 14
                    onTextChanged: menu.programQuery = text
                    Keys.onEscapePressed: menu.open = false
                    Keys.onReturnPressed: menu.killProcess(menu.selectedProcess)
                    Keys.onEnterPressed: menu.killProcess(menu.selectedProcess)
                    Keys.onPressed: event => {
                      if (event.key === Qt.Key_Down) {
                        menu.cycleProcess(1);
                        event.accepted = true;
                      } else if (event.key === Qt.Key_Up) {
                        menu.cycleProcess(-1);
                        event.accepted = true;
                      }
                    }
                  }
                }
              }

              Row {
                width: parent.width
                height: 24
                spacing: 10

                Text {
                  width: parent.width - 220
                  text: menu.filteredProcesses.length + " programs"
                  color: theme.muted
                  font.pixelSize: 11
                  font.weight: Font.Medium
                }

                Text {
                  width: 56
                  text: "CPU"
                  color: theme.muted
                  horizontalAlignment: Text.AlignRight
                  font.pixelSize: 10
                  font.weight: Font.DemiBold
                }

                Text {
                  width: 56
                  text: "MEM"
                  color: theme.muted
                  horizontalAlignment: Text.AlignRight
                  font.pixelSize: 10
                  font.weight: Font.DemiBold
                }
              }

              Rectangle {
                width: parent.width
                height: parent.height - 78
                radius: theme.radiusLarge
                color: theme.surface
                border.width: 1
                border.color: theme.border
                clip: true

                Text {
                  anchors.centerIn: parent
                  text: "No matching programs"
                  color: theme.muted
                  font.pixelSize: 13
                  visible: menu.filteredProcesses.length === 0
                }

                ListView {
                  id: programList
                  anchors.fill: parent
                  anchors.margins: 8
                  model: menu.filteredProcesses
                  spacing: 4
                  clip: true
                  boundsBehavior: Flickable.StopAtBounds
                  currentIndex: menu.selectedProcessIndex
                  visible: menu.filteredProcesses.length > 0

                  delegate: ProgramRow {
                    required property var modelData
                    required property int index
                    process: modelData
                    selected: menu.selectedProcessIndex === index
                    onSelectedRequested: menu.selectedProcessIndex = index
                    onKillRequested: {
                      menu.selectedProcessIndex = index;
                      menu.killProcess(modelData);
                    }
                  }
                }
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              visible: !menu.hasData && menu.errorMessage.length === 0
              text: "Collecting system data"
              color: theme.muted
              font.pixelSize: 13
            }
          }
        }
      }
    }
  }
}

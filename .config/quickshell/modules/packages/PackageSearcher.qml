import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../shared"

Scope {
  id: root

  readonly property var sourceFilters: [
    { key: "all", label: "All" },
    { key: "official", label: "Official" },
    { key: "aur", label: "AUR" },
    { key: "installed", label: "Installed" }
  ]

  readonly property string searchScript: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/package-search.sh"
  readonly property string detailScript: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/package-detail.sh"
  readonly property string actionScript: Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/package-action.sh"

  Theme {
    id: theme
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: menu

      required property var modelData
      property bool open: false
      property string query: ""
      property string sourceFilter: "all"
      property var results: []
      property var detail: null
      property int selectedIndex: 0
      property int searchToken: 0
      property int detailToken: 0
      property bool loading: false
      property bool detailLoading: false
      property string errorMessage: ""
      property string detailError: ""
      property bool hasAurHelper: false
      property string aurHelper: ""
      property bool hasTerminal: false
      property string activeSearchKey: ""
      property var aurSearchCache: ({})
      readonly property var selectedPackage: results.length > 0 ? results[Math.max(0, Math.min(selectedIndex, results.length - 1))] : null
      readonly property var hyprMonitor: Hyprland.monitorFor(screen)
      readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : screen.name

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
          query = "";
          sourceFilter = "all";
          results = [];
          detail = null;
          errorMessage = "";
          detailError = "";
          selectedIndex = 0;
          detectToolsProc.exec(["bash", "-lc", "helper=''; command -v paru >/dev/null 2>&1 && helper=paru; [[ -z \"$helper\" ]] && command -v yay >/dev/null 2>&1 && helper=yay; terminal=false; for term in ghostty kitty alacritty wezterm foot konsole; do command -v \"$term\" >/dev/null 2>&1 && terminal=true && break; done; printf '%s\\n%s\\n' \"$helper\" \"$terminal\""]);
          Qt.callLater(() => searchInput.forceActiveFocus());
        }
      }

      onSelectedIndexChanged: fetchSelectedDetails()

      function resetSelection() {
        selectedIndex = 0;
        Qt.callLater(() => {
          if (resultList) {
            resultList.positionViewAtIndex(0, ListView.Beginning);
          }
        });
      }

      function cycleSelection(direction) {
        const count = results.length;
        if (count === 0) {
          selectedIndex = 0;
          return;
        }

        selectedIndex = (selectedIndex + direction + count) % count;
      }

      function sourceLabel(pkg) {
        if (!pkg) {
          return "";
        }

        return pkg.source === "aur" ? "AUR" : (pkg.repository || pkg.source || "official");
      }

      function installedLabel(pkg) {
        return pkg && pkg.installed ? "Installed" : "";
      }

      function arrayText(value) {
        if (!value) {
          return "None";
        }

        if (Array.isArray(value)) {
          return value.length > 0 ? value.join(", ") : "None";
        }

        return value.toString().length > 0 ? value.toString() : "None";
      }

      function dateText(epoch) {
        if (!epoch) {
          return "Unknown";
        }

        return new Date(epoch * 1000).toLocaleDateString();
      }

      function actionAllowed(action, pkg) {
        if (!pkg) {
          return false;
        }
        if (action === "remove" || action === "update") {
          return !!pkg.installed;
        }
        if ((action === "install" || action === "pkgbuild") && pkg.source === "aur") {
          return hasAurHelper;
        }
        if (action === "pkgbuild" || action === "aur-page") {
          return pkg.source === "aur";
        }
        return true;
      }

      function runSearch() {
        const trimmed = query.trim();
        if (trimmed.length === 0 && sourceFilter !== "installed") {
          results = [];
          detail = null;
          errorMessage = "";
          loading = false;
          return;
        }

        searchToken += 1;
        activeSearchKey = sourceFilter + "::" + trimmed;
        if (sourceFilter === "aur" && aurSearchCache[activeSearchKey]) {
          results = aurSearchCache[activeSearchKey];
          loading = false;
          errorMessage = "";
          resetSelection();
          fetchSelectedDetails();
          return;
        }

        loading = true;
        errorMessage = "";
        searchProc.exec([root.searchScript, sourceFilter, trimmed, searchToken.toString()]);
      }

      function fetchSelectedDetails() {
        const pkg = selectedPackage;
        if (!pkg || !pkg.name) {
          detail = null;
          return;
        }

        detailToken += 1;
        detailLoading = true;
        detailError = "";
        detailProc.exec([root.detailScript, pkg.source || "official", pkg.name, detailToken.toString()]);
      }

      function runAction(action) {
        const pkg = detail || selectedPackage;
        if (!pkg || !pkg.name) {
          return;
        }

        if (!hasTerminal && ["install", "remove", "update", "pkgbuild"].indexOf(action) >= 0) {
          detailError = "No supported terminal found.";
          return;
        }

        if (!actionAllowed(action, pkg)) {
          detailError = pkg.source === "aur" && !hasAurHelper
            ? "Install paru or yay for AUR actions."
            : "Action is not available for this package.";
          return;
        }

        Quickshell.execDetached([root.actionScript, action, pkg.source || "official", pkg.name]);
      }

      IpcHandler {
        target: "packages." + menu.ipcTargetName

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
        id: searchDebounce
        interval: 320
        repeat: false
        onTriggered: menu.runSearch()
      }

      Process {
        id: detectToolsProc
        stdout: StdioCollector {
          onStreamFinished: {
            const lines = text.trim().split("\n");
            menu.aurHelper = lines[0] || "";
            menu.hasAurHelper = menu.aurHelper.length > 0;
            menu.hasTerminal = (lines[1] || "") === "true";
          }
        }
      }

      Process {
        id: searchProc
        stdout: StdioCollector {
          onStreamFinished: {
            menu.loading = false;
            try {
              const payload = JSON.parse(text);
              if (payload.token !== menu.searchToken.toString()) {
                return;
              }
              menu.errorMessage = payload.error || "";
              menu.results = payload.results || [];
              if (menu.sourceFilter === "aur" && menu.errorMessage.length === 0) {
                const nextCache = Object.assign({}, menu.aurSearchCache);
                nextCache[menu.activeSearchKey] = menu.results;
                menu.aurSearchCache = nextCache;
              }
              menu.resetSelection();
              menu.fetchSelectedDetails();
            } catch (error) {
              menu.errorMessage = "Package search returned malformed data.";
              menu.results = [];
              menu.detail = null;
            }
          }
        }
      }

      Process {
        id: detailProc
        stdout: StdioCollector {
          onStreamFinished: {
            menu.detailLoading = false;
            try {
              const payload = JSON.parse(text);
              if (payload.token !== menu.detailToken.toString()) {
                return;
              }
              menu.detailError = payload.error || "";
              menu.detail = payload.package || null;
            } catch (error) {
              menu.detailError = "Package details returned malformed data.";
              menu.detail = null;
            }
          }
        }
      }

      Item {
        id: overlay
        anchors.fill: parent
        focus: menu.open
        Keys.onEscapePressed: menu.open = false

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
          width: Math.min(parent.width - 64, 1120)
          height: Math.min(parent.height - 80, 720)
          radius: theme.radiusLarge
          color: theme.panel
          border.width: 1
          border.color: theme.border

          MouseArea {
            anchors.fill: parent
          }

          Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Rectangle {
              width: parent.width
              height: 42
              radius: theme.radiusLarge
              color: theme.surface
              border.width: 1
              border.color: searchInput.activeFocus ? theme.accent : theme.border

              Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰏖"
                  color: theme.muted
                  font.pixelSize: 15
                }

                TextInput {
                  id: searchInput
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 25
                  height: parent.height
                  text: menu.query
                  color: theme.foreground
                  selectionColor: theme.accentContainer
                  selectedTextColor: theme.accentContainerForeground
                  verticalAlignment: TextInput.AlignVCenter
                  clip: true
                  font.pixelSize: 14
                  onTextChanged: {
                    menu.query = text;
                    menu.searchToken += 1;
                    searchDebounce.restart();
                  }
                  Keys.onEscapePressed: menu.open = false
                  Keys.onReturnPressed: menu.fetchSelectedDetails()
                  Keys.onEnterPressed: menu.fetchSelectedDetails()
                  Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down) {
                      menu.cycleSelection(1);
                      event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                      menu.cycleSelection(-1);
                      event.accepted = true;
                    }
                  }
                }
              }
            }

            Row {
              width: parent.width
              height: 30
              spacing: 8

              Repeater {
                model: root.sourceFilters

                Rectangle {
                  required property var modelData
                  readonly property bool active: menu.sourceFilter === modelData.key

                  width: Math.max(78, filterLabel.implicitWidth + 24)
                  height: parent.height
                  radius: theme.radiusLarge
                  color: active ? theme.accentContainer : filterArea.containsMouse ? theme.surfaceHover : theme.surface
                  border.width: 1
                  border.color: active ? theme.accent : theme.border

                  Text {
                    id: filterLabel
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.active ? theme.accentContainerForeground : theme.foreground
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                  }

                  MouseArea {
                    id: filterArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      menu.sourceFilter = parent.modelData.key;
                      menu.searchToken += 1;
                      searchDebounce.restart();
                    }
                  }
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: menu.hasAurHelper ? "AUR helper: " + menu.aurHelper : "AUR install disabled: paru/yay missing"
                color: menu.hasAurHelper ? theme.muted : theme.warning
                font.pixelSize: 11
                font.weight: Font.Medium
              }
            }

            Row {
              width: parent.width
              height: parent.height - y
              spacing: 12

              Rectangle {
                id: resultPane
                width: Math.round(parent.width * 0.44)
                height: parent.height
                radius: theme.radiusLarge
                color: theme.surface
                border.width: 1
                border.color: theme.border
                clip: true

                Text {
                  anchors.centerIn: parent
                  width: parent.width - 32
                  text: menu.loading ? "Searching packages" : menu.errorMessage.length > 0 ? menu.errorMessage : menu.sourceFilter === "installed" && menu.query.trim().length === 0 ? "Installed packages" : "No packages found"
                  color: menu.errorMessage.length > 0 ? theme.urgent : theme.muted
                  horizontalAlignment: Text.AlignHCenter
                  font.pixelSize: 13
                  visible: menu.results.length === 0
                }

                ListView {
                  id: resultList
                  anchors.fill: parent
                  anchors.margins: 8
                  model: menu.results
                  clip: true
                  spacing: 6
                  visible: menu.results.length > 0
                  boundsBehavior: Flickable.StopAtBounds
                  currentIndex: menu.selectedIndex

                  delegate: Rectangle {
                    id: resultRow
                    required property var modelData
                    required property int index
                    readonly property bool selected: menu.selectedIndex === index

                    width: resultList.width
                    height: 76
                    radius: theme.radiusLarge
                    color: selected ? theme.accentContainer : rowArea.containsMouse ? theme.surfaceHover : "transparent"

                    Column {
                      anchors.left: parent.left
                      anchors.leftMargin: 12
                      anchors.right: parent.right
                      anchors.rightMargin: 12
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: 5

                      Row {
                        width: parent.width
                        height: 18
                        spacing: 8

                        Text {
                          width: parent.width - sourceBadge.width - installedText.implicitWidth - 24
                          text: resultRow.modelData.name || ""
                          color: resultRow.selected ? theme.accentContainerForeground : theme.foreground
                          elide: Text.ElideRight
                          font.pixelSize: 13
                          font.weight: Font.DemiBold
                        }

                        Rectangle {
                          id: sourceBadge
                          width: sourceText.implicitWidth + 14
                          height: 18
                          radius: theme.radiusSmall
                          color: resultRow.selected ? theme.accent : theme.surfaceHigh

                          Text {
                            id: sourceText
                            anchors.centerIn: parent
                            text: menu.sourceLabel(resultRow.modelData)
                            color: resultRow.selected ? theme.accentForeground : theme.muted
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                          }
                        }

                        Text {
                          id: installedText
                          text: menu.installedLabel(resultRow.modelData)
                          color: resultRow.selected ? theme.accentContainerForeground : theme.accent
                          visible: text.length > 0
                          font.pixelSize: 10
                          font.weight: Font.DemiBold
                        }
                      }

                      Text {
                        width: parent.width
                        text: (resultRow.modelData.version || "") + (resultRow.modelData.description ? "  " + resultRow.modelData.description : "")
                        color: resultRow.selected ? theme.accentContainerForeground : theme.muted
                        elide: Text.ElideRight
                        font.pixelSize: 11
                      }
                    }

                    MouseArea {
                      id: rowArea
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onEntered: menu.selectedIndex = index
                      onClicked: {
                        menu.selectedIndex = index;
                        menu.fetchSelectedDetails();
                      }
                    }
                  }
                }
              }

              Rectangle {
                id: detailPane
                width: parent.width - resultPane.width - parent.spacing
                height: parent.height
                radius: theme.radiusLarge
                color: theme.surfaceHigh
                border.width: 1
                border.color: theme.border
                clip: true

                Text {
                  anchors.centerIn: parent
                  width: parent.width - 32
                  text: menu.detailLoading ? "Loading package details" : menu.detailError.length > 0 ? menu.detailError : "Select a package"
                  color: menu.detailError.length > 0 ? theme.urgent : theme.muted
                  horizontalAlignment: Text.AlignHCenter
                  font.pixelSize: 13
                  visible: !menu.detail
                }

                Flickable {
                  anchors.fill: parent
                  anchors.margins: 14
                  clip: true
                  contentWidth: width
                  contentHeight: detailColumn.height
                  visible: !!menu.detail
                  boundsBehavior: Flickable.StopAtBounds

                  Column {
                    id: detailColumn
                    width: parent.width
                    spacing: 12

                    Row {
                      width: parent.width
                      spacing: 10

                      Column {
                        width: parent.width - actionColumn.width - parent.spacing
                        spacing: 5

                        Text {
                          width: parent.width
                          text: menu.detail ? menu.detail.name : ""
                          color: theme.foreground
                          elide: Text.ElideRight
                          font.pixelSize: 21
                          font.weight: Font.DemiBold
                        }

                        Text {
                          width: parent.width
                          text: menu.detail ? [menu.detail.version || "unknown", menu.sourceLabel(menu.detail), menu.detail.installed ? "installed" : "not installed"].join("  ") : ""
                          color: theme.muted
                          elide: Text.ElideRight
                          font.pixelSize: 12
                          font.weight: Font.Medium
                        }
                      }

                      Column {
                        id: actionColumn
                        width: 154
                        spacing: 6

                        Repeater {
                          model: [
                            { label: "Install", action: "install", visible: menu.detail && !menu.detail.installed },
                            { label: "Remove", action: "remove", visible: menu.detail && menu.detail.installed },
                            { label: menu.detail && menu.detail.installed ? "Update/Reinstall" : "Reinstall", action: "update", visible: menu.detail && menu.detail.installed },
                            { label: "View PKGBUILD", action: "pkgbuild", visible: menu.detail && menu.detail.source === "aur" },
                            { label: "Open AUR", action: "aur-page", visible: menu.detail && menu.detail.source === "aur" },
                            { label: "Copy name", action: "copy-name", visible: !!menu.detail }
                          ]

                          Rectangle {
                            required property var modelData
                            readonly property bool allowed: menu.actionAllowed(modelData.action, menu.detail)

                            width: parent.width
                            height: modelData.visible ? 30 : 0
                            radius: theme.radiusLarge
                            visible: modelData.visible
                            color: allowed ? actionArea.containsMouse ? theme.accent : theme.accentContainer : theme.surface
                            border.width: 1
                            border.color: allowed ? theme.accent : theme.border

                            Text {
                              anchors.centerIn: parent
                              text: parent.modelData.label
                              color: parent.allowed ? theme.accentContainerForeground : theme.muted
                              elide: Text.ElideRight
                              font.pixelSize: 11
                              font.weight: Font.DemiBold
                            }

                            MouseArea {
                              id: actionArea
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: parent.allowed ? Qt.PointingHandCursor : Qt.ArrowCursor
                              onClicked: menu.runAction(parent.modelData.action)
                            }
                          }
                        }
                      }
                    }

                    Text {
                      width: parent.width
                      text: menu.detail ? (menu.detail.description || "No description available.") : ""
                      color: theme.foreground
                      wrapMode: Text.WordWrap
                      font.pixelSize: 13
                    }

                    Repeater {
                      model: menu.detail ? [
                        { label: "Maintainer", value: menu.detail.maintainer || "Unknown", visible: menu.detail.source === "aur" },
                        { label: "Votes", value: (menu.detail.votes || 0).toString(), visible: menu.detail.source === "aur" },
                        { label: "Popularity", value: (menu.detail.popularity || 0).toString(), visible: menu.detail.source === "aur" },
                        { label: "Out of date", value: menu.detail.outOfDate ? "Yes" : "No", visible: menu.detail.source === "aur" },
                        { label: "Last updated", value: menu.dateText(menu.detail.lastModified), visible: menu.detail.source === "aur" },
                        { label: "License", value: menu.arrayText(menu.detail.license), visible: true },
                        { label: "Dependencies", value: menu.arrayText(menu.detail.depends), visible: true },
                        { label: "Optional dependencies", value: menu.arrayText(menu.detail.optDepends), visible: true },
                        { label: "Provides", value: menu.arrayText(menu.detail.provides), visible: true },
                        { label: "Conflicts", value: menu.arrayText(menu.detail.conflicts), visible: true }
                      ] : []

                      Column {
                        required property var modelData
                        width: parent.width
                        spacing: 3
                        visible: modelData.visible

                        Text {
                          width: parent.width
                          text: parent.modelData.label
                          color: theme.muted
                          font.pixelSize: 10
                          font.weight: Font.DemiBold
                        }

                        Text {
                          width: parent.width
                          text: parent.modelData.value
                          color: theme.foreground
                          wrapMode: Text.WordWrap
                          font.pixelSize: 12
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

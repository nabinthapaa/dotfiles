import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../shared"
import "components"

Item {
  required property var parentWindow
  property bool open: false

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

  id: menu
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
  readonly property var hyprMonitor: Hyprland.monitorFor(parentWindow.screen)
  readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : parentWindow.screen.name

  opacity: open ? 1 : 0
  visible: opacity > 0
  Behavior on opacity { NumberAnimation { duration: 150 } }
  Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

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
        searchProc.exec([menu.searchScript, sourceFilter, trimmed, searchToken.toString()]);
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
        detailProc.exec([menu.detailScript, pkg.source || "official", pkg.name, detailToken.toString()]);
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

        Quickshell.execDetached([menu.actionScript, action, pkg.source || "official", pkg.name]);
      }

      IpcHandler {
        target: "packageManager." + menu.ipcTargetName

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

  Column {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 12
    focus: menu.open
    Keys.onEscapePressed: menu.open = false

    SearchBox {
      id: searchInput
      width: parent.width
      icon: "󰏖"
      text: menu.query
      onSearchTextChanged: (newText) => {
        menu.query = newText;
        menu.searchToken += 1;
        searchDebounce.restart();
      }
      onAccepted: menu.fetchSelectedDetails()
      onEscapePressed: menu.open = false
      onMoveSelection: (direction) => {
        menu.cycleSelection(direction > 0 ? 1 : -1);
      }
    }

    PackageFilters {
      menu: menu
      sourceFilters: menu.sourceFilters
      onTriggerSearch: searchDebounce.restart()
    }

    Row {
      width: parent.width
      height: parent.height - y
      spacing: 12

      PackageList {
        id: resultPane
        width: Math.round(parent.width * 0.44)
        height: parent.height
        menu: menu
      }

      PackageDetails {
        id: detailPane
        width: parent.width - resultPane.width - parent.spacing
        height: parent.height
        menu: menu
      }
    }
  }
}

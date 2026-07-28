import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../../shared"
import "applauncher"
import "applauncher/providers"

Item {
  id: root

  required property var parentWindow

  property bool open: false
  property string query: ""
  property int selectedIndex: 0

  readonly property var hyprMonitor: Hyprland.monitorFor(root.parentWindow.screen)
  readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : root.parentWindow.screen.name
  readonly property int popupWidth: Math.min(560, root.parentWindow.width - theme.islandPaddingH * 2)
  readonly property int popupHeight: Math.min(580, root.parentWindow.screen.height - theme.barHeight - theme.islandPaddingH * 2)

  width: 0
  height: 0

  AppProvider { id: appProvider }
  FileProvider { id: fileProvider }
  BannerManager { id: bannerManager }

  property var activeProvider: appProvider

  onOpenChanged: {
    if (open) {
      query = "";
      resetSelection();
      searchFocusTimer.restart();
    }
  }

  onSelectedIndexChanged: {
    if (root.open && appList && activeProvider.results.length > 0) {
      appList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
  }

  Timer {
    id: searchDebounce
    interval: 150
    repeat: false
    onTriggered: {
      const q = root.query.trim();
      
      if (q.startsWith("f: ") || q.startsWith("file: ")) {
        root.activeProvider = fileProvider;
        const subquery = q.replace(/^(f|file):\s*/, "");
        fileProvider.search(subquery);
        bannerManager.search(""); // clear banner
      } else {
        root.activeProvider = appProvider;
        appProvider.search(q);
        bannerManager.search(q);
      }
    }
  }

  function launch(entry) {
    if (selectedIndex === -1 && bannerManager.hasBanner) {
      bannerManager.launch();
      open = false;
      return;
    }

    if (!entry) return;

    activeProvider.launch(entry);
    open = false;
  }

  function selectedApplication() {
    if (activeProvider.results.length === 0) return null;
    return activeProvider.results[Math.max(0, Math.min(selectedIndex, activeProvider.results.length - 1))];
  }

  function cycleSelection(direction) {
    const count = activeProvider.results.length;
    const minIndex = bannerManager.hasBanner ? -1 : 0;
    
    if (count === 0) {
      selectedIndex = minIndex;
      return;
    }

    let nextIndex = selectedIndex + direction;
    if (nextIndex < minIndex) nextIndex = count - 1;
    if (nextIndex >= count) nextIndex = minIndex;
    
    selectedIndex = nextIndex;
  }

  function resetSelection() {
    selectedIndex = bannerManager.hasBanner ? -1 : 0;
    Qt.callLater(() => {
      if (appList) {
        appList.positionViewAtIndex(0, ListView.Beginning);
      }
    });
  }

  Theme {
    id: theme
  }

  Timer {
    id: searchFocusTimer
    interval: 40
    repeat: false
    onTriggered: searchInput.forceActiveFocus()
  }

  IpcHandler {
    target: "appLauncher." + root.ipcTargetName

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
  }

  Column {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 12
    opacity: root.open ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Row {
      width: parent.width
      height: 42
      spacing: 10

      SearchBox {
        id: searchInput
        width: parent.width
        icon: "󰍉"
        text: root.query
        onSearchTextChanged: (newText) => {
          root.query = newText;
          root.resetSelection();
          searchDebounce.restart();
        }
        onAccepted: root.launch(root.selectedApplication())
        onEscapePressed: root.open = false
        onMoveSelection: (direction) => { root.cycleSelection(direction); }
      }
    }

    Text {
      width: parent.width
      text: root.query.length === 0 ? root.activeProvider.name : root.activeProvider.results.length + " results"
      color: theme.muted
      font.pixelSize: 11
      font.weight: Font.Medium
    }

    Item {
      width: parent.width
      height: parent.height - y

      Text {
        anchors.centerIn: parent
        width: parent.width - 32
        text: root.activeProvider.loading ? "Searching..." : "No results found"
        color: theme.muted
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 13
        visible: activeProvider.results.length === 0 && !bannerManager.hasBanner
      }

      Column {
        anchors.fill: parent
        spacing: 12

        Rectangle {
          width: parent.width
          height: bannerManager.hasBanner ? 64 : 0
          visible: bannerManager.hasBanner
          radius: theme.radiusLarge
          color: root.selectedIndex === -1 ? theme.accentContainer : (qalcArea.containsMouse ? theme.surfaceHover : theme.surface)

          Text {
            anchors.centerIn: parent
            width: parent.width - 32
            text: bannerManager.bannerText
            color: root.selectedIndex === -1 ? theme.accentContainerForeground : theme.foreground
            font.pixelSize: 24
            font.weight: root.selectedIndex === -1 ? Font.Bold : Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
          }

          MouseArea {
            id: qalcArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = -1
            onClicked: root.launch(null)
          }

          Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        }

        GridView {
          id: appList

          width: parent.width
          height: parent.height - (bannerManager.hasBanner ? 64 + parent.spacing : 0)
          clip: true
          visible: root.activeProvider.results.length > 0
          model: root.activeProvider.results
          cellWidth: width / Math.max(1, Math.floor(width / 140))
          cellHeight: 110
          boundsBehavior: Flickable.StopAtBounds
          currentIndex: Math.max(0, root.selectedIndex)

          Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

          delegate: AppLauncherDelegate {
            width: appList.cellWidth
            height: appList.cellHeight
            selectedIndex: root.selectedIndex
            popupOpen: root.open
            onHoverEntered: (hoverIndex) => { root.selectedIndex = hoverIndex; }
            onLaunchClicked: (appEntry) => { root.launch(appEntry); }
          }
        }
      }
    }
  }
}

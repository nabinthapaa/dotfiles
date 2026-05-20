import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../../shared"

Item {
  id: root

  required property var parentWindow

  property bool open: false
  property string query: ""
  property int selectedIndex: 0
  property var wallpapers: []
  property string currentWallpaper: ""
  readonly property var filteredWallpapers: filterWallpapers()
  readonly property var hyprMonitor: Hyprland.monitorFor(root.parentWindow.screen)
  readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : root.parentWindow.screen.name
  readonly property int popupWidth: Math.min(760, root.parentWindow.width - theme.barPadding * 2)
  readonly property int popupHeight: Math.min(560, root.parentWindow.screen.height - theme.barHeight - theme.barPadding * 2)

  width: 0
  height: 0

  onOpenChanged: {
    if (open) {
      query = "";
      refreshWallpapers();
      searchFocusTimer.restart();
    }
  }

  onSelectedIndexChanged: {
    if (root.open && wallpaperList && root.filteredWallpapers.length > 0) {
      wallpaperList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
  }

  function basename(path) {
    return path.split("/").pop();
  }

  function displayName(path) {
    return basename(path).replace(/\.(jpe?g|png|webp)$/i, "");
  }

  function fileUrl(path) {
    return encodeURI("file://" + path).replace(/#/g, "%23");
  }

  function filterWallpapers() {
    const search = query.trim().toLowerCase();
    const items = wallpapers.slice().sort((a, b) => displayName(a).localeCompare(displayName(b)));

    if (search.length === 0) {
      return items;
    }

    return items.filter(path => {
      const haystack = [displayName(path), basename(path), path].join(" ").toLowerCase();
      return haystack.indexOf(search) >= 0;
    });
  }

  function selectedWallpaper() {
    if (filteredWallpapers.length === 0) {
      return "";
    }

    return filteredWallpapers[Math.max(0, Math.min(selectedIndex, filteredWallpapers.length - 1))];
  }

  function cycleSelection(direction) {
    const count = filteredWallpapers.length;
    if (count === 0) {
      selectedIndex = 0;
      return;
    }

    selectedIndex = (selectedIndex + direction + count) % count;
  }

  function resetSelection(preferCurrent) {
    let nextIndex = 0;

    if (preferCurrent && currentWallpaper.length > 0) {
      const currentIndex = filteredWallpapers.indexOf(currentWallpaper);
      if (currentIndex >= 0) {
        nextIndex = currentIndex;
      }
    }

    selectedIndex = nextIndex;
    Qt.callLater(() => {
      if (wallpaperList) {
        wallpaperList.positionViewAtIndex(nextIndex, ListView.Beginning);
      }
    });
  }

  function refreshWallpapers() {
    wallpaperListProc.exec(["bash", "-lc", "find \"$HOME/wallpaper\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%p\\n' | sort -f"]);
    currentWallpaperProc.exec(["bash", "-lc", "cat \"$HOME/.config/hypr/cache/current_wallpaper\" 2>/dev/null || true"]);
  }

  function applyWallpaper(path) {
    if (path.length === 0) {
      return;
    }

    Quickshell.execDetached([
      Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/apply-wallpaper.sh",
      path
    ]);

    currentWallpaper = path;
    open = false;
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

  Process {
    id: wallpaperListProc

    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        root.wallpapers = output.length === 0
          ? []
          : output.split("\n").filter(path => path.length > 0);
        root.resetSelection(root.query.length === 0);
      }
    }
  }

  Process {
    id: currentWallpaperProc

    stdout: StdioCollector {
      onStreamFinished: {
        root.currentWallpaper = text.trim();
        if (root.query.length === 0) {
          root.resetSelection(true);
        }
      }
    }
  }

  IpcHandler {
    target: "wallpaperLauncher." + root.ipcTargetName

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

  PopupWindow {
    id: wallpaperPopup

    anchor.window: root.parentWindow
    anchor.rect.x: (root.parentWindow.width - width) / 2
    anchor.rect.y: Math.max(theme.barHeight + 8, (root.parentWindow.screen.height - height) / 2)
    implicitWidth: root.popupWidth
    implicitHeight: root.popupHeight
    visible: root.open
    grabFocus: true
    color: "transparent"

    onVisibleChanged: {
      if (!visible) {
        root.open = false;
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: theme.radiusLarge
      color: theme.panel
      border.width: 1
      border.color: theme.border
      opacity: root.open ? 1 : 0
      scale: root.open ? 1 : 0.97
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
              text: "󰸉"
              color: theme.muted
              font.pixelSize: 15
            }

            TextInput {
              id: searchInput

              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 25
              height: parent.height
              text: root.query
              color: theme.foreground
              selectionColor: theme.accentContainer
              selectedTextColor: theme.accentContainerForeground
              verticalAlignment: TextInput.AlignVCenter
              clip: true
              font.pixelSize: 14
              onTextChanged: {
                root.query = text;
                root.resetSelection(false);
              }
              onAccepted: root.applyWallpaper(root.selectedWallpaper())

              Keys.onEscapePressed: root.open = false
              Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
                  root.cycleSelection(1);
                  event.accepted = true;
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
                  root.cycleSelection(-1);
                  event.accepted = true;
                }
              }
            }
          }
        }

        Row {
          width: parent.width
          height: parent.height - y
          spacing: 12

          Rectangle {
            id: previewPane

            width: Math.round(parent.width * 0.48)
            height: parent.height
            radius: theme.radiusLarge
            color: theme.surface
            border.width: 1
            border.color: theme.border
            clip: true

            Image {
              anchors.fill: parent
              source: root.selectedWallpaper().length > 0 ? root.fileUrl(root.selectedWallpaper()) : ""
              sourceSize.width: width
              sourceSize.height: height
              fillMode: Image.PreserveAspectCrop
              visible: source.toString().length > 0
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 72
              color: theme.panel
              opacity: 0.92
              visible: root.selectedWallpaper().length > 0
            }

            Column {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: 14
              spacing: 4
              visible: root.selectedWallpaper().length > 0

              Text {
                width: parent.width
                text: root.displayName(root.selectedWallpaper())
                color: theme.foreground
                elide: Text.ElideRight
                font.pixelSize: 14
                font.weight: Font.DemiBold
              }

              Text {
                width: parent.width
                text: root.selectedWallpaper() === root.currentWallpaper ? "Current wallpaper" : "Enter to apply"
                color: theme.muted
                elide: Text.ElideRight
                font.pixelSize: 11
                font.weight: Font.Medium
              }
            }

            Text {
              anchors.centerIn: parent
              width: parent.width - 32
              text: "No wallpaper selected"
              color: theme.muted
              horizontalAlignment: Text.AlignHCenter
              font.pixelSize: 13
              visible: root.selectedWallpaper().length === 0
            }
          }

          Rectangle {
            width: parent.width - previewPane.width - parent.spacing
            height: parent.height
            radius: theme.radiusLarge
            color: theme.surfaceHigh
            border.width: 1
            border.color: theme.border
            clip: true

            Text {
              anchors.centerIn: parent
              width: parent.width - 32
              text: "No wallpapers found"
              color: theme.muted
              horizontalAlignment: Text.AlignHCenter
              font.pixelSize: 13
              visible: root.filteredWallpapers.length === 0
            }

            ListView {
              id: wallpaperList

              anchors.fill: parent
              anchors.margins: 8
              clip: true
              visible: root.filteredWallpapers.length > 0
              model: root.filteredWallpapers
              spacing: 6
              boundsBehavior: Flickable.StopAtBounds
              currentIndex: root.selectedIndex

              delegate: Rectangle {
                id: wallpaperRow

                required property string modelData
                required property int index

                readonly property bool selected: root.selectedIndex === index
                readonly property bool current: modelData === root.currentWallpaper

                width: wallpaperList.width
                height: 50
                radius: theme.radiusLarge
                color: selected
                  ? theme.accentContainer
                  : wallpaperArea.containsMouse ? theme.surfaceHover : "transparent"

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 12
                  anchors.right: currentBadge.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.displayName(wallpaperRow.modelData)
                  color: wallpaperRow.selected ? theme.accentContainerForeground : theme.foreground
                  elide: Text.ElideRight
                  maximumLineCount: 1
                  font.pixelSize: 13
                  font.weight: wallpaperRow.selected ? Font.DemiBold : Font.Medium
                }

                Text {
                  id: currentBadge

                  anchors.right: parent.right
                  anchors.rightMargin: 12
                  anchors.verticalCenter: parent.verticalCenter
                  width: visible ? implicitWidth : 0
                  text: "Current"
                  color: wallpaperRow.selected ? theme.accentContainerForeground : theme.accent
                  visible: wallpaperRow.current
                  font.pixelSize: 10
                  font.weight: Font.DemiBold
                }

                MouseArea {
                  id: wallpaperArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selectedIndex = index
                  onClicked: root.applyWallpaper(wallpaperRow.modelData)
                }
              }
            }
          }
        }
      }
    }
  }
}

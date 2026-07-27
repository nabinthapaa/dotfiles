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
  readonly property int popupWidth: Math.min(880, root.parentWindow.width - theme.islandPaddingH * 2)
  readonly property int popupHeight: Math.min(680, root.parentWindow.screen.height - theme.barHeight - theme.islandPaddingH * 2)

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
    if (root.open && wallpaperGrid && root.filteredWallpapers.length > 0) {
      wallpaperGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
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
  
  function cycleSelectionGrid(dx, dy) {
    const count = filteredWallpapers.length;
    if (count === 0) return;
    
    // dx = -1/1 (left/right), dy = -1/1 (up/down)
    const cols = Math.max(1, Math.floor(wallpaperGrid.width / wallpaperGrid.cellWidth));
    
    let newIndex = selectedIndex;
    if (dx !== 0) {
        newIndex += dx;
    }
    if (dy !== 0) {
        newIndex += dy * cols;
    }
    
    // bounds check
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= count) newIndex = count - 1;
    
    selectedIndex = newIndex;
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
      if (wallpaperGrid) {
        wallpaperGrid.positionViewAtIndex(nextIndex, GridView.Beginning);
      }
    });
  }

  function refreshWallpapers() {
    wallpaperListProc.running = false;
    wallpaperListProc.running = true;
    currentWallpaperProc.running = false;
    currentWallpaperProc.running = true;
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
    command: ["bash", "-lc", "find \"$HOME/wallpaper\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%p\\n' | sort -f"]
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
    command: ["bash", "-lc", "cat \"$HOME/.config/hypr/cache/current_wallpaper\" 2>/dev/null || true"]
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
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }
      Behavior on opacity {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
      }

      Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Search Bar (Sleek, borderless look)
        Rectangle {
          width: parent.width
          height: 48
          radius: theme.radius
          color: theme.surface
          border.width: searchInput.activeFocus ? 2 : 1
          border.color: searchInput.activeFocus ? theme.accent : Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.4)

          Behavior on border.color { ColorAnimation { duration: 120 } }

          Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰸉"
              color: searchInput.activeFocus ? theme.accent : theme.muted
              font.pixelSize: 18
              Behavior on color { ColorAnimation { duration: 120 } }
            }

            TextInput {
              id: searchInput
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 32
              height: parent.height
              text: root.query
              color: theme.foreground
              selectionColor: theme.accentContainer
              selectedTextColor: theme.accentContainerForeground
              verticalAlignment: TextInput.AlignVCenter
              clip: true
              font.pixelSize: 15
              
              onTextChanged: {
                root.query = text;
                root.resetSelection(false);
              }
              onAccepted: root.applyWallpaper(root.selectedWallpaper())

              Keys.onEscapePressed: root.open = false
              Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
                  root.cycleSelectionGrid(1, 0); // Next
                  event.accepted = true;
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
                  root.cycleSelectionGrid(-1, 0); // Previous
                  event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                  root.cycleSelectionGrid(1, 0);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                  root.cycleSelectionGrid(-1, 0);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                  root.cycleSelectionGrid(0, 1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                  root.cycleSelectionGrid(0, -1);
                  event.accepted = true;
                }
              }
            }
          }
        }

        // Grid View Area
        Item {
          width: parent.width
          height: parent.height - y
          
          Text {
            anchors.centerIn: parent
            text: "No wallpapers found"
            color: theme.muted
            font.pixelSize: 14
            visible: root.filteredWallpapers.length === 0
          }

          GridView {
            id: wallpaperGrid
            anchors.fill: parent
            clip: true
            model: root.filteredWallpapers
            
            // 3 columns layout (account for scrollbar padding if any)
            cellWidth: Math.floor(width / 3)
            // 16:9 aspect ratio + spacing
            cellHeight: Math.round(cellWidth * (9/16)) + 8 
            
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            
            delegate: Item {
              id: wallpaperRow
              
              required property string modelData
              required property int index
              
              readonly property bool selected: root.selectedIndex === index
              readonly property bool current: modelData === root.currentWallpaper
              
              width: wallpaperGrid.cellWidth
              height: wallpaperGrid.cellHeight
              
              Rectangle {
                id: card
                anchors.fill: parent
                anchors.margins: 6
                radius: theme.radius
                color: theme.surfaceHigh
                clip: true
                
                border.width: wallpaperRow.selected ? 4 : 1
                border.color: wallpaperRow.selected ? theme.accent : Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.4)
                
                scale: wallpaperRow.selected ? 1.05 : (wallpaperArea.containsMouse ? 1.02 : 1.0)
                z: wallpaperRow.selected ? 10 : (wallpaperArea.containsMouse ? 5 : 0)
                
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on border.width { NumberAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                
                Image {
                  anchors.fill: parent
                  source: root.fileUrl(wallpaperRow.modelData)
                  sourceSize.width: width
                  sourceSize.height: height
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                }
                
                // Dim gradient overlay at the bottom for text readability
                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  height: 36
                  gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
                  }
                }
                
                Text {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  anchors.bottomMargin: 8
                  text: root.displayName(wallpaperRow.modelData)
                  color: "#ffffff" // Always white for contrast against dark gradient
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                }
                
                // Current wallpaper badge (Floating Checkmark)
                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.right
                  anchors.margins: 8
                  width: 24
                  height: 24
                  radius: theme.radiusPill
                  color: theme.accent
                  visible: wallpaperRow.current
                  
                  Text {
                    anchors.centerIn: parent
                    text: "󰄬"
                    color: theme.accentForeground
                    font.pixelSize: 14
                    font.weight: Font.Bold
                  }
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

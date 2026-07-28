import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../../shared"

Item {
  id: root

  required property var parentWindow

  property bool open: false
  property bool privateMode: false
  property string query: ""
  property int selectedIndex: 0
  property var clips: []
  property var pinnedIds: []
  readonly property var filteredClips: filterClips()
  readonly property var hyprMonitor: Hyprland.monitorFor(root.parentWindow.screen)
  readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : root.parentWindow.screen.name
  readonly property int popupWidth: Math.min(620, root.parentWindow.width - theme.islandPaddingH * 2)
  readonly property int popupHeight: Math.min(560, root.parentWindow.screen.height - theme.barHeight - theme.islandPaddingH * 2)

  width: 0
  height: 0

  onOpenChanged: {
    if (open) {
      query = "";
      loadPins();
      loadPrivateMode();
      refreshClips();
      searchFocusTimer.restart();
    }
  }

  onSelectedIndexChanged: {
    if (root.open && clipList && root.filteredClips.length > 0) {
      clipList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
  }

  function filterClips() {
    const search = query.trim().toLowerCase();
    const items = orderedClips();

    if (search.length === 0) {
      return items;
    }

    return items.filter(clip => previewText(clip).toLowerCase().indexOf(search) >= 0);
  }

  function orderedClips() {
    const pinned = [];
    const normal = [];

    for (const clip of clips) {
      if (isPinned(clip)) {
        pinned.push(clip);
      } else {
        normal.push(clip);
      }
    }

    return pinned.concat(normal);
  }

  function previewText(clip) {
    const tabIndex = clip.indexOf("\t");
    const text = tabIndex >= 0 ? clip.slice(tabIndex + 1) : clip;
    return text.replace(/\s+/g, " ").trim();
  }

  function clipKind(clip) {
    const text = previewText(clip);

    if (/^image\//i.test(text) || text.indexOf("[[ binary data") >= 0) {
      return "Image";
    }

    if (/^https?:\/\//i.test(text)) {
      return "Link";
    }

    return "Text";
  }

  function isImageClip(clip) {
    return clipKind(clip) === "Image";
  }

  function clipId(clip) {
    const tabIndex = clip.indexOf("\t");
    return tabIndex >= 0 ? clip.slice(0, tabIndex) : "";
  }

  function previewPath(clip) {
    const id = clipId(clip);
    return id.length > 0 ? "/tmp/quickshell-clipboard-previews/" + id + ".png" : "";
  }

  function stateDir() {
    const xdgState = Quickshell.env("XDG_STATE_HOME");
    return xdgState && xdgState.length > 0 ? xdgState : Quickshell.env("HOME") + "/.local/state";
  }

  function pinsPath() {
    return stateDir() + "/quickshell/clipboard-pins";
  }

  function privatePath() {
    return stateDir() + "/quickshell/clipboard-private";
  }

  function fileUrl(path) {
    return encodeURI("file://" + path).replace(/#/g, "%23");
  }

  function selectedClip() {
    if (filteredClips.length === 0) {
      return "";
    }

    return filteredClips[Math.max(0, Math.min(selectedIndex, filteredClips.length - 1))];
  }

  function cycleSelection(direction) {
    const count = filteredClips.length;
    if (count === 0) {
      selectedIndex = 0;
      return;
    }

    selectedIndex = (selectedIndex + direction + count) % count;
  }

  function resetSelection() {
    selectedIndex = 0;
    Qt.callLater(() => {
      if (clipList) {
        clipList.positionViewAtIndex(0, ListView.Beginning);
      }
    });
  }

  function shellQuote(value) {
    return "'" + value.replace(/'/g, "'\"'\"'") + "'";
  }

  function isPinned(clip) {
    const id = clipId(clip);
    return id.length > 0 && pinnedIds.indexOf(id) >= 0;
  }

  function loadPins() {
    pinsProc.exec(["bash", "-lc", "cat " + shellQuote(pinsPath()) + " 2>/dev/null || true"]);
  }

  function savePins() {
    Quickshell.execDetached([
      "bash",
      "-lc",
      "mkdir -p " + shellQuote(stateDir() + "/quickshell") + "; printf '%s\\n' " + shellQuote(pinnedIds.join("\n")) + " | sed '/^$/d' > " + shellQuote(pinsPath())
    ]);
  }

  function togglePinned(clip) {
    const id = clipId(clip);
    if (id.length === 0) {
      return;
    }

    const next = pinnedIds.slice();
    const index = next.indexOf(id);
    if (index >= 0) {
      next.splice(index, 1);
    } else {
      next.unshift(id);
    }

    pinnedIds = next;
    savePins();
    resetSelection();
  }

  function loadPrivateMode() {
    privateProc.exec(["bash", "-lc", "test -f " + shellQuote(privatePath()) + " && printf true || printf false"]);
  }

  function setPrivateMode(enabled) {
    privateMode = enabled;
    Quickshell.execDetached([
      "bash",
      "-lc",
      "mkdir -p " + shellQuote(stateDir() + "/quickshell") + "; " + (enabled ? "touch " : "rm -f ") + shellQuote(privatePath())
    ]);
  }

  function refreshClips() {
    cliphistProc.exec([
      "bash",
      "-lc",
      "preview_dir=\"/tmp/quickshell-clipboard-previews\"; mkdir -p \"$preview_dir\"; cliphist list 2>/dev/null | while IFS= read -r line; do if [[ \"$line\" == *\"[[ binary data\"* && \"$line\" == *\"png\"* ]]; then id=\"${line%%$'\\t'*}\"; if [[ \"$id\" =~ ^[0-9]+$ ]]; then printf '%s\\n' \"$line\" | cliphist decode > \"$preview_dir/$id.png\" 2>/dev/null || true; fi; fi; printf '%s\\n' \"$line\"; done"
    ]);
  }

  function copyClip(clip) {
    if (clip.length === 0) {
      return;
    }

    Quickshell.execDetached([
      "bash",
      "-lc",
      "printf '%s\\n' " + shellQuote(clip) + " | cliphist decode | wl-copy"
    ]);

    open = false;
  }

  function quickPasteClip(clip) {
    if (clip.length === 0) {
      return;
    }

    Quickshell.execDetached([
      "bash",
      "-lc",
      "printf '%s\\n' " + shellQuote(clip) + " | cliphist decode | wl-copy; if command -v wtype >/dev/null 2>&1; then wtype -M ctrl v -m ctrl; elif command -v ydotool >/dev/null 2>&1; then ydotool key 29:1 47:1 47:0 29:0; else notify-send 'Clipboard' 'Copied. Install wtype for quick paste.' >/dev/null 2>&1 || true; fi"
    ]);

    open = false;
  }

  function deleteClip(clip) {
    const id = clipId(clip);
    if (clip.length === 0 || id.length === 0) {
      return;
    }

    Quickshell.execDetached([
      "bash",
      "-lc",
      "printf '%s\\n' " + shellQuote(clip) + " | cliphist delete"
    ]);

    clips = clips.filter(item => clipId(item) !== id);
    pinnedIds = pinnedIds.filter(item => item !== id);
    savePins();
    resetSelection();
  }

  function clearAll() {
    Quickshell.execDetached(["bash", "-lc", "cliphist wipe; rm -f /tmp/quickshell-clipboard-previews/*.png 2>/dev/null || true"]);
    clips = [];
    pinnedIds = [];
    savePins();
    resetSelection();
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
    id: cliphistProc

    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        root.clips = output.length === 0
          ? []
          : output.split("\n").filter(clip => clip.length > 0);
        root.resetSelection();
      }
    }
  }

  Process {
    id: pinsProc

    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        root.pinnedIds = output.length === 0
          ? []
          : output.split("\n").filter(id => id.length > 0);
      }
    }
  }

  Process {
    id: privateProc

    stdout: StdioCollector {
      onStreamFinished: root.privateMode = text.trim() === "true"
    }
  }

  IpcHandler {
    target: "clipboardLauncher." + root.ipcTargetName

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

    SearchBox {
      id: searchInput
      width: parent.width
      icon: "󰅇"
      text: root.query
      onSearchTextChanged: (newText) => {
        root.query = newText;
        root.resetSelection();
      }
      onAccepted: root.copyClip(root.selectedClip())
      onEscapePressed: root.open = false
      onMoveSelection: (direction) => { root.cycleSelection(direction); }
    }

    Text {
      width: parent.width
      text: root.query.length === 0 ? (root.privateMode ? "Clipboard private" : "Clipboard") : root.filteredClips.length + " results"
      color: theme.muted
      font.pixelSize: 11
      font.weight: Font.Medium
    }

    Row {
      width: parent.width
      height: 30
      spacing: 8

      Rectangle {
        width: 98
        height: parent.height
        radius: theme.radiusLarge
        color: root.privateMode ? theme.accentContainer : privateArea.containsMouse ? theme.surfaceHover : theme.surface
        border.width: 1
        border.color: root.privateMode ? theme.accent : theme.border

        Text {
          anchors.centerIn: parent
          text: "Private"
          color: root.privateMode ? theme.accentContainerForeground : theme.foreground
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }

        MouseArea {
          id: privateArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.setPrivateMode(!root.privateMode)
        }
      }

      Rectangle {
        width: 82
        height: parent.height
        radius: theme.radiusLarge
        color: clearArea.containsMouse ? theme.surfaceHover : theme.surface
        border.width: 1
        border.color: theme.border

        Text {
          anchors.centerIn: parent
          text: "Clear all"
          color: theme.foreground
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }

        MouseArea {
          id: clearArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.clearAll()
        }
      }
    }

    Item {
      width: parent.width
      height: parent.height - y

      Text {
        anchors.centerIn: parent
        width: parent.width - 32
        text: root.clips.length === 0 ? "Clipboard is empty" : "No clips found"
        color: theme.muted
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 13
        visible: root.filteredClips.length === 0
      }

      ListView {
        id: clipList

        anchors.fill: parent
        clip: true
        visible: root.filteredClips.length > 0
        model: root.filteredClips
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selectedIndex

        delegate: Rectangle {
          id: clipRow

          required property string modelData
          required property int index

          readonly property bool selected: root.selectedIndex === index
          readonly property string preview: root.previewText(modelData)
          readonly property bool imageClip: root.isImageClip(modelData)
          readonly property bool pinned: root.isPinned(modelData)

          width: clipList.width
          height: imageClip ? 136 : 56
          radius: theme.radiusLarge
          color: selected
            ? theme.accentContainer
            : clipArea.containsMouse ? theme.surfaceHover : theme.surface

          Rectangle {
            id: kindBadge

            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 28
            radius: theme.radiusSmall
            color: clipRow.selected ? theme.accent : theme.surfaceHigh
            visible: !clipRow.imageClip

            Text {
              anchors.centerIn: parent
              text: root.clipKind(clipRow.modelData)
              color: clipRow.selected ? theme.accentForeground : theme.muted
              font.pixelSize: 10
              font.weight: Font.DemiBold
            }
          }

          Rectangle {
            id: imageFrame

            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 180
            height: 120
            radius: theme.radiusSmall
            color: theme.surfaceHigh
            border.width: 1
            border.color: clipRow.selected ? theme.accent : theme.border
            clip: true
            visible: clipRow.imageClip

            Image {
              anchors.fill: parent
              anchors.margins: 1
              source: root.previewPath(clipRow.modelData).length > 0 ? root.fileUrl(root.previewPath(clipRow.modelData)) : ""
              sourceSize.height: 120
              fillMode: Image.PreserveAspectFit
              horizontalAlignment: Image.AlignLeft
              verticalAlignment: Image.AlignVCenter
              cache: false
            }
          }

          Text {
            anchors.left: clipRow.imageClip ? imageFrame.right : kindBadge.right
            anchors.leftMargin: 12
            anchors.right: actionGroup.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: (clipRow.pinned ? "Pinned  " : "") + (clipRow.preview.length > 0 ? clipRow.preview : "Empty clip")
            color: clipRow.selected ? theme.accentContainerForeground : theme.foreground
            elide: Text.ElideRight
            maximumLineCount: 1
            font.pixelSize: 13
            font.weight: clipRow.selected ? Font.DemiBold : Font.Medium
          }

          MouseArea {
            id: clipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = index
            onClicked: root.copyClip(clipRow.modelData)
          }

          Row {
            id: actionGroup

            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
              model: [
                { label: clipRow.pinned ? "󰐃" : "󰐂", action: "pin" },
                { label: "󰐕", action: "paste" },
                { label: "󰆴", action: "delete" }
              ]

              Rectangle {
                required property var modelData

                width: 28
                height: 28
                radius: theme.radiusLarge
                color: actionArea.containsMouse ? theme.surfaceHover : clipRow.selected ? theme.accentContainer : theme.surfaceHigh
                border.width: 1
                border.color: clipRow.selected ? theme.accent : theme.border

                Text {
                  anchors.centerIn: parent
                  text: parent.modelData.label
                  color: clipRow.selected ? theme.accentContainerForeground : theme.foreground
                  font.pixelSize: 13
                }

                MouseArea {
                  id: actionArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (parent.modelData.action === "pin") {
                      root.togglePinned(clipRow.modelData);
                    } else if (parent.modelData.action === "paste") {
                      root.quickPasteClip(clipRow.modelData);
                    } else if (parent.modelData.action === "delete") {
                      root.deleteClip(clipRow.modelData);
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

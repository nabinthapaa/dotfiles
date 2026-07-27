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
  readonly property var applications: DesktopEntries.applications.values
  readonly property var filteredApplications: filterApplications()
  readonly property var hyprMonitor: Hyprland.monitorFor(root.parentWindow.screen)
  readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : root.parentWindow.screen.name
  readonly property int popupWidth: Math.min(560, root.parentWindow.width - theme.islandPaddingH * 2)
  readonly property int popupHeight: Math.min(580, root.parentWindow.screen.height - theme.barHeight - theme.islandPaddingH * 2)

  width: 0
  height: 0

  onOpenChanged: {
    if (open) {
      query = "";
      resetSelection();
      searchFocusTimer.restart();
    }
  }

  onSelectedIndexChanged: {
    if (root.open && appList && root.filteredApplications.length > 0) {
      appList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
  }

  function filterApplications() {
    const search = query.trim().toLowerCase();
    const apps = applications
      .filter(app => app && !app.noDisplay)
      .sort((a, b) => a.name.localeCompare(b.name));

    if (search.length === 0) {
      return apps;
    }

    return apps.filter(app => {
      const keywords = app.keywords ? app.keywords.join(" ") : "";
      const categories = app.categories ? app.categories.join(" ") : "";
      const haystack = [
        app.name,
        app.genericName,
        app.comment,
        keywords,
        categories
      ].join(" ").toLowerCase();

      return haystack.indexOf(search) >= 0;
    });
  }

  function iconSource(entry) {
    if (!entry || entry.icon.length === 0) {
      return "";
    }

    if (entry.icon.indexOf("/") >= 0 || entry.icon.indexOf(":") >= 0) {
      return entry.icon;
    }

    const resolved = Quickshell.iconPath(entry.icon, true);
    return resolved.length > 0 ? resolved : "";
  }

  function launch(entry) {
    if (!entry) {
      return;
    }

    entry.execute();
    open = false;
  }

  function selectedApplication() {
    if (filteredApplications.length === 0) {
      return null;
    }

    return filteredApplications[Math.max(0, Math.min(selectedIndex, filteredApplications.length - 1))];
  }

  function cycleSelection(direction) {
    const count = filteredApplications.length;
    if (count === 0) {
      selectedIndex = 0;
      return;
    }

    selectedIndex = (selectedIndex + direction + count) % count;
  }

  function resetSelection() {
    selectedIndex = 0;
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

  PopupWindow {
    id: launcherPopup

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

        Row {
          width: parent.width
          height: 42
          spacing: 10

          Rectangle {
            width: parent.width
            height: parent.height
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
                text: "󰍉"
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
                  root.resetSelection();
                }
                onAccepted: root.launch(root.selectedApplication())

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
        }

        Text {
          width: parent.width
          text: root.query.length === 0 ? "Applications" : root.filteredApplications.length + " results"
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
            text: "No applications found"
            color: theme.muted
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 13
            visible: root.filteredApplications.length === 0
          }

          ListView {
            id: appList

            anchors.fill: parent
            clip: true
            visible: root.filteredApplications.length > 0
            model: root.filteredApplications
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: root.selectedIndex

            delegate: Rectangle {
              id: appRow

              required property var modelData
              required property int index

              readonly property bool selected: root.selectedIndex === index

              width: appList.width
              height: 56
              radius: theme.radiusLarge
              color: selected
                ? theme.accentContainer
                : appArea.containsMouse ? theme.surfaceHover : theme.surface

              Rectangle {
                id: appIcon

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                radius: height / 2
                color: appRow.selected ? theme.accent : theme.surfaceHigh

                Image {
                  anchors.centerIn: parent
                  width: 22
                  height: 22
                  source: root.iconSource(appRow.modelData)
                  sourceSize.width: width
                  sourceSize.height: height
                  fillMode: Image.PreserveAspectFit
                  visible: source.toString().length > 0
                }

                Text {
                  anchors.centerIn: parent
                  text: "󰣆"
                  color: appRow.selected ? theme.accentForeground : theme.muted
                  font.pixelSize: 18
                  visible: root.iconSource(appRow.modelData).length === 0
                }
              }

              Text {
                anchors.left: appIcon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: appRow.modelData.name
                color: appRow.selected ? theme.accentContainerForeground : theme.foreground
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: 13
                font.weight: appRow.selected ? Font.DemiBold : Font.Medium
              }

              MouseArea {
                id: appArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIndex = index
                onClicked: root.launch(appRow.modelData)
              }
            }
          }
        }
      }
    }
  }
}

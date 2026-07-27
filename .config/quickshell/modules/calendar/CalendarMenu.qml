import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../shared"

Item {
  id: root
  
  implicitWidth: 680
  implicitHeight: 380
  
  scale: open ? 1 : 0.95
  opacity: open ? 1 : 0
  visible: opacity > 0
  Behavior on opacity { NumberAnimation { duration: 150 } }
  Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
  
  property bool open: false
  property var tasks: []
  
  readonly property var hyprMonitor: Hyprland.monitorFor(parentWindow.screen)
  readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : parentWindow.screen.name
  
  required property var parentWindow
  
  Theme { id: theme }
  
  function refreshTasks() {
    taskProc.running = false;
    taskProc.running = true;
  }
  
  onOpenChanged: {
    if (open) {
      refreshTasks();
    }
  }
  
  Process {
    id: taskProc
    command: ["bash", "-c", "touch ~/.todo.txt && cat ~/.todo.txt"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim();
        root.tasks = out.length === 0 ? [] : out.split('\n');
      }
    }
  }

  function getDaysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate();
  }

  function getFirstDayOfMonth(year, month) {
    return new Date(year, month, 1).getDay();
  }

  function generateCalendar() {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth();
    const currentDay = today.getDate();
    
    const daysInMonth = getDaysInMonth(year, month);
    const firstDay = getFirstDayOfMonth(year, month);
    
    let days = [];
    
    // Fill empty slots for first week
    for (let i = 0; i < firstDay; i++) {
      days.push({ day: "", isToday: false });
    }
    
    // Fill days
    for (let i = 1; i <= daysInMonth; i++) {
      days.push({ day: i.toString(), isToday: (i === currentDay) });
    }
    
    return days;
  }
  
  property var calendarModel: generateCalendar()
  
  IpcHandler {
    target: "calendarMenu." + root.ipcTargetName
    function toggle(): void { root.open = !root.open; }
    function close(): void { root.open = false; }
    function open(): void { root.open = true; }
  }
  

    
    Rectangle {
      anchors.fill: parent
      radius: theme.radiusLarge
      color: theme.panel
      border.width: 1
      border.color: theme.border
      opacity: root.open ? 1 : 0
      scale: root.open ? 1 : 0.95
      transformOrigin: Item.Top
      
      Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
      Behavior on opacity { NumberAnimation { duration: 150 } }
      
      Row {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 32
        
        // Left: Calendar
        Column {
          width: 250
          height: parent.height
          spacing: 16
          
          Text {
            text: Qt.formatDate(new Date(), "MMMM yyyy")
            color: theme.foreground
            font.pixelSize: 22
            font.weight: Font.Bold
          }
          
          // Days of week
          Row {
            width: parent.width
            spacing: 0
            Repeater {
              model: ["S", "M", "T", "W", "T", "F", "S"]
              Text {
                width: 250 / 7
                text: modelData
                color: theme.muted
                font.pixelSize: 13
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }
          
          // Calendar Grid
          Grid {
            width: parent.width
            columns: 7
            spacing: 0
            
            Repeater {
              model: root.calendarModel
              
              Rectangle {
                width: 250 / 7
                height: 34
                color: modelData.isToday ? theme.accent : "transparent"
                radius: 17
                
                Text {
                  anchors.centerIn: parent
                  text: modelData.day
                  color: modelData.isToday ? theme.accentForeground : theme.foreground
                  font.pixelSize: 14
                  font.weight: modelData.isToday ? Font.Bold : Font.Normal
                }
              }
            }
          }
        }
        
        // Vertical Divider
        Rectangle {
          width: 1
          height: parent.height
          color: theme.border
        }
        
        // Right: Agenda / Todos
        Column {
          width: parent.width - 250 - 32 - 1
          height: parent.height
          spacing: 16
          
          Row {
            width: parent.width
            
            Text {
              text: "Agenda"
              color: theme.foreground
              font.pixelSize: 22
              font.weight: Font.Bold
            }
            
            Item { width: 1; height: 1; Layout.fillWidth: true } // spacer
            
            Text {
              text: "~/.todo.txt"
              color: theme.muted
              font.pixelSize: 12
              verticalAlignment: Text.AlignBottom
            }
          }
          
          ListView {
            width: parent.width
            height: parent.height - 40
            clip: true
            model: root.tasks
            spacing: 8
            
            delegate: Rectangle {
              width: parent.width
              height: 48
              radius: theme.radius
              color: theme.surfaceHigh
              
              Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14
                
                Rectangle {
                  width: 20
                  height: 20
                  radius: 10
                  color: "transparent"
                  border.width: 2
                  border.color: theme.muted
                  anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 34
                  text: modelData
                  color: theme.foreground
                  font.pixelSize: 14
                  elide: Text.ElideRight
                }
              }
            }
            Text {
              anchors.centerIn: parent
              text: "No tasks! You're all caught up 🎉"
              color: theme.muted
              font.pixelSize: 14
              visible: root.tasks.length === 0
            }
          }
        }
      }
    }
  }

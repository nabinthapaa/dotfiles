import Quickshell
import Quickshell.Io
import QtQuick
import "../../../../shared"

Rectangle {
  id: root
  
  width: parent ? parent.width : 352
  height: 64
  radius: theme.radiusLarge
  color: theme.surfaceHigh

  Theme { id: theme }

  property string weatherCondition: "Loading..."
  property string weatherTemp: ""
  property string weatherFeelsLike: ""
  property string weatherChance: ""
  property string weatherAqi: ""

  Process {
    id: weatherProc
    command: ["sh", "-c", Quickshell.env("HOME") + "/dotfiles/.config/quickshell/scripts/weather-full.sh || echo 'Unknown|--°C|--°C|--%|-- AQI'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split("|");
        if (parts.length >= 5) {
           root.weatherCondition = parts[0];
           root.weatherTemp = parts[1].replace("+", "");
           root.weatherFeelsLike = parts[2].replace("+", "");
           root.weatherChance = parts[3];
           root.weatherAqi = parts[4];
        } else {
           root.weatherCondition = "Offline";
           root.weatherTemp = "--°C";
           root.weatherFeelsLike = "--°C";
           root.weatherChance = "--%";
           root.weatherAqi = "--";
        }
      }
    }
  }

  Timer {
    interval: 1800000 // 30 mins
    running: true
    repeat: true
    onTriggered: {
      weatherProc.running = false;
      weatherProc.running = true;
    }
  }

  Row {
    anchors.centerIn: parent
    spacing: 20

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.weatherCondition
      color: theme.foreground
      font.pixelSize: 32
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: root.weatherTemp || "..."
        color: theme.foreground
        font.pixelSize: 18
        font.weight: Font.DemiBold
      }

      Text {
        text: "Feels like " + root.weatherFeelsLike
        color: theme.muted
        font.pixelSize: 11
        font.weight: Font.Medium
      }
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 1
      height: 28
      color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.6)
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: "AQI " + root.weatherAqi
        color: Number(root.weatherAqi) > 100 ? theme.urgent : (Number(root.weatherAqi) > 50 ? theme.warning : theme.accent)
        font.pixelSize: 12
        font.weight: Font.DemiBold
      }

      Text {
        text: root.weatherChance + " Rain"
        color: theme.muted
        font.pixelSize: 11
        font.weight: Font.Medium
      }
    }
  }
}

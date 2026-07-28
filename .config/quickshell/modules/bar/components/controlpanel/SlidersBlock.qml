import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "../../../../shared"

Rectangle {
  id: root
  
  required property var osd
  required property var brightnessTracker
  
  width: parent ? parent.width : 352
  height: slidersCol.implicitHeight + 24
  radius: theme.radiusLarge
  color: theme.surfaceHigh
  
  Theme { id: theme }

  function clampLevel(level) { return Math.max(0, Math.min(1, level)); }

  function sliderLevel(kind) {
    if (kind === "mic") return Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? clampLevel(Pipewire.defaultAudioSource.audio.volume) : 0;
    if (kind === "audio") return Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? clampLevel(Pipewire.defaultAudioSink.audio.volume) : 0;
    if (kind === "brightness") return clampLevel(root.brightnessTracker.level);
    return 0;
  }

  function setSliderLevel(kind, level) {
    const nextLevel = clampLevel(level);
    if (kind === "mic" && Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
      Pipewire.defaultAudioSource.audio.volume = nextLevel;
      Pipewire.defaultAudioSource.audio.muted = nextLevel === 0;
      root.osd.showMic(nextLevel, Pipewire.defaultAudioSource.audio.muted);
    } else if (kind === "audio" && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
      Pipewire.defaultAudioSink.audio.volume = nextLevel;
      Pipewire.defaultAudioSink.audio.muted = nextLevel === 0;
      root.osd.showVolume(nextLevel, Pipewire.defaultAudioSink.audio.muted);
    } else if (kind === "brightness") {
      root.brightnessTracker.setLevel(nextLevel);
    }
  }

  Column {
    id: slidersCol
    anchors.fill: parent
    anchors.margins: 12
    spacing: 16
    
    Repeater {
      model: [
        { key: "audio", icon: "󰕾" },
        { key: "mic", icon: "󰍬" },
        { key: "brightness", icon: "󰃠" }
      ]
      
      delegate: Row {
        required property var modelData
        width: parent.width
        spacing: 10
        
        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: 20
          text: modelData.icon
          color: theme.foreground
          font.pixelSize: 16
          horizontalAlignment: Text.AlignHCenter
        }
        
        Item {
          id: sliderTrack
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 30
          height: 24
          
          Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: 16
            radius: 8
            color: theme.surfaceHover
            
            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Math.max(height, parent.width * root.sliderLevel(modelData.key))
              radius: parent.radius
              color: theme.accent
              
              Behavior on width { NumberAnimation { duration: 100 } }
            }
          }
          
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function setLevel(mouseX) { root.setSliderLevel(modelData.key, mouseX / width); }
            onPressed: mouse => setLevel(mouse.x)
            onPositionChanged: mouse => { if (pressed) setLevel(mouse.x); }
          }
        }
      }
    }
  }
}

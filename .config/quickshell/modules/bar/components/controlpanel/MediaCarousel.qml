import Quickshell.Services.Mpris
import QtQuick
import "../../../../shared"

Rectangle {
  id: root
  
  width: parent ? parent.width : 352
  height: 80
  radius: theme.radiusLarge
  color: theme.surfaceHigh
  clip: true

  Theme { id: theme }

  readonly property int playerCount: Mpris.players.values.length
  visible: playerCount > 0

  ListView {
    id: playerCarousel
    anchors.fill: parent
    orientation: ListView.Horizontal
    snapMode: ListView.SnapOneItem
    highlightRangeMode: ListView.StrictlyEnforceRange
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    
    model: Mpris.players.values
    
    delegate: Item {
      required property var modelData
      width: playerCarousel.width
      height: playerCarousel.height

      MediaPlayerView {
        anchors.fill: parent
        player: modelData
        showBlurBackground: false
      }
    }
  }
  
  // Carousel Indicators
  Row {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 4
    visible: root.playerCount > 1
    
    Repeater {
      model: root.playerCount
      delegate: Rectangle {
        width: playerCarousel.currentIndex === index ? 12 : 6
        height: 4
        radius: 2
        color: playerCarousel.currentIndex === index ? theme.accent : theme.muted
        opacity: 0.8
        Behavior on width { NumberAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 150 } }
      }
    }
  }
}

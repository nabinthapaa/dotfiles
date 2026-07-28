import Quickshell.Services.Mpris
import QtQuick
import "../../shared"

Rectangle {
  id: root

  readonly property int playerCount: Mpris.players.values.length
  readonly property var player: playerCount > 0 ? Mpris.players.values[0] : null

  visible: player !== null
  height: visible ? 72 : 0
  radius: theme.radiusLarge
  color: "transparent"
  border.width: 1
  border.color: theme.border
  clip: true
  opacity: visible ? 1 : 0

  Theme {
    id: theme
  }

  Behavior on opacity {
    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
  }

  MediaPlayerView {
    anchors.fill: parent
    player: root.player
    showBlurBackground: true
  }
}

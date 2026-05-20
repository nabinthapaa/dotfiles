import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import "../../shared"

Scope {
  id: root

  property string title: "Volume"
  property string detail: ""
  property string icon: "󰕾"
  property real level: 0
  property bool hasLevel: true
  property bool active: false
  property bool windowVisible: false
  property bool watchChanges: false
  property real lastSinkVolume: -1
  property bool lastSinkMuted: false
  property real lastSourceVolume: -1
  property bool lastSourceMuted: false
  property real lastBrightness: -1
  property string lastPowerProfile: ""

  readonly property bool sinkReady: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
  readonly property real sinkVolume: sinkReady ? clamp(Pipewire.defaultAudioSink.audio.volume) : -1
  readonly property bool sinkMuted: sinkReady ? Pipewire.defaultAudioSink.audio.muted : false
  readonly property bool sourceReady: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio
  readonly property real sourceVolume: sourceReady ? clamp(Pipewire.defaultAudioSource.audio.volume) : -1
  readonly property bool sourceMuted: sourceReady ? Pipewire.defaultAudioSource.audio.muted : false
  readonly property string currentPowerProfile: normalizeProfile(PowerProfile.toString(PowerProfiles.profile))

  onSinkVolumeChanged: handleSinkChanged()
  onSinkMutedChanged: handleSinkChanged()
  onSourceVolumeChanged: handleSourceChanged()
  onSourceMutedChanged: handleSourceChanged()
  onCurrentPowerProfileChanged: handlePowerProfileChanged()

  Component.onCompleted: {
    syncWatchedState();
    refreshBrightness();
    watchArmTimer.restart();
  }

  function clamp(value) {
    return Math.max(0, Math.min(1, value));
  }

  function normalizeProfile(profile) {
    const normalized = String(profile || "").toLowerCase();
    if (normalized === "powersaver" || normalized === "power_saver") {
      return "power-saver";
    }
    if (normalized === "performance") {
      return "performance";
    }
    return "balanced";
  }

  function syncWatchedState() {
    lastSinkVolume = sinkVolume;
    lastSinkMuted = sinkMuted;
    lastSourceVolume = sourceVolume;
    lastSourceMuted = sourceMuted;
    lastPowerProfile = currentPowerProfile;
  }

  function handleSinkChanged() {
    if (!watchChanges || sinkVolume < 0) {
      lastSinkVolume = sinkVolume;
      lastSinkMuted = sinkMuted;
      return;
    }

    if (Math.abs(sinkVolume - lastSinkVolume) < 0.001 && sinkMuted === lastSinkMuted) {
      return;
    }

    lastSinkVolume = sinkVolume;
    lastSinkMuted = sinkMuted;
    showVolume(sinkVolume, sinkMuted);
  }

  function handleSourceChanged() {
    if (!watchChanges || sourceVolume < 0) {
      lastSourceVolume = sourceVolume;
      lastSourceMuted = sourceMuted;
      return;
    }

    if (Math.abs(sourceVolume - lastSourceVolume) < 0.001 && sourceMuted === lastSourceMuted) {
      return;
    }

    lastSourceVolume = sourceVolume;
    lastSourceMuted = sourceMuted;
    showMic(sourceVolume, sourceMuted);
  }

  function handlePowerProfileChanged() {
    if (!watchChanges || currentPowerProfile === lastPowerProfile) {
      lastPowerProfile = currentPowerProfile;
      return;
    }

    lastPowerProfile = currentPowerProfile;
    showPowerProfile(currentPowerProfile);
  }

  function refreshBrightness() {
    brightnessProc.exec(["brightnessctl", "-m"]);
  }

  function show(iconName, titleText, detailText, value, withLevel) {
    icon = iconName;
    title = titleText;
    detail = detailText;
    level = clamp(value);
    hasLevel = withLevel;
    hideWindowTimer.stop();
    windowVisible = true;
    active = true;
    hideTimer.restart();
  }

  function showVolume(value, muted) {
    show(muted || value <= 0 ? "󰝟" : value < 0.45 ? "󰕿" : "󰕾", muted ? "Muted" : "Volume", Math.round(clamp(value) * 100) + "%", value, true);
  }

  function showMic(value, muted) {
    show(muted || value <= 0 ? "󰍭" : "󰍬", muted ? "Mic muted" : "Microphone", Math.round(clamp(value) * 100) + "%", value, true);
  }

  function showBrightness(value) {
    show("󰃠", "Brightness", Math.round(clamp(value) * 100) + "%", value, true);
  }

  function showPowerProfile(profile) {
    const label = profile === "performance" ? "Performance" : profile === "power-saver" ? "Power saver" : "Balanced";
    const iconName = profile === "performance" ? "󰓅" : profile === "power-saver" ? "󰾆" : "󰾅";
    show(iconName, "Power mode", label, 0, false);
  }

  function showAirplane(enabled) {
    show(enabled ? "󰀝" : "󰖩", "Airplane mode", enabled ? "On" : "Off", 0, false);
  }

  function showSilent(enabled) {
    show(enabled ? "󰂛" : "󰂚", "Silent mode", enabled ? "On" : "Off", 0, false);
  }

  Theme {
    id: theme
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  Timer {
    id: watchArmTimer
    interval: 500
    repeat: false
    onTriggered: {
      syncWatchedState();
      watchChanges = true;
    }
  }

  Timer {
    id: hideTimer
    interval: 1300
    repeat: false
    onTriggered: {
      root.active = false;
      hideWindowTimer.restart();
    }
  }

  Timer {
    id: hideWindowTimer
    interval: 170
    repeat: false
    onTriggered: root.windowVisible = false
  }

  Timer {
    interval: 900
    running: true
    repeat: true
    onTriggered: root.refreshBrightness()
  }

  Process {
    id: brightnessProc

    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(",");
        if (parts.length < 4) {
          return;
        }

        const parsed = Number(parts[3].replace("%", ""));
        if (Number.isNaN(parsed)) {
          return;
        }

        const nextBrightness = root.clamp(parsed / 100);
        if (!root.watchChanges || root.lastBrightness < 0) {
          root.lastBrightness = nextBrightness;
          return;
        }

        if (Math.abs(nextBrightness - root.lastBrightness) < 0.005) {
          return;
        }

        root.lastBrightness = nextBrightness;
        root.showBrightness(nextBrightness);
      }
    }
  }

  IpcHandler {
    target: "osd"

    function volume(level: real, muted: bool): void {
      root.showVolume(level, muted);
    }

    function mic(level: real, muted: bool): void {
      root.showMic(level, muted);
    }

    function brightness(level: real): void {
      root.showBrightness(level);
    }

    function powerProfile(profile: string): void {
      root.showPowerProfile(profile);
    }

    function airplane(enabled: bool): void {
      root.showAirplane(enabled);
    }

    function silent(enabled: bool): void {
      root.showSilent(enabled);
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: osdWindow

      required property var modelData

      screen: modelData
      implicitHeight: 82
      color: "transparent"
      visible: root.windowVisible
      aboveWindows: true
      exclusionMode: ExclusionMode.Ignore

      anchors {
        left: true
        right: true
        bottom: true
      }

      margins {
        bottom: 38
      }

      Rectangle {
        id: bubble

        width: Math.max(220, Math.min(320, parent.width - theme.barPadding * 2))
        height: parent.height
        x: (parent.width - width) / 2
        radius: theme.radiusLarge
        color: theme.surface
        border.width: 1
        border.color: theme.border
        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.96

        Behavior on scale {
          NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
          }
        }

        Row {
          anchors.fill: parent
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          spacing: 14

          Rectangle {
            width: 46
            height: 46
            anchors.verticalCenter: parent.verticalCenter
            radius: 23
            color: theme.accentContainer

            Text {
              anchors.centerIn: parent
              text: root.icon
              color: theme.accentContainerForeground
              font.pixelSize: 21
              font.weight: Font.DemiBold
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 46 - parent.spacing
            spacing: 8

            Row {
              width: parent.width
              height: 20
              spacing: theme.gap

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - detailText.width - parent.spacing
                text: root.title
                color: theme.foreground
                elide: Text.ElideRight
                font.pixelSize: 13
                font.weight: Font.DemiBold
              }

              Text {
                id: detailText
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(96, implicitWidth)
                text: root.detail
                color: theme.muted
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                font.pixelSize: 12
                font.weight: Font.Medium
              }
            }

            Rectangle {
              width: parent.width
              height: root.hasLevel ? 8 : 0
              radius: 4
              color: theme.surfaceHigh
              visible: root.hasLevel

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.level
                radius: 4
                color: theme.accent
              }
            }
          }
        }
      }
    }
  }
}

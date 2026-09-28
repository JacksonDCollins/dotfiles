import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    property string outputName: ""
    property string symbol: "volume_up"
    property string label: "Volume up"
    property real volumeLevel: -1
    property bool muted: false
    readonly property var targetScreen: Quickshell.screens.find(output => output.name === outputName) || Quickshell.screens[0] || null
    readonly property ScreenTheme theme: Theme.forScreen(targetScreen)

    function show(action: string, state: string): void {
        const snapshot = state.trim();
        let level = -1;
        let isMuted = false;
        switch (action) {
        case "volume-up":
        case "volume-down":
        case "mute": {
            const match = /^Volume:\s+([0-9]+(?:\.[0-9]+)?)\s*(\[MUTED\])?$/.exec(snapshot);
            if (match && Number.isFinite(Number(match[1]))) {
                level = Math.max(0, Math.min(1, Number(match[1])));
                isMuted = !!match[2];
                symbol = isMuted || level === 0 ? "volume_off" : level <= 0.5 ? "volume_down" : "volume_up";
                label = (isMuted ? "Muted, volume " : "Volume ") + Math.round(Number(match[1]) * 100) + " percent";
            } else {
                symbol = "help_outline";
                label = "Volume unavailable";
            }
            break;
        }
        case "play-pause":
            if (snapshot === "Playing") { symbol = "play_arrow"; label = "Playing"; }
            else if (snapshot === "Paused") { symbol = "pause"; label = "Paused"; }
            else if (snapshot === "Stopped") { symbol = "stop"; label = "Stopped"; }
            else { symbol = "help_outline"; label = "Playback unavailable"; }
            break;
        case "next": symbol = "skip_next"; label = "Next track"; break;
        case "previous": symbol = "skip_previous"; label = "Previous track"; break;
        default: return;
        }
        volumeLevel = level;
        muted = isMuted;
        outputName = Hyprland.focusedMonitor?.name || "";
        dismiss.restart();
    }

    IpcHandler {
        target: "mediaOsd"
        function display(action: string, state: string): void { root.show(action, state); }
    }
    Timer { id: dismiss; interval: 1200 }

    screen: targetScreen
    anchors.top: true
    margins.top: theme ? theme.bar.height + theme.spacing.extraLarge : 0
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dotfiles-media-osd"
    visible: dismiss.running && targetScreen !== null && theme !== null
    color: "transparent"
    implicitWidth: theme ? Math.max(1, Math.min(
        theme.iconFont.pixelSize + 2 * theme.widget.padding
            + (volumeLevel >= 0 ? theme.spacing.medium + Math.max(1, theme.spacing.small) : 0),
        targetScreen.width - 2 * theme.spacing.medium)) : 1
    implicitHeight: theme ? theme.iconFont.pixelSize + 2 * theme.widget.padding : 1

    Rectangle {
        anchors.fill: parent
        color: root.theme ? root.theme.surface : "transparent"
        radius: root.theme ? root.theme.radius.large : 0
        border.color: root.theme ? root.theme.border : "transparent"
        border.width: root.theme ? root.theme.widget.borderWidth : 0
        RowLayout {
            anchors.fill: parent
            anchors.margins: root.theme ? root.theme.widget.padding : 0
            spacing: root.theme ? root.theme.spacing.medium : 0
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.symbol
                font: root.theme ? root.theme.iconFont : Qt.font({})
                color: root.theme ? root.theme.accent : "transparent"
                renderType: Text.NativeRendering
                Accessible.name: root.label
            }
            Rectangle {
                objectName: "volumeMeter"
                visible: root.volumeLevel >= 0
                Layout.preferredWidth: root.theme ? Math.max(1, root.theme.spacing.small) : 1
                Layout.fillHeight: true
                radius: width / 2
                color: root.theme ? root.theme.surfacePressed : "transparent"
                Accessible.ignored: true
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: parent.height * Math.max(0, root.volumeLevel)
                    radius: parent.radius
                    color: root.theme ? (root.muted ? root.theme.muted : root.theme.accent) : "transparent"
                }
            }
        }
    }
}

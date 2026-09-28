pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    required property ScreenTheme theme
    property bool active: false
    signal closeRequested()
    readonly property var audioNodes: Pipewire.nodes.values.filter(node => node.audio !== null)
    readonly property var outputs: audioNodes.filter(node => !node.isStream && node.isSink)
    readonly property var inputs: audioNodes.filter(node => !node.isStream && (node.type & PwNodeType.Source))
    readonly property var playback: audioNodes.filter(node => node.isStream && node.isSink)
    spacing: root.theme.spacing.small
    onActiveChanged: { if (active) forceActiveFocus(); }
    Keys.onEscapePressed: closeRequested()

    function name(node): string { return node ? node.description || node.nickname || node.name : "Unavailable"; }
    function selectOutput(index): void {
        if (active && Pipewire.ready && index >= 0 && index < outputs.length)
            Pipewire.preferredDefaultAudioSink = outputs[index];
    }
    function selectInput(index): void {
        if (active && Pipewire.ready && index >= 0 && index < inputs.length)
            Pipewire.preferredDefaultAudioSource = inputs[index];
    }
    component Label: Text {
        Layout.fillWidth: true
        textFormat: Text.PlainText
        font: root.theme.smallFont
        color: root.theme.foreground
        wrapMode: Text.WordWrap
    }
    component Selector: Basic.ComboBox {
        Layout.fillWidth: true
        font: root.theme.smallFont
        palette.button: root.theme.surface
        palette.buttonText: root.theme.foreground
        palette.text: root.theme.foreground
        palette.base: root.theme.background
        palette.window: root.theme.background
        palette.windowText: root.theme.foreground
        palette.highlight: root.theme.accent
        palette.highlightedText: root.theme.accentForeground
    }
    RowLayout {
        Layout.fillWidth: true
        Label { text: "Audio"; font: root.theme.largeFont }
        Basic.Button {
            text: "Close"
            font: root.theme.smallFont
            palette.button: root.theme.surface
            palette.buttonText: root.theme.foreground
            Accessible.name: "Close audio popup"
            onClicked: root.closeRequested()
        }
    }
    Label { visible: !Pipewire.ready; text: "PipeWire is unavailable. Check PipeWire and WirePlumber."; color: root.theme.muted }
    Basic.ScrollView {
        id: scroll
        Layout.fillWidth: true; Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true
        Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
        ColumnLayout {
            width: scroll.availableWidth
            spacing: root.theme.spacing.medium
            Label { text: "Output"; font: root.theme.font }
            Selector {
                objectName: "audioOutputSelector"
                model: root.outputs.map(node => root.name(node))
                currentIndex: root.outputs.indexOf(Pipewire.defaultAudioSink)
                displayText: currentIndex >= 0 ? currentText : "No output selected"
                enabled: root.active && Pipewire.ready && root.outputs.length > 0
                Accessible.name: "Audio output device"
                onActivated: index => root.selectOutput(index)
            }
            AudioVolumeControl { theme: root.theme;
                objectName: "outputVolume"
                Layout.fillWidth: true
                active: root.active && Pipewire.ready
                node: Pipewire.defaultAudioSink
                label: "Output volume"
            }
            Label { visible: root.outputs.length === 0; text: "No playback devices detected."; color: root.theme.muted }
            Label { text: "Microphone"; font: root.theme.font }
            Selector {
                objectName: "audioInputSelector"
                model: root.inputs.map(node => root.name(node))
                currentIndex: root.inputs.indexOf(Pipewire.defaultAudioSource)
                displayText: currentIndex >= 0 ? currentText : "No input selected"
                enabled: root.active && Pipewire.ready && root.inputs.length > 0
                Accessible.name: "Microphone device"
                onActivated: index => root.selectInput(index)
            }
            AudioVolumeControl { theme: root.theme;
                objectName: "inputVolume"
                Layout.fillWidth: true
                active: root.active && Pipewire.ready
                node: Pipewire.defaultAudioSource
                label: "Microphone volume"
            }
            Label { visible: root.inputs.length === 0; text: "No microphone devices detected."; color: root.theme.muted }
            Label { text: "Applications"; font: root.theme.font }
            Label { visible: root.playback.length === 0; text: "No application playback streams."; color: root.theme.muted }
            Repeater {
                model: root.playback
                delegate: AudioVolumeControl { theme: root.theme;
                    required property PwNode modelData
                    objectName: "applicationVolume"
                    Layout.fillWidth: true
                    active: root.active && Pipewire.ready
                    node: modelData
                    label: {
                        const props = modelData.ready ? modelData.properties : ({});
                        const app = props["application.name"] || root.name(modelData);
                        const media = props["media.name"] || "";
                        return media && media !== app ? app + " · " + media : app;
                    }
                }
            }
            Label {
                text: "Device selection changes the preferred default. Apps explicitly routed elsewhere may stay there. Volume is limited to 100%; adjusting it never automatically unmutes."
                color: root.theme.muted
            }
        }
    }
}

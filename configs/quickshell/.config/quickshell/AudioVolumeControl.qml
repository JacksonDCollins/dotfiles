pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    property PwNode node: null
    property bool active: false
    property string label: node ? node.description || node.nickname || node.name : "Unavailable"
    readonly property bool usable: active && node !== null && node.ready && node.audio !== null
    readonly property real amount: usable && Number.isFinite(node.audio.volume) ? node.audio.volume : 0
    readonly property bool muted: usable && node.audio.muted
    spacing: Theme.spacing.small

    PwObjectTracker { objects: root.active && root.node ? [root.node] : [] }
    function setVolume(value): void {
        if (usable && Number.isFinite(value)) node.audio.volume = Math.max(0, Math.min(1, value));
    }
    function toggleMute(): void { if (usable) node.audio.muted = !node.audio.muted; }

    Text {
        Layout.fillWidth: true
        text: root.label
        textFormat: Text.PlainText
        elide: Text.ElideRight
        font: Theme.smallFont
        color: Theme.foreground
    }
    RowLayout {
        Layout.fillWidth: true
        Basic.Button {
            id: muteButton
            objectName: "audioMute"
            text: root.muted ? "Unmute" : "Mute"
            Accessible.name: (root.muted ? "Unmute " : "Mute ") + root.label
            enabled: root.usable
            padding: Theme.spacing.medium
            font: Theme.smallFont
            hoverEnabled: true
            onClicked: root.toggleMute()
            contentItem: Text {
                text: muteButton.text; font: muteButton.font
                color: muteButton.enabled ? root.muted ? Theme.warning : Theme.foreground : Theme.muted
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                radius: Theme.radius.small
                color: muteButton.down ? Theme.surfacePressed : muteButton.hovered ? Theme.surfaceHover : Theme.surface
                border.width: muteButton.visualFocus ? Theme.widget.borderWidth : 0
                border.color: Theme.focusBorder
            }
        }
        Basic.Slider {
            id: slider
            objectName: "audioVolume"
            Layout.fillWidth: true
            from: 0; to: 1; stepSize: 0.01
            enabled: root.usable
            Accessible.name: root.label + " volume"
            onMoved: root.setVolume(value)
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth; height: 4; radius: 2
                color: Theme.surfaceHover
                Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 2; color: root.muted ? Theme.muted : Theme.accent }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 14; implicitHeight: 14; radius: 7
                color: slider.enabled ? Theme.foreground : Theme.muted
                border.color: Theme.focusBorder
                border.width: slider.visualFocus ? 2 : 0
            }
        }
        Binding {
            target: slider; property: "value"; value: root.amount
            when: !slider.pressed
            restoreMode: Binding.RestoreNone
        }
        Text {
            Layout.minimumWidth: 44
            text: root.usable ? Math.round(root.amount * 100) + "%" : "--"
            font: Theme.smallFont
            color: root.muted ? Theme.muted : Theme.foreground
            horizontalAlignment: Text.AlignRight
        }
    }
}

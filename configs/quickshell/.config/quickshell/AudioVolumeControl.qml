pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    required property ScreenTheme theme
    property PwNode node: null
    property bool active: false
    property string label: node ? node.description || node.nickname || node.name : "Unavailable"
    readonly property bool usable: active && node !== null && node.ready && node.audio !== null
    readonly property real amount: usable && Number.isFinite(node.audio.volume) ? node.audio.volume : 0
    readonly property bool muted: usable && node.audio.muted
    spacing: root.theme.spacing.small

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
        font: root.theme.smallFont
        color: root.theme.foreground
    }
    RowLayout {
        Layout.fillWidth: true
        Basic.Button {
            id: muteButton
            objectName: "audioMute"
            text: root.muted ? "Unmute" : "Mute"
            Accessible.name: (root.muted ? "Unmute " : "Mute ") + root.label
            enabled: root.usable
            padding: root.theme.spacing.medium
            font: root.theme.smallFont
            hoverEnabled: true
            onClicked: root.toggleMute()
            contentItem: Text {
                text: muteButton.text; font: muteButton.font
                color: muteButton.enabled ? root.muted ? root.theme.warning : root.theme.foreground : root.theme.muted
                horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                radius: root.theme.radius.small
                color: muteButton.down ? root.theme.surfacePressed : muteButton.hovered ? root.theme.surfaceHover : root.theme.surface
                border.width: muteButton.visualFocus ? root.theme.widget.borderWidth : 0
                border.color: root.theme.focusBorder
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
                color: root.theme.surfaceHover
                Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 2; color: root.muted ? root.theme.muted : root.theme.accent }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 14; implicitHeight: 14; radius: 7
                color: slider.enabled ? root.theme.foreground : root.theme.muted
                border.color: root.theme.focusBorder
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
            font: root.theme.smallFont
            color: root.muted ? root.theme.muted : root.theme.foreground
            horizontalAlignment: Text.AlignRight
        }
    }
}

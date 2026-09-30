pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import QtQuick.Controls.Basic as Basic

Row {
    id: root
    required property ScreenTheme theme
    property real maximumButtonWidth: root.theme.bar.workspaceMaxWidth
    Repeater {
        // model: Hyprland.workspaces
        model: Hyprland.workspaces.values.filter(w => w.monitor === Hyprland.monitorFor(root.theme.screen))
        delegate: Basic.ToolButton {
            id: button
            required property var modelData
            implicitWidth: Math.min(label.implicitWidth + 2 * root.theme.spacing.medium, root.maximumButtonWidth)
            implicitHeight: label.implicitHeight
            horizontalPadding: root.theme.spacing.medium
            verticalPadding: 0
            hoverEnabled: true
            Accessible.name: "Workspace " + modelData.name + (modelData.active ? ", active" : "")
            onClicked: modelData.activate()
            background: Rectangle {
                radius: root.theme.radius.medium
                color: button.down ? root.theme.surfacePressed : button.hovered ? root.theme.surfaceHover : button.modelData.active ? root.theme.selectionBackground : root.theme.background
                border.color: root.theme.focusBorder
                border.width: button.visualFocus ? root.theme.widget.borderWidth : 0
            }
            contentItem: Text {
                id: label
                text: button.modelData.name
                textFormat: Text.PlainText
                font: root.theme.font
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: button.modelData.active ? root.theme.selectionForeground : root.theme.foreground
            }
        }
    }
}

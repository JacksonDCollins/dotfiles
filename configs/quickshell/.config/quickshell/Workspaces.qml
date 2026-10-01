pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import QtQuick.Controls.Basic as Basic

Row {
    id: root
    required property ScreenTheme theme
    property var models: Hyprland.workspaces.values.filter(w => w.monitor === Hyprland.monitorFor(root.theme.screen))
    Repeater {
        model: root.models
        delegate: Basic.ToolButton {
            id: button
            required property var modelData
            width: Math.max(0, (root.width - root.leftPadding - root.rightPadding - root.spacing * Math.max(0, root.models.length - 1)) / Math.max(1, root.models.length))
            implicitHeight: root.theme.bar.height
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
                text: {
                    const windows = button.modelData.toplevels.values;
                    return button.modelData.name + (windows.length ? " · " + windows.map(w => w.title).filter(title => title && title.length).join(" · ") : "");
                }
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

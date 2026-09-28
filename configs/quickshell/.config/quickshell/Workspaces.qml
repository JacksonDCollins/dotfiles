import QtQuick
import Quickshell.Hyprland
import QtQuick.Controls.Basic as Basic

Row {
    id: root
    property real maximumButtonWidth: 120
    Repeater {
        model: Hyprland.workspaces
        delegate: Basic.ToolButton {
            id: button
            required property var modelData
            implicitWidth: Math.min(label.implicitWidth + 2 * Theme.spacing.medium, root.maximumButtonWidth)
            implicitHeight: label.implicitHeight
            horizontalPadding: Theme.spacing.medium
            verticalPadding: 0
            hoverEnabled: true
            Accessible.name: "Workspace " + modelData.name + (modelData.active ? ", active" : "")
            onClicked: modelData.activate()
            background: Rectangle {
                radius: Theme.radius.medium
                color: button.down ? Theme.surfacePressed : button.hovered ? Theme.surfaceHover
                    : button.modelData.active ? Theme.selectionBackground : Theme.background
                border.color: Theme.focusBorder
                border.width: button.visualFocus ? Theme.widget.borderWidth : 0
            }
            contentItem: Text {
                id: label
                text: button.modelData.name
                textFormat: Text.PlainText
                font: Theme.font
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: button.modelData.active ? Theme.selectionForeground : Theme.foreground
            }
        }
    }
}

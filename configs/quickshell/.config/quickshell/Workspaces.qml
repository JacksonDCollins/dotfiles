import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

Row {
    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: container
            required property var modelData

            implicitWidth: label.width
            implicitHeight: label.height
            radius: Theme.radius.medium
            color: {
                if (Hyprland.focusedWorkspace == container.modelData) {
                    return Theme.selectionBackground;
                } else {
                    return Theme.background;
                }
            }

            TapHandler {
                onTapped: container.modelData.activate()
            }

            Text {
                id: label
                text: container.modelData.name
                font: Theme.font
                leftPadding: Theme.spacing.medium
                rightPadding: Theme.spacing.medium
                color: {
                    if (Hyprland.focusedWorkspace == container.modelData) {
                        return Theme.selectionForeground;
                    } else {
                        return Theme.foreground;
                    }
                }
            }
        }
    }
}

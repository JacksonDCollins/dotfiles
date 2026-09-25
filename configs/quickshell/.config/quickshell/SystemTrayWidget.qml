import Quickshell.Widgets
import QtQuick
import Quickshell.Services.SystemTray
import QtQuick.Controls

Row {
    spacing: Theme.spacing.small
    Repeater {
        model: SystemTray.items

        delegate: ToolButton {
            id: button
            required property var modelData

            implicitWidth: Theme.bar.height
            implicitHeight: Theme.bar.height
            padding: Theme.spacing.small
            hoverEnabled: true
            Accessible.name: modelData.title

            contentItem: IconImage {
                implicitSize: Math.max(1, Theme.bar.height - 2 * Theme.spacing.small)
                source: button.modelData.icon
            }

            background: Rectangle {
                radius: Theme.radius.small
                color: button.down ? Theme.surfacePressed : button.hovered ? Theme.surfaceHover : "transparent"
                border.width: button.visualFocus ? Theme.widget.borderWidth : 0
                border.color: Theme.focusBorder
            }

            onClicked: {
                if (modelData.onlyMenu) {
                    if (modelData.hasMenu)
                        trayMenu.popup(button, 0, button.height);
                } else {
                    modelData.activate();
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    if (button.modelData.hasMenu)
                        trayMenu.popup(button, 0, button.height);
                }
            }

            Keys.onMenuPressed: {
                if (modelData.hasMenu)
                    trayMenu.popup(button, 0, button.height);
            }

            TrayMenu {
                id: trayMenu
                handle: button.modelData.menu
            }
        }
    }
}

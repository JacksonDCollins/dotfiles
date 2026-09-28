import Quickshell.Widgets
import QtQuick
import Quickshell.Services.SystemTray
import QtQuick.Controls

Row {
    id: root
    required property ScreenTheme theme
    spacing: root.theme.tray.spacing
    Repeater {
        model: SystemTray.items

        delegate: ToolButton {
            id: button
            required property var modelData

            implicitWidth: root.theme.tray.iconSize + 2 * root.theme.tray.padding
            implicitHeight: root.theme.tray.iconSize + 2 * root.theme.tray.padding
            padding: root.theme.tray.padding
            hoverEnabled: true
            Accessible.name: modelData.title || modelData.tooltipTitle || modelData.id || "Tray application"

            contentItem: IconImage {
                implicitSize: root.theme.tray.iconSize
                source: button.modelData.icon
            }

            background: Rectangle {
                radius: root.theme.radius.small
                color: button.down ? root.theme.surfacePressed : button.hovered ? root.theme.surfaceHover : "transparent"
                border.width: button.visualFocus ? root.theme.widget.borderWidth : 0
                border.color: root.theme.focusBorder
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

            TrayMenu { theme: root.theme;
                id: trayMenu
                handle: button.modelData.menu
            }
        }
    }
}

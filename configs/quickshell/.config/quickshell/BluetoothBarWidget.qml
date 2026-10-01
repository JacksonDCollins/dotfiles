import Quickshell.Bluetooth
import Quickshell
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: root
    required property ScreenTheme theme
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool connected: adapter !== null && adapter.devices.values.some(device => device.connected)
    implicitWidth: icon.implicitWidth + 2 * root.theme.spacing.medium
    implicitHeight: root.theme.bar.height
    padding: 0
    hoverEnabled: true
    Accessible.name: !adapter ? "Bluetooth: no adapter" : !adapter.enabled ? "Bluetooth off" : connected ? "Bluetooth connected" : "Bluetooth on"
    onClicked: popup.visible = !popup.visible

    background: Rectangle {
        radius: root.theme.radius.medium
        color: root.down ? root.theme.surfacePressed : root.hovered ? root.theme.surfaceHover : root.theme.background
        border.color: root.theme.focusBorder
        border.width: root.visualFocus ? root.theme.widget.borderWidth : 0
    }
    contentItem: MaterialIcon { theme: root.theme;
        id: icon
        text: !root.adapter || !root.adapter.enabled ? "bluetooth_disabled" : root.connected ? "bluetooth_connected" : "bluetooth"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({
            family: root.theme.iconFont.family,
            pixelSize: root.theme.tray.iconSize,
            variableAxes: root.theme.iconFont.variableAxes
        })
        color: !root.adapter || !root.adapter.enabled ? root.theme.muted : root.connected ? root.theme.accent : root.theme.foreground
    }

    DesktopPopup { theme: root.theme;
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: root.theme.popups.bluetooth.width
        preferredHeight: root.theme.popups.bluetooth.height
        color: "transparent"
        grabFocus: true

        Rectangle {
            anchors.fill: parent
            color: root.theme.background
            radius: root.theme.radius.large
            border.color: root.theme.border
            border.width: root.theme.widget.borderWidth

            BluetoothWidget { theme: root.theme;
                anchors.fill: parent
                anchors.margins: root.theme.widget.padding
                adapter: root.adapter
                active: popup.visible
                onCloseRequested: popup.visible = false
            }
        }
    }
}

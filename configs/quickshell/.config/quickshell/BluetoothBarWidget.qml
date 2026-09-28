import Quickshell.Bluetooth
import Quickshell
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: root
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool connected: adapter !== null && adapter.devices.values.some(device => device.connected)
    implicitWidth: icon.implicitWidth + 2 * Theme.spacing.medium
    implicitHeight: textMetrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: !adapter ? "Bluetooth: no adapter" : !adapter.enabled ? "Bluetooth off" : connected ? "Bluetooth connected" : "Bluetooth on"
    onClicked: popup.visible = !popup.visible

    FontMetrics {
        id: textMetrics
        font: Theme.font
    }
    background: Rectangle {
        radius: Theme.radius.medium
        color: root.down ? Theme.surfacePressed : root.hovered ? Theme.surfaceHover : Theme.background
        border.color: Theme.focusBorder
        border.width: root.visualFocus ? Theme.widget.borderWidth : 0
    }
    contentItem: MaterialIcon {
        id: icon
        text: !root.adapter || !root.adapter.enabled ? "bluetooth_disabled" : root.connected ? "bluetooth_connected" : "bluetooth"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({
            family: Theme.iconFont.family,
            pixelSize: Theme.font.pixelSize,
            variableAxes: Theme.iconFont.variableAxes
        })
        color: !root.adapter || !root.adapter.enabled ? Theme.muted : root.connected ? Theme.accent : Theme.foreground
    }

    DesktopPopup {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: 380
        preferredHeight: 440
        color: "transparent"
        grabFocus: true

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.radius.large
            border.color: Theme.border
            border.width: Theme.widget.borderWidth

            BluetoothWidget {
                anchors.fill: parent
                anchors.margins: Theme.widget.padding
                adapter: root.adapter
                active: popup.visible
                onCloseRequested: popup.visible = false
            }
        }
    }
}

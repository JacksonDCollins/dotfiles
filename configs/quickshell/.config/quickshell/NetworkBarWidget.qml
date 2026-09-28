import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: root
    readonly property var devices: Networking.devices.values
    readonly property bool wiredConnected: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool connected: devices.some(d => d.connected)
    readonly property bool limited: connected && (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal)
    implicitWidth: icon.implicitWidth + 2 * Theme.spacing.medium
    implicitHeight: metrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: limited ? "Network: limited connectivity" : connected ? "Network connected" : "Network disconnected"
    onClicked: popup.visible = !popup.visible

    FontMetrics { id: metrics; font: Theme.font }
    background: Rectangle {
        radius: Theme.radius.medium
        color: root.down ? Theme.surfacePressed : root.hovered ? Theme.surfaceHover : Theme.background
        border.color: Theme.focusBorder
        border.width: root.visualFocus ? Theme.widget.borderWidth : 0
    }
    contentItem: MaterialIcon {
        id: icon
        text: root.devices.length === 0 ? "network_check"
            : root.wiredConnected || !root.devices.some(d => d.type === DeviceType.Wifi) ? "lan"
            : root.connected ? "wifi" : Networking.wifiEnabled ? "wifi_find" : "wifi_off"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({family: Theme.iconFont.family, pixelSize: Theme.font.pixelSize, variableAxes: Theme.iconFont.variableAxes})
        color: root.limited ? Theme.warning : root.connected ? Theme.accent : Theme.muted
    }
    DesktopPopup {
        id: popup
        property bool settingsOpen: false
        onVisibleChanged: { if (!visible) settingsOpen = false; }
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: 400
        preferredHeight: 480
        color: "transparent"
        grabFocus: true
        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.radius.large
            border.color: Theme.border
            border.width: Theme.widget.borderWidth
            NetworkWidget {
                anchors.fill: parent
                anchors.margins: Theme.widget.padding
                visible: !popup.settingsOpen
                active: popup.visible && !popup.settingsOpen
                onSettingsRequested: popup.settingsOpen = true
                onCloseRequested: popup.visible = false
            }
            NetworkSettings {
                anchors.fill: parent
                anchors.margins: Theme.widget.padding
                visible: popup.settingsOpen
                active: popup.visible && popup.settingsOpen
                onBackRequested: popup.settingsOpen = false
                onCloseRequested: popup.visible = false
            }
        }
    }
}

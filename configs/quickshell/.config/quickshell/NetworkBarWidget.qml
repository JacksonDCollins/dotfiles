import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: root
    required property ScreenTheme theme
    readonly property var devices: Networking.devices.values
    readonly property bool wiredConnected: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool connected: devices.some(d => d.connected)
    readonly property bool limited: connected && (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal)
    implicitWidth: icon.implicitWidth + 2 * root.theme.spacing.medium
    implicitHeight: metrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: limited ? "Network: limited connectivity" : connected ? "Network connected" : "Network disconnected"
    onClicked: popup.visible = !popup.visible

    FontMetrics { id: metrics; font: root.theme.font }
    background: Rectangle {
        radius: root.theme.radius.medium
        color: root.down ? root.theme.surfacePressed : root.hovered ? root.theme.surfaceHover : root.theme.background
        border.color: root.theme.focusBorder
        border.width: root.visualFocus ? root.theme.widget.borderWidth : 0
    }
    contentItem: MaterialIcon { theme: root.theme;
        id: icon
        text: root.devices.length === 0 ? "network_check"
            : root.wiredConnected || !root.devices.some(d => d.type === DeviceType.Wifi) ? "lan"
            : root.connected ? "wifi" : Networking.wifiEnabled ? "wifi_find" : "wifi_off"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({family: root.theme.iconFont.family, pixelSize: root.theme.font.pixelSize, variableAxes: root.theme.iconFont.variableAxes})
        color: root.limited ? root.theme.warning : root.connected ? root.theme.accent : root.theme.muted
    }
    DesktopPopup { theme: root.theme;
        id: popup
        property bool settingsOpen: false
        onVisibleChanged: { if (!visible) settingsOpen = false; }
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: root.theme.popups.network.width
        preferredHeight: root.theme.popups.network.height
        color: "transparent"
        grabFocus: true
        Rectangle {
            anchors.fill: parent
            color: root.theme.background
            radius: root.theme.radius.large
            border.color: root.theme.border
            border.width: root.theme.widget.borderWidth
            NetworkWidget { theme: root.theme;
                anchors.fill: parent
                anchors.margins: root.theme.widget.padding
                visible: !popup.settingsOpen
                active: popup.visible && !popup.settingsOpen
                onSettingsRequested: popup.settingsOpen = true
                onCloseRequested: popup.visible = false
            }
            NetworkSettings { theme: root.theme;
                anchors.fill: parent
                anchors.margins: root.theme.widget.padding
                visible: popup.settingsOpen
                active: popup.visible && popup.settingsOpen
                onBackRequested: popup.settingsOpen = false
                onCloseRequested: popup.visible = false
            }
        }
    }
}

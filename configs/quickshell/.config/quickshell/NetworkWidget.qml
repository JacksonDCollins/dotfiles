pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property ScreenTheme theme
    property bool active: false
    property var scanningDevices: []
    property Network trackedNetwork: null
    property Network passwordNetwork: null
    property string message: ""
    property bool failed: false
    signal closeRequested()
    signal settingsRequested()
    spacing: root.theme.spacing.small

    readonly property var devices: Networking.devices.values
    readonly property var wifiDevices: devices.filter(d => d.type === DeviceType.Wifi && d.nmManaged)
    readonly property var networks: {
        const result = [];
        for (const device of devices)
            for (const network of device.networks.values) result.push(network);
        return result.sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.known) - Number(a.known)
            || strength(b) - strength(a) || a.name.localeCompare(b.name));
    }
    readonly property bool changing: networks.some(n => n.stateChanging)
    readonly property var monitoredDevice: devices.find(d => d.connected && d.type === DeviceType.Wired)
        || devices.find(d => d.connected) || null
    NetworkDetails {
        id: liveDetails
        diagnosticsOnly: true
        live: true
        active: root.active && root.monitoredDevice !== null
        interfaceName: root.monitoredDevice ? root.monitoredDevice.name : ""
        wireless: root.monitoredDevice !== null && root.monitoredDevice.type === DeviceType.Wifi
    }
    readonly property string status: {
        if (Networking.backend === NetworkBackendType.None) return "NetworkManager is unavailable.";
        if (devices.length === 0) return "No network interfaces detected.";
        if (!devices.some(d => d.connected)) return "Disconnected";
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full: return "Internet available";
        case NetworkConnectivity.Portal: return "Connected — sign-in required (captive portal)";
        case NetworkConnectivity.Limited: return "Connected — limited internet access";
        case NetworkConnectivity.None: return "Connected — no internet access reported";
        default: return "Connected — internet status not checked";
        }
    }

    function isWifi(network): bool { return network.device.type === DeviceType.Wifi; }
    function strength(network): real { return isWifi(network) ? network.signalStrength : 1; }
    function usesPassword(network): bool {
        return isWifi(network) && (network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk || network.security === WifiSecurityType.Sae);
    }
    function stopScan(): void {
        for (const device of scanningDevices) if (device) device.scannerEnabled = false;
        scanningDevices = [];
    }
    function clearPassword(): void { passwordNetwork = null; password.text = ""; }
    function connectNetwork(network): void {
        clearPassword();
        trackedNetwork = network;
        failed = false;
        message = "";
        if (!network.known && usesPassword(network)) {
            passwordNetwork = network;
        } else if (network.known || !isWifi(network) || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) {
            message = "Connecting to " + network.name + "…";
            network.connect();
        } else {
            message = "This network needs an enterprise or legacy profile. Configure it with NetworkManager (nmcli), then reconnect here.";
        }
    }
    function submitPassword(): void {
        const network = passwordNetwork;
        if (!network || password.text.length === 0 || !active || changing) return;
        // Send secrets directly over the native API, never command arguments/files.
        // NetworkManager validates the security-specific password requirements.
        trackedNetwork = network;
        failed = false;
        message = "Connecting to " + network.name + "…";
        const secret = password.text;
        clearPassword();
        network.connectWithPsk(secret);
    }
    onActiveChanged: {
        if (active) forceActiveFocus();
        else { stopScan(); clearPassword(); }
    }
    onPasswordNetworkChanged: password.text = ""
    onDevicesChanged: stopScan()
    onNetworksChanged: {
        if (passwordNetwork && !networks.includes(passwordNetwork)) clearPassword();
    }
    Component.onDestruction: stopScan()
    Keys.onEscapePressed: closeRequested()

    Connections {
        target: Networking
        function onWifiEnabledChanged(): void {
            if (!Networking.wifiEnabled) { root.stopScan(); root.clearPassword(); }
        }
    }
    Connections {
        target: root.trackedNetwork
        function onConnectionFailed(reason): void {
            root.failed = true;
            root.message = "Connection failed: " + ConnectionFailReason.toString(reason);
            if (root.active && root.trackedNetwork && root.usesPassword(root.trackedNetwork)
                    && (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout)) {
                root.passwordNetwork = root.trackedNetwork;
                root.message = "A Wi-Fi password is required, or the saved password was rejected.";
            }
        }
        function onConnectedChanged(): void {
            if (root.trackedNetwork && root.trackedNetwork.connected) {
                root.message = "Connected to " + root.trackedNetwork.name;
                root.failed = false;
                root.clearPassword();
            }
        }
    }
    Timer {
        interval: 15000
        running: root.scanningDevices.length > 0
        onTriggered: root.stopScan()
    }

    component ActionButton: Basic.Button {
        id: button
        font: root.theme.smallFont
        padding: root.theme.spacing.medium
        hoverEnabled: true
        contentItem: Text {
            text: button.text
            font: button.font
            textFormat: Text.PlainText
            color: button.enabled ? root.theme.foreground : root.theme.muted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: root.theme.radius.small
            color: button.down ? root.theme.surfacePressed : button.hovered ? root.theme.surfaceHover : root.theme.surface
            border.color: root.theme.focusBorder
            border.width: button.visualFocus ? root.theme.widget.borderWidth : 0
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: "Network"; font: root.theme.largeFont; color: root.theme.foreground }
        ActionButton { text: "Close"; Accessible.name: "Close network popup"; onClicked: root.closeRequested() }
    }
    Text {
        Layout.fillWidth: true
        text: root.status
        textFormat: Text.PlainText
        font: root.theme.smallFont
        color: root.theme.muted
        wrapMode: Text.WordWrap
    }
    Rectangle {
        objectName: "liveNetworkInfo"
        Layout.fillWidth: true
        visible: root.monitoredDevice !== null
        implicitHeight: liveInfo.implicitHeight + 2 * root.theme.spacing.small
        radius: root.theme.radius.small
        color: root.theme.surface
        ColumnLayout {
            id: liveInfo
            anchors.fill: parent
            anchors.margins: root.theme.spacing.small
            spacing: root.theme.spacing.small
            Text {
                Layout.fillWidth: true
                text: "Link speed: " + (liveDetails.linkSpeed || "--")
                    + "\nPing (avg 5): " + liveDetails.liveLatency
                    + "\nPacket loss (last 24): " + liveDetails.liveLoss
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
                font: root.theme.smallFont
                color: root.theme.foreground
            }
            Text {
                Layout.fillWidth: true
                text: liveDetails.interfaceName + " · Ping → " + (liveDetails.pingTarget || "--") + " · 1s"
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                font: root.theme.smallFont
                color: root.theme.muted
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        ActionButton {
            objectName: "wifiPowerButton"
            text: Networking.wifiEnabled ? "Wi-Fi off" : "Wi-Fi on"
            enabled: root.wifiDevices.length > 0 && Networking.wifiHardwareEnabled
            Accessible.name: "Toggle Wi-Fi power"
            onClicked: { root.stopScan(); root.clearPassword(); Networking.wifiEnabled = !Networking.wifiEnabled; }
        }
        ActionButton {
            objectName: "wifiScanButton"
            text: root.scanningDevices.length > 0 ? "Stop scan" : "Scan"
            enabled: Networking.wifiEnabled && Networking.wifiHardwareEnabled && root.wifiDevices.length > 0
                && (root.scanningDevices.length > 0 || root.wifiDevices.some(d => !d.scannerEnabled))
            onClicked: {
                if (root.scanningDevices.length > 0) root.stopScan();
                else {
                    root.scanningDevices = root.wifiDevices.filter(d => !d.scannerEnabled);
                    for (const device of root.scanningDevices) device.scannerEnabled = true;
                }
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.wifiDevices.length === 0 ? "No managed Wi-Fi adapter" : !Networking.wifiHardwareEnabled ? "Wi-Fi hardware blocked" : ""
            font: root.theme.smallFont
            color: root.theme.muted
            wrapMode: Text.WordWrap
        }
    }
    Text {
        Layout.fillWidth: true
        visible: root.networks.length === 0
        text: "No networks found. Scan for Wi-Fi, or open Settings & diagnostics for saved and hidden profiles."
        wrapMode: Text.WordWrap
        font: root.theme.smallFont
        color: root.theme.muted
    }
    Basic.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: availableWidth
        Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
        ColumnLayout {
            width: root.width
            spacing: root.theme.spacing.small
            Repeater {
                model: root.networks
                delegate: Rectangle {
                    id: row
                    required property Network modelData
                    readonly property bool wifi: root.isWifi(modelData)
                    Layout.fillWidth: true
                    implicitHeight: contents.implicitHeight + 2 * root.theme.spacing.small
                    radius: root.theme.radius.small
                    color: root.theme.surface
                    RowLayout {
                        id: contents
                        anchors.fill: parent
                        anchors.margins: root.theme.spacing.small
                        spacing: root.theme.spacing.small
                        MaterialIcon { theme: root.theme; text: row.wifi ? "wifi" : "lan"; color: row.modelData.connected ? root.theme.accent : root.theme.muted }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name || (row.wifi ? "Hidden network" : "Wired connection")
                                textFormat: Text.PlainText
                                font: root.theme.font
                                color: root.theme.foreground
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.device.name + " · " + (row.modelData.connected ? "Connected" : row.modelData.stateChanging ? "Working…" : row.modelData.known ? "Saved" : "Available")
                                    + (row.wifi ? " · " + Math.round(root.strength(row.modelData) * 100) + "%" : "")
                                textFormat: Text.PlainText
                                font: root.theme.smallFont
                                color: root.theme.muted
                                elide: Text.ElideRight
                            }
                        }
                        ActionButton {
                            text: row.modelData.stateChanging ? "Working…" : row.modelData.connected ? "Disconnect" : "Connect"
                            enabled: row.modelData.device.nmManaged && !row.modelData.stateChanging && !root.changing
                                && (!row.wifi || (Networking.wifiEnabled && Networking.wifiHardwareEnabled && row.modelData.name.length > 0))
                            Accessible.name: text + " " + row.modelData.name
                            onClicked: {
                                root.clearPassword();
                                if (row.modelData.connected) { root.trackedNetwork = row.modelData; row.modelData.disconnect(); }
                                else root.connectNetwork(row.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: root.message !== ""
        text: root.message
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        font: root.theme.smallFont
        color: root.failed ? root.theme.error : root.theme.muted
    }
    Text {
        Layout.fillWidth: true
        visible: root.passwordNetwork !== null
        text: "Password for " + (root.passwordNetwork ? root.passwordNetwork.name : "")
        textFormat: Text.PlainText
        elide: Text.ElideRight
        font: root.theme.smallFont
        color: root.theme.foreground
    }
    Basic.TextField {
        id: password
        objectName: "wifiPassword"
        Layout.fillWidth: true
        visible: root.passwordNetwork !== null
        echoMode: TextInput.Password
        font: root.theme.font
        color: root.theme.foreground
        selectionColor: root.theme.selectionBackground
        selectedTextColor: root.theme.selectionForeground
        placeholderText: "Wi-Fi password"
        Accessible.name: placeholderText
        onVisibleChanged: { if (visible) forceActiveFocus(); else text = ""; }
        onAccepted: root.submitPassword()
        background: Rectangle {
            radius: root.theme.radius.small
            color: root.theme.surface
            border.color: password.activeFocus ? root.theme.focusBorder : root.theme.border
            border.width: root.theme.widget.borderWidth
        }
    }
    RowLayout {
        visible: root.passwordNetwork !== null
        ActionButton { text: "Connect"; enabled: password.text.length > 0 && !root.changing; onClicked: root.submitPassword() }
        ActionButton { text: "Cancel"; onClicked: root.clearPassword() }
    }
    ActionButton {
        Layout.fillWidth: true
        text: "Settings & diagnostics…"
        onClicked: {
            root.clearPassword();
            root.stopScan();
            root.settingsRequested();
        }
    }
}

pragma ComponentBehavior: Bound
import Quickshell.Networking
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property ScreenTheme theme
    property bool active: false
    readonly property var devices: Networking.devices.values
    property var selectedDevice: devices.find(d => d.connected) || devices[0] || null
    property bool manualDns: false
    property bool confirmForget: false
    readonly property bool canJoinHidden: selectedDevice !== null && selectedDevice.type === DeviceType.Wifi
        && selectedDevice.nmManaged && Networking.wifiEnabled && Networking.wifiHardwareEnabled
    onCanJoinHiddenChanged: { if (!canJoinHidden) hiddenPassword.text = ""; }
    onSelectedDeviceChanged: hiddenPassword.text = ""
    signal backRequested()
    signal closeRequested()
    spacing: root.theme.spacing.small
    onDevicesChanged: { if (!devices.includes(selectedDevice)) selectedDevice = devices.find(d => d.connected) || devices[0] || null; }
    onActiveChanged: { if (active) forceActiveFocus(); else { hiddenPassword.text = ""; confirmForget = false; } }
    Keys.onEscapePressed: closeRequested()

    NetworkDetails {
        id: details
        active: root.active
        interfaceName: root.selectedDevice ? root.selectedDevice.name : ""
        wireless: root.selectedDevice !== null && root.selectedDevice.type === DeviceType.Wifi
        onUuidChanged: root.confirmForget = false
        onProfileLoaded: {
            root.manualDns = !automaticDns;
            ipv4.text = dns4; ipv6.text = dns6;
        }
    }
    component Label: Text {
        Layout.fillWidth: true
        font: root.theme.smallFont
        color: root.theme.foreground
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
    }
    component ActionButton: Basic.Button {
        id: control
        padding: root.theme.spacing.medium
        font: root.theme.smallFont
        hoverEnabled: true
        contentItem: Text {
            text: control.text; font: control.font; textFormat: Text.PlainText
            color: control.enabled ? root.theme.foreground : root.theme.muted
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: root.theme.radius.small
            color: control.down ? root.theme.surfacePressed : control.hovered ? root.theme.surfaceHover : root.theme.surface
            border.color: root.theme.focusBorder
            border.width: control.visualFocus ? root.theme.widget.borderWidth : 0
        }
    }
    component Field: Basic.TextField {
        id: control
        Layout.fillWidth: true
        font: root.theme.smallFont
        color: root.theme.foreground
        placeholderTextColor: root.theme.muted
        selectionColor: root.theme.selectionBackground
        selectedTextColor: root.theme.selectionForeground
        Accessible.name: placeholderText
        background: Rectangle {
            color: root.theme.surface; radius: root.theme.radius.small
            border.width: root.theme.widget.borderWidth
            border.color: control.activeFocus ? root.theme.focusBorder : root.theme.border
        }
    }
    component Selector: Basic.ComboBox {
        Layout.fillWidth: true
        font: root.theme.smallFont
        palette.button: root.theme.surface
        palette.buttonText: root.theme.foreground
        palette.text: root.theme.foreground
        palette.base: root.theme.background
        palette.window: root.theme.background
        palette.windowText: root.theme.foreground
        palette.highlight: root.theme.accent
        palette.highlightedText: root.theme.accentForeground
    }
    RowLayout {
        Layout.fillWidth: true
        ActionButton { text: "Back"; onClicked: root.backRequested() }
        Label { text: "Network settings"; font: root.theme.font }
        ActionButton { text: "Close"; onClicked: root.closeRequested() }
    }
    Label { visible: details.message !== ""; text: details.message; color: details.failed ? root.theme.error : root.theme.muted }
    Basic.ScrollView {
        id: settingsScroll
        Layout.fillWidth: true; Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true
        Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
        ColumnLayout {
            width: settingsScroll.availableWidth
            spacing: root.theme.spacing.small
            Label { text: "Current connection"; font: root.theme.font }
            Selector {
                model: root.devices.map(d => d.name)
                currentIndex: root.devices.indexOf(root.selectedDevice)
                enabled: !details.busy && !details.pingRunning
                Accessible.name: "Network interface"
                onActivated: index => { root.selectedDevice = root.devices[index]; }
            }
            Label {
                text: "Profile: " + (details.info["GENERAL.CONNECTION"] || "None")
                    + "\nState: " + (details.info["GENERAL.STATE"] || "Unavailable")
                    + "\nMAC: " + (details.info["GENERAL.HWADDR"] || "Unavailable")
                    + "\nLink speed: " + (details.linkSpeed || "Unavailable")
                    + "\nIPv4: " + (details.info["IP4.ADDRESS"] || "None")
                    + "\nIPv6: " + (details.info["IP6.ADDRESS"] || "None")
                    + "\nGateway: " + (details.info["IP4.GATEWAY"] || details.info["IP6.GATEWAY"] || "None")
                    + "\nActive DNS: " + [details.info["IP4.DNS"], details.info["IP6.DNS"]].filter(v => v).join(", ")
            }
            ActionButton { text: "Refresh info"; enabled: !details.busy; onClicked: { details.message = ""; details.failed = false; details.refresh(); } }
            Label { text: "Ping / packet loss (five packets)"; font: root.theme.font }
            Field { text: details.pingTarget; placeholderText: "Gateway, IP address or hostname"; onTextEdited: details.pingTarget = text }
            RowLayout {
                ActionButton { text: "Test"; enabled: details.interfaceName !== "" && !details.pingRunning; onClicked: details.ping() }
                ActionButton { text: "Stop"; enabled: details.pingRunning; onClicked: details.stopPing() }
            }
            Label { text: details.pingResult || "Runs only when you press Test. ICMP may be blocked; link speed is not measured internet throughput."; color: root.theme.muted }

            Label { text: "Saved profile"; font: root.theme.font }
            Selector {
                model: details.profiles.map(p => p.label)
                currentIndex: details.profiles.findIndex(p => p.uuid === details.uuid)
                enabled: !details.busy
                Accessible.name: "Saved network profile"
                onActivated: index => details.selectProfile(details.profiles[index].uuid)
            }
            Label { text: details.uuid ? "UUID: " + details.uuid : "No saved profiles"; color: root.theme.muted }
            RowLayout {
                ActionButton {
                    text: details.autoconnect ? "Autoconnect: on" : "Autoconnect: off"
                    enabled: details.uuid !== "" && !details.busy
                    onClicked: details.setAutoconnect(!details.autoconnect)
                }
                ActionButton { text: "Forget…"; enabled: details.uuid !== "" && !details.busy; onClicked: root.confirmForget = true }
            }
            Label {
                visible: root.confirmForget
                text: "Forget this profile and its saved credentials? An active connection using it may disconnect."
                color: root.theme.warning
            }
            RowLayout {
                visible: root.confirmForget
                ActionButton { text: "Confirm forget"; enabled: !details.busy; onClicked: { root.confirmForget = false; details.forget(); } }
                ActionButton { text: "Cancel"; onClicked: root.confirmForget = false }
            }
            Label { text: "DNS for the selected saved profile"; font: root.theme.font }
            Selector {
                model: ["Automatic (DHCP / router)", "Custom DNS only"]
                currentIndex: root.manualDns ? 1 : 0
                enabled: !details.busy && details.uuid !== ""
                onActivated: index => root.manualDns = index === 1
                Accessible.name: "DNS mode"
            }
            Field { id: ipv4; placeholderText: "IPv4 DNS: e.g. 1.1.1.1, 9.9.9.9"; enabled: root.manualDns && !details.busy }
            Field { id: ipv6; placeholderText: "IPv6 DNS: e.g. 2606:4700:4700::1111"; enabled: root.manualDns && !details.busy }
            ActionButton { text: "Apply DNS"; enabled: details.uuid !== "" && !details.busy; onClicked: details.saveDns(!root.manualDns, ipv4.text, ipv6.text) }
            Label {
                text: (details.mixedDns ? "This profile currently uses different DNS modes for IPv4 and IPv6. " : "")
                    + "Apply sets the chosen mode for both IP families. Automatic clears custom servers. Live reapply does not force a reconnect."
                color: root.theme.muted
            }

            Label { text: "Join a hidden Wi-Fi network"; font: root.theme.font }
            Field { id: hiddenSsid; placeholderText: "Exact SSID (up to 32 UTF-8 bytes)"; enabled: root.canJoinHidden && !details.busy }
            Selector {
                id: hiddenSecurity
                model: ["WPA/WPA2 Personal", "WPA3 Personal (SAE)", "Open (unencrypted)"]
                enabled: root.canJoinHidden && !details.busy
                Accessible.name: "Hidden Wi-Fi security"
                onActivated: hiddenPassword.text = ""
            }
            Field {
                id: hiddenPassword
                placeholderText: "Hidden Wi-Fi password"
                echoMode: TextInput.Password
                visible: hiddenSecurity.currentIndex !== 2
                enabled: root.canJoinHidden && !details.busy
            }
            ActionButton {
                text: "Join hidden network"
                enabled: root.canJoinHidden && !details.busy && hiddenSsid.text.length > 0
                    && (hiddenSecurity.currentIndex === 2 || hiddenPassword.text.length > 0)
                onClicked: {
                    details.hidden(hiddenSsid.text, ["wpa-psk", "sae", "open"][hiddenSecurity.currentIndex], hiddenPassword.text);
                    hiddenPassword.text = "";
                }
            }
            Label { text: "Uses the selected Wi-Fi interface. Creates a new saved profile with autoconnect initially off. Enterprise/certificate setup remains outside this editor."; color: root.theme.muted }
        }
    }
}

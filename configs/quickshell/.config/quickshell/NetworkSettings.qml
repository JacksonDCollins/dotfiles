pragma ComponentBehavior: Bound
import Quickshell.Networking
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

ColumnLayout {
    id: root
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
    spacing: Theme.spacing.small
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
        font: Theme.smallFont
        color: Theme.foreground
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
    }
    component ActionButton: Basic.Button {
        id: control
        padding: Theme.spacing.medium
        font: Theme.smallFont
        hoverEnabled: true
        contentItem: Text {
            text: control.text; font: control.font; textFormat: Text.PlainText
            color: control.enabled ? Theme.foreground : Theme.muted
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: Theme.radius.small
            color: control.down ? Theme.surfacePressed : control.hovered ? Theme.surfaceHover : Theme.surface
            border.color: Theme.focusBorder
            border.width: control.visualFocus ? Theme.widget.borderWidth : 0
        }
    }
    component Field: Basic.TextField {
        id: control
        Layout.fillWidth: true
        font: Theme.smallFont
        color: Theme.foreground
        placeholderTextColor: Theme.muted
        selectionColor: Theme.selectionBackground
        selectedTextColor: Theme.selectionForeground
        Accessible.name: placeholderText
        background: Rectangle {
            color: Theme.surface; radius: Theme.radius.small
            border.width: Theme.widget.borderWidth
            border.color: control.activeFocus ? Theme.focusBorder : Theme.border
        }
    }
    component Selector: Basic.ComboBox {
        Layout.fillWidth: true
        font: Theme.smallFont
        palette.button: Theme.surface
        palette.buttonText: Theme.foreground
        palette.text: Theme.foreground
        palette.base: Theme.background
        palette.window: Theme.background
        palette.windowText: Theme.foreground
        palette.highlight: Theme.accent
        palette.highlightedText: Theme.accentForeground
    }
    RowLayout {
        Layout.fillWidth: true
        ActionButton { text: "Back"; onClicked: root.backRequested() }
        Label { text: "Network settings"; font: Theme.font }
        ActionButton { text: "Close"; onClicked: root.closeRequested() }
    }
    Label { visible: details.message !== ""; text: details.message; color: details.failed ? Theme.error : Theme.muted }
    Basic.ScrollView {
        id: settingsScroll
        Layout.fillWidth: true; Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true
        Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
        ColumnLayout {
            width: settingsScroll.availableWidth
            spacing: Theme.spacing.small
            Label { text: "Current connection"; font: Theme.font }
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
            Label { text: "Ping / packet loss (five packets)"; font: Theme.font }
            Field { text: details.pingTarget; placeholderText: "Gateway, IP address or hostname"; onTextEdited: details.pingTarget = text }
            RowLayout {
                ActionButton { text: "Test"; enabled: details.interfaceName !== "" && !details.pingRunning; onClicked: details.ping() }
                ActionButton { text: "Stop"; enabled: details.pingRunning; onClicked: details.stopPing() }
            }
            Label { text: details.pingResult || "Runs only when you press Test. ICMP may be blocked; link speed is not measured internet throughput."; color: Theme.muted }

            Label { text: "Saved profile"; font: Theme.font }
            Selector {
                model: details.profiles.map(p => p.label)
                currentIndex: details.profiles.findIndex(p => p.uuid === details.uuid)
                enabled: !details.busy
                Accessible.name: "Saved network profile"
                onActivated: index => details.selectProfile(details.profiles[index].uuid)
            }
            Label { text: details.uuid ? "UUID: " + details.uuid : "No saved profiles"; color: Theme.muted }
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
                color: Theme.warning
            }
            RowLayout {
                visible: root.confirmForget
                ActionButton { text: "Confirm forget"; enabled: !details.busy; onClicked: { root.confirmForget = false; details.forget(); } }
                ActionButton { text: "Cancel"; onClicked: root.confirmForget = false }
            }
            Label { text: "DNS for the selected saved profile"; font: Theme.font }
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
                color: Theme.muted
            }

            Label { text: "Join a hidden Wi-Fi network"; font: Theme.font }
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
            Label { text: "Uses the selected Wi-Fi interface. Creates a new saved profile with autoconnect initially off. Enterprise/certificate setup remains outside this editor."; color: Theme.muted }
        }
    }
}

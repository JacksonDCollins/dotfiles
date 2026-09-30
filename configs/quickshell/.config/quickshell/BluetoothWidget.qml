pragma ComponentBehavior: Bound
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property ScreenTheme theme
    property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    property bool active: false
    property BluetoothAdapter scanningAdapter: null
    signal closeRequested()
    spacing: root.theme.spacing.small

    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property bool powerBusy: adapter !== null && (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) =>
        Number(b.connected) - Number(a.connected) || Number(b.paired || b.bonded) - Number(a.paired || a.bonded)
        || (a.name || a.address).localeCompare(b.name || b.address)) : []

    function stopScan(): void {
        if (scanningAdapter)
            scanningAdapter.discovering = false;
        scanningAdapter = null;
    }
    onActiveChanged: {
        if (active) forceActiveFocus();
        else { stopScan(); pairing.cancel(""); }
    }
    onAdapterChanged: { stopScan(); pairing.cancel("Bluetooth adapter changed."); }
    onPoweredChanged: {
        if (!powered) { stopScan(); pairing.cancel("Bluetooth was turned off."); }
    }
    Component.onDestruction: stopScan()
    Keys.onEscapePressed: closeRequested()

    Timer {
        interval: 30000
        running: root.scanningAdapter !== null
        onTriggered: root.stopScan()
    }
    BluetoothPairing {
        id: pairing
        onPromptTextChanged: pinInput.text = ""
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
        Text {
            Layout.fillWidth: true
            text: "Bluetooth"
            font: root.theme.largeFont
            color: root.theme.foreground
        }
        ActionButton {
            text: "Close"
            Accessible.name: "Close Bluetooth popup"
            onClicked: root.closeRequested()
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: !root.adapter ? "No Bluetooth adapter detected" : root.adapter.name
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font: root.theme.font
            color: root.theme.muted
        }
        ActionButton {
            objectName: "powerButton"
            text: root.powerBusy ? "Working…" : root.powered ? "Turn off" : "Turn on"
            enabled: root.adapter !== null && !root.powerBusy && root.adapter.state !== BluetoothAdapterState.Blocked
            Accessible.name: "Toggle Bluetooth power"
            onClicked: {
                root.stopScan();
                pairing.cancel("");
                root.adapter.enabled = !root.powered;
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: !root.powered || root.devices.length === 0
        text: !root.adapter ? "Check that an adapter is connected and Bluetooth is available on this system."
            : root.adapter.state === BluetoothAdapterState.Blocked ? "Bluetooth is blocked. Check your hardware radio switch or airplane mode."
            : !root.powered ? "Bluetooth is off." : "No devices found. Scan for nearby devices."
        wrapMode: Text.WordWrap
        font: root.theme.smallFont
        color: root.theme.muted
    }
    RowLayout {
        Layout.fillWidth: true
        ActionButton {
            objectName: "scanButton"
            text: root.scanningAdapter ? "Stop scan" : root.adapter && root.adapter.discovering ? "Scanning…" : "Scan"
            enabled: root.powered && !root.powerBusy && !pairing.busy && (root.scanningAdapter !== null || !root.adapter.discovering)
            onClicked: {
                if (root.scanningAdapter) root.stopScan();
                else {
                    root.scanningAdapter = root.adapter;
                    root.adapter.discovering = true;
                }
            }
        }
        Text {
            Layout.fillWidth: true
            text: "Scans stop after 30 seconds or when this popup closes."
            wrapMode: Text.WordWrap
            font: root.theme.smallFont
            color: root.theme.muted
        }
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
                model: root.powered ? root.devices : []
                delegate: Rectangle {
                    id: row
                    required property BluetoothDevice modelData
                    readonly property bool busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                    Layout.fillWidth: true
                    implicitHeight: rowContent.implicitHeight + 2 * root.theme.spacing.small
                    color: root.theme.surface
                    radius: root.theme.radius.small
                    RowLayout {
                        id: rowContent
                        anchors.fill: parent
                        anchors.margins: root.theme.spacing.small
                        spacing: root.theme.spacing.small
                        MaterialIcon { theme: root.theme;
                            text: row.modelData.icon.includes("audio") ? "headphones" : row.modelData.icon.includes("keyboard") ? "keyboard" : row.modelData.icon.includes("mouse") ? "mouse" : "bluetooth"
                            color: row.modelData.connected ? root.theme.accent : root.theme.muted
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name || row.modelData.address
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                font: root.theme.font
                                color: root.theme.foreground
                            }
                            Text {
                                Layout.fillWidth: true
                                text: (row.modelData.blocked ? "Blocked" : row.modelData.pairing ? "Pairing…" : row.busy ? "Working…" : row.modelData.connected ? "Connected" : row.modelData.paired || row.modelData.bonded ? "Saved" : "Nearby")
                                    + (row.modelData.batteryAvailable ? " · " + Math.round(row.modelData.battery * 100) + "%" : "")
                                elide: Text.ElideRight
                                font: root.theme.smallFont
                                color: root.theme.muted
                            }
                        }
                        ActionButton {
                            text: row.busy ? "Working…" : row.modelData.connected ? "Disconnect" : row.modelData.paired || row.modelData.bonded ? "Connect" : "Pair…"
                            enabled: root.powered && !root.powerBusy && !row.busy && !row.modelData.blocked && !pairing.busy
                            Accessible.name: text + " " + (row.modelData.name || row.modelData.address)
                            onClicked: {
                                if (row.modelData.connected) row.modelData.disconnect();
                                else if (row.modelData.paired || row.modelData.bonded) row.modelData.connect();
                                else { root.stopScan(); pairing.start(row.modelData); }
                            }
                        }
                        ActionButton {
                            text: "Forget"
                            visible: row.modelData.paired || row.modelData.bonded
                            enabled: root.powered && !root.powerBusy && !row.busy && !pairing.busy
                            Accessible.name: "Forget " + (row.modelData.name || row.modelData.address)
                            onClicked: row.modelData.forget()
                        }
                    }
                }
            }
        }
    }
    Text {
        Layout.fillWidth: true
        text: pairing.message || "Choose Pair for a new device. Confirmation and PIN prompts appear here."
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        font: root.theme.smallFont
        color: pairing.phase === "error" ? root.theme.error : root.theme.muted
    }
    Text {
        Layout.fillWidth: true
        visible: pairing.promptText !== ""
        text: pairing.promptText
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        font: root.theme.font
        color: root.theme.foreground
    }
    Basic.TextField {
        id: pinInput
        Layout.fillWidth: true
        visible: pairing.promptKind === "pin" || pairing.promptKind === "passkey"
        maximumLength: pairing.promptKind === "passkey" ? 6 : 16
        validator: RegularExpressionValidator {
            regularExpression: pairing.promptKind === "passkey" ? /^[0-9]{1,6}$/ : /^[\x20-\x7e]{1,16}$/
        }
        echoMode: TextInput.Password
        font: root.theme.font
        color: root.theme.foreground
        selectionColor: root.theme.selectionBackground
        selectedTextColor: root.theme.selectionForeground
        placeholderText: pairing.promptKind === "passkey" ? "Passkey" : "PIN"
        Accessible.name: placeholderText
        onVisibleChanged: { if (visible) forceActiveFocus(); else text = ""; }
        onAccepted: { if (acceptableInput) pairing.reply(text); }
        background: Rectangle {
            radius: root.theme.radius.small
            color: root.theme.surface
            border.color: pinInput.activeFocus ? root.theme.focusBorder : root.theme.border
            border.width: root.theme.widget.borderWidth
        }
    }
    RowLayout {
        visible: pairing.busy
        ActionButton {
            visible: pairing.promptKind === "confirm"
            text: "Confirm"
            onClicked: pairing.reply("yes")
        }
        ActionButton {
            visible: pairing.promptKind === "confirm"
            text: "Reject"
            onClicked: pairing.reply("no")
        }
        ActionButton {
            visible: pinInput.visible
            text: "Submit"
            enabled: pinInput.acceptableInput
            onClicked: pairing.reply(pinInput.text)
        }
        ActionButton {
            text: "Cancel"
            onClicked: pairing.cancel("")
        }
    }
}

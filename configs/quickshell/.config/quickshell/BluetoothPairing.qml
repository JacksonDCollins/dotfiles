import QtQuick
import Quickshell
import Quickshell.Io

// bluetoothctl owns the BlueZ agent; this controller only translates its UI.
Scope {
    id: root
    property var device: null
    property string phase: "idle"
    property string promptKind: ""
    property string promptText: ""
    property string message: ""
    property string buffer: ""
    property string controllerAddress: ""
    readonly property bool busy: session.running || phase === "starting" || phase === "pairing" || phase === "prompt"
    readonly property bool awaitingReply: promptKind === "pin" || promptKind === "passkey" || promptKind === "confirm"

    function start(target): void {
        if (busy) return;
        if (!target || !/^(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(target.address)
                || !target.adapter || !/^\/org\/bluez\/hci[0-9]+$/.test(target.adapter.dbusPath)) {
            message = "Cannot pair: invalid device or adapter.";
            return;
        }
        device = target;
        buffer = "";
        controllerAddress = "";
        promptKind = "";
        promptText = "";
        message = "Starting pairing…";
        phase = "starting";
        // Resolve the actual adapter MAC instead of assuming bluetoothctl's default
        // adapter matches Quickshell's. systemd supplies busctl on our Arch systems.
        session.command = ["/bin/sh", "-c",
            "command -v bluetoothctl >/dev/null 2>&1 || exit 127; command -v script >/dev/null 2>&1 || exit 127; "
            + "controller=$(busctl --system get-property org.bluez \"$1\" org.bluez.Adapter1 Address) || exit 1; "
            + "printf '__QS_CONTROLLER__ %s\\n' \"$controller\"; "
            + "exec script --quiet --return --flush --echo never --command 'exec bluetoothctl --agent KeyboardDisplay' /dev/null",
            "quickshell-bluetooth", target.adapter.dbusPath];
        session.running = true;
    }

    function cancel(reason): void {
        const wasBusy = busy;
        phase = "idle";
        promptKind = "";
        promptText = "";
        if (wasBusy && device && device.pairing) device.cancelPair();
        session.running = false; // script handles SIGTERM and tears down its PTY child.
        if (wasBusy) message = reason || "Pairing cancelled.";
    }
    function fail(reason): void {
        cancel(reason);
        phase = "error";
        message = reason;
    }
    function reply(value): void {
        if (!busy || !awaitingReply) return;
        if (promptKind === "confirm") {
            if (value !== "yes" && value !== "no") return;
        } else if (promptKind === "passkey") {
            if (!/^[0-9]{1,6}$/.test(value)) return;
        } else if (!/^[\x20-\x7e]{1,16}$/.test(value)) {
            return; // PINs must not contain newlines or terminal control characters.
        }
        session.write(value + "\n");
        promptKind = "";
        promptText = "";
        phase = "pairing";
        message = "Waiting for the device…";
    }
    function offer(kind, text): void {
        promptKind = kind;
        promptText = text;
        phase = "prompt";
        message = "Pairing " + (device ? device.name || device.address : "device");
    }

    function receive(chunk): void {
        if (phase !== "starting" && phase !== "pairing" && phase !== "prompt") return;
        // Retain incomplete escape sequences/prompts across chunks. Never log the
        // raw stream: bluetoothctl may echo entered PINs even with PTY echo off.
        buffer += chunk;
        if (buffer.length > 65536) {
            fail("Bluetooth produced too much output. Pairing stopped safely.");
            return;
        }
        buffer = buffer.replace(/\x1b\][^\x07]*(?:\x07|\x1b\\)/g, "")
            .replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "").replace(/\r/g, "\n");
        let match = buffer.match(/__QS_CONTROLLER__ s "((?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2})"/);
        if (match) controllerAddress = match[1];
        if (phase === "starting" && controllerAddress && /(?:^|\n)Agent registered(?:\n|$)/.test(buffer)) {
            phase = "pairing";
            message = "Waiting for the device…";
            buffer = "";
            session.write("select " + controllerAddress + "\npair " + device.address + "\n");
            return;
        }
        if (/(?:^|\n)(?:Failed to (?:pair|register agent|connect)|No default controller available|Device [0-9A-Fa-f:]+ not available|Controller [0-9A-Fa-f:]+ not available)/.test(buffer)) {
            fail("Pairing failed. Check Bluetooth power and put the device in pairing mode, then retry.");
            return;
        }
        if (phase !== "starting" && /(?:^|\n)Pairing successful(?:\n|$)/.test(buffer)) {
            phase = "done";
            promptKind = "";
            promptText = "";
            message = "Paired. You can now connect to the device.";
            buffer = "";
            session.write("quit\n");
            return;
        }
        // Prompts are anchored to the agent prefix, never arbitrary device names.
        const prompts = [
            [/\[agent\] Confirm passkey ([0-9]{6}) \(yes\/no\):\s*/, "confirm"],
            [/\[agent\] Accept pairing \(yes\/no\):\s*/, "confirm"],
            [/\[agent\] Authorize service ([0-9a-fA-F-]+) \(yes\/no\):\s*/, "confirm"],
            [/\[agent\] Enter PIN code:\s*/, "pin"],
            [/\[agent\] Enter passkey \(number in 0-999999\):\s*/, "passkey"],
            [/\[agent\] Passkey: ([0-9]{6})(?:\n|$)/, "display"],
            [/\[agent\] PIN code: ([^\n]+)\n/, "display"]
        ];
        for (const entry of prompts) {
            match = entry[0].exec(buffer);
            if (!match || (match.index > 0 && buffer[match.index - 1] !== "\n")) continue;
            buffer = buffer.slice(match.index + match[0].length);
            let text = match[0].replace(/^\[agent\] /, "").trim();
            if (entry[1] === "display") text = "Enter " + match[1] + " on the Bluetooth device, then press its Enter key.";
            offer(entry[1], text);
            return;
        }
        if (/(?:^|\n)\[agent\] Cancel(?:\n|$)/.test(buffer)) {
            fail("Pairing was cancelled by the device.");
        }
        // Unknown prompts are never answered automatically; the user can cancel,
        // and the overall deadline terminates a stalled or unsupported exchange.
    }

    Component.onDestruction: cancel("")
    Timer {
        interval: 120000
        running: root.phase === "starting" || root.phase === "pairing" || root.phase === "prompt"
        onTriggered: root.fail("Pairing timed out. Put the device in pairing mode and retry.")
    }
    Timer {
        interval: 1000
        running: root.phase === "done" && session.running
        onTriggered: session.running = false
    }
    Process {
        id: session
        stdinEnabled: true
        environment: ({ LC_ALL: "C", TERM: "dumb", NO_COLOR: "1", SHELL: "/bin/sh" })
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.receive(data)
        }
        onExited: (exitCode, exitStatus) => {
            if (root.phase === "done" || root.phase === "idle" || root.phase === "error") return;
            root.fail(exitCode === 127 ? "Install bluez-utils and util-linux to enable pairing." : "Bluetooth pairing stopped unexpectedly. Check that Bluetooth is available.");
        }
    }
}

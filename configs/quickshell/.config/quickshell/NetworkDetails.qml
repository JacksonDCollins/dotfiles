import QtQuick
import Quickshell
import Quickshell.Io

// nmcli supplies profile editing not exposed by our installed QML networking API.
Scope {
    id: root
    property bool active: false
    property bool diagnosticsOnly: false
    property bool live: false
    property string interfaceName: ""
    property bool wireless: false
    property var profiles: []
    property string uuid: ""
    property var info: ({})
    property bool autoconnect: false
    property bool automaticDns: true
    property bool mixedDns: false
    property string dns4: ""
    property string dns6: ""
    property string linkSpeed: ""
    property string message: ""
    property bool failed: false
    property string pingTarget: ""
    property string pingResult: ""
    property bool probeCancelled: false
    property var liveSamples: []
    property string liveError: ""
    readonly property string liveLatency: {
        if (liveError) return liveError;
        if (!liveSamples.length) return "--";
        if (liveSamples[liveSamples.length - 1] === null) return "Timeout";
        const replies = liveSamples.slice(-5).filter(value => value !== null);
        return (replies.reduce((sum, value) => sum + value, 0) / replies.length).toFixed(1) + " ms";
    }
    readonly property string liveLoss: liveError || !liveSamples.length ? "--"
        : Math.round(100 * liveSamples.filter(value => value === null).length / liveSamples.length) + "%"
    readonly property bool busy: reader.running || writer.running || refreshPending
    readonly property bool pingRunning: probe.running
    property string readKind: ""
    property string writeKind: ""
    property bool refreshPending: false
    property string actionUuid: ""
    property string actionInterface: ""
    property string actionPath: ""
    property string secret: ""
    signal profileLoaded()

    function validUuid(value): bool { return /^[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$/.test(value); }
    function split(line): var {
        // nmcli --terse escapes colon and backslash, including IPv6 addresses.
        const parts = [""];
        let escaped = false;
        for (const c of line) {
            if (escaped) { parts[parts.length - 1] += c; escaped = false; }
            else if (c === "\\") escaped = true;
            else if (c === ":") parts.push("");
            else parts[parts.length - 1] += c;
        }
        if (escaped) parts[parts.length - 1] += "\\";
        return parts;
    }
    function fields(text): var {
        const result = {};
        for (const line of text.trim().split("\n")) {
            const values = split(line);
            if (values.length < 2) continue;
            const key = values.shift().replace(/\[[0-9]+\]$/, "");
            const value = values.join(":");
            result[key] = result[key] ? result[key] + ", " + value : value;
        }
        return result;
    }
    function read(kind, args): void { readKind = kind; reader.command = args; reader.running = true; }
    function refresh(): void {
        if (!active) return;
        if (reader.running || writer.running) { refreshPending = true; return; }
        refreshPending = false;
        if (!live) { info = ({}); linkSpeed = ""; }
        if (!interfaceName) { if (!diagnosticsOnly) loadProfiles(); return; }
        read("info", ["nmcli", "-t", "-e", "yes", "-f", "GENERAL.CONNECTION,GENERAL.CON-UUID,GENERAL.STATE,GENERAL.HWADDR,GENERAL.DBUS-PATH,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,IP6.GATEWAY,IP6.DNS", "device", "show", interfaceName]);
    }
    function finishInfo(): void {
        if (live && active && !probe.running && !liveSamples.length) Qt.callLater(ping);
        if (!diagnosticsOnly) loadProfiles();
    }
    function loadProfiles(): void {
        read("profiles", ["nmcli", "-t", "-e", "yes", "-f", "UUID,NAME,TYPE,DEVICE", "connection", "show"]);
    }
    function selectProfile(value): void {
        if (busy || !validUuid(value)) return;
        uuid = value;
        loadProfile();
    }
    function loadProfile(): void {
        autoconnect = false; automaticDns = true; mixedDns = false; dns4 = ""; dns6 = "";
        if (!validUuid(uuid)) return;
        read("profile", ["nmcli", "-t", "-e", "yes", "-f", "connection.autoconnect,ipv4.ignore-auto-dns,ipv4.dns,ipv6.ignore-auto-dns,ipv6.dns", "connection", "show", "uuid", uuid]);
    }
    function mutate(kind, args): void {
        writeKind = kind; message = "Working…"; failed = false;
        writer.command = args; writer.running = true;
    }
    function setAutoconnect(value): void {
        if (busy || !validUuid(uuid)) return;
        mutate("saved", ["nmcli", "connection", "modify", "uuid", uuid, "connection.autoconnect", value ? "yes" : "no"]);
    }
    function forget(): void {
        if (busy || !validUuid(uuid)) return;
        mutate("forgotten", ["nmcli", "connection", "delete", "uuid", uuid]);
    }
    function saveDns(automatic, ipv4, ipv6): void {
        if (busy || !validUuid(uuid)) return;
        if (ipv4.length > 1024 || ipv6.length > 1024 || (!automatic && ((!ipv4.trim() && !ipv6.trim()) || !/^[0-9.,\s]*$/.test(ipv4) || !/^[0-9a-fA-F:.,\s]*$/.test(ipv6)))) {
            failed = true; message = "Enter numeric DNS server addresses, or choose Automatic."; return;
        }
        actionUuid = uuid;
        actionPath = info["GENERAL.CON-UUID"] === uuid ? info["GENERAL.DBUS-PATH"] || "" : "";
        mutate("dns", ["nmcli", "connection", "modify", "uuid", uuid,
            "ipv4.ignore-auto-dns", automatic ? "no" : "yes", "ipv4.dns", automatic ? "" : ipv4.trim().replace(/[\s,]+/g, ","),
            "ipv6.ignore-auto-dns", automatic ? "no" : "yes", "ipv6.dns", automatic ? "" : ipv6.trim().replace(/[\s,]+/g, ",")]);
    }
    function hidden(ssid, security, password): void {
        if (busy || !interfaceName || !wireless) return;
        let bytes = 0;
        try { bytes = encodeURIComponent(ssid).replace(/%[0-9A-F]{2}/gi, "x").length; } catch (e) { bytes = 0; }
        if (!bytes || bytes > 32 || password.length > 256 || /[\r\n\x00]/.test(ssid + password)
                || !["open", "wpa-psk", "sae"].includes(security) || (security !== "open" && !password)) {
            failed = true; message = "Enter an SSID of 1–32 UTF-8 bytes and a password for secured Wi-Fi."; return;
        }
        newUuid.reload();
        actionUuid = newUuid.text().trim();
        if (!validUuid(actionUuid)) { failed = true; message = "Could not allocate a profile UUID."; return; }
        actionInterface = interfaceName;
        secret = security === "open" ? "" : password;
        const args = ["nmcli", "connection", "add", "type", "wifi", "ifname", actionInterface,
            "con-name", "Hidden " + ssid, "connection.uuid", actionUuid, "ssid", ssid,
            "802-11-wireless.hidden", "yes", "connection.autoconnect", "no"];
        if (security !== "open") args.push("wifi-sec.key-mgmt", security);
        mutate("hidden-create", args);
    }
    function ping(): void {
        if (!active || probe.running || !interfaceName) return;
        if (pingTarget.length > 253 || !/^[a-zA-Z0-9:][a-zA-Z0-9.:%_-]*$/.test(pingTarget)) {
            pingResult = "Enter a valid IP address or hostname."; return;
        }
        probeCancelled = false;
        if (!live || !pingResult) pingResult = "Measuring ping and packet loss…";
        probe.command = live
            ? ["ping", "-n", "-I", interfaceName, "-c", "1", "-W", "0.8", "-w", "1", "--", pingTarget]
            : ["ping", "-n", "-I", interfaceName, "-c", "5", "-i", "0.2", "-W", "2", "-w", "12", "--", pingTarget];
        probe.running = true;
    }
    function stopPing(): void { if (probe.running) { probeCancelled = true; pingResult = "Ping cancelled."; probe.running = false; } }
    onActiveChanged: {
        if (active) { pingResult = ""; liveSamples = []; liveError = ""; refresh(); }
        else { refreshPending = false; readKind = ""; reader.running = false; stopPing(); }
    }
    onPingTargetChanged: { if (live) { stopPing(); liveSamples = []; liveError = ""; } }
    onInterfaceNameChanged: { stopPing(); liveSamples = []; liveError = ""; pingResult = ""; pingTarget = ""; info = ({}); linkSpeed = ""; if (active) refresh(); }
    Component.onDestruction: { secret = ""; probe.running = false; }

    Timer {
        interval: 5000
        running: root.active && root.live && root.interfaceName !== ""
        repeat: true
        onTriggered: { if (!root.busy) root.refresh(); }
    }
    Timer {
        interval: 1000
        running: root.active && root.live && root.interfaceName !== "" && root.pingTarget !== ""
        repeat: true
        onTriggered: root.ping()
    }
    FileView { id: newUuid; path: "/proc/sys/kernel/random/uuid"; blockLoading: true }
    Process {
        id: reader
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { id: readOutput }
        stderr: StdioCollector { id: readError }
        onExited: (exitCode, exitStatus) => {
            if (!root.active) return;
            if (root.refreshPending) { Qt.callLater(root.refresh); return; }
            if (exitCode !== 0) {
                if (root.readKind === "bitrate") { root.linkSpeed = "Unavailable"; root.finishInfo(); return; }
                root.failed = true; root.message = "Could not read network settings: " + readError.text.trim().slice(0, 300);
                root.profiles = []; root.uuid = "";
                if (root.live) { root.info = ({}); root.linkSpeed = "Unavailable"; root.pingResult = "Connection information unavailable."; }
                return;
            }
            const text = readOutput.text;
            switch (root.readKind) {
            case "info": {
                root.info = root.fields(text);
                if (root.live) root.pingTarget = root.info["IP4.ADDRESS"] ? "1.1.1.1" : "2606:4700:4700::1111";
                else if (!root.pingTarget) root.pingTarget = root.info["IP4.GATEWAY"] || root.info["IP6.GATEWAY"] || "1.1.1.1";
                const path = root.info["GENERAL.DBUS-PATH"];
                if (/^\/org\/freedesktop\/NetworkManager\/Devices\/[0-9]+$/.test(path || "")) {
                    root.read("bitrate", ["busctl", "--system", "get-property", "org.freedesktop.NetworkManager", path,
                        root.wireless ? "org.freedesktop.NetworkManager.Device.Wireless" : "org.freedesktop.NetworkManager.Device.Wired",
                        root.wireless ? "Bitrate" : "Speed"]);
                } else { root.linkSpeed = "Unavailable"; root.finishInfo(); }
                break;
            }
            case "bitrate": {
                const match = /^u ([0-9]+)/.exec(text);
                root.linkSpeed = match && Number(match[1]) > 0 ? (Number(match[1]) / (root.wireless ? 1000 : 1)) + " Mbit/s" : "Unavailable";
                root.finishInfo(); break;
            }
            case "profiles": {
                root.profiles = text.trim().split("\n").map(line => root.split(line))
                    .filter(p => root.validUuid(p[0]) && (p[2] === "802-11-wireless" || p[2] === "802-3-ethernet"))
                    .map(p => ({ uuid: p[0], name: p[1], device: p[3] || "", label: p[1] + " [" + p[0].slice(0, 8) + "]" + (p[3] ? " · " + p[3] : "") }));
                if (!root.profiles.some(p => p.uuid === root.uuid))
                    root.uuid = root.profiles.some(p => p.uuid === root.info["GENERAL.CON-UUID"]) ? root.info["GENERAL.CON-UUID"] : root.profiles.length ? root.profiles[0].uuid : "";
                root.loadProfile(); break;
            }
            case "profile": {
                const data = root.fields(text);
                root.autoconnect = data["connection.autoconnect"] === "yes";
                root.automaticDns = data["ipv4.ignore-auto-dns"] !== "yes" && data["ipv6.ignore-auto-dns"] !== "yes";
                root.mixedDns = (data["ipv4.ignore-auto-dns"] === "yes") !== (data["ipv6.ignore-auto-dns"] === "yes");
                root.dns4 = data["ipv4.dns"] || ""; root.dns6 = data["ipv6.dns"] || "";
                root.profileLoaded();
                break;
            }
            }
        }
    }
    Process {
        id: writer
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { id: writeOutput }
        stderr: StdioCollector { id: writeError }
        onStarted: {
            if (root.writeKind === "hidden-up") {
                writer.write(root.secret ? "802-11-wireless-security.psk:" + root.secret + "\n" : "");
                root.secret = "";
                writer.stdinEnabled = false; // close after queued bytes; nmcli reads to EOF.
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.secret = "";
                root.failed = true;
                root.message = root.writeKind === "hidden-up" ? "Connection failed. The hidden profile was saved; use Forget before recreating it."
                    : root.writeKind === "dns-apply" || root.writeKind === "dns-check" ? "DNS saved, but live application could not be confirmed. Reconnect when convenient."
                    : "Network change failed: " + writeError.text.trim().slice(0, 300);
                if (root.active) { root.refreshPending = true; Qt.callLater(root.refresh); }
                return;
            }
            if (root.writeKind === "hidden-create") {
                root.uuid = root.actionUuid;
                writer.stdinEnabled = true;
                root.mutate("hidden-up", ["nmcli", "--wait", "30", "connection", "up", "uuid", root.actionUuid,
                    "ifname", root.actionInterface, "passwd-file", "/dev/stdin"]);
                return;
            }
            if (root.writeKind === "dns" && /^\/org\/freedesktop\/NetworkManager\/Devices\/[0-9]+$/.test(root.actionPath)) {
                root.mutate("dns-check", ["busctl", "--json=short", "--system", "call", "org.freedesktop.NetworkManager",
                    root.actionPath, "org.freedesktop.NetworkManager.Device", "GetAppliedConnection", "u", "0"]);
                return;
            }
            if (root.writeKind === "dns-check") {
                try {
                    const applied = JSON.parse(writeOutput.text).data;
                    if (applied[0].connection.uuid.data === root.actionUuid && Number.isSafeInteger(applied[1]) && applied[1] > 0) {
                        // A nonzero version rejects a connection switch between checking and applying.
                        root.mutate("dns-apply", ["busctl", "--system", "call", "org.freedesktop.NetworkManager",
                            root.actionPath, "org.freedesktop.NetworkManager.Device", "Reapply", "a{sa{sv}}tu", "0", String(applied[1]), "0"]);
                        return;
                    }
                } catch (e) { root.failed = true; }
            }
            root.message = root.writeKind === "forgotten" ? "Profile and saved credentials removed."
                : root.writeKind === "dns-check" || root.writeKind === "dns" ? "DNS saved for the next connection."
                : root.writeKind === "hidden-up" ? "Hidden network connected. Enable Autoconnect below if desired." : "Settings saved.";
            if (root.active) { root.refreshPending = true; Qt.callLater(root.refresh); }
        }
    }
    Process {
        id: probe
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { id: pingOutput }
        stderr: StdioCollector { id: pingError }
        onExited: (exitCode, exitStatus) => {
            if (!root.active || root.probeCancelled) return;
            const counts = /(\d+) packets transmitted, (\d+) (?:packets )?received[^\n]*?([0-9.]+)% packet loss/.exec(pingOutput.text);
            const rtt = /(?:rtt|round-trip)[^\n]*= ([0-9.]+)\/([0-9.]+)\/([0-9.]+)\/([0-9.]+) ms/.exec(pingOutput.text);
            if (root.live) {
                if (counts && Number(counts[1]) === 1 && (Number(counts[2]) === 0 || rtt)) {
                    root.liveError = "";
                    const latency = Number(counts[2]) > 0 && rtt ? Number(rtt[2]) : null;
                    root.liveSamples = root.liveSamples.concat([latency]).slice(-24);
                } else root.liveError = "Unavailable";
                return;
            }
            root.pingResult = counts ? counts[1] + " sent, " + counts[2] + " received · " + counts[3] + "% loss"
                + (rtt ? "\nRTT min/avg/max: " + rtt[1] + " / " + rtt[2] + " / " + rtt[3] + " ms" : "\nNo latency measurement available.")
                : "Ping failed: " + pingError.text.trim().slice(0, 250);
        }
    }
}

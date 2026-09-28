pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery.ready && battery.isLaptopBattery && battery.isPresent
        && Number.isFinite(battery.percentage) && battery.percentage >= 0 && battery.percentage <= 1
    readonly property int percent: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property bool discharging: hasBattery && UPower.onBattery
        && (battery.state === UPowerDeviceState.Discharging || battery.state === UPowerDeviceState.Empty)
    readonly property int warningLevel: discharging ? (battery.percentage <= 0.05 ? 2 : battery.percentage <= 0.15 ? 1 : 0) : 0
    readonly property string status: hasBattery ? UPowerDeviceState.toString(battery.state) : ""
    readonly property string estimate: {
        if (!hasBattery) return "";
        const charging = battery.state === UPowerDeviceState.Charging;
        const seconds = charging ? battery.timeToFull : discharging ? battery.timeToEmpty : 0;
        if (!Number.isFinite(seconds) || seconds <= 0) return "";
        const minutes = Math.max(1, Math.round(seconds / 60));
        return (minutes >= 60 ? Math.floor(minutes / 60) + "h " : "") + (minutes % 60) + "m "
            + (charging ? "until full" : "remaining") + " (estimate)";
    }
    property var backlights: []
    readonly property bool available: hasBattery || backlights.length > 0
    readonly property bool busy: writer.running
    property string message: ""
    property int warned: 0

    function checkBattery(): void {
        if (!hasBattery || !UPower.onBattery || battery.percentage >= 0.2) warned = 0;
        if (warningLevel <= warned || warningLevel === 0 || notification.running) return;
        notification.level = warningLevel;
        notification.command = ["busctl", "--user", "--timeout=5", "call", "org.freedesktop.Notifications",
            "/org/freedesktop/Notifications", "org.freedesktop.Notifications", "Notify", "susssasa{sv}i",
            "Power", "0", "", warningLevel === 2 ? "Battery critically low" : "Low battery",
            "Battery at " + percent + "%. Connect a charger.", "0", "1", "urgency", "y",
            warningLevel === 2 ? "2" : "1", "-1"];
        notification.running = true;
    }
    onWarningLevelChanged: Qt.callLater(root.checkBattery)
    onPercentChanged: Qt.callLater(root.checkBattery)
    onHasBatteryChanged: Qt.callLater(root.checkBattery)
    Connections { target: UPower; function onOnBatteryChanged(): void { Qt.callLater(root.checkBattery); } }
    Process {
        id: notification
        property int level: 0
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code === 0) {
                if (root.warningLevel > 0) root.warned = Math.max(root.warned, level);
                Qt.callLater(root.checkBattery);
            }
        }
    }
    // Sysfs backlights only: no keyboard LEDs, gamma dimming or external-monitor DDC.
    function refresh(): void { if (!reader.running && !writer.running) reader.running = true; }
    function setBrightness(name, percentage): void {
        if (writer.running || !Number.isFinite(percentage)) return;
        const device = backlights.find(d => d.name === name);
        if (!device) return;
        const value = Math.max(1, Math.round(device.maximum * Math.max(1, Math.min(100, percentage)) / 100));
        message = "";
        writer.command = ["busctl", "--system", "--timeout=5", "call", "org.freedesktop.login1",
            "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetBrightness",
            "ssu", "backlight", name, String(value)];
        writer.running = true;
    }
    Process {
        id: reader
        command: ["bash", "-c", "for p in /sys/class/backlight/*; do [ -d \"$p\" ] || continue; read -r current < \"$p/brightness\" 2>/dev/null || continue; read -r maximum < \"$p/max_brightness\" 2>/dev/null || continue; printf '%s\\t%s\\t%s\\n' \"${p##*/}\" \"$current\" \"$maximum\"; done"]
        stdout: StdioCollector { id: readings }
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0) return;
            const devices = [];
            for (const line of readings.text.trim().split("\n")) {
                const parts = line.split("\t");
                if (parts.length !== 3 || !/^[A-Za-z0-9_][A-Za-z0-9_.:-]*$/.test(parts[0])
                    || !/^\d+$/.test(parts[1]) || !/^\d+$/.test(parts[2])) continue;
                const current = Number(parts[1]), maximum = Number(parts[2]);
                if (!Number.isSafeInteger(maximum) || maximum < 1 || maximum > 4294967295 || current > maximum) continue;
                devices.push({name: parts[0], maximum: maximum, percent: Math.round(100 * current / maximum)});
            }
            root.backlights = devices;
        }
    }
    Process {
        id: writer
        stdout: StdioCollector {}
        stderr: StdioCollector { id: failure }
        onExited: (code, status) => {
            if (code !== 0) root.message = "Could not confirm brightness change: " + (failure.text.trim().slice(0, 300) || "logind refused the request.");
            Qt.callLater(root.refresh);
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: { root.refresh(); root.checkBattery(); } }
    Component.onCompleted: { refresh(); Qt.callLater(root.checkBattery); }
}

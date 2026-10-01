import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Basic
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: false
    implicitWidth: 400
    implicitHeight: 300
    anchors {
        top: true
        left: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayershellLayer.Overlay

    contentItem.Keys.onEscapePressed: root.visible = false
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    IpcHandler {
        id: ipc
        target: "clipboard"
        function show(): void {
            cursorReader.running = true;
        }
    }

    Process {
        id: cursorReader
        command: ["hyprctl", "cursorpos", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const pos = JSON.parse(text);
                    if (!Number.isFinite(pos.x) || !Number.isFinite(pos.y)) {
                        return;
                    }

                    const output = Quickshell.screens.find(s => pos.x >= s.x && pos.x < s.x + s.width && pos.y >= s.y && pos.y < s.y + s.height);

                    if (!output) {
                        return;
                    }

                    root.screen = output;
                    root.margins.left = Math.max(0, Math.min(pos.x - output.x, output.width - root.implicitWidth));
                    root.margins.top = Math.max(0, Math.min(pos.y - output.y, output.height - root.implicitHeight));

                    root.visible = true;
                    Qt.callLater(() => {
                        root.contentItem.forceActiveFocus();
                    });
                } catch (error) {
                    console.error("Failed to parse cursor position:", error);
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Text {
            text: "Clipboard"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}

pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.ToolButton {
    id: root
    property string pendingAction: ""
    property string message: ""
    readonly property bool busy: actionProcess.running
    readonly property var actions: [
        {action: "lock", label: "Lock"},
        {action: "suspend", label: "Suspend"},
        {action: "logout", label: "Log out"},
        {action: "reboot", label: "Restart"},
        {action: "poweroff", label: "Shut down"}
    ]
    readonly property string pendingLabel: {
        const entry = actions.find(item => item.action === pendingAction);
        return entry ? entry.label : "";
    }
    function request(action): void {
        if (busy || !actions.some(item => item.action === action)) return;
        message = "";
        if (action === "lock") execute(action);
        else pendingAction = action;
    }
    function confirm(): void { if (pendingAction && !busy) execute(pendingAction); }
    function execute(action): void {
        if (busy || !actions.some(item => item.action === action)) return;
        pendingAction = "";
        message = action === "suspend" || action === "lock" ? "Waiting for the lock screen…" : "Requesting session action…";
        actionProcess.command = ["bash", Quickshell.env("HOME") + "/.local/bin/dotfiles-session", action];
        actionProcess.running = true;
    }
    implicitWidth: icon.implicitWidth + 2 * Theme.spacing.medium
    implicitHeight: metrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: "Lock and session controls"
    onClicked: popup.visible = !popup.visible
    FontMetrics { id: metrics; font: Theme.font }
    background: Rectangle {
        radius: Theme.radius.medium
        color: root.down ? Theme.surfacePressed : root.hovered ? Theme.surfaceHover : Theme.background
        border.width: root.visualFocus ? Theme.widget.borderWidth : 0
        border.color: Theme.focusBorder
    }
    contentItem: MaterialIcon {
        id: icon
        text: "power_settings_new"
        color: Theme.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({family: Theme.iconFont.family, pixelSize: Theme.font.pixelSize, variableAxes: Theme.iconFont.variableAxes})
    }
    Process {
        id: actionProcess
        stdout: StdioCollector {}
        stderr: StdioCollector { id: actionError }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) { root.message = ""; popup.visible = false; }
            else root.message = "Action failed: " + (actionError.text.trim().slice(0, 400) || "See the session service logs.");
        }
    }
    component ActionButton: Basic.Button {
        Layout.fillWidth: true
        font: Theme.smallFont
        padding: Theme.spacing.medium
        palette.button: Theme.surface
        palette.buttonText: Theme.foreground
        palette.highlight: Theme.accent
        enabled: !root.busy
    }
    DesktopPopup {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: 320
        preferredHeight: content.implicitHeight + 2 * Theme.widget.padding
        color: "transparent"
        grabFocus: true
        onVisibleChanged: {
            if (visible) content.forceActiveFocus();
            else { root.pendingAction = ""; if (!root.busy) root.message = ""; }
        }
        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.large
            color: Theme.background
            border.color: Theme.border
            border.width: Theme.widget.borderWidth
            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.widget.padding }
                spacing: Theme.spacing.small
                Keys.onEscapePressed: { root.pendingAction = ""; popup.visible = false; }
                Text { text: "Session"; font: Theme.largeFont; color: Theme.foreground }
                Repeater {
                    model: root.actions
                    delegate: ActionButton {
                        required property var modelData
                        text: modelData.label
                        visible: root.pendingAction === ""
                        onClicked: root.request(modelData.action)
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.pendingAction !== ""
                    text: root.pendingAction === "suspend" ? "Lock the session and suspend?"
                        : root.pendingLabel + "? Save your work first; applications will be closed."
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    font: Theme.smallFont
                    color: Theme.warning
                }
                ActionButton {
                    visible: root.pendingAction !== ""
                    text: "Confirm " + root.pendingLabel.toLowerCase()
                    onClicked: root.confirm()
                }
                ActionButton {
                    visible: root.pendingAction !== ""
                    text: "Cancel"
                    onClicked: root.pendingAction = ""
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.message !== ""
                    text: root.message
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    font: Theme.smallFont
                    color: root.busy ? Theme.muted : Theme.error
                }
                ActionButton { text: "Close"; enabled: true; onClicked: popup.visible = false }
            }
        }
    }
}

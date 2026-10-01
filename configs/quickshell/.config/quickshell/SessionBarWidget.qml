pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.ToolButton {
    id: root
    required property ScreenTheme theme
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
    implicitWidth: icon.implicitWidth + 2 * root.theme.spacing.medium
    implicitHeight: root.theme.bar.height
    padding: 0
    hoverEnabled: true
    Accessible.name: "Lock and session controls"
    onClicked: popup.visible = !popup.visible
    background: Rectangle {
        radius: root.theme.radius.medium
        color: root.down ? root.theme.surfacePressed : root.hovered ? root.theme.surfaceHover : root.theme.background
        border.width: root.visualFocus ? root.theme.widget.borderWidth : 0
        border.color: root.theme.focusBorder
    }
    contentItem: MaterialIcon { theme: root.theme;
        id: icon
        text: "power_settings_new"
        color: root.theme.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({family: root.theme.iconFont.family, pixelSize: root.theme.tray.iconSize, variableAxes: root.theme.iconFont.variableAxes})
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
        font: root.theme.smallFont
        padding: root.theme.spacing.medium
        palette.button: root.theme.surface
        palette.buttonText: root.theme.foreground
        palette.highlight: root.theme.accent
        enabled: !root.busy
    }
    DesktopPopup { theme: root.theme;
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: root.theme.popups.session.width
        preferredHeight: root.theme.popups.session.height || content.implicitHeight + 2 * root.theme.widget.padding
        color: "transparent"
        grabFocus: true
        onVisibleChanged: {
            if (visible) content.forceActiveFocus();
            else { root.pendingAction = ""; if (!root.busy) root.message = ""; }
        }
        Rectangle {
            anchors.fill: parent
            radius: root.theme.radius.large
            color: root.theme.background
            border.color: root.theme.border
            border.width: root.theme.widget.borderWidth
            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.theme.widget.padding }
                spacing: root.theme.spacing.small
                Keys.onEscapePressed: { root.pendingAction = ""; popup.visible = false; }
                Text { text: "Session"; font: root.theme.largeFont; color: root.theme.foreground }
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
                    font: root.theme.smallFont
                    color: root.theme.warning
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
                    font: root.theme.smallFont
                    color: root.busy ? root.theme.muted : root.theme.error
                }
                ActionButton { text: "Close"; enabled: true; onClicked: popup.visible = false }
            }
        }
    }
}

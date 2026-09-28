pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls.Basic as Basic

PanelWindow {
    id: root
    required property var service
    property string outputName: ""
    property bool hadToasts: false
    function selectOutput(): void {
        const showing = service.toasts.length > 0;
        if (showing && !hadToasts) outputName = Hyprland.focusedMonitor?.name || "";
        hadToasts = showing;
    }
    Component.onCompleted: selectOutput()
    Connections {
        target: root.service
        function onToastsChanged(): void { root.selectOutput(); }
    }
    readonly property var targetScreen: Quickshell.screens.find(output => output.name === outputName) || Quickshell.screens[0] || null
    screen: targetScreen
    anchors { top: true; right: true }
    margins { top: Theme.bar.height + Theme.spacing.medium; right: Theme.spacing.medium }
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dotfiles-notifications"
    visible: service.toasts.length > 0
    implicitWidth: Math.max(1, Math.min(400, targetScreen ? targetScreen.width - 2 * Theme.spacing.medium : 400))
    implicitHeight: Math.min(cards.implicitHeight, targetScreen ? Math.max(1, targetScreen.height - Theme.bar.height - 2 * Theme.spacing.medium) : 600)
    color: "transparent"
    Basic.ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        Column {
            id: cards
            width: parent.width
            spacing: Theme.spacing.small
            Repeater {
                model: root.service.toasts
                delegate: NotificationCard {
                    required property var modelData
                    width: cards.width
                    service: root.service
                    entry: modelData
                    compact: true
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls.Basic as Basic

PanelWindow {
    id: root
    readonly property ScreenTheme theme: Theme.forScreen(targetScreen)
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
    margins { top: root.theme.bar.height + root.theme.spacing.medium; right: root.theme.spacing.medium }
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dotfiles-notifications"
    visible: service.toasts.length > 0
    implicitWidth: Math.max(1, Math.min(root.theme.popups.toasts.width, targetScreen ? targetScreen.width - 2 * root.theme.spacing.medium : root.theme.popups.toasts.width))
    implicitHeight: Math.min(root.theme.popups.toasts.height || cards.implicitHeight, cards.implicitHeight, targetScreen ? Math.max(1, targetScreen.height - root.theme.bar.height - 2 * root.theme.spacing.medium) : root.theme.popups.toasts.height)
    color: "transparent"
    Basic.ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        Column {
            id: cards
            width: parent.width
            spacing: root.theme.spacing.small
            Repeater {
                model: root.service.toasts
                delegate: NotificationCard { theme: root.theme;
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

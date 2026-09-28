import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Basic

Scope {
    id: root
    required property var notificationService
    required property var powerService
    property string keyboardScreen: ""
    IpcHandler {
        target: "bar"
        function toggleKeyboard(): void {
            const output = Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
            root.keyboardScreen = root.keyboardScreen === output ? "" : output;
        }
    }
    // Overflow scrolls instead of covering the clock; tab focus reveals clipped controls.
    component BarStrip: Flickable {
        id: strip
        clip: true
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        function revealFocus(): void {
            const item = Window.window?.activeFocusItem;
            let ancestor = item;
            while (ancestor && ancestor !== contentItem) ancestor = ancestor.parent;
            if (!ancestor) return;
            const x = item.mapToItem(contentItem, 0, 0).x;
            if (x < contentX) contentX = x;
            else if (x + item.width > contentX + width) contentX = x + item.width - width;
            contentX = Math.max(0, Math.min(contentX, contentWidth - width));
        }
        Connections {
            target: strip.Window.window
            function onActiveFocusItemChanged(): void { strip.revealFocus(); }
        }
        WheelHandler {
            enabled: strip.contentWidth > strip.width
            onWheel: event => {
                const delta = event.pixelDelta.y || event.angleDelta.y / 120 * Theme.bar.height * 2;
                if (!delta) { event.accepted = false; return; }
                strip.contentX = Math.max(0, Math.min(strip.contentWidth - strip.width, strip.contentX - delta));
                event.accepted = true;
            }
        }
        Basic.ScrollBar.horizontal: Basic.ScrollBar {
            height: 3
            palette.mid: Theme.muted
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: container
            required property var modelData
            readonly property bool keyboardActive: root.keyboardScreen !== "" && root.keyboardScreen === screen.name
            readonly property real sideWidth: Math.max(0, (width - clockWidget.width) / 2 - Theme.spacing.small)
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Theme.bar.height
            color: Theme.bar.background
            WlrLayershell.keyboardFocus: keyboardActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            onKeyboardActiveChanged: if (keyboardActive) contentItem.forceActiveFocus(Qt.ShortcutFocusReason)
            contentItem.Keys.onEscapePressed: root.keyboardScreen = ""
            Item {
                anchors.fill: parent
                BarStrip {
                    id: workspaceStrip
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    width: Math.min(contentWidth, container.sideWidth)
                    height: parent.height
                    contentWidth: workspaces.implicitWidth
                    Workspaces {
                        id: workspaces
                        maximumButtonWidth: Math.max(1, Math.min(120, container.sideWidth))
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: Theme.spacing.medium
                    }
                }
                ClockWidget {
                    id: clockWidget
                    compact: container.width < 900
                    anchors.centerIn: parent
                }
                BarStrip {
                    id: controlsStrip
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: Math.min(contentWidth, container.sideWidth)
                    height: parent.height
                    contentWidth: controls.implicitWidth
                    Row {
                        id: controls
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacing.small
                        rightPadding: Theme.spacing.medium
                        PlayerBarWidget {
                            anchors.verticalCenter: parent.verticalCenter
                            maximumWidth: Math.min(320, Math.max(0, container.sideWidth - builtinWidgets.implicitWidth
                                - tray.implicitWidth - controls.rightPadding - 2 * controls.spacing))
                        }
                        SystemTrayWidget { id: tray; visible: implicitWidth > 0; anchors.verticalCenter: parent.verticalCenter }
                        Row {
                            id: builtinWidgets
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacing.small
                            AudioBarWidget {}
                            NetworkBarWidget {}
                            BluetoothBarWidget {}
                            PowerBarWidget { service: root.powerService }
                            NotificationBarWidget { service: root.notificationService }
                            SessionBarWidget {}
                        }
                    }
                }
            }
        }
    }
}

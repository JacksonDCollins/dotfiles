pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Basic
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "Keybindings.js" as Bindings

PanelWindow {
    id: root
    property string outputName: ""
    property var bindings: []
    property string error: ""
    readonly property var targetScreen: Quickshell.screens.find(output => output.name === outputName) || Quickshell.screens[0] || null
    readonly property ScreenTheme theme: Theme.forScreen(targetScreen)
    readonly property var matches: Bindings.search(bindings, search.text)

    visible: false
    screen: targetScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dotfiles-keybindings"
    // Exclusive layer focus redirects outside clicks here, preventing grab dismissal.
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: theme && targetScreen ? Math.min(theme.popups.keybindings.width, targetScreen.width - 2 * theme.spacing.large) : 1
    implicitHeight: theme && targetScreen ? Math.min(theme.popups.keybindings.height, targetScreen.height - 2 * theme.spacing.large) : 1
    contentItem.Keys.onEscapePressed: root.visible = false

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    IpcHandler {
        target: "keybindings"
        function toggle(): void {
            if (root.visible) {
                root.visible = false;
                return;
            }
            root.outputName = Hyprland.focusedMonitor?.name || "";
            search.text = "";
            root.error = "";
            root.bindings = [];
            root.visible = true;
            loader.running = true;
            Qt.callLater(() => search.forceActiveFocus());
        }
    }
    Process {
        id: loader
        command: ["hyprctl", "-j", "binds"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data))
                        throw new Error("Expected a keybinding list");
                    root.bindings = Bindings.entries(data);
                } catch (error) {
                    root.error = "Could not read Hyprland keybindings.";
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0)
                root.error = "Could not query Hyprland. Close and reopen to retry.";
        }
    }
    Rectangle {
        anchors.fill: parent
        color: root.theme ? root.theme.surface : "transparent"
        radius: root.theme ? root.theme.radius.large : 0
        border.color: root.theme ? root.theme.border : "transparent"
        border.width: root.theme ? root.theme.widget.borderWidth : 0
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.theme ? root.theme.spacing.large : 0
            spacing: root.theme ? root.theme.spacing.medium : 0
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Hyprland keybindings"
                    font: root.theme ? root.theme.largeFont : Qt.font({})
                    color: root.theme ? root.theme.foreground : "white"
                    elide: Text.ElideRight
                }
                Basic.Button {
                    text: "Close"
                    Accessible.name: "Close keybinding reference"
                    onClicked: root.visible = false
                    padding: root.theme ? root.theme.spacing.small : 0
                    contentItem: Text {
                        text: parent.text
                        font: root.theme ? root.theme.font : Qt.font({})
                        color: root.theme ? root.theme.foreground : "white"
                    }
                    background: Rectangle {
                        radius: root.theme ? root.theme.radius.small : 0
                        color: parent.hovered ? root.theme.surfaceHover : root.theme.surface
                        border.color: parent.activeFocus ? root.theme.focusBorder : root.theme.border
                    }
                }
            }
            Basic.TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search shortcuts or actions…"
                Accessible.name: "Search keybindings"
                font: root.theme ? root.theme.font : Qt.font({})
                color: root.theme ? root.theme.foreground : "white"
                placeholderTextColor: root.theme ? root.theme.muted : "gray"
                selectionColor: root.theme ? root.theme.selectionBackground : "blue"
                selectedTextColor: root.theme ? root.theme.selectionForeground : "white"
                padding: root.theme ? root.theme.widget.padding : 0
                onTextChanged: {
                    list.currentIndex = -1;
                    list.positionViewAtBeginning();
                }
                Keys.onDownPressed: list.selectStep(1)
                Keys.onUpPressed: list.selectStep(-1)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
                        list.page(event.key === Qt.Key_PageDown);
                        event.accepted = true;
                    }
                }
                background: Rectangle {
                    color: root.theme ? root.theme.background : "transparent"
                    radius: root.theme ? root.theme.radius.small : 0
                    border.color: root.theme ? (search.activeFocus ? root.theme.focusBorder : root.theme.border) : "transparent"
                    border.width: root.theme ? root.theme.widget.borderWidth : 0
                }
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.matches
                spacing: root.theme ? root.theme.spacing.small : 0
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: -1
                highlightFollowsCurrentItem: false
                highlightMoveDuration: 0
                highlightResizeDuration: 0

                function selectStep(step: int): void {
                    if (!count) return;
                    cancelFlick();
                    currentIndex = Math.max(0, Math.min(count - 1, currentIndex + step));
                    positionViewAtIndex(currentIndex, ListView.Contain);
                }

                function page(down: bool): void {
                    if (!count) return;
                    cancelFlick();
                    const bottom = originY + Math.max(0, contentHeight - height);
                    contentY = Math.max(originY, Math.min(bottom, contentY + (down ? height : -height)));
                    // Wait for delegates at the new viewport to be laid out, then
                    // skip any inter-row spacing at the requested visible edge.
                    Qt.callLater(() => {
                        const top = contentY;
                        const end = Math.min(contentY + height, originY + contentHeight);
                        for (let y = down ? end - 1 : top; y >= top && y < end; y += down ? -1 : 1) {
                            const index = indexAt(width / 2, y);
                            if (index < 0) continue;
                            currentIndex = index;
                            const item = itemAtIndex(index);
                            if (item) {
                                const hasMore = down ? index < count - 1 : index > 0;
                                const margin = hasMore && root.theme ? root.theme.spacing.medium : 0;
                                const alignedY = down ? item.y + item.height - height + margin : item.y - margin;
                                contentY = Math.max(originY, Math.min(originY + Math.max(0, contentHeight - height), alignedY));
                            }
                            break;
                        }
                    });
                }
                Basic.ScrollBar.vertical: Basic.ScrollBar {
                    palette.mid: root.theme ? root.theme.muted : "gray"
                }
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: rowContent.implicitHeight + 2 * (root.theme ? root.theme.widget.padding : 0)
                    radius: root.theme ? root.theme.radius.small : 0
                    color: root.theme ? (ListView.isCurrentItem ? root.theme.surfaceHover : root.theme.background) : "transparent"
                    Accessible.role: Accessible.ListItem
                    Accessible.name: modelData.shortcut + ": " + modelData.description
                    ColumnLayout {
                        id: rowContent
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        anchors.margins: root.theme ? root.theme.widget.padding : 0
                        spacing: root.theme ? root.theme.spacing.small : 0
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.shortcut
                            font: root.theme ? root.theme.font : Qt.font({})
                            color: root.theme ? root.theme.accent : "white"
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.description
                            font: root.theme ? root.theme.font : Qt.font({})
                            color: root.theme ? root.theme.foreground : "white"
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: row.modelData.context
                            font: root.theme ? root.theme.smallFont : Qt.font({})
                            color: root.theme ? root.theme.muted : "gray"
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: loader.running || root.error !== "" || root.matches.length === 0
                    text: loader.running ? "Loading keybindings…" : root.error || "No matching keybindings"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    font: root.theme ? root.theme.font : Qt.font({})
                    color: root.theme ? root.theme.muted : "gray"
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.matches.length + " / " + root.bindings.length + " shortcuts · Fuzzy search · ↑↓ scroll · Esc close"
                wrapMode: Text.Wrap
                font: root.theme ? root.theme.smallFont : Qt.font({})
                color: root.theme ? root.theme.muted : "gray"
            }
        }
    }
}

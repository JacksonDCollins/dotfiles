pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Basic
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "ClipboardHistory.js" as Clips

PanelWindow {
    id: root
    visible: false
    readonly property ScreenTheme theme: Theme.forScreen(root.screen)
    implicitWidth: theme && screen ? Math.min(theme.popups.clipboard.width, screen.width - 2 * theme.spacing.small) : 1
    implicitHeight: theme && screen ? Math.min(theme.popups.clipboard.height, screen.height - 2 * theme.spacing.small) : 1
    color: "transparent"
    anchors {
        top: true
        left: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

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
            search.text = "";
            root.error = "";
            root.clips = [];
            cursorReader.running = true;
            loader.running = true;
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
                        search.forceActiveFocus();
                    });
                } catch (error) {
                    console.error("Failed to parse cursor position:", error);
                }
            }
        }
    }

    Process {
        id: loader
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const entries = [];
                    for (const line of text.split("\n")) {
                        const tab = line.indexOf("\t");
                        if (tab === -1 || !/^\d+$/.test(line.slice(0, tab)))
                            continue;
                        entries.push({
                            id: line.slice(0, tab),
                            preview: line.slice(tab + 1)
                        });
                    }
                    root.clips = Clips.entries(entries);
                    root.error = "";
                } catch (error) {
                    root.error = "Could not read clipboard history: " + error.message;
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0)
                root.error = "Could not query clipboard history. Close and reopen to retry.";
        }
    }

    Process {
        id: copyProcess

        onExited: (code, status) => {
            if (code === 0 && status === 0) {
                root.visible = false;
            } else {
                root.error = "Failed to copy clipboard entry.";
            }
        }
    }

    function copyEntry(id: string): void {
        if (copyProcess.running)
            return;

        root.error = "";
        copyProcess.command = ["bash", "-c", 'umask 077; file=$(mktemp) || exit 1; ' + 'trap \'rm -f -- "$file"\' EXIT; ' + 'cliphist decode "$1" > "$file" && wl-copy < "$file"', "clipboard-copy", id];
        copyProcess.running = true;
    }

    property var clips: []
    readonly property var matches: Clips.search(clips, search.text)
    property string error: ""
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
                    text: "Clipboard history"
                    font: root.theme ? root.theme.largeFont : Qt.font({})
                    color: root.theme ? root.theme.foreground : "white"
                    elide: Text.ElideRight
                }
                Basic.Button {
                    text: "Close"
                    Accessible.name: "Close clipboard history"
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
                placeholderText: "Search clipboard history…"
                Accessible.name: "Search clipboard history"
                font: root.theme ? root.theme.font : Qt.font({})
                color: root.theme ? root.theme.foreground : "white"
                placeholderTextColor: root.theme ? root.theme.muted : "gray"
                selectionColor: root.theme ? root.theme.selectionBackground : "blue"
                selectedTextColor: root.theme ? root.theme.selectionForeground : "white"
                padding: root.theme ? root.theme.widget.padding : 0
                onTextChanged: Qt.callLater(() => {
                    clipboardList.currentIndex = -1;
                    clipboardList.positionViewAtBeginning();
                })
                Keys.onDownPressed: clipboardList.selectStep(1)
                Keys.onUpPressed: clipboardList.selectStep(-1)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
                        clipboardList.page(event.key === Qt.Key_PageDown);
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
                id: clipboardList
                property bool keyboardNavigating: false
                function selectPointerRow(): void {
                    if (keyboardNavigating || !pointerHover.containsMouse)
                        return;
                    const index = indexAt(pointerHover.mouseX + contentX, pointerHover.mouseY + contentY);
                    if (index >= 0)
                        currentIndex = index;
                }
                onContentYChanged: Qt.callLater(selectPointerRow)
                MouseArea {
                    id: pointerHover
                    parent: clipboardList
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    onPositionChanged: {
                        clipboardList.keyboardNavigating = false;
                        clipboardList.selectPointerRow();
                    }
                    onWheel: wheel => {
                        clipboardList.keyboardNavigating = false;
                        wheel.accepted = false;
                        Qt.callLater(clipboardList.selectPointerRow);
                    }
                }
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
                    if (!count)
                        return;
                    keyboardNavigating = true;
                    cancelFlick();
                    currentIndex = Math.max(0, Math.min(count - 1, currentIndex + step));
                    positionViewAtIndex(currentIndex, ListView.Contain);
                }

                function page(down: bool): void {
                    if (!count)
                        return;
                    keyboardNavigating = true;
                    cancelFlick();
                    const bottom = originY + Math.max(0, contentHeight - height);
                    contentY = Math.max(originY, Math.min(bottom, contentY + (down ? height : -height)));
                    // Match the keybinding menu: select a laid-out row at the new edge.
                    Qt.callLater(() => {
                        const top = contentY;
                        const end = Math.min(contentY + height, originY + contentHeight);
                        for (let y = down ? end - 1 : top; y >= top && y < end; y += down ? -1 : 1) {
                            const index = indexAt(width / 2, y);
                            if (index < 0)
                                continue;
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
                    onPressedChanged: if (pressed)
                        clipboardList.keyboardNavigating = false
                    active: search.activeFocus || clipboardList.moving || hovered || pressed
                    palette.mid: root.theme ? root.theme.muted : "gray"
                }
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: clipboardList.width
                    height: rowContent.implicitHeight + 2 * (root.theme ? root.theme.widget.padding : 0)
                    radius: root.theme ? root.theme.radius.small : 0
                    color: root.theme ? (ListView.isCurrentItem ? root.theme.surfaceHover : root.theme.background) : "transparent"
                    Accessible.role: Accessible.ListItem
                    Accessible.name: modelData.details + ": " + modelData.preview
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.copyEntry(row.modelData.id)
                    }
                    ColumnLayout {
                        id: rowContent
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: root.theme ? root.theme.widget.padding : 0
                        }
                        spacing: root.theme ? root.theme.spacing.small : 0
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.theme ? root.theme.spacing.small : 0
                            MaterialIcon {
                                theme: root.theme
                                text: row.modelData.kind === "image" ? "image" : row.modelData.kind === "binary" ? "insert_drive_file" : "text_snippet"
                                color: root.theme ? root.theme.accent : "white"
                                font.pixelSize: root.theme ? root.theme.font.pixelSize : 14
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.details
                                textFormat: Text.PlainText
                                font: root.theme ? root.theme.smallFont : Qt.font({})
                                color: root.theme ? root.theme.muted : "gray"
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: row.modelData.kind !== "image"
                            text: row.modelData.preview
                            textFormat: Text.PlainText
                            font: root.theme ? root.theme.font : Qt.font({})
                            color: root.theme ? root.theme.foreground : "white"
                            wrapMode: Text.Wrap
                        }
                        Loader {
                            id: thumbnail
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? (root.theme ? root.theme.bar.height * 3 : 90) : 0
                            visible: row.modelData.kind === "image"
                            active: visible && root.visible && row.y + row.height > clipboardList.contentY && row.y < clipboardList.contentY + clipboardList.height
                            sourceComponent: Image {
                                id: imagePreview
                                property string previewMessage: "Loading preview…"
                                asynchronous: true
                                cache: false
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: Math.max(1, Math.round(width))
                                sourceSize.height: Math.max(1, Math.round(height))
                                Component.onCompleted: decoder.running = true
                                Component.onDestruction: decoder.running = false
                                onStatusChanged: if (status === Image.Error)
                                    previewMessage = "Preview unavailable"
                                Process {
                                    id: decoder
                                    // ponytail: cap each in-memory preview at 4 MiB; add downsampling if large images need previews.
                                    command: ["bash", "-o", "pipefail", "-c", "cliphist decode \"$1\" | head -c 4194305 | base64 -w 0", "clipboard-preview", row.modelData.id]
                                    stdout: StdioCollector {
                                        id: imageData
                                    }
                                    onExited: (code, exitStatus) => {
                                        if (imageData.text.length >= 5592408)
                                            imagePreview.previewMessage = "Preview limited to 4 MiB";
                                        else if (code !== 0 || exitStatus !== 0 || !imageData.text.length)
                                            imagePreview.previewMessage = "Preview unavailable";
                                        else
                                            imagePreview.source = "data:image/" + row.modelData.format + ";base64," + imageData.text;
                                    }
                                }
                                Text {
                                    anchors.fill: parent
                                    visible: imagePreview.status !== Image.Ready
                                    text: imagePreview.previewMessage
                                    textFormat: Text.PlainText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.Wrap
                                    font: root.theme ? root.theme.smallFont : Qt.font({})
                                    color: root.theme ? root.theme.muted : "gray"
                                }
                            }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: loader.running || root.error !== "" || root.matches.length === 0
                    text: loader.running ? "Loading clipboard history…" : root.error || (root.clips.length ? "No matching clipboard entries" : "Clipboard history is empty")
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    font: root.theme ? root.theme.font : Qt.font({})
                    color: root.theme ? root.theme.muted : "gray"
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.matches.length + " / " + root.clips.length + " entries · Fuzzy search · ↑↓ scroll · PgUp/PgDn · Esc close"
                wrapMode: Text.Wrap
                font: root.theme ? root.theme.smallFont : Qt.font({})
                color: root.theme ? root.theme.muted : "gray"
            }
        }
    }
}

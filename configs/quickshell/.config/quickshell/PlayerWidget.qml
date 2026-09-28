pragma ComponentBehavior: Bound
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell

ColumnLayout {
    id: root
    required property ScreenTheme theme
    anchors.fill: parent
    anchors.margins: root.theme.widget.padding
    spacing: root.theme.spacing.small
    property bool userSwipe: false
    // PopupWindow uses a different proxy type; it cannot be cast to QsWindow.
    readonly property var shellWindow: QsWindow.window

    // Let native controls finish rebuilding their models before restoring selection.
    function syncSelection(): void {
        const index = Media.players.indexOf(Media.selectedPlayer);
        playerSelector.currentIndex = index;
        if (pages.count === Media.players.length)
            pages.setCurrentIndex(index);
    }
    Component.onCompleted: Qt.callLater(syncSelection)
    Connections {
        target: Media
        function onPlayersChanged(): void {
            Qt.callLater(root.syncSelection);
        }
        function onSelectedPlayerChanged(): void {
            Qt.callLater(root.syncSelection);
        }
    }

    component MediaButton: Basic.ToolButton {
        id: control
        property bool stateAvailable: true
        property bool markUnavailable: false
        implicitWidth: Math.max(root.theme.bar.height, root.theme.iconFont.pixelSize + 2 * root.theme.spacing.small)
        implicitHeight: implicitWidth
        padding: root.theme.spacing.small
        hoverEnabled: true
        font: root.theme.iconFont

        contentItem: MaterialIcon { theme: root.theme;
            text: control.text
            font: control.font
            color: control.highlighted ? root.theme.accent : control.enabled ? root.theme.foreground : root.theme.muted
            opacity: control.enabled ? 1 : 0.5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            visible: control.markUnavailable && !control.enabled
            text: "×"
            font: root.theme.smallFont
            color: root.theme.muted
            Accessible.ignored: true
        }
        background: Rectangle {
            radius: root.theme.radius.small
            color: control.down ? root.theme.surfacePressed : control.hovered ? root.theme.surfaceHover : "transparent"
            border.color: root.theme.focusBorder
            border.width: control.visualFocus ? root.theme.widget.borderWidth : 0
        }
    }

    Basic.ComboBox {
        id: playerSelector
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: root.width
        visible: count > 0
        model: Media.players.map(p => p.identity || "Unknown player")
        onModelChanged: Qt.callLater(root.syncSelection)
        displayText: Media.selectedPlayer ? Media.selectedPlayer.identity || "Unknown player" : "Select player"
        font: root.theme.smallFont
        hoverEnabled: true
        implicitWidth: Math.min(root.width, contentItem.implicitWidth + leftPadding + rightPadding)
        implicitHeight: root.theme.bar.height
        leftPadding: root.theme.spacing.medium
        rightPadding: root.theme.spacing.medium + indicator.width + root.theme.spacing.small
        Accessible.name: "Select media player"
        onActivated: index => Media.selectPlayer(Media.players[index])

        palette.text: root.theme.foreground
        palette.buttonText: root.theme.foreground
        palette.highlightedText: root.theme.foreground
        palette.highlight: root.theme.surfaceHover
        palette.button: root.theme.surface
        palette.window: root.theme.background
        palette.windowText: root.theme.foreground
        palette.base: root.theme.background
        palette.alternateBase: root.theme.surface
        palette.light: root.theme.surfaceHover
        palette.midlight: root.theme.surfacePressed
        palette.mid: root.theme.border
        palette.dark: root.theme.muted
        palette.shadow: root.theme.border
        palette.placeholderText: root.theme.muted
        palette.disabled.text: root.theme.muted
        palette.disabled.buttonText: root.theme.muted
        palette.disabled.highlightedText: root.theme.muted

        contentItem: Text {
            text: playerSelector.displayText
            font: playerSelector.font
            color: root.theme.foreground
            textFormat: Text.PlainText
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: MaterialIcon { theme: root.theme;
            x: playerSelector.width - width - root.theme.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            font: root.theme.iconFont
            color: root.theme.muted
        }
        background: Rectangle {
            radius: height / 2
            color: playerSelector.down ? root.theme.surfacePressed : playerSelector.hovered ? root.theme.surfaceHover : root.theme.surface
            border.color: playerSelector.visualFocus ? root.theme.focusBorder : root.theme.border
            border.width: root.theme.widget.borderWidth
        }
        FontMetrics {
            id: optionMetrics
            font: Qt.font({
                family: playerSelector.font.family,
                pixelSize: playerSelector.font.pixelSize,
                weight: Font.DemiBold
            })
        }
        delegate: Basic.ItemDelegate {
            id: option
            required property string modelData
            required property int index
            width: playerSelector.popup.availableWidth
            padding: root.theme.spacing.medium
            text: modelData
            font.weight: playerSelector.currentIndex === index ? Font.DemiBold : Font.Normal
            highlighted: playerSelector.highlightedIndex === index
            hoverEnabled: playerSelector.hoverEnabled

            contentItem: Text {
                text: option.text
                font: option.font
                color: option.enabled ? root.theme.foreground : root.theme.muted
                textFormat: Text.PlainText
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: root.theme.radius.small
                color: !option.enabled ? root.theme.background : option.down ? root.theme.surfacePressed : option.highlighted || option.hovered ? root.theme.surfaceHover : root.theme.background
                border.color: root.theme.focusBorder
                border.width: option.visualFocus ? root.theme.widget.borderWidth : 0
            }
        }
        popup.contentItem: ListView {
            implicitHeight: contentHeight
            model: playerSelector.delegateModel
            currentIndex: playerSelector.highlightedIndex
            highlightMoveDuration: 0
            clip: true
            Basic.ScrollIndicator.vertical: Basic.ScrollIndicator {
                palette.mid: root.theme.muted
                palette.text: root.theme.foreground
            }
        }
        popup.padding: root.theme.spacing.small
        popup.width: {
            let widest = 0;
            for (const name of playerSelector.model)
                widest = Math.max(widest, optionMetrics.advanceWidth(name));
            return Math.min(root.width * 0.8, Math.ceil(widest) + 2 * (root.theme.spacing.medium + playerSelector.popup.padding));
        }
        popup.x: (playerSelector.width - playerSelector.popup.width) / 2
        popup.height: Math.min(playerSelector.popup.contentItem.implicitHeight + 2 * playerSelector.popup.padding, root.height)
        popup.background: Rectangle {
            color: root.theme.background
            radius: root.theme.radius.medium
            border.color: root.theme.border
            border.width: root.theme.widget.borderWidth
        }
    }

    Text {
        visible: Media.players.length === 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        text: "No media players detected"
        font: root.theme.font
        color: root.theme.muted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }

    Basic.SwipeView {
        id: pages
        visible: count > 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        onCountChanged: Qt.callLater(root.syncSelection)
        // Route arrow keys through the shared selection, not just the view's index.
        Component.onCompleted: (contentItem as ListView).keyNavigationEnabled = false

        Keys.onLeftPressed: {
            if (currentIndex > 0)
                Media.selectPlayer(Media.players[currentIndex - 1]);
        }
        Keys.onRightPressed: {
            if (currentIndex + 1 < count)
                Media.selectPlayer(Media.players[currentIndex + 1]);
        }

        Repeater {
            model: Mpris.players

            Item {
                id: page
                required property MprisPlayer modelData
                readonly property bool updating: metadata.loading || metadata.showingPreviousTrack

                TrackMetadata {
                    id: metadata
                    sourcePlayer: page.modelData
                }

                RowLayout {
                    id: mediaRow
                    anchors.fill: parent
                    spacing: root.theme.spacing.small

                    ClippingRectangle {
                        readonly property real diameter: {
                            const available = Math.max(0, Math.min(mediaRow.height, mediaRow.width / 3,
                                mediaRow.width - playbackControls.implicitWidth - volumeSlider.implicitWidth - 2 * mediaRow.spacing));

                            if (albumArt.status !== Image.Ready)
                                return available;

                            const dpr = root.shellWindow?.devicePixelRatio ?? 1;
                            const nativeSize = Math.min(albumArt.sourceSize.width, albumArt.sourceSize.height);

                            return Math.min(available, nativeSize / dpr);
                        }
                        Layout.preferredWidth: diameter
                        Layout.preferredHeight: diameter
                        Layout.alignment: Qt.AlignVCenter
                        radius: width / 2
                        color: root.theme.surface

                        Image {
                            id: albumArt
                            anchors.fill: parent
                            source: metadata.track.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            retainWhileLoading: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: root.theme.background
                            opacity: 0.6
                            visible: loadingIndicator.running
                        }
                        Basic.BusyIndicator {
                            id: loadingIndicator
                            anchors.centerIn: parent
                            width: root.theme.bar.height
                            height: width
                            running: page.updating || albumArt.status === Image.Loading
                            visible: running
                            palette.dark: root.theme.accent
                            Accessible.name: page.updating ? "Waiting for track information" : "Loading artwork"
                        }
                        Basic.ToolButton {
                            id: openPlayer
                            anchors.fill: parent
                            enabled: page.modelData && page.modelData.canRaise
                            hoverEnabled: true
                            Accessible.name: "Open " + (page.modelData?.identity || "media player")
                            Accessible.description: enabled ? "Bring this player's window to the front." : "Opening this player is unavailable via MPRIS."
                            onClicked: {
                                if (page.modelData?.canRaise)
                                    page.modelData.raise();
                            }
                            contentItem: Item {}
                            HoverHandler {
                                enabled: openPlayer.enabled
                                cursorShape: Qt.PointingHandCursor
                            }
                            background: Rectangle {
                                radius: width / 2
                                color: "transparent"
                                border.color: openPlayer.visualFocus ? root.theme.focusBorder : root.theme.muted
                                border.width: openPlayer.enabled && (openPlayer.visualFocus || openPlayer.hovered) ? root.theme.widget.borderWidth : 0
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: playbackControls.implicitWidth
                        spacing: root.theme.spacing.small
                        opacity: page.updating ? 0.5 : 1
                        Text {
                            Layout.fillWidth: true
                            text: metadata.track.title || "No track information"
                            font: root.theme.font
                            color: root.theme.foreground
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: metadata.track.album
                            visible: text.length > 0
                            font: root.theme.font
                            color: root.theme.muted
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: metadata.track.artist
                            visible: text.length > 0
                            font: root.theme.font
                            color: root.theme.muted
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                        MediaSeekBar { theme: root.theme;
                            Layout.fillWidth: true
                            sourcePlayer: page.modelData
                            updating: page.updating
                            active: pages.currentItem === page && (root.shellWindow?.visible ?? false)
                        }
                        RowLayout {
                            id: playbackControls
                            Layout.alignment: Qt.AlignHCenter
                            spacing: root.theme.spacing.small
                            readonly property bool playing: page.modelData && page.modelData.playbackState === MprisPlaybackState.Playing
                            enabled: page.modelData && page.modelData.canControl && !page.updating

                            MediaButton {
                                id: repeatButton
                                markUnavailable: true
                                stateAvailable: page.modelData && page.modelData.loopSupported
                                text: stateAvailable && page.modelData.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                                enabled: stateAvailable
                                highlighted: stateAvailable && page.modelData.loopState !== MprisLoopState.None
                                Accessible.name: "Repeat: " + (!stateAvailable ? "unavailable" : page.modelData.loopState === MprisLoopState.Track ? "current track" : page.modelData.loopState === MprisLoopState.Playlist ? "all tracks" : "off")
                                Accessible.description: !stateAvailable ? "Repeat unavailable: the player does not report its repeat state." : Accessible.name + (!page.modelData.canControl ? " (read-only)." : page.updating ? " (temporarily disabled while the track updates)." : ". Click to cycle off, all tracks, and current track.")
                                Accessible.checkable: stateAvailable
                                Accessible.checked: highlighted
                                onClicked: {
                                    if (enabled)
                                        page.modelData.loopState = page.modelData.loopState === MprisLoopState.None ? MprisLoopState.Playlist : page.modelData.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
                                }
                            }
                            MediaButton {
                                text: "skip_previous"
                                Accessible.name: "Previous track"
                                enabled: page.modelData && page.modelData.canGoPrevious
                                onClicked: page.modelData.previous()
                            }
                            MediaButton {
                                text: playbackControls.playing ? "pause" : "play_arrow"
                                Accessible.name: playbackControls.playing ? "Pause" : "Play"
                                enabled: page.modelData && (playbackControls.playing ? page.modelData.canPause : page.modelData.canPlay)
                                onClicked: page.modelData.togglePlaying()
                            }
                            MediaButton {
                                text: "skip_next"
                                Accessible.name: "Next track"
                                enabled: page.modelData && page.modelData.canGoNext
                                onClicked: page.modelData.next()
                            }
                            MediaButton {
                                id: shuffleButton
                                markUnavailable: true
                                stateAvailable: page.modelData && page.modelData.shuffleSupported
                                text: "shuffle"
                                enabled: stateAvailable
                                highlighted: stateAvailable && page.modelData.shuffle
                                Accessible.name: "Shuffle: " + (!stateAvailable ? "unavailable" : highlighted ? "on" : "off")
                                Accessible.description: !stateAvailable ? "Shuffle unavailable: the player does not report its shuffle state." : Accessible.name + (!page.modelData.canControl ? " (read-only)." : page.updating ? " (temporarily disabled while the track updates)." : ". Click to toggle shuffle.")
                                Accessible.checkable: stateAvailable
                                Accessible.checked: highlighted
                                onClicked: {
                                    if (enabled)
                                        page.modelData.shuffle = !page.modelData.shuffle;
                                }
                            }
                        }
                    }
                    Basic.Slider {
                        id: volumeSlider
                        Layout.preferredWidth: implicitWidth
                        Layout.fillHeight: true
                        Layout.maximumHeight: root.theme.bar.height * 4
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: root.theme.bar.height
                        orientation: Qt.Vertical
                        padding: root.theme.spacing.small
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: page.modelData?.volumeSupported ? Math.max(0, Math.min(1, page.modelData.volume)) : 0
                        enabled: page.modelData && page.modelData.canControl && page.modelData.volumeSupported
                        Accessible.name: "Player volume"
                        Accessible.description: !page.modelData?.volumeSupported ? "Volume unavailable: the player does not report its volume." : "Reported volume: " + Math.round(value * 100) + "%" + (!page.modelData.canControl ? " (read-only). " : ". ") + "Some players report a fixed value or ignore volume changes; MPRIS cannot reliably identify this."
                        onMoved: {
                            if (enabled)
                                page.modelData.volume = value;
                        }
                        background: Rectangle {
                            x: (volumeSlider.width - width) / 2
                            y: volumeSlider.topPadding
                            width: root.theme.spacing.small
                            height: volumeSlider.availableHeight
                            radius: width / 2
                            color: root.theme.surface
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.height * volumeSlider.position
                                visible: page.modelData?.volumeSupported ?? false
                                radius: parent.radius
                                color: volumeSlider.enabled ? root.theme.accent : root.theme.muted
                            }
                        }
                        handle: Rectangle {
                            visible: page.modelData?.volumeSupported ?? false
                            x: (volumeSlider.width - width) / 2
                            y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
                            implicitWidth: root.theme.spacing.medium
                            implicitHeight: implicitWidth
                            radius: width / 2
                            color: !volumeSlider.enabled ? root.theme.muted : volumeSlider.visualFocus ? root.theme.foreground : root.theme.accent
                            border.color: root.theme.focusBorder
                            border.width: volumeSlider.visualFocus ? root.theme.widget.borderWidth : 0
                        }
                    }
                }
            }
        }

        Connections {
            target: pages.contentItem
            function onDraggingChanged(): void {
                if ((pages.contentItem as ListView).dragging)
                    root.userSwipe = true;
            }
            function onMovementEnded(): void {
                if (root.userSwipe) {
                    root.userSwipe = false;
                    Media.selectPlayer(Media.players[pages.currentIndex] || null);
                }
            }
        }
    }
}

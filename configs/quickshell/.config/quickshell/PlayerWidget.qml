pragma ComponentBehavior: Bound
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: Theme.widget.padding
    spacing: Theme.spacing.small
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
        implicitWidth: Math.max(Theme.bar.height, Theme.iconFont.pixelSize + 2 * Theme.spacing.small)
        implicitHeight: implicitWidth
        padding: Theme.spacing.small
        hoverEnabled: true
        font: Theme.iconFont

        contentItem: MaterialIcon {
            text: control.text
            font: control.font
            color: control.highlighted ? Theme.accent : control.enabled ? Theme.foreground : Theme.muted
            opacity: control.enabled ? 1 : 0.5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            visible: control.markUnavailable && !control.enabled
            text: "×"
            font: Theme.smallFont
            color: Theme.muted
            Accessible.ignored: true
        }
        background: Rectangle {
            radius: Theme.radius.small
            color: control.down ? Theme.surfacePressed : control.hovered ? Theme.surfaceHover : "transparent"
            border.color: Theme.focusBorder
            border.width: control.visualFocus ? Theme.widget.borderWidth : 0
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
        font: Theme.smallFont
        hoverEnabled: true
        implicitWidth: Math.min(root.width, contentItem.implicitWidth + leftPadding + rightPadding)
        implicitHeight: Theme.bar.height
        leftPadding: Theme.spacing.medium
        rightPadding: Theme.spacing.medium + indicator.width + Theme.spacing.small
        Accessible.name: "Select media player"
        onActivated: index => Media.selectPlayer(Media.players[index])

        palette.text: Theme.foreground
        palette.buttonText: Theme.foreground
        palette.highlightedText: Theme.foreground
        palette.highlight: Theme.surfaceHover
        palette.button: Theme.surface
        palette.window: Theme.background
        palette.windowText: Theme.foreground
        palette.base: Theme.background
        palette.alternateBase: Theme.surface
        palette.light: Theme.surfaceHover
        palette.midlight: Theme.surfacePressed
        palette.mid: Theme.border
        palette.dark: Theme.muted
        palette.shadow: Theme.border
        palette.placeholderText: Theme.muted
        palette.disabled.text: Theme.muted
        palette.disabled.buttonText: Theme.muted
        palette.disabled.highlightedText: Theme.muted

        contentItem: Text {
            text: playerSelector.displayText
            font: playerSelector.font
            color: Theme.foreground
            textFormat: Text.PlainText
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: MaterialIcon {
            x: playerSelector.width - width - Theme.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            font: Theme.iconFont
            color: Theme.muted
        }
        background: Rectangle {
            radius: height / 2
            color: playerSelector.down ? Theme.surfacePressed : playerSelector.hovered ? Theme.surfaceHover : Theme.surface
            border.color: playerSelector.visualFocus ? Theme.focusBorder : Theme.border
            border.width: Theme.widget.borderWidth
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
            padding: Theme.spacing.medium
            text: modelData
            font.weight: playerSelector.currentIndex === index ? Font.DemiBold : Font.Normal
            highlighted: playerSelector.highlightedIndex === index
            hoverEnabled: playerSelector.hoverEnabled

            contentItem: Text {
                text: option.text
                font: option.font
                color: option.enabled ? Theme.foreground : Theme.muted
                textFormat: Text.PlainText
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: Theme.radius.small
                color: !option.enabled ? Theme.background : option.down ? Theme.surfacePressed : option.highlighted || option.hovered ? Theme.surfaceHover : Theme.background
                border.color: Theme.focusBorder
                border.width: option.visualFocus ? Theme.widget.borderWidth : 0
            }
        }
        popup.contentItem: ListView {
            implicitHeight: contentHeight
            model: playerSelector.delegateModel
            currentIndex: playerSelector.highlightedIndex
            highlightMoveDuration: 0
            clip: true
            Basic.ScrollIndicator.vertical: Basic.ScrollIndicator {
                palette.mid: Theme.muted
                palette.text: Theme.foreground
            }
        }
        popup.padding: Theme.spacing.small
        popup.width: {
            let widest = 0;
            for (const name of playerSelector.model)
                widest = Math.max(widest, optionMetrics.advanceWidth(name));
            return Math.min(root.width * 0.8, Math.ceil(widest) + 2 * (Theme.spacing.medium + playerSelector.popup.padding));
        }
        popup.x: (playerSelector.width - playerSelector.popup.width) / 2
        popup.height: Math.min(playerSelector.popup.contentItem.implicitHeight + 2 * playerSelector.popup.padding, root.height)
        popup.background: Rectangle {
            color: Theme.background
            radius: Theme.radius.medium
            border.color: Theme.border
            border.width: Theme.widget.borderWidth
        }
    }

    Text {
        visible: Media.players.length === 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        text: "No media players detected"
        font: Theme.font
        color: Theme.muted
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
                    spacing: Theme.spacing.small

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
                        color: Theme.surface

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
                            color: Theme.background
                            opacity: 0.6
                            visible: loadingIndicator.running
                        }
                        Basic.BusyIndicator {
                            id: loadingIndicator
                            anchors.centerIn: parent
                            width: Theme.bar.height
                            height: width
                            running: page.updating || albumArt.status === Image.Loading
                            visible: running
                            palette.dark: Theme.accent
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
                                border.color: openPlayer.visualFocus ? Theme.focusBorder : Theme.muted
                                border.width: openPlayer.enabled && (openPlayer.visualFocus || openPlayer.hovered) ? Theme.widget.borderWidth : 0
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: playbackControls.implicitWidth
                        spacing: Theme.spacing.small
                        opacity: page.updating ? 0.5 : 1
                        Text {
                            Layout.fillWidth: true
                            text: metadata.track.title || "No track information"
                            font: Theme.font
                            color: Theme.foreground
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
                            font: Theme.font
                            color: Theme.muted
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: metadata.track.artist
                            visible: text.length > 0
                            font: Theme.font
                            color: Theme.muted
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                        MediaSeekBar {
                            Layout.fillWidth: true
                            sourcePlayer: page.modelData
                            updating: page.updating
                            active: pages.currentItem === page && (root.shellWindow?.visible ?? false)
                        }
                        RowLayout {
                            id: playbackControls
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Theme.spacing.small
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
                        Layout.maximumHeight: Theme.bar.height * 4
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Theme.bar.height
                        orientation: Qt.Vertical
                        padding: Theme.spacing.small
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
                            width: Theme.spacing.small
                            height: volumeSlider.availableHeight
                            radius: width / 2
                            color: Theme.surface
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.height * volumeSlider.position
                                visible: page.modelData?.volumeSupported ?? false
                                radius: parent.radius
                                color: volumeSlider.enabled ? Theme.accent : Theme.muted
                            }
                        }
                        handle: Rectangle {
                            visible: page.modelData?.volumeSupported ?? false
                            x: (volumeSlider.width - width) / 2
                            y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
                            implicitWidth: Theme.spacing.medium
                            implicitHeight: implicitWidth
                            radius: width / 2
                            color: !volumeSlider.enabled ? Theme.muted : volumeSlider.visualFocus ? Theme.foreground : Theme.accent
                            border.color: Theme.focusBorder
                            border.width: volumeSlider.visualFocus ? Theme.widget.borderWidth : 0
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

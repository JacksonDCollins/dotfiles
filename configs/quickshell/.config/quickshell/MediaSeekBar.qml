pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls.Basic as Basic
import Quickshell.Services.Mpris

RowLayout {
    id: root
    required property MprisPlayer sourcePlayer
    property bool active: true
    property bool updating: false
    property real observedPosition: 0
    property real wavePhase: 0
    property bool gestureValid: false
    property MprisPlayer gesturePlayer: null
    readonly property bool hasPosition: sourcePlayer && sourcePlayer.positionSupported
    readonly property real duration: sourcePlayer && sourcePlayer.lengthSupported && Number.isFinite(sourcePlayer.length) && sourcePlayer.length > 0 && sourcePlayer.length <= 2147483647 ? sourcePlayer.length : 0
    readonly property bool playing: sourcePlayer && sourcePlayer.playbackState === MprisPlaybackState.Playing
    readonly property bool seekEnabled: active && visible && !updating && hasPosition && duration > 0 && sourcePlayer.canControl && sourcePlayer.canSeek
    spacing: Theme.spacing.small

    function formatTime(seconds: real): string {
        if (!Number.isFinite(seconds) || seconds < 0)
            return "--:--";
        const total = Math.floor(seconds);
        const hours = Math.floor(total / 3600);
        const minutes = String(Math.floor(total / 60) % 60).padStart(2, "0");
        const remainder = String(total % 60).padStart(2, "0");
        return (hours > 0 ? hours + ":" : "") + minutes + ":" + remainder;
    }

    function refreshPosition(): void {
        if (!slider || slider.pressed)
            return;
        const value = sourcePlayer && sourcePlayer.positionSupported ? sourcePlayer.position : 0;
        observedPosition = Number.isFinite(value) ? Math.max(0, duration > 0 ? Math.min(value, duration) : value) : 0;
    }

    function cancelGesture(): void {
        gestureValid = false;
        gesturePlayer = null;
    }

    function seek(seconds: real): void {
        if (!seekEnabled || !Number.isFinite(seconds))
            return;
        const target = Math.max(0, Math.min(seconds, duration));
        sourcePlayer.position = target;
        observedPosition = target;
    }

    function wavePath(end: real, height: real, phase: real): string {
        if (end <= 0)
            return "";
        let path = "";
        for (let x = 0; ; x = Math.min(x + 2, end)) {
            const y = height / 2 + Math.sin(x * Math.PI / 16 - phase) * Theme.spacing.small / 2;
            path += (x === 0 ? "M" : "L") + x.toFixed(2) + "," + y.toFixed(2) + " ";
            if (x === end)
                break;
        }
        return path;
    }

    onSourcePlayerChanged: {
        cancelGesture();
        observedPosition = 0;
        wavePhase = 0;
        refreshPosition();
    }
    onSeekEnabledChanged: {
        if (!seekEnabled)
            cancelGesture();
    }
    onActiveChanged: refreshPosition()
    onUpdatingChanged: refreshPosition()
    onDurationChanged: {
        cancelGesture();
        refreshPosition();
    }
    Component.onCompleted: refreshPosition()

    Connections {
        target: root.sourcePlayer
        function onPositionChanged(): void { root.refreshPosition(); }
        function onPositionSupportedChanged(): void { root.refreshPosition(); }
        function onPlaybackStateChanged(): void { root.refreshPosition(); }
        function onTrackChanged(): void { root.cancelGesture(); }
        function onPostTrackChanged(): void { root.refreshPosition(); }
    }

    FrameAnimation {
        running: root.active && root.visible && !root.updating && root.hasPosition && root.playing
        onTriggered: {
            root.wavePhase = (root.wavePhase + frameTime * Math.PI) % (2 * Math.PI);
            root.refreshPosition();
        }
    }

    Text {
        text: root.formatTime(root.hasPosition && !root.updating ? slider.pressed ? slider.value : root.observedPosition : -1)
        font: Theme.smallFont
        color: Theme.muted
    }

    Basic.Slider {
        id: slider
        Layout.fillWidth: true
        Layout.minimumWidth: Theme.spacing.extraLarge * 2
        implicitHeight: Theme.bar.height
        padding: Theme.spacing.small
        from: 0
        to: root.duration || 1
        value: root.observedPosition
        enabled: root.seekEnabled
        stepSize: 5
        Accessible.name: "Track position"

        onPressedChanged: {
            if (pressed) {
                root.gesturePlayer = root.sourcePlayer;
                root.gestureValid = root.seekEnabled;
            } else {
                const commit = root.gestureValid && root.gesturePlayer === root.sourcePlayer;
                root.cancelGesture();
                if (commit)
                    root.seek(value);
                else
                    root.refreshPosition();
            }
        }
        // Consume navigation keys here rather than letting the SwipeView change players.
        Keys.onLeftPressed: root.seek(value - stepSize)
        Keys.onRightPressed: root.seek(value + stepSize)
        Keys.onDownPressed: root.seek(value - stepSize)
        Keys.onUpPressed: root.seek(value + stepSize)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                root.seek(event.key === Qt.Key_Home ? from : to);
                event.accepted = true;
            }
        }

        background: Item {
            id: track
            x: slider.leftPadding
            y: slider.topPadding
            width: slider.availableWidth
            height: slider.availableHeight

            Rectangle {
                x: thumb.x - slider.leftPadding + thumb.width + Theme.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - x)
                height: 2
                radius: height / 2
                color: Theme.border
            }
            Shape {
                anchors.fill: parent
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: slider.enabled ? Theme.accent : Theme.muted
                    strokeWidth: 2
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg {
                        path: root.wavePath(Math.max(0, thumb.x - slider.leftPadding - Theme.spacing.small), track.height, root.wavePhase)
                    }
                }
            }
        }
        handle: Rectangle {
            id: thumb
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + (slider.availableHeight - height) / 2
            implicitWidth: Theme.spacing.small
            implicitHeight: Theme.spacing.extraLarge
            radius: width / 2
            color: !slider.enabled ? Theme.muted : slider.visualFocus ? Theme.foreground : Theme.accent
            border.color: Theme.focusBorder
            border.width: slider.visualFocus ? Theme.widget.borderWidth : 0
        }
    }

    Text {
        text: root.formatTime(root.duration > 0 && !root.updating ? root.duration : -1)
        font: Theme.smallFont
        color: Theme.muted
    }
}

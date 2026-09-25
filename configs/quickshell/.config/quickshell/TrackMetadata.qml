import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root
    required property MprisPlayer sourcePlayer
    property bool ready: false
    property var track: ({ title: "", artist: "", album: "", artUrl: "" })
    readonly property var incoming: snapshot()
    property var lastIncoming: track
    // Metadata is settling, not confirmation that the player is loading a track.
    readonly property bool loading: settle.running
    readonly property bool showingPreviousTrack: sourcePlayer && track.title.trim().length > 0 && !sameTrack(track, incoming)

    function sameTrack(a: var, b: var): bool {
        return a.title === b.title && a.artist === b.artist && a.album === b.album && a.artUrl === b.artUrl;
    }

    function snapshot(): var {
        return {
            title: sourcePlayer ? sourcePlayer.trackTitle : "",
            artist: sourcePlayer ? sourcePlayer.trackArtist : "",
            album: sourcePlayer ? sourcePlayer.trackAlbum : "",
            artUrl: sourcePlayer ? sourcePlayer.trackArtUrl : ""
        };
    }

    function reset(): void {
        settle.stop();
        // Read the new player directly; incoming may not have reevaluated yet.
        lastIncoming = snapshot();
        track = lastIncoming;
    }

    function schedule(): void {
        if (!ready || sameTrack(incoming, lastIncoming))
            return;
        lastIncoming = incoming;
        settle.stop();
        if (!sourcePlayer) {
            reset();
        } else if (incoming.title.trim().length > 0) {
            settle.restart();
        }
        // Empty metadata is unavailable, not proof that the previous track ended.
        // Retain the last valid snapshot until new metadata or a different player.
    }

    onIncomingChanged: schedule()
    onSourcePlayerChanged: {
        if (ready)
            reset(); // Never show one player's cached track on another player.
    }
    Component.onCompleted: {
        ready = true;
        reset();
    }

    readonly property Timer settle: Timer {
        interval: 250
        onTriggered: root.track = root.incoming
    }
}

pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    property MprisPlayer selectedPlayer: null
    property var recentPlayers: []
    property var previousPlayingPlayers: []
    readonly property var players: Mpris.players.values
    readonly property var playingPlayers: players.filter(p => p && p.playbackState === MprisPlaybackState.Playing)

    function selectPlayer(candidate: MprisPlayer): void {
        if (players.includes(candidate))
            selectedPlayer = candidate;
    }

    function reconcile(): void {
        recentPlayers = recentPlayers.filter(p => players.includes(p));
        if (!players.includes(selectedPlayer))
            selectedPlayer = recentPlayers[0] || playingPlayers[0] || players[0] || null;
    }

    onPlayingPlayersChanged: {
        for (const current of playingPlayers) {
            if (!previousPlayingPlayers.includes(current)) {
                recentPlayers = [current].concat(recentPlayers.filter(p => p !== current));
                selectedPlayer = current;
            }
        }
        previousPlayingPlayers = playingPlayers;
        reconcile();
    }
    onPlayersChanged: reconcile()
    Component.onCompleted: reconcile()
}

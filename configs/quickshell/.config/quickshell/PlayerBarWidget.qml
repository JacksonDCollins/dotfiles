import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Rectangle {
    id: player
    property real maximumWidth: 320
    implicitWidth: content.implicitWidth
    implicitHeight: trackLabel.implicitHeight
    radius: Theme.radius.medium
    color: Theme.background

    readonly property MprisPlayer activePlayer: Media.selectedPlayer

    TrackMetadata {
        id: metadata
        sourcePlayer: player.activePlayer
    }

    TapHandler {
        onTapped: popup.visible = !popup.visible
    }

    PopupWindow {
        id: popup
        color: "transparent"

        anchor.item: player
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        implicitWidth: 320 //Hyprland.focusedMonitor.width * 1 / 2
        implicitHeight: 200 //Hyprland.focusedMonitor.height * 1 / 3

        grabFocus: true

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.radius.large
            border.color: Theme.border
            border.width: Theme.widget.borderWidth

            PlayerWidget {}
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Theme.spacing.small
        leftPadding: Theme.spacing.medium
        rightPadding: Theme.spacing.medium

        MaterialIcon {
            id: mediaIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "play_circle"
            font: Qt.font({
                family: Theme.iconFont.family,
                pixelSize: Theme.font.pixelSize,
                variableAxes: Theme.iconFont.variableAxes
            })
            color: metadata.loading || metadata.showingPreviousTrack ? Theme.muted : Theme.foreground
        }
        Text {
            id: trackLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: player.activePlayer !== null
            text: {
                const title = metadata.track.title || "Unknown title";
                const artist = metadata.track.artist;
                return title + (artist ? " - " + artist : "");
            }
            width: Math.min(implicitWidth, Math.max(0, player.maximumWidth - mediaIcon.width - content.leftPadding - content.rightPadding - content.spacing))
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font: Theme.font
            color: mediaIcon.color
        }
    }
}

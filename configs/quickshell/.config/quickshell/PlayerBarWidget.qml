import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: player
    required property ScreenTheme theme
    property real maximumWidth: player.theme.bar.playerMaxWidth
    implicitWidth: content.implicitWidth
    implicitHeight: trackLabel.implicitHeight
    padding: 0
    hoverEnabled: true
    Accessible.name: "Media controls" + (activePlayer ? ": " + (metadata.track.title || activePlayer.identity) : "")
    onClicked: popup.visible = !popup.visible
    background: Rectangle {
        radius: player.theme.radius.medium
        color: player.down ? player.theme.surfacePressed : player.hovered ? player.theme.surfaceHover : player.theme.background
        border.color: player.theme.focusBorder
        border.width: player.visualFocus ? player.theme.widget.borderWidth : 0
    }

    readonly property MprisPlayer activePlayer: Media.selectedPlayer

    TrackMetadata {
        id: metadata
        sourcePlayer: player.activePlayer
    }

    DesktopPopup { theme: player.theme;
        id: popup
        color: "transparent"

        anchor.item: player
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        preferredWidth: player.theme.popups.player.width
        preferredHeight: player.theme.popups.player.height

        grabFocus: true

        Rectangle {
            anchors.fill: parent
            color: player.theme.background
            radius: player.theme.radius.large
            border.color: player.theme.border
            border.width: player.theme.widget.borderWidth

            PlayerWidget { theme: player.theme;}
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: player.theme.spacing.small
        leftPadding: player.theme.spacing.medium
        rightPadding: player.theme.spacing.medium

        MaterialIcon { theme: player.theme;
            id: mediaIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "play_circle"
            font: Qt.font({
                family: player.theme.iconFont.family,
                pixelSize: player.theme.font.pixelSize,
                variableAxes: player.theme.iconFont.variableAxes
            })
            color: metadata.loading || metadata.showingPreviousTrack ? player.theme.muted : player.theme.foreground
        }
        Text {
            id: trackLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: player.activePlayer !== null && player.maximumWidth >= 120
            text: {
                const title = metadata.track.title || "Unknown title";
                const artist = metadata.track.artist;
                return title + (artist ? " - " + artist : "");
            }
            width: Math.min(implicitWidth, Math.max(0, player.maximumWidth - mediaIcon.width - content.leftPadding - content.rightPadding - content.spacing))
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font: player.theme.font
            color: mediaIcon.color
        }
    }
}

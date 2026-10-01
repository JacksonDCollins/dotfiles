import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: root
    required property ScreenTheme theme
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: Pipewire.ready && sink !== null && sink.ready && sink.audio !== null
    readonly property bool muted: available && sink.audio.muted
    readonly property int percent: available ? Math.round(sink.audio.volume * 100) : 0
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
    implicitWidth: icon.implicitWidth + 2 * root.theme.spacing.medium
    implicitHeight: root.theme.bar.height //metrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: !available ? "Audio unavailable" : muted ? "Audio muted" : "Audio volume " + percent + " percent"
    onClicked: popup.visible = !popup.visible
    FontMetrics {
        id: metrics
        font: root.theme.font
    }
    background: Rectangle {
        radius: root.theme.radius.medium
        color: root.down ? root.theme.surfacePressed : root.hovered ? root.theme.surfaceHover : root.theme.background
        border.color: root.theme.focusBorder
        border.width: root.visualFocus ? root.theme.widget.borderWidth : 0
    }
    contentItem: MaterialIcon {
        id: icon
        theme: root.theme
        text: !root.available || root.muted ? "volume_off" : root.percent === 0 ? "volume_mute" : root.percent < 50 ? "volume_down" : "volume_up"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({
            family: root.theme.iconFont.family,
            // pixelSize: root.theme.font.pixelSize,
            pixelSize: root.theme.tray.iconSize,
            variableAxes: root.theme.iconFont.variableAxes
        })
        color: root.available && !root.muted ? root.theme.foreground : root.theme.muted
    }
    DesktopPopup {
        id: popup
        theme: root.theme
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: root.theme.popups.audio.width
        preferredHeight: root.theme.popups.audio.height
        color: "transparent"
        grabFocus: true
        Rectangle {
            anchors.fill: parent
            color: root.theme.background
            radius: root.theme.radius.large
            border.color: root.theme.border
            border.width: root.theme.widget.borderWidth
            AudioWidget {
                theme: root.theme
                anchors.fill: parent
                anchors.margins: root.theme.widget.padding
                active: popup.visible
                onCloseRequested: popup.visible = false
            }
        }
    }
}

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: Pipewire.ready && sink !== null && sink.ready && sink.audio !== null
    readonly property bool muted: available && sink.audio.muted
    readonly property int percent: available ? Math.round(sink.audio.volume * 100) : 0
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    implicitWidth: icon.implicitWidth + 2 * Theme.spacing.medium
    implicitHeight: metrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: !available ? "Audio unavailable" : muted ? "Audio muted" : "Audio volume " + percent + " percent"
    onClicked: popup.visible = !popup.visible
    FontMetrics { id: metrics; font: Theme.font }
    background: Rectangle {
        radius: Theme.radius.medium
        color: root.down ? Theme.surfacePressed : root.hovered ? Theme.surfaceHover : Theme.background
        border.color: Theme.focusBorder
        border.width: root.visualFocus ? Theme.widget.borderWidth : 0
    }
    contentItem: MaterialIcon {
        id: icon
        text: !root.available || root.muted ? "volume_off" : root.percent === 0 ? "volume_mute" : root.percent < 50 ? "volume_down" : "volume_up"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({family: Theme.iconFont.family, pixelSize: Theme.font.pixelSize, variableAxes: Theme.iconFont.variableAxes})
        color: root.available && !root.muted ? Theme.foreground : Theme.muted
    }
    DesktopPopup {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: 400
        preferredHeight: 480
        color: "transparent"
        grabFocus: true
        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.radius.large
            border.color: Theme.border
            border.width: Theme.widget.borderWidth
            AudioWidget {
                anchors.fill: parent
                anchors.margins: Theme.widget.padding
                active: popup.visible
                onCloseRequested: popup.visible = false
            }
        }
    }
}

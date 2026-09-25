import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Controls

Rectangle {
    id: clock
    implicitWidth: label.width
    implicitHeight: label.height
    radius: Theme.radius.medium
    color: Theme.background

    TapHandler {
        onTapped: popup.visible = !popup.visible
    }

    PopupWindow {
        id: popup
        color: "transparent"

        anchor.item: clock
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        implicitWidth: 320 //Hyprland.focusedMonitor.width * 1 / 2
        implicitHeight: 200 //Hyprland.focusedMonitor.height * 1 / 3

        grabFocus: true

        onVisibleChanged: {
            if (visible) {
                calendar.resetToToday();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.radius.large
            border.color: Theme.border
            border.width: Theme.widget.borderWidth

            CalendarWidget {
                id: calendar
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Time.time("dddd h:mm")
        font: Theme.font
        leftPadding: Theme.spacing.medium
        rightPadding: Theme.spacing.medium
        color: Theme.foreground
    }
}

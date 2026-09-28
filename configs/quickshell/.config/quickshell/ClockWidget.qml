import QtQuick
import Quickshell
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: clock
    property bool compact: false
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    padding: 0
    hoverEnabled: true
    Accessible.name: "Calendar, " + Time.time("dddd h:mm")
    onClicked: popup.visible = !popup.visible
    background: Rectangle {
        radius: Theme.radius.medium
        color: clock.down ? Theme.surfacePressed : clock.hovered ? Theme.surfaceHover : Theme.background
        border.color: Theme.focusBorder
        border.width: clock.visualFocus ? Theme.widget.borderWidth : 0
    }

    DesktopPopup {
        id: popup
        color: "transparent"

        anchor.item: clock
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        preferredWidth: 320
        preferredHeight: 250

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

    contentItem: Text {
        id: label
        text: Time.time(clock.compact ? "h:mm" : "dddd h:mm")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Theme.font
        leftPadding: Theme.spacing.medium
        rightPadding: Theme.spacing.medium
        color: Theme.foreground
    }
}

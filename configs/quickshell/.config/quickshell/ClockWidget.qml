import QtQuick
import Quickshell
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: clock
    required property ScreenTheme theme
    property bool compact: false
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    padding: 0
    hoverEnabled: true
    Accessible.name: "Calendar, " + Time.time("dddd h:mm")
    onClicked: popup.visible = !popup.visible
    background: Rectangle {
        radius: clock.theme.radius.medium
        color: clock.down ? clock.theme.surfacePressed : clock.hovered ? clock.theme.surfaceHover : clock.theme.background
        border.color: clock.theme.focusBorder
        border.width: clock.visualFocus ? clock.theme.widget.borderWidth : 0
    }

    DesktopPopup { theme: clock.theme;
        id: popup
        color: "transparent"

        anchor.item: clock
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        preferredWidth: clock.theme.popups.calendar.width
        preferredHeight: clock.theme.popups.calendar.height

        grabFocus: true

        onVisibleChanged: {
            if (visible) {
                calendar.resetToToday();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: clock.theme.background
            radius: clock.theme.radius.large
            border.color: clock.theme.border
            border.width: clock.theme.widget.borderWidth

            CalendarWidget { theme: clock.theme;
                id: calendar
            }
        }
    }

    contentItem: Text {
        id: label
        text: Time.time(clock.compact ? "h:mm" : "dddd h:mm")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: clock.theme.font
        leftPadding: clock.theme.spacing.medium
        rightPadding: clock.theme.spacing.medium
        color: clock.theme.foreground
    }
}

pragma ComponentBehavior: Bound
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick

ColumnLayout {
    id: layout
    anchors.fill: parent
    anchors.margins: Theme.widget.padding
    spacing: Theme.spacing.small

    function changeMonth(change: int): void {
        const month = grid.month + change;
        grid.year += Math.floor(month / 12);
        grid.month = ((month % 12) + 12) % 12;
    }

    function resetToToday(): void {
        const today = new Date();
        grid.year = today.getFullYear();
        grid.month = today.getMonth();
    }

    component CalendarButton: ToolButton {
        id: button
        required property int changeValue
        font: Theme.iconFont
        implicitWidth: Theme.iconFont.pixelSize + 2 * Theme.spacing.small
        implicitHeight: implicitWidth
        padding: Theme.spacing.small
        hoverEnabled: true
        onClicked: layout.changeMonth(changeValue)

        contentItem: MaterialIcon {
            text: button.text
            font: button.font
            color: button.enabled ? Theme.foreground : Theme.muted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: Theme.radius.small
            color: button.down ? Theme.surfacePressed : button.hovered ? Theme.surfaceHover : Theme.surface
            border.width: button.visualFocus ? Theme.widget.borderWidth : 0
            border.color: Theme.focusBorder
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small
        CalendarButton {
            text: "chevron_left"
            Accessible.name: "Previous month"
            changeValue: -1
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: grid.locale.toString(new Date(grid.year, grid.month, 1), "MMMM yyyy")
            font: Theme.font
            color: Theme.foreground
        }
        CalendarButton {
            text: "chevron_right"
            Accessible.name: "Next month"
            changeValue: 1
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        columnSpacing: Theme.spacing.medium
        rowSpacing: Theme.spacing.small

        DayOfWeekRow {
            locale: grid.locale
            font: Theme.font
            palette.text: Theme.muted
            spacing: grid.spacing
            Layout.column: 1
            Layout.fillWidth: true
        }

        WeekNumberColumn {
            id: weekNumbers
            month: grid.month
            year: grid.year
            locale: grid.locale
            font: Theme.smallFont
            palette.text: Theme.muted
            spacing: grid.spacing

            Layout.fillHeight: true

            delegate: Text {
                required property int weekNumber
                text: weekNumber
                font: weekNumbers.font
                color: weekNumbers.palette.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true

            font: Theme.font
            palette.text: Theme.foreground
            spacing: Theme.spacing.small

            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: model.month === grid.month ? 1 : 0.5
                text: grid.locale.toString(model.date, "d")
                font: grid.font
                color: model.today ? Theme.accent : grid.palette.text
            }
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick

ColumnLayout {
    id: layout
    required property ScreenTheme theme
    anchors.fill: parent
    anchors.margins: layout.theme.widget.padding
    spacing: layout.theme.spacing.small

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
        font: layout.theme.iconFont
        implicitWidth: layout.theme.iconFont.pixelSize + 2 * layout.theme.spacing.small
        implicitHeight: implicitWidth
        padding: layout.theme.spacing.small
        hoverEnabled: true
        onClicked: layout.changeMonth(changeValue)

        contentItem: MaterialIcon { theme: layout.theme;
            text: button.text
            font: button.font
            color: button.enabled ? layout.theme.foreground : layout.theme.muted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: layout.theme.radius.small
            color: button.down ? layout.theme.surfacePressed : button.hovered ? layout.theme.surfaceHover : layout.theme.surface
            border.width: button.visualFocus ? layout.theme.widget.borderWidth : 0
            border.color: layout.theme.focusBorder
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: layout.theme.spacing.small
        CalendarButton {
            text: "chevron_left"
            Accessible.name: "Previous month"
            changeValue: -1
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: grid.locale.toString(new Date(grid.year, grid.month, 1), "MMMM yyyy")
            font: layout.theme.font
            color: layout.theme.foreground
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
        columnSpacing: layout.theme.spacing.medium
        rowSpacing: layout.theme.spacing.small

        DayOfWeekRow {
            locale: grid.locale
            font: layout.theme.font
            palette.text: layout.theme.muted
            spacing: grid.spacing
            Layout.column: 1
            Layout.fillWidth: true
        }

        WeekNumberColumn {
            id: weekNumbers
            month: grid.month
            year: grid.year
            locale: grid.locale
            font: layout.theme.smallFont
            palette.text: layout.theme.muted
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

            font: layout.theme.font
            palette.text: layout.theme.foreground
            spacing: layout.theme.spacing.small

            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: model.month === grid.month ? 1 : 0.5
                text: grid.locale.toString(model.date, "d")
                font: grid.font
                color: model.today ? layout.theme.accent : grid.palette.text
            }
        }
    }
}

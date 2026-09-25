pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property string _time: {
        Qt.formatDateTime(clock.date, "ddd MMM d hh:mm:ss AP t yyyy");
    }

    function time(format: string): string {
        return Qt.formatDateTime(clock.date, format);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

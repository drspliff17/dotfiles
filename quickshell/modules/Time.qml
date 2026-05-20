// Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property int currentFormat: 0
    readonly property var formats: ["hh:mm AP", "ddd dd MMM", "ddd dd-MM-yy  hh:mm AP"]

    readonly property string time: {
        Qt.formatDateTime(clock.date, formats[currentFormat]);
    }

    function cycleFormat() {
        currentFormat = (currentFormat + 1) % formats.length;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

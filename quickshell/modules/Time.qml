// Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property int currentFormat: 0
    readonly property var formats: ["HH:mm AP", "ddd dd MMM", "ddd  dd-MM-yy  HH:mm AP"]

    readonly property string time: {
        Qt.formatDateTime(clock.date, formats[currentFormat]);
    }

    readonly property string verticalTime: {
        Qt.formatDateTime(clock.date, "hh\nmm");
    }
    function cycleFormat() {
        currentFormat = (currentFormat + 1) % formats.length;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

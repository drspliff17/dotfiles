import QtQuick
import Quickshell.Io

//YOinked from QS Example repo
QtObject {
    id: button
    required property string command
    required property string text

    readonly property var process: Process {
        command: ["bash", "-c", button, command]
    }

    function exec() {
        process.startDetached();
        Qt.quit();
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "modules"

Scope {
    id: shellroot

    // Watch for pywal update, and trigger Colors singleton reload
    FileView {
        id: walFile

        path: "/home/drspliff/.cache/wal/colors.json"
        watchChanges: true
        blockLoading: true

        function reloadColors() {
            try {
                Colors.setColors(JSON.parse(text()));
            } catch (e) {
                console.log("wal parse failed:", e);
            }
        }

        onLoaded: reloadColors()

        onFileChanged: reload()

        onTextChanged: reloadColors()
    }

    // Watch for command files, and trigger CLI to process them if found
    FileView {
        id: commandFile

        path: "/home/drspliff/.config/quickshell/data/cmd_dispatch.json"
        watchChanges: true
        blockLoading: true

        function reloadCommand() {
            try {
                CLI.setProp(JSON.parse(text()));
            } catch (e) {
                console.log("command parse failed:", e);
            }
        }
        onFileChanged: reload()
        onTextChanged: reloadCommand()
    }

    Process {
        id: writer
    }

    Connections {
        target: CLI

        function onWriteResponseRequested(data) {
            let path = "/home/drspliff/.config/quickshell/data/cmd_response";
            writer.command = ["bash", "-c", "echo '" + data.replace(/'/g, "'\\''") + "' > " + path];
            writer.running = true;
        }
    }

    Bar {
        id: bar
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "modules"

Scope {
    id: shellroot

    readonly property string configPath: "/home/drspliff/.config/quickshell/config.json"

    // Config Loader
    FileView {
        path: shellroot.configPath
        watchChanges: true
        blockLoading: true

        function loadConfig() {
            try {
                let parsed = JSON.parse(text());
                for (let key in parsed) {
                    if (key in Config) {
                        Config[key] = parsed[key];
                    }
                }
                console.log(`Loaded config file ${shellroot.configPath}`);
            } catch (e) {
                console.log(`Config error parse failed: ${e}`);
            }
        }

        onLoaded: loadConfig()
        onFileChanged: reload()
        onTextChanged: loadConfig()
    }

    // Config Saver
    Process {
        id: configWriter
    }

    function saveConfig() {
        let data = {};
        for (let key in Config) {
            if (typeof Config[key] === "function")
                continue;
            if (key.startsWith("barPresetDefault"))
                continue;
            data[key] = Config[key];
        }
        let json = JSON.stringify(data, null, 4);
        let escaped = json.replace(/'/g, "'\\''");
        configWriter.command = ["bash", "-c", "echo '" + escaped + "' >" + shellroot.configPath];
        configWriter.running = true;
        console.log(`Saved config ${shellroot.configPath}`);
    }

    // Config Save/Load Connections
    Connections {
        target: Config

        function onSaveRequested() {
            shellroot.saveConfig();
        }
    }

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
                CLI.set_Property(JSON.parse(text()));
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

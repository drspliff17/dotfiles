pragma Singleton

import QtQuick

QtObject {

    property string command: ""
    property var args: []

    function setProp(obj) {
        CLI.command = obj.command;
        CLI.args = obj.args;

        executeCommand();
    }

    // Main logic
    function executeCommand(command_overwrite) {
        if (command_overwrite)
            CLI.command = command_overwrite;
        if (!command) {
            return;
        }
        switch (command) {
        case "set_barPreset":
            Config.config_barPreset = args[0];
            break;
        case "cycle_barPreset":
            let presets = Config.config_barPresetOrder;
            let i = presets.indexOf(Config.config_barPreset);
            if (i < 0)
                i = 0;
            Config.config_barPreset = presets[(i + 1) % presets.length];
            break;
        }
    }
}

pragma Singleton

import QtQuick

QtObject {

    property string command: ""
    property var args: []
    property var handlers: ({})

    Component.onCompleted: {
        handlers.set_barPreset = set_barPreset;
        handlers.cycle_barPreset = cycle_barPreset;
        handlers.get_barPreset = get_barPreset;
    }

    signal writeResponseRequested(string data)

    function setProp(obj) {
        CLI.command = obj.command;
        CLI.args = obj.args;

        executeCommand();
    }

    function set_barPreset() {
        Config.config_barPreset = args[0];
    }

    function cycle_barPreset() {
        let presets = Config.config_barPresetOrder;
        let i = presets.indexOf(Config.config_barPreset);
        if (i < 0)
            i = 0;
        Config.config_barPreset = presets[(i + 1) % presets.length];
    }

    function get_barPreset() {
        writeResponseRequested(Config.config_barPreset);
    }

    // Main logic
    function executeCommand(command_overwrite) {
        if (command_overwrite)
            CLI.command = command_overwrite;
        if (!command) {
            return;
        }
        const fn = handlers[command];
        if (fn) {
            fn();
        } else {
            console.log("Unknown command:", command);
        }
    }
}

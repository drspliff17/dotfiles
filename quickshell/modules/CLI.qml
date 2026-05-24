pragma Singleton

import QtQuick

QtObject {

    signal writeResponseRequested(string data)

    property string command: ""
    property var args: []
    property var handlers: ({})

    // Update main CLI properties
    function setProp(obj) {
        CLI.command = obj.command;
        CLI.args = obj.args;

        executeCommand();
    }

    // Local command logic
    function set_configProperty() {
        Config.interactProperty("set", args[0], args[1]);
    }

    function get_configProperty() {
        Config.interactProperty("get", args[0]);
    }

    function cycle_barPreset() {
        let presets = Config.config_barPresetOrder;
        let i = presets.indexOf(Config.config_barPreset);
        if (i < 0)
            i = 0;
        Config.config_barPreset = presets[(i + 1) % presets.length];
    }

    Component.onCompleted: {
        handlers.set_configProperty = set_configProperty;
        handlers.get_configProperty = get_configProperty;
        handlers.cycle_barPreset = cycle_barPreset;
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

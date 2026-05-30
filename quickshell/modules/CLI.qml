pragma Singleton

import QtQuick

QtObject {

    signal writeResponseRequested(string data)

    property string command: ""
    property var args: []
    property var handlers: ({})

    // Update main CLI properties
    function set_Property(obj) {
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
        let presets = Config.barPresetOrder;
        let i = presets.indexOf(Config.barPreset);
        if (i < 0)
            i = 0;
        Config.barPreset = presets[(i + 1) % presets.length];
    }

    function reset_barPresetOrder() {
        Config.barPresetOrder = Config.barPresetDefault;
    }

    function pop_barPresetOrder() {
        const removed = Config.barPresetOrder.pop();
        console.log("Popped preset:", removed);
        return removed;
    }

    // function cycle_CmusFormat() {
    //   const max = 1;
    //   let cur = Config.barWidgets_Cmus_format;
    //   if(cur === max){
    //     Config.barWidgets_Cmus_format
    //   }
    // }

    function request_save() {
        Config.saveRequested();
    }

    Component.onCompleted: {
        handlers.set_configProperty = set_configProperty;
        handlers.get_configProperty = get_configProperty;
        handlers.cycle_barPreset = cycle_barPreset;
        handlers.pop_barPresetOrder = pop_barPresetOrder;
        handlers.reset_barPresetOrder = reset_barPresetOrder;
        handlers.request_save = request_save;
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

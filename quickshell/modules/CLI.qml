pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io


QtObject {

    property string command: ""
    property var args: []

    function setProp(obj){
      CLI.command = obj.command
      CLI.args = obj.args

      executeCommand()
    }

    // Main logic
    function executeCommand(command_overwrite){
      if(command_overwrite) CLI.command = command_overwrite
      if (!command){
        return
      }
      switch(command){
        case "set_barPreset":
          Config.config_barPreset = args[0]
        break;
        case "cycle_barPreset":
          let i = Config.config_barPresetOrder.indexOf(Config.config_barPreset);
          if (i < 0)
              i = 0;
          Config.config_barPreset = Config.config_barPresetOrder[(i + 1) % Config.config_barPresetOrder.length];
        break;
      }
    }
}

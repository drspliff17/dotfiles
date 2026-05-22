pragma Singleton

import QtQuick

QtObject {
    property string command: ""
    property var args: []

    function assertArgCount(count){
      if(args.length !== count){
        return false
      }
      return true
    }

    function assertCondition(condition){
      if(!condition) return false
      return true
    }

    function executeCommand(){
      if (!command){
        return
      }
      switch(command){
        case "set_barPreset":
          if(!assertArgCount(1)) return
          if(!assertCondition(["top", "bottom", "left", "right"].includes(args[0]))) return
          Config.config_barPreset = args[0]
        break;
      }
    }
}

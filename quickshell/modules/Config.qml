pragma Singleton

import QtQuick

QtObject {
    property int config_barWidgets_Radius: 10
    property bool config_barWidgets_doHoverOpacity: true

    property string config_barPreset: "bottom"
    property var config_barPresetOrder: ["top", "right", "bottom", "left"]

    function interactProperty(mode, propName, propValue) {
        if (propName in this) {
            switch(mode){
              case "set":
                this[propName] = propValue
                console.log(`Config.interactProperty() >> Set property ( ${propName} ) to value [ ${propValue} ]`);
              break;
              case "get":
                CLI.writeResponseRequested(this[propName])
              break;
              default:
                console.warn(`Config.interactProperty() >> Invalid mode given: ${mode}`)
                return false
              break;
            }
            return true;
        }
        console.warn(`Config.interactProperty() >> Unknown config property: ${propName}`);
        return false;
    }
}

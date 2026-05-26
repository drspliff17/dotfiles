pragma Singleton

import QtQuick

QtObject {
    id: root

    signal saveRequested

    // Bar Configuration
    property real barPanel_Opacity: 1.0

    property int barWidgets_Radius: 10
    property real barWidgets_baseOpacity: 0.45
    property real barWidgets_hoverOpacity: 0.9

    property int barWidgets_doChangeOpacity: 1
    property int barWidgets_WorkspaceWidget_doChangeOpacity: 1

    property real barWidgets_staticOpacity: 0.9

    property string barPreset: "bottom"
    readonly property var barPresetDefault: ["top", "right", "bottom", "left"]
    property var barPresetOrder: ["top", "right", "bottom", "left"]

    // Set/Get any config property by name
    function interactProperty(mode, propName, propValue) {
        if (propName in this) {
            switch (mode) {
            case "set":
                this[propName] = propValue;
                console.log(`Config.interactProperty() >> Set property ( ${propName} ) to value [ ${propValue} ]`);
                break;
            case "get":
                CLI.writeResponseRequested(this[propName]);
                break;
            default:
                console.warn(`Config.interactProperty() >> Invalid mode given: ${mode}`);
                return false;
                break;
            }
            saveRequested();
            return true;
        }
        console.warn(`Config.interactProperty() >> Unknown config property: ${propName}`);
        return false;
    }

    onBarPanel_OpacityChanged: {
        Colors.updateSpecial();
    }
}

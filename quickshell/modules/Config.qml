pragma Singleton

import QtQuick

QtObject {
    id: root

    signal saveRequested
    signal cmusFormatChanged(int v)
    signal weatherFormatChanged(int v)

    // Bar Configuration
    property real barPanel_Opacity: 1.0

    property int barWidgets_Cmus_format: 1
    property int barWidgets_Weather_format: 1

    property int barWidgets_Weather_enabled: 0

    property int barWidgets_Radius: 10
    property real barWidgets_baseOpacity: 0.45
    property real barWidgets_hoverOpacity: 0.9

    property int barWidgets_doChangeOpacity: 1
    property int barWidgets_WorkspaceWidget_doChangeOpacity: 1

    property real barWidgets_staticOpacity: 0.9

    property string barPreset: "bottom"
    readonly property var barPresetDefault: ["top", "right", "bottom", "left"]
    property var barPresetOrder: ["top", "right", "bottom", "left"]

    // Set any config property by name
    function interactProperty(mode, propName, propValue) {
        if (propName in this) {
            //NOTE: Moved get mode into quickshell_command_dispatch.sh as an override, to allow
            // for an easier time using jq to pull values (the values that are actually being used by QS)

            switch (mode) {
            case "set":
                this[propName] = propValue;
                console.log(`Config.interactProperty() >> Set property ( ${propName} ) to value [ ${propValue} ]`);
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

    onBarWidgets_Cmus_formatChanged: {
        cmusFormatChanged(barWidgets_Cmus_format);
    }

    onBarWidgets_Weather_formatChanged: {
        weatherFormatChanged(barWidgets_Weather_format);
    }
}

pragma Singleton

import QtQuick

QtObject {
    property int config_barWidgets_Radius: 10
    property bool config_barWidgets_doHoverOpacity: true

    property string config_barPreset: "bottom"
    property var config_barPresetOrder: ["top", "right", "bottom", "left"]
}

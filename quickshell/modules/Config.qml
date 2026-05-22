pragma Singleton

import QtQuick

QtObject {
    property int config_barWidgetRadius: 10

    property string config_barPreset: "bottom"
    property var config_barPresetOrder: ["top", "right", "bottom", "left"]
}

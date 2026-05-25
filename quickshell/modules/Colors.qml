pragma Singleton

import QtQuick

QtObject {
    property var colors: ({})
    property var special: ({})
    property color bg_transparent

    function updateSpecial() {
        if (special)
            bg_transparent = Qt.alpha(Qt.color(special.background), Config.barPanel_Opacity);
    }

    function setColors(obj) {
        colors = obj.colors || ({});
        special = obj.special || ({});
        updateSpecial();
    }
}

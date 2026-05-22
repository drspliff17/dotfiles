pragma Singleton

import QtQuick

QtObject {
    property var colors: ({})
    property var special: ({})

    function setColors(obj) {
        colors = obj.colors || ({});
        special = obj.special || ({});
    }
}

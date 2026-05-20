pragma Singleton

import QtQuick

QtObject {
    property var data: ({})
    property var colors: ({})
    property var special: ({})

    function setColors(obj) {
        data = obj;
        colors = obj.colors || ({});
        special = obj.special || ({});
    }
}

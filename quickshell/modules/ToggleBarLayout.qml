import QtQuick

Rectangle {
    id: root

    property string currentPreset
    signal cycleRequested

    radius: 8
    color: Colors.colors.color3
    border.color: Colors.colors.color1
    border.width: 1

    width: 24
    height: 24

    Text {
        anchors.centerIn: parent
        color: "white"

        text: {
            if (currentPreset === "top")
                return "↑";
            if (currentPreset === "right")
                return "→";
            if (currentPreset === "bottom")
                return "↓";
            if (currentPreset === "left")
                return "←";
            return "?";
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.cycleRequested()
    }
}

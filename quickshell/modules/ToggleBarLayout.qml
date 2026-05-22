import QtQuick

Rectangle {
    id: root

    required property real baseOpacity
    required property real hoverOpacity

    property string currentPreset
    signal cycleRequested

    color: Colors.colors.color3
    border.color: Colors.colors.color1
    border.width: 1
    opacity: baseOpacity

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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.opacity = root.hoverOpacity
        onExited: root.opacity = root.baseOpacity
        onClicked: root.cycleRequested()
    }
}

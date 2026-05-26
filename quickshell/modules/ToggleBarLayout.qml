import QtQuick

Rectangle {
    id: root

    required property real baseOpacity
    required property real hoverOpacity

    property string currentPreset
    signal cycleRequested

    WidgetBehavior_Opacity {
        id: ctl_opacity
        target: root
        baseOpacity: 0.45
        hoverOpacity: 0.9
    }

    color: Colors.colors.color3
    border.color: Colors.colors.color1
    border.width: 1
    opacity: ctl_opacity.update(false)

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

        onEntered: ctl_opacity.update(true)
        onExited: ctl_opacity.update(false)
        onClicked: root.cycleRequested()
    }
}

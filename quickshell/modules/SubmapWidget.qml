import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: root

    required property real baseOpacity
    required property real hoverOpacity

    property bool vertical: false
    color: Colors.colors.color3
    opacity: baseOpacity

    border.color: Colors.colors.color1
    border.width: 1

    implicitWidth: vertical ? textItem.implicitWidth + 8 : textItem.implicitWidth + 10
    implicitHeight: vertical ? textItem.implicitHeight + 8 : textItem.implicitHeight + 8

    property string submap: ""
    property bool showSelf: submap === "" ? false : true
    visible: showSelf
    Text {
        id: textItem
        color: "white"
        visible: root.visible
        anchors.centerIn: parent
        text: root.submap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.opacity = root.hoverOpacity
        onExited: root.opacity = root.baseOpacity
        onClicked: Hyprland.dispatch("hl.dsp.submap('reset')")
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") {
                root.submap = event.data;
            }
        }
    }
}

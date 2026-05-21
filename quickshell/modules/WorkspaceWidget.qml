import QtQuick
import Quickshell.Hyprland

Row {
    id: root
    property int radius: 6
    spacing: 6

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            required property var modelData

            visible: modelData.id > 0

            width: visible ? 28 : 0
            height: visible ? 28 : 0
            radius: root.radius

            property bool active: Hyprland.focusedWorkspace?.id === modelData.id

            color: active ? Colors.colors.color3 : Colors.colors.color8

            Text {
                anchors.centerIn: parent
                text: modelData.id
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}

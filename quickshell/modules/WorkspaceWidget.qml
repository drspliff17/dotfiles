import QtQuick
import Quickshell.Hyprland

Row {
    id: root
    property int radius: 6
    spacing: 4

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            required property var modelData

            visible: modelData.id > 0

            width: visible ? 28 : 0
            height: visible ? 28 : 0

            radius: root.radius

            property bool active: Hyprland.focusedWorkspace?.id === modelData.id

            opacity: active ? 1.0 : 0.7
            color: Colors.colors.color3
            border.color: Colors.colors.color1
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: modelData.id
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + "})")
            }
        }
    }
}

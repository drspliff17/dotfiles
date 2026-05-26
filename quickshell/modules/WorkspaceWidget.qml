pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

Flow {
    id: root

    property int radius: 6
    property bool vertical: false

    spacing: 4

    flow: vertical ? Flow.TopToBottom : Flow.LeftToRight

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: rec
            required property var modelData
            visible: modelData.id > 0

            width: visible ? 24 : 0
            height: visible ? 24 : 0

            radius: root.radius

            property bool active: Hyprland.focusedWorkspace?.id === modelData.id
            WidgetBehavior_Opacity {
                id: ctl_opacity
                target: rec
                baseOpacity: 0.30
                hoverOpacity: 0.55
                isWorkspace: true
            }

            color: Colors.colors.color3

            border.color: Colors.colors.color1
            border.width: 1

            onActiveChanged: {
                ctl_opacity.update_workspace(active);
            }

            Text {
                anchors.centerIn: parent
                text: rec.modelData.id
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: ctl_opacity.update_workspace(true)
                onExited: ctl_opacity.update_workspace(false)
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + rec.modelData.id + "})")
            }
        }
    }
}

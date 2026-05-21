import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    property int widgetRadius: 10

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30

            Row {
                anchors.fill: parent
                spacing: 10

                ClockWidget {
                    radius: widgetRadius
                }

                WorkspaceWidget {
                    radius: widgetRadius
                }
            }
        }
    }
}

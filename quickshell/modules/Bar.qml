import QtQuick
import Quickshell

Scope {
    property int widgetRadius: 10

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: Colors.colors.color1

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 1
                spacing: 10
                WorkspaceWidget {
                    radius: widgetRadius
                }

                ClockWidget {
                    radius: widgetRadius
                }
            }
        }
    }
}

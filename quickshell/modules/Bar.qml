import QtQuick
import Quickshell

Scope {
    property int widgetRadius: 10

    QtObject {
        id: layoutPresets

        function bar(preset) {
            switch (preset) {
            case "top":
                return {
                    orientation: "horizontal",
                    anchors: {
                        top: true,
                        bottom: false,
                        left: true,
                        right: true
                    },
                    implicitHeight: 32,
                    implicitWidth: undefined
                };
            case "bottom":
                return {
                    orientation: "horizontal",
                    anchors: {
                        top: false,
                        bottom: true,
                        left: true,
                        right: true
                    },
                    implicitHeight: 32,
                    implicitWidth: undefined
                };
            case "left":
                return {
                    orientation: "vertical",
                    anchors: {
                        top: true,
                        bottom: true,
                        left: true,
                        right: false
                    },
                    implicitHeight: undefined,
                    implicitWidth: 32
                };
            case "right":
                return {
                    orientation: "vertical",
                    anchors: {
                        top: true,
                        bottom: true,
                        left: false,
                        right: true
                    },
                    implicitHeight: undefined,
                    implicitWidth: 32
                };
            default:
                return {
                    orientation: "horizontal",
                    anchors: {
                        top: true,
                        bottom: false,
                        left: true,
                        right: true
                    },
                    implicitHeight: 32,
                    implicitWidth: undefined
                };
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property string barPreset: "top"

            readonly property var layout: layoutPresets.bar(barPreset)

            readonly property bool horizontal: layout.orientation === "horizontal"

            readonly property bool vertical: layout.orientation === "vertical"

            required property var modelData

            screen: modelData
            color: Colors.colors.color0

            anchors {
                top: layout.anchors.top
                bottom: layout.anchors.bottom
                left: layout.anchors.left
                right: layout.anchors.right
            }

            implicitHeight: layout.implicitHeight
            implicitWidth: layout.implicitWidth

            // HORIZONTAL BAR
            Item {
                anchors.fill: parent
                visible: horizontal

                // LEFT SECTION
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    spacing: 10

                    WorkspaceWidget {
                        radius: widgetRadius
                        spacing: 2
                        vertical: false
                    }
                }

                // CENTER SECTION
                Item {
                    anchors.centerIn: parent
                }

                // RIGHT SECTION
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 16
                    spacing: 4

                    Item {
                        width: 32
                        height: 32

                        ToggleBarLayout {
                            anchors.centerIn: parent
                            width: 24
                            height: 24

                            currentPreset: barPreset

                            onCycleRequested: {
                                const presets = ["top", "right", "bottom", "left"];
                                let i = presets.indexOf(barPreset);
                                if (i < 0)
                                    i = 0;
                                barPreset = presets[(i + 1) % presets.length];
                            }
                        }
                    }

                    ClockWidget {
                        radius: widgetRadius
                        vertical: false

                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // VERTICAL BAR
            Item {
                anchors.fill: parent
                visible: vertical

                // TOP SECTION
                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 10
                    spacing: 10

                    WorkspaceWidget {
                        radius: widgetRadius
                        spacing: 2
                        vertical: true
                    }
                }

                // CENTER SECTION
                Item {
                    anchors.centerIn: parent
                }

                // BOTTOM SECTION
                Column {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 10
                    spacing: 5

                    Item {
                        width: 32
                        height: 32

                        ToggleBarLayout {
                            anchors.centerIn: parent
                            width: 24
                            height: 24

                            currentPreset: barPreset

                            onCycleRequested: {
                                const presets = ["top", "right", "bottom", "left"];
                                let i = presets.indexOf(barPreset);
                                if (i < 0)
                                    i = 0;
                                barPreset = presets[(i + 1) % presets.length];
                            }
                        }
                    }

                    ClockWidget {
                        radius: widgetRadius
                        vertical: true

                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}

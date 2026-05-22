import QtQuick
import Quickshell

Scope {
    property int widgetRadius: 10

    // Layout Presets for Status Bar
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

    // Main Bar - using Variants so that monitor adjusts  TODO: Ensure this happens when monitor changes, probably a signal for this exact thing already
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData

            property string barPreset: "bottom"

            property string screenMode: "primary" // "all", "primary", "inverted"
            property string preferredScreenName: "HDMI-A-1"
            property string fallbackScreenName: "eDP-1"

            readonly property var layout: layoutPresets.bar(barPreset)
            readonly property bool horizontal: layout.orientation === "horizontal"
            readonly property bool vertical: layout.orientation === "vertical"

            readonly property bool preferredExists: Quickshell.screens.some(s => s.name === preferredScreenName)
            readonly property bool fallbackExists: Quickshell.screens.some(s => s.name === fallbackScreenName)

            readonly property bool shouldUseThisScreen: {
                if (preferredExists)
                    return modelData.name === preferredScreenName;

                if (fallbackExists)
                    return modelData.name === fallbackScreenName;

                return modelData === Quickshell.primaryScreen;
            }

            function isVisibleScreen(screen) {
                if (screenMode === "all")
                    return true;

                if (screenMode === "primary")
                    return Quickshell.screens.some(s => s.name === preferredScreenName) ? screen.name === preferredScreenName : screen.name === fallbackScreenName;

                if (screenMode === "inverted")
                    return Quickshell.screens.some(s => s.name === fallbackScreenName) ? screen.name === fallbackScreenName : screen.name === preferredScreenName;

                return false;
            }

            screen: modelData
            visible: isVisibleScreen(modelData)

            color: Colors.special.background

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
                visible: bar.horizontal

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

                Item {
                    anchors.centerIn: parent
                    visible: bar.horizontal

                    Cmus {}
                }

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

                            baseOpacity: 0.45
                            hoverOpacity: 0.9

                            currentPreset: bar.barPreset

                            onCycleRequested: {
                                const presets = ["top", "right", "bottom", "left"];
                                let i = presets.indexOf(bar.barPreset);
                                if (i < 0)
                                    i = 0;
                                bar.barPreset = presets[(i + 1) % presets.length];
                            }
                        }
                    }

                    Item {
                        width: 110
                        height: 32

                        SysVolume {
                            anchors.centerIn: parent
                            vertical: false
                            baseOpacity: 0.45
                            hoverOpacity: 0.9
                            radius: widgetRadius
                        }
                    }

                    ClockWidget {
                        radius: widgetRadius
                        vertical: false
                        baseOpacity: 0.65
                        hoverOpacity: 0.9
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // VERTICAL BAR
            Item {
                anchors.fill: parent
                visible: bar.vertical

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

                Item {
                    anchors.centerIn: parent
                }

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

                            baseOpacity: 0.45
                            hoverOpacity: 0.9

                            currentPreset: bar.barPreset

                            onCycleRequested: {
                                const presets = ["top", "right", "bottom", "left"];
                                let i = presets.indexOf(bar.barPreset);
                                if (i < 0)
                                    i = 0;
                                bar.barPreset = presets[(i + 1) % presets.length];
                            }
                        }
                    }

                    ClockWidget {
                        radius: widgetRadius
                        vertical: true
                        baseOpacity: 0.65
                        hoverOpacity: 1.0
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}

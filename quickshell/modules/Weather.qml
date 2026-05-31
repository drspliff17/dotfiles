import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: root
    property bool vertical: false
    property int wformat: 1
    visible: true

    WidgetBehavior_Opacity {
        id: ctl_opacity
        target: root
        baseOpacity: 0.45
        hoverOpacity: 0.9
    }

    opacity: ctl_opacity.update(false)
    color: Colors.colors.color3
    implicitWidth: textItem.contentWidth + 14
    implicitHeight: textItem.contentHeight + 14

    function triggerUpdate() {
        root.wformat = Config.barWidgets_Weather_format;
        updateWeatherTimer.restart();
        updateWeatherData.running = true;
    }

    function cycleFormat() {
        if (root.wformat === 1) {
            Config.barWidgets_Weather_format = 2;
        } else {
            Config.barWidgets_Weather_format = 1;
        }
        root.triggerUpdate();
    }

    Component.onCompleted: {
        root.wformat = Config.barWidgets_Weather_format;
        updateWeatherData.running = true;
    }

    Connections {
        target: Config
        function onWeatherFormatChanged(v) {
            root.wformat = v;
            root.triggerUpdate();
        }
    }

    Timer {
        id: updateWeatherTimer
        interval: 3600000
        running: true
        repeat: true

        onTriggered: {
            updateWeatherData.running = true;
        }
    }

    Process {
        id: updateWeatherData
        command: ["bash", "-c", `/home/drspliff/.config/bash/scripts/qs_weather.sh ${root.wformat}`]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                textItem.text = text;
            }
        }
    }

    Text {
        id: textItem
        text: ""
        color: "white"

        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenterOffset: 8

        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: ctl_opacity.update(true)
        onExited: ctl_opacity.update(false)
        onClicked: root.cycleFormat()
    }
}

import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: root
    property bool vertical: false
    property int wformat: 1
    property string creq: `wttr.in?format=${wformat}`

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
        updateWeatherTimer.restart();
        updateWeatherData.running = true;
    }

    Component.onCompleted: {
        updateWeatherData.running = true;
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
        onClicked: function (mouse) {
            switch (mouse) {
            case Qt.LeftButton:
                break;
            case Qt.RightButton:
                root.triggerUpdate();
                break;
            }
        }
    }
}

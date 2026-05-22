import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root
    required property real baseOpacity
    required property real hoverOpacity

    property bool vertical: false
    color: Colors.colors.color3
    opacity: baseOpacity

    border.color: Colors.colors.color1
    border.width: 1

    implicitWidth: vertical ? 28 : textItem.implicitWidth + 10
    implicitHeight: vertical ? textItem.implicitHeight + 8 : textItem.implicitHeight + 8

    Text {
        id: textItem

        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        anchors.centerIn: parent

        PwObjectTracker {
            objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
        }

        function getVol(node) {
            const v = node?.audio?.volume;
            return (v !== null && v !== undefined) ? v : 0;
        }

        function outputIcon(v) {
            if (v <= 0)
                return " ";
            if (v < 0.5)
                return " ";
            return " ";
        }

        function inputIcon(v) {
            if (v <= 0)
                return " ";
            return " ";
        }

        function update() {
            const sink = Pipewire.defaultAudioSink;
            const source = Pipewire.defaultAudioSource;

            const outVol = getVol(sink);
            const inVol = getVol(source);

            const outStr = `${outputIcon(outVol)} ${(outVol * 100).toFixed(0)}%`;
            const inStr = `${inputIcon(inVol)} ${(inVol * 100).toFixed(0)}%`;

            if (root.vertical) {
                textItem.text = `${outStr}\n${inStr}`;
            } else {
                textItem.text = ` ${outStr}  ${inStr} `;
            }
        }

        Component.onCompleted: update()

        Connections {
            target: Pipewire
            function onDefaultAudioSinkChanged() {
                textItem.update();
            }
            function onDefaultAudioSourceChanged() {
                textItem.update();
            }
        }

        Connections {
            target: Pipewire.defaultAudioSink?.audio
            function onVolumeChanged() {
                textItem.update();
            }
        }

        Connections {
            target: Pipewire.defaultAudioSource?.audio
            function onVolumeChanged() {
                textItem.update();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.opacity = root.hoverOpacity
        onExited: root.opacity = root.baseOpacity
        onClicked: {
            Quickshell.execDetached({
                command: ["pavucontrol"]
            });
        }
    }
}

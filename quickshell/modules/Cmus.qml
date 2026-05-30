import QtQuick
import Quickshell.Services.Mpris

Rectangle {
    id: root

    implicitWidth: textItem.implicitWidth
    implicitHeight: textItem.implicitHeight
    color: "transparent"
    property var player: null

    function updatePlayer() {
        player = Mpris.players.values.find(p => p.identity.includes("cmus"));
    }

    function updateFormat() {
        index = Config.barWidgets_Cmus_format;
        formatted = formats[index];
    }

    Component.onCompleted: updatePlayer()

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.updatePlayer();
        }
    }

    Connections {
        target: Config
        function onCmusFormatChanged() {
            root.updateFormat();
        }
    }

    readonly property string title: player.trackTitle || ""
    readonly property string artist: player.trackArtist || ""
    readonly property string playing: player.isPlaying ? " " : " "
    readonly property real volume: player.volume * 100
    readonly property string volume_f: `${volume}%`
    readonly property var formats: [`${playing} ${artist}  -  ${title}  (${volume_f})`, `${playing} ${title}`]

    property int index: Config.barWidgets_Cmus_format
    property string formatted: player ? formats[index] : ""
    property int nextFormat: index === formats.length ? 0 : index + 1

    Text {
        id: textItem

        text: root.formatted
        color: Colors.colors.color5

        horizontalAlignment: Text.AlignHCenter

        anchors.centerIn: parent
    }
}

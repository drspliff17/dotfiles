import QtQuick
import Quickshell
import Quickshell.Io
import "modules"

Scope {

    FileView {
        id: walFile

        path: "/home/drspliff/.cache/wal/colors.json"
        watchChanges: true
        blockLoading: true

        function reloadColors() {
            try {
                Colors.setColors(JSON.parse(text()));
            } catch (e) {
                console.log("wal parse failed:", e);
            }
        }

        onLoaded: reloadColors()

        onFileChanged: {
            reload();
        }

        onTextChanged: {
            reloadColors();
        }
    }

    Bar {}
}

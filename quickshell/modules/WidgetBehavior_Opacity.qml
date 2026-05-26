import QtQuick

QtObject {
    property Item target
    property real baseOpacity
    property real hoverOpacity
    property int isStatic: Config.barWidgets_doChangeOpacity
    property bool isWorkspace: false

    function update(hover = false) {
        if (Config.barWidgets_doChangeOpacity === 1) {
            target.opacity = hover ? hoverOpacity : baseOpacity;
        } else {
            forceStatic();
        }
    }

    function update_workspace(hover = false) {
        if (target.active) {
            target.opacity = 0.9;
            return;
        }
        if (Config.barWidgets_doChangeOpacity_Workspace === 1) {
            target.opacity = hover ? hoverOpacity : baseOpacity;
        } else {
            forceStatic();
        }
    }

    function forceStatic() {
        target.opacity = Config.barWidgets_staticOpacity;
    }

    onIsStaticChanged: function () {
        if (isStatic === 0) {
            if (isWorkspace) {
                update_workspace();
                return;
            }
            forceStatic();
        } else {
            if (isWorkspace) {
                update_workspace();
            } else {
                update();
            }
        }
    }
}

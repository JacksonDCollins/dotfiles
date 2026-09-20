import QtQuick
import Quickshell
import Quickshell.Hyprland
import "file:///usr/share/omarchy/shell/plugins/bar/widgets" as OmarchyWidgets

OmarchyWidgets.Workspaces {
  id: root

  readonly property var barWindow: root.QsWindow.window
  readonly property string screenName: barWindow && barWindow.screen
    ? String(barWindow.screen.name) : ""

  function workspaceIds() {
    var ids = []
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var workspace = values[i]
      var id = workspace.id
      if (id > 0 && id <= 10 && workspace.monitor
          && workspace.monitor.name === root.screenName) {
        ids.push(id)
      }
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }
}

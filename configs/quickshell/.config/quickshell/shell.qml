import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    // Change this URL to use your own image (relative to this file).
    property url wallpaper: Qt.resolvedUrl("wallpaper.jpeg")

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: "#111827"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper"
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            mask: Region {}

            Image {
                anchors.fill: parent
                source: root.wallpaper
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
}

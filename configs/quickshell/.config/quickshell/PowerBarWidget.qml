pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.ToolButton {
    id: root
    required property var service
    property string selection: ""
    readonly property var selected: service.backlights.find(d => d.name === selection) || service.backlights[0] || null
    readonly property string deviceName: selected ? selected.name : ""
    property var pending: null
    function commitBrightness(): void {
        const request = pending;
        pending = null;
        if (popup.visible && request && request.name === deviceName) service.setBrightness(request.name, request.value);
    }
    onDeviceNameChanged: pending = null
    visible: service.available
    onVisibleChanged: if (!visible) popup.visible = false
    implicitWidth: icon.implicitWidth + 2 * Theme.spacing.medium
    implicitHeight: metrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: service.hasBattery ? "Battery " + service.percent + " percent, " + service.status : "Screen brightness"
    onClicked: popup.visible = !popup.visible
    FontMetrics { id: metrics; font: Theme.font }
    background: Rectangle {
        radius: Theme.radius.medium
        color: root.down ? Theme.surfacePressed : root.hovered ? Theme.surfaceHover : Theme.background
        border.width: root.visualFocus ? Theme.widget.borderWidth : 0
        border.color: Theme.focusBorder
    }
    contentItem: MaterialIcon {
        id: icon
        text: !root.service.hasBattery ? "brightness_6"
            : root.service.battery.state === UPowerDeviceState.Charging ? "battery_charging_full"
            : root.service.percent <= 15 ? "battery_alert" : root.service.percent < 40 ? "battery_2_bar"
            : root.service.percent < 75 ? "battery_4_bar" : "battery_full"
        color: root.service.warningLevel === 2 ? Theme.error : root.service.warningLevel === 1 ? Theme.warning : Theme.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({family: Theme.iconFont.family, pixelSize: Theme.font.pixelSize, variableAxes: Theme.iconFont.variableAxes})
    }
    DesktopPopup {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: 360
        preferredHeight: content.implicitHeight + 2 * Theme.widget.padding
        color: "transparent"
        grabFocus: true
        onVisibleChanged: {
            if (visible) { root.service.refresh(); content.forceActiveFocus(); }
            else root.pending = null;
        }
        Timer { interval: 2000; running: popup.visible; repeat: true; onTriggered: root.service.refresh() }
        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.large
            color: Theme.background
            border.color: Theme.border
            border.width: Theme.widget.borderWidth
            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.widget.padding }
                spacing: Theme.spacing.medium
                Keys.onEscapePressed: popup.visible = false
                Text { text: "Power"; color: Theme.foreground; font: Theme.largeFont }
                Text {
                    visible: root.service.hasBattery
                    text: root.service.percent + "% · " + root.service.status
                    font: Theme.font
                    color: root.service.warningLevel === 2 ? Theme.error : Theme.foreground
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.service.estimate !== ""
                    text: root.service.estimate
                    wrapMode: Text.WordWrap
                    font: Theme.smallFont
                    color: Theme.muted
                }
                Text {
                    visible: root.selected !== null
                    text: "Screen brightness"
                    font: Theme.font
                    color: Theme.foreground
                }
                Basic.ComboBox {
                    Layout.fillWidth: true
                    visible: root.service.backlights.length > 1
                    model: root.service.backlights.map(d => d.name)
                    currentIndex: model.indexOf(root.deviceName)
                    onActivated: index => root.selection = model[index]
                    font: Theme.smallFont
                    palette.button: Theme.surface
                    palette.buttonText: Theme.foreground
                    palette.text: Theme.foreground
                    palette.base: Theme.surface
                    palette.window: Theme.background
                    palette.mid: Theme.border
                    palette.highlight: Theme.accent
                    palette.highlightedText: Theme.background
                    Accessible.name: "Backlight device"
                }
                RowLayout {
                    visible: root.selected !== null
                    Layout.fillWidth: true
                    Basic.Slider {
                        id: brightness
                        Layout.fillWidth: true
                        from: 1
                        to: 100
                        stepSize: 1
                        enabled: root.selected !== null && !root.service.busy
                        palette.highlight: Theme.accent
                        palette.button: Theme.foreground
                        palette.mid: Theme.surfaceHover
                        palette.dark: Theme.surfacePressed
                        palette.light: Theme.surfaceHover
                        Accessible.name: "Screen brightness"
                        onMoved: {
                            root.pending = {name: root.deviceName, value: value};
                            if (!pressed) root.commitBrightness();
                        }
                        onPressedChanged: if (!pressed) root.commitBrightness()
                        Binding {
                            target: brightness
                            property: "value"
                            value: root.selected ? root.selected.percent : 1
                            when: !brightness.pressed && root.pending === null && !root.service.busy
                            restoreMode: Binding.RestoreNone
                        }
                    }
                    Text {
                        text: (brightness.pressed || root.service.busy ? Math.round(brightness.value) : root.selected ? root.selected.percent : 0) + "%"
                        font: Theme.smallFont
                        color: Theme.foreground
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.service.message !== ""
                    text: root.service.message
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    font: Theme.smallFont
                    color: Theme.error
                }
                Basic.Button {
                    Layout.fillWidth: true
                    text: "Close"
                    font: Theme.smallFont
                    palette.button: Theme.surface
                    palette.buttonText: Theme.foreground
                    onClicked: popup.visible = false
                }
            }
        }
    }
}

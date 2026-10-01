pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.ToolButton {
    id: root
    required property ScreenTheme theme
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
    implicitWidth: icon.implicitWidth + 2 * root.theme.spacing.medium
    implicitHeight: root.theme.bar.height
    padding: 0
    hoverEnabled: true
    Accessible.name: service.hasBattery ? "Battery " + service.percent + " percent, " + service.status : "Screen brightness"
    onClicked: popup.visible = !popup.visible
    background: Rectangle {
        radius: root.theme.radius.medium
        color: root.down ? root.theme.surfacePressed : root.hovered ? root.theme.surfaceHover : root.theme.background
        border.width: root.visualFocus ? root.theme.widget.borderWidth : 0
        border.color: root.theme.focusBorder
    }
    contentItem: MaterialIcon { theme: root.theme;
        id: icon
        text: !root.service.hasBattery ? "brightness_6"
            : root.service.battery.state === UPowerDeviceState.Charging ? "battery_charging_full"
            : root.service.percent <= 15 ? "battery_alert" : root.service.percent < 40 ? "battery_2_bar"
            : root.service.percent < 75 ? "battery_4_bar" : "battery_full"
        color: root.service.warningLevel === 2 ? root.theme.error : root.service.warningLevel === 1 ? root.theme.warning : root.theme.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: Qt.font({family: root.theme.iconFont.family, pixelSize: root.theme.tray.iconSize, variableAxes: root.theme.iconFont.variableAxes})
    }
    DesktopPopup { theme: root.theme;
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: root.theme.popups.power.width
        preferredHeight: root.theme.popups.power.height || content.implicitHeight + 2 * root.theme.widget.padding
        color: "transparent"
        grabFocus: true
        onVisibleChanged: {
            if (visible) { root.service.refresh(); content.forceActiveFocus(); }
            else root.pending = null;
        }
        Timer { interval: 2000; running: popup.visible; repeat: true; onTriggered: root.service.refresh() }
        Rectangle {
            anchors.fill: parent
            radius: root.theme.radius.large
            color: root.theme.background
            border.color: root.theme.border
            border.width: root.theme.widget.borderWidth
            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.theme.widget.padding }
                spacing: root.theme.spacing.medium
                Keys.onEscapePressed: popup.visible = false
                Text { text: "Power"; color: root.theme.foreground; font: root.theme.largeFont }
                Text {
                    visible: root.service.hasBattery
                    text: root.service.percent + "% · " + root.service.status
                    font: root.theme.font
                    color: root.service.warningLevel === 2 ? root.theme.error : root.theme.foreground
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.service.estimate !== ""
                    text: root.service.estimate
                    wrapMode: Text.WordWrap
                    font: root.theme.smallFont
                    color: root.theme.muted
                }
                Text {
                    visible: root.selected !== null
                    text: "Screen brightness"
                    font: root.theme.font
                    color: root.theme.foreground
                }
                Basic.ComboBox {
                    Layout.fillWidth: true
                    visible: root.service.backlights.length > 1
                    model: root.service.backlights.map(d => d.name)
                    currentIndex: model.indexOf(root.deviceName)
                    onActivated: index => root.selection = model[index]
                    font: root.theme.smallFont
                    palette.button: root.theme.surface
                    palette.buttonText: root.theme.foreground
                    palette.text: root.theme.foreground
                    palette.base: root.theme.surface
                    palette.window: root.theme.background
                    palette.mid: root.theme.border
                    palette.highlight: root.theme.accent
                    palette.highlightedText: root.theme.background
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
                        palette.highlight: root.theme.accent
                        palette.button: root.theme.foreground
                        palette.mid: root.theme.surfaceHover
                        palette.dark: root.theme.surfacePressed
                        palette.light: root.theme.surfaceHover
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
                        font: root.theme.smallFont
                        color: root.theme.foreground
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.service.message !== ""
                    text: root.service.message
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    font: root.theme.smallFont
                    color: root.theme.error
                }
                Basic.Button {
                    Layout.fillWidth: true
                    text: "Close"
                    font: root.theme.smallFont
                    palette.button: root.theme.surface
                    palette.buttonText: root.theme.foreground
                    onClicked: popup.visible = false
                }
            }
        }
    }
}

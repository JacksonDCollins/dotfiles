import Quickshell
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: container
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.bar.height
            color: Theme.bar.background

            Item {
                anchors.fill: parent

                Workspaces {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    leftPadding: Theme.spacing.medium
                }
                ClockWidget {
                    id: clockWidget
                    anchors.centerIn: parent
                }
                PlayerBarWidget {
                    anchors {
                        left: clockWidget.right
                        leftMargin: Theme.spacing.small
                        verticalCenter: parent.verticalCenter
                    }
                }

                SystemTrayWidget {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    rightPadding: Theme.spacing.medium
                }
            }
        }
    }
}

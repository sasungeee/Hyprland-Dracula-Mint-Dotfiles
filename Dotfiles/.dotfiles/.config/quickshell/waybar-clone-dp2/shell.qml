import Quickshell
import QtQuick

// Equivalent of config.jsonc: this instance is only shown on DP-2.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData
            visible: modelData.name === "DP-2"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 76 // room for the bar's animated battery extension
            exclusiveZone: 37 // keep the original top-bar reservation
            exclusionMode: ExclusionMode.Normal
            color: "transparent"

            // The window is 76 px tall for the battery popup animation, but only
            // the visible bar and (while open) the popup should receive pointer input.
            // Everywhere else, mouse events pass through to windows underneath.
            mask: Region {
                regions: [
                    Region { item: bar.panelItem },
                    Region {
                        x: bar.batteryExpansionOpen ? bar.batteryPopupX : 0
                        y: bar.batteryExpansionOpen ? bar.batteryPopupY : 0
                        width: bar.batteryExpansionOpen ? bar.batteryPopupWidth : 0
                        height: bar.batteryExpansionOpen ? bar.batteryPopupHeight : 0
                    }
                ]
            }

            Bar {
                id: bar
                anchors.fill: parent
                targetScreen: modelData
            }
        }
    }
}

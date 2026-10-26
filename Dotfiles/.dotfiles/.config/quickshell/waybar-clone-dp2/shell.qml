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

            Bar {
                anchors.fill: parent
                targetScreen: modelData
            }
        }
    }
}

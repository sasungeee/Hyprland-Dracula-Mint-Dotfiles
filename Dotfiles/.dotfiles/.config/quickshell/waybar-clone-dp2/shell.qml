import Quickshell
import Quickshell.Wayland
import QtQuick

// Equivalent of config.jsonc: this instance is only shown on DP-2.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            property var modelData
            screen: modelData
            visible: modelData.name === "DP-2"

            anchors {
                top: true
                left: true
                right: true
            }

            // Full-screen-height transparent overlay lets the keyboard-layout OSD
            // sit in the center of the monitor. The input mask still passes clicks
            // through everywhere except the bar and currently open popups.
            implicitHeight: modelData.height
            exclusiveZone: 37 // keep the original top-bar reservation
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.keyboardFocus: bar.keyboardInputRequested ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            // The window is tall enough for both popup animations, but only the
            // visible bar and an open popup receive pointer input. The rest remains
            // click-through to windows underneath.
            mask: Region {
                regions: [
                    Region { item: bar.panelItem },
                    Region {
                        x: bar.batteryExpansionOpen ? bar.batteryPopupX : 0
                        y: bar.batteryExpansionOpen ? bar.batteryPopupY : 0
                        width: bar.batteryExpansionOpen ? bar.batteryPopupWidth : 0
                        height: bar.batteryExpansionOpen ? bar.batteryPopupHeight : 0
                    },
                    Region {
                        x: bar.calendarPopupVisible ? bar.calendarPopupX : 0
                        y: bar.calendarPopupVisible ? bar.calendarPopupY : 0
                        width: bar.calendarPopupVisible ? bar.calendarPopupWidth : 0
                        height: bar.calendarPopupVisible ? bar.calendarPopupHeight : 0
                    },
                    Region {
                        x: bar.calculatorPopupVisible ? bar.calculatorPopupX : 0
                        y: bar.calculatorPopupVisible ? bar.calculatorPopupY : 0
                        width: bar.calculatorPopupVisible ? bar.calculatorPopupWidth : 0
                        height: bar.calculatorPopupVisible ? bar.calculatorPopupHeight : 0
                    },
                    Region {
                        x: bar.powerPopupVisible ? bar.powerPopupX : 0
                        y: bar.powerPopupVisible ? bar.powerPopupY : 0
                        width: bar.powerPopupVisible ? bar.powerPopupWidth : 0
                        height: bar.powerPopupVisible ? bar.powerPopupHeight : 0
                    },
                    Region {
                        x: bar.brightnessPopupVisible ? bar.brightnessPopupX : 0
                        y: bar.brightnessPopupVisible ? bar.brightnessPopupY : 0
                        width: bar.brightnessPopupVisible ? bar.brightnessPopupWidth : 0
                        height: bar.brightnessPopupVisible ? bar.brightnessPopupHeight : 0
                    },
                    Region {
                        x: bar.volumePopupVisible ? bar.volumePopupX : 0
                        y: bar.volumePopupVisible ? bar.volumePopupY : 0
                        width: bar.volumePopupVisible ? bar.volumePopupWidth : 0
                        height: bar.volumePopupVisible ? bar.volumePopupHeight : 0
                    },
                    Region {
                        x: bar.musicPreviewPopupVisible ? bar.musicPreviewPopupX : 0
                        y: bar.musicPreviewPopupVisible ? bar.musicPreviewPopupY : 0
                        width: bar.musicPreviewPopupVisible ? bar.musicPreviewPopupWidth : 0
                        height: bar.musicPreviewPopupVisible ? bar.musicPreviewPopupHeight : 0
                    },
                    Region {
                        x: bar.bluetoothPopupVisible ? bar.bluetoothPopupX : 0
                        y: bar.bluetoothPopupVisible ? bar.bluetoothPopupY : 0
                        width: bar.bluetoothPopupVisible ? bar.bluetoothPopupWidth : 0
                        height: bar.bluetoothPopupVisible ? bar.bluetoothPopupHeight : 0
                    },
                    Region {
                        x: bar.networkPopupVisible ? bar.networkPopupX : 0
                        y: bar.networkPopupVisible ? bar.networkPopupY : 0
                        width: bar.networkPopupVisible ? bar.networkPopupWidth : 0
                        height: bar.networkPopupVisible ? bar.networkPopupHeight : 0
                    },
                    Region {
                        x: bar.appLauncherPopupVisible ? bar.appLauncherPopupX : 0
                        y: bar.appLauncherPopupVisible ? bar.appLauncherPopupY : 0
                        width: bar.appLauncherPopupVisible ? bar.appLauncherPopupWidth : 0
                        height: bar.appLauncherPopupVisible ? bar.appLauncherPopupHeight : 0
                    }
                ]
            }

            Bar {
                id: bar
                anchors.fill: parent
                targetScreen: modelData
                shellWindow: panelWindow
            }
        }
    }
}

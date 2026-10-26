import QtQuick
import Quickshell.Io

// Small polling helper used by status modules.
Item {
    id: root
    property var command: []
    property int interval: 1000
    property string value: ""

    visible: false
    width: 0
    height: 0

    Process {
        id: proc
        command: root.command
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.value = this.text.trim()
        }
    }

    Timer {
        interval: root.interval
        repeat: true
        running: true
        onTriggered: {
            if (!proc.running)
                proc.running = true;
        }
    }
}

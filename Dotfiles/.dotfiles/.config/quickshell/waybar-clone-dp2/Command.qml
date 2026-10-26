import QtQuick
import Quickshell.Io

// Reusable command runner. If input arrives while a process is running,
// queue it so fast wheel events are not silently lost.
Item {
    id: root
    property var command: []
    property bool queueWhileRunning: false
    property int pendingRuns: 0

    visible: false
    width: 0
    height: 0

    function run() {
        if (proc.running) {
            if (root.queueWhileRunning)
                // Bound the queue to prevent an accidental runaway backlog.
                pendingRuns = Math.min(pendingRuns + 1, 40);
        } else {
            proc.running = true;
        }
    }

    Process {
        id: proc
        command: root.command
        running: false
        onExited: {
            if (root.pendingRuns > 0) {
                root.pendingRuns -= 1;
                Qt.callLater(function() {
                    if (!proc.running) proc.running = true;
                });
            }
        }
    }
}

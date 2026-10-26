import QtQuick
import Quickshell.Io

// Merge a short burst of wheel events into one brightnessctl invocation.
// If another burst arrives while brightnessctl is running, it is applied next.
Item {
    id: root

    property var baseCommand: []
    property int stepPercent: 1
    property int pendingSteps: 0
    property int pendingLimit: 100
    property int debounceMs: 25

    visible: false
    width: 0
    height: 0

    function request(steps) {
        if (steps === 0)
            return;
        pendingSteps = Math.max(-pendingLimit, Math.min(pendingLimit, pendingSteps + steps));
        debounce.restart();
    }

    function dispatchPending() {
        if (proc.running || pendingSteps === 0)
            return;

        var steps = pendingSteps;
        pendingSteps = 0;
        var amount = Math.abs(steps * stepPercent);
        var adjustment = String(amount) + "%" + (steps > 0 ? "+" : "-");
        proc.command = root.baseCommand.concat(["set", adjustment]);
        proc.running = true;
    }

    Timer {
        id: debounce
        interval: root.debounceMs
        repeat: false
        onTriggered: root.dispatchPending()
    }

    Process {
        id: proc
        command: root.baseCommand
        running: false
        onExited: {
            if (root.pendingSteps !== 0)
                debounce.restart();
        }
    }
}

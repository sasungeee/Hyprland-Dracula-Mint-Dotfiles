import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

Item {
    id: root

    readonly property color barBg: "#1e1f29"
    readonly property color groupBg: "#2a2c39"
    readonly property color textColor: "#C5C8C6"
    readonly property color accent: "#25A487"
    readonly property color emptyColor: "#878887"

    property string clockText: Qt.formatDateTime(new Date(), "hh:mm:ss")
    property var targetScreen: null
    readonly property var targetMonitor: targetScreen ? Hyprland.monitorFor(targetScreen) : null
    property var batteryFields: batteryPoll.value.split("|")
    property int batteryPercent: Math.max(0, parseInt(batteryFields[0] || "0"))
    property string batteryState: batteryFields.length > 1 ? batteryFields[1] : "unknown"
    property string batteryTime: batteryFields.length > 2 ? batteryFields.slice(2).join("|") : ""
    property var volumeFields: volumePoll.value.split("|")
    readonly property int volumePercent: audioSink && audioSink.audio
        ? Math.round(audioSink.audio.volume * 100)
        : Math.max(0, parseInt(volumeFields[0] || "0"))
    readonly property string volumeState: audioSink && audioSink.audio
        ? (audioSink.audio.muted ? "muted" : "normal")
        : (volumeFields.length > 1 ? volumeFields[1] : "muted")
    readonly property string volumeIcon: volumeState === "muted" ? ""
        : (volumePercent < 33 ? "" : (volumePercent < 66 ? "" : ""))
    readonly property var audioSink: Pipewire.defaultAudioSink
    property int volumeWheelRemainder: 0
    property int brightnessWheelRemainder: 0
    property bool batteryExpansionOpen: false
    // Expose only the actual bar and the temporary battery popup as input areas
    // for the containing PanelWindow. The window itself must stay tall enough
    // for the popup animation, but its transparent remainder must be click-through.
    property var panelItem: panel
    readonly property real batteryPopupX: panel.x + batteryExpansion.x
    readonly property real batteryPopupY: panel.y + batteryExpansion.y
    readonly property real batteryPopupWidth: batteryExpansion.width
    readonly property real batteryPopupHeight: batteryExpansion.height
    property var languageFields: languagePoll.value.split("|")
    property string languageShort: languageFields.length > 0 && languageFields[0].length > 0 ? languageFields[0] : "??"
    property var occupiedIds: occupiedPoll.value.length > 0 ? occupiedPoll.value.split(",") : []

    function workspaceOccupied(number) {
        // Use Quickshell's live Hyprland workspace model first, and also keep
        // the clients-based polling result as a fallback for compositor/API quirks.
        if (occupiedIds.indexOf(String(number)) !== -1)
            return true;

        var allWorkspaces = Hyprland.workspaces.values;
        for (var i = 0; i < allWorkspaces.length; ++i) {
            var ws = allWorkspaces[i];
            if (Number(ws.id) !== Number(number))
                continue;
            if (ws.toplevels && ws.toplevels.values)
                return ws.toplevels.values.length > 0;
        }
        return false;
    }

    function workspaceActive(number) {
        // Both bars show the globally focused workspace, regardless of which
        // monitor the workspace currently belongs to.
        var focused = Hyprland.focusedWorkspace;
        return focused ? Number(focused.id) === Number(number) : false;
    }

    function brightnessWheelSteps(deltaY) {
        brightnessWheelRemainder += deltaY;
        var steps = Math.trunc(brightnessWheelRemainder / 120);
        brightnessWheelRemainder -= steps * 120;
        return steps;
    }

    function adjustVolumeSteps(steps) {
        var sink = Pipewire.defaultAudioSink;
        if (!sink || !sink.audio || steps === 0)
            return;
        // Set PipeWire volume directly: no shell process and no queued wpctl calls.
        var nextVolume = sink.audio.volume + steps * 0.05;
        sink.audio.volume = Math.max(0, Math.min(1.5, nextVolume));
    }

    function wheelSteps(deltaY) {
        volumeWheelRemainder += deltaY;
        var steps = Math.trunc(volumeWheelRemainder / 120);
        volumeWheelRemainder -= steps * 120;
        return steps;
    }

    // Waybar uses Pango markup; convert its common span color attribute to Qt rich text.
    function pangoToHtml(markup) {
        return (markup || "")
            .replace(/<span\s+color=(['\"])(.*?)\1>/g, '<span style="color:$2">')
            .replace(/<span\s+foreground=(['\"])(.*?)\1>/g, '<span style="color:$2">');
    }

    readonly property string networkMarkup: pangoToHtml(networkPoll.value)

    function batteryIconForLevel(level) {
        if (level < 20) return "";
        if (level < 40) return "";
        if (level < 60) return "";
        if (level < 80) return "";
        return "";
    }

    function formatBatteryDuration(value) {
        var remaining = (value || "").trim();
        if (!remaining.length || /^(n\/a|unknown|0 seconds|0 minutes)$/i.test(remaining))
            return "";

        // Accept older UPower output such as "7.2 hours" as well as the
        // human-readable "7 hours 14 minutes" emitted by the status script.
        var match = remaining.match(/^([0-9]+(?:\.[0-9]+)?)\s+hours?$/i);
        if (match) return formatBatteryMinutes(Math.round(Number(match[1]) * 60));
        match = remaining.match(/^([0-9]+(?:\.[0-9]+)?)\s+minutes?$/i);
        if (match) return formatBatteryMinutes(Math.round(Number(match[1])));
        return remaining;
    }

    function formatBatteryMinutes(totalMinutes) {
        totalMinutes = Math.max(0, Math.round(totalMinutes));
        var hours = Math.floor(totalMinutes / 60);
        var minutes = totalMinutes % 60;
        var hourText = hours + (hours === 1 ? " hour" : " hours");
        var minuteText = minutes + (minutes === 1 ? " minute" : " minutes");
        if (hours > 0 && minutes > 0) return hourText + " " + minuteText;
        if (hours > 0) return hourText;
        return minuteText;
    }

    readonly property string batteryBubbleText: {
        if (batteryState === "charging") return "charging";
        if (batteryState === "plugged") return "plugged";
        if (batteryState === "full") return "fully charged";
        if (batteryState === "discharging")
            return formatBatteryDuration(batteryTime) || "time unavailable";
        return "battery status unavailable";
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.clockText = Qt.formatDateTime(new Date(), "hh:mm:ss")
    }

    // A short close delay lets the pointer move from the battery icon into the
    // attached extension without collapsing it in between.
    Timer {
        id: batteryCloseTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!batteryMouse.containsMouse && !batteryBubbleMouse.containsMouse)
                root.batteryExpansionOpen = false;
        }
    }

    // Keep the default PipeWire sink bound so its audio volume/mute state is live.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // Status polls. Avoid polling volume: PipeWire updates it reactively.
    Poll { id: idlePoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "idle"]; interval: 1000 }
    Poll { id: cpuPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "cpu"]; interval: 2000 }
    Poll { id: memoryPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "memory"]; interval: 2000 }
    Poll { id: windowPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "window"]; interval: 1000 }
    Poll { id: occupiedPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "occupied"]; interval: 500 }
    Poll { id: batteryPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "battery"]; interval: 1000 }
    Poll { id: volumePoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "volume"]; interval: 1000 }
    Poll { id: backlightPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "backlight"]; interval: 100 }
    Poll { id: languagePoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "language"]; interval: 500 }
    Poll {
        id: networkPoll
        command: ["/bin/bash", "-lc", "~/.config/rofi/network-manager.sh --status --enabled-color '#a6e3a1' --disabled-color '#f38ba8'"]
        interval: 3000
    }

    // Actions copied from the Waybar module on-click settings.
    Command { id: idleAction; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "toggle-idle"] }
    Command { id: missionCenterAction; command: ["/bin/bash", "-lc", "missioncenter"] }
    Command { id: launcherAction; command: ["/bin/bash", "-lc", "rofi -show drun -theme ~/.config/rofi/launchers/type-2/style-1.rasi"] }
    Command { id: audioAction; command: ["/bin/bash", "-lc", "pgrep -x pwvucontrol >/dev/null && pkill -x pwvucontrol || com.saivert.pwvucontrol &"] }
    Command { id: calcAction; command: ["/bin/bash", "-lc", "rofi -show calc -modi calc -no-show-match -no-sort -calc-command \"echo -n '{result}'\" -theme ~/.config/rofi/launchers/type-2/style-1-calc.rasi -show drun"] }
    Command { id: calendarAction; command: ["/bin/bash", "-lc", "gsimplecal"] }
    Command { id: networkAction; command: ["/bin/bash", "-lc", "~/.config/rofi/network-manager.sh"] }
    Command { id: powerAction; command: ["/bin/bash", "-lc", "~/.config/rofi/rofi-power-menu.sh"] }
    AdjustCommand { id: brightnessAdjustAction; baseCommand: ["brightnessctl", "-d", "intel_backlight"]; stepPercent: 1 }

    Rectangle {
        id: panel
        width: Math.min(1900, root.width)
        height: 32
        y: 5
        anchors.horizontalCenter: parent.horizontalCenter
        color: root.barBg
        radius: 5
        clip: false

        // Battery details are attached directly to the lower edge of the bar.
        // The Canvas scales around the join line, so it unfolds downwards, like
        // the working v8 animation, rather than being revealed through a clip.
        Item {
            id: batteryExpansion
            property real revealProgress: root.batteryExpansionOpen ? 1.0 : 0.0
            property real batteryCenterX: rightModules.x + batteryModule.x + batteryModule.width / 2
            x: batteryCenterX - width / 2
            y: panel.height - 10
            // Extra width holds the two hidden-bracket shoulders; the main
            // rectangular body and text remain centered on the battery module.
            readonly property int shoulderSize: 5
            width: batteryBubbleText.implicitWidth + 28 + 2 * shoulderSize
            height: 44
            visible: revealProgress > 0.001 || root.batteryExpansionOpen
            z: 100

            Behavior on revealProgress {
                NumberAnimation {
                    // Restore the known-working Scale animation timing from v8.
                    duration: 160
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: batteryBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: batteryBubbleShape.width / 2
                    // Keep the attachment line tucked 1 px beneath the bar edge.
                    origin.y: 9
                    yScale: batteryExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18)
                        return;

                    var w = width;
                    var h = height;
                    // Draw the shoulder 1 px higher so its top edge is hidden by the bar.
                    var joinY = 9;
                    var radius = 8;
                    var shoulderSize = batteryExpansion.shoulderSize;
                    var inset = 0.5;
                    // 'left' and 'right' are the vertical walls of the plain
                    // rectangular body. The bracket tips extend one shoulderSize
                    // outward, but stay attached along the bar's full lower edge.
                    var left = shoulderSize + inset;
                    var right = w - shoulderSize - inset;

                    // Concealed shelf-bracket profile. The top edge runs all the
                    // way across and is not outlined. At each right-angle joint,
                    // a curved triangular support reaches outward along the bar,
                    // then its concave hypotenuse returns to the body's vertical
                    // side. There is no central bump, pointer, or top indentation.
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(
                        right + shoulderSize * 0.3, joinY,
                        right, joinY + shoulderSize * 0.3,
                        right, joinY + shoulderSize
                    );
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(
                        left, joinY + shoulderSize * 0.3,
                        left - shoulderSize * 0.3, joinY,
                        left - shoulderSize, joinY
                    );
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();

                    // Outline the two concave hypotenuses, sides and rounded
                    // bottom. Never stroke the top seam, so it looks hidden behind
                    // the bar just like the top of a concealed shelf bracket.
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(
                        left - shoulderSize * 0.3, joinY + 0.5,
                        left + 0.5, joinY + shoulderSize * 0.3,
                        left + 0.5, joinY + shoulderSize
                    );
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(
                        right - 0.5, joinY + shoulderSize * 0.3,
                        right + shoulderSize * 0.3, joinY + 0.5,
                        right + shoulderSize, joinY + 0.5
                    );
                    ctx.strokeStyle = root.groupBg.toString();
                    ctx.lineWidth = 1;
                    ctx.lineCap = "butt";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Text {
                id: batteryBubbleText
                anchors.horizontalCenter: parent.horizontalCenter
                y: 10 + (parent.height - 10 - height) / 2
                text: root.batteryBubbleText
                color: root.textColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                opacity: Math.max(0, Math.min(1, (parent.revealProgress - 0.48) / 0.28))
                visible: parent.revealProgress > 0.48
            }

            MouseArea {
                id: batteryBubbleMouse
                x: 0
                y: 10
                width: parent.width
                height: parent.height - 10
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.ArrowCursor
                onEntered: {
                    batteryCloseTimer.stop();
                    root.batteryExpansionOpen = true;
                }
                onExited: batteryCloseTimer.restart()
            }
        }

        // LEFT: idle, CPU, memory, active window class
        Row {
            id: leftModules
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Item {
                width: 20; height: 32
                Text {
                    anchors.centerIn: parent
                    text: idlePoll.value.length ? idlePoll.value : " 󰅶 "
                    color: root.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }
                MouseArea { cursorShape: Qt.PointingHandCursor; anchors.fill: parent; onClicked: idleAction.run() }
            }

            Item {
                width: cpuRow.implicitWidth + 10; height: 32
                Row { id: cpuRow; anchors.centerIn: parent; spacing: 4
                    Text { text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                    Text { text: (cpuPoll.value.length ? cpuPoll.value : "0") + "%"; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                MouseArea { cursorShape: Qt.PointingHandCursor; anchors.fill: parent; onClicked: missionCenterAction.run() }
            }

            Item {
                width: memoryRow.implicitWidth + 10; height: 32
                Row { id: memoryRow; anchors.centerIn: parent; spacing: 4
                    Text { text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                    Text { text: (memoryPoll.value.length ? memoryPoll.value : "0") + "%"; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                MouseArea { cursorShape: Qt.PointingHandCursor; anchors.fill: parent; onClicked: missionCenterAction.run() }
            }

            Item {
                width: windowText.text.length === 0 ? 0 : Math.min(windowText.implicitWidth + 18, 420)
                height: 32
                Text {
                    id: windowText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    width: Math.min(implicitWidth, 402)
                    text: windowPoll.value
                    color: root.textColor
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // CENTER: Rofi launcher and persistent workspaces 1-10.
        Row {
            id: centerModules
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                id: rofiCapsule
                width: 34; height: 24
                anchors.verticalCenter: parent.verticalCenter
                color: root.groupBg
                radius: 5
                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    color: root.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                }
                MouseArea { cursorShape: Qt.PointingHandCursor; id: launcherMouse; anchors.fill: parent; hoverEnabled: true; onClicked: launcherAction.run() }
            }

            Rectangle {
                id: workspacesCapsule
                width: workspacesRow.implicitWidth + 10
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                color: root.groupBg
                radius: 5

                Row {
                    id: workspacesRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: 10
                        delegate: Item {
                            id: workspaceButton
                            required property int index
                            readonly property int workspaceNumber: index + 1
                            readonly property bool isActive: root.workspaceActive(workspaceNumber)
                            readonly property bool isOccupied: root.workspaceOccupied(workspaceNumber)
                            readonly property bool isHovered: workspaceMouse.containsMouse
                            width: workspaceLabel.implicitWidth + 16
                            height: 24

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 2
                                anchors.rightMargin: 2
                                color: "transparent"
                                radius: 0
                            }

                            Text {
                                id: workspaceLabel
                                anchors.centerIn: parent
                                text: workspaceNumber === 8 ? "󰈹" : (workspaceNumber === 9 ? "" : (workspaceNumber === 10 ? "" : String(workspaceNumber)))
                                color: (workspaceButton.isActive || workspaceButton.isOccupied || workspaceButton.isHovered) ? root.textColor : root.emptyColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.bottom: parent.bottom
                                height: 2
                                color: workspaceButton.isActive ? root.accent : root.textColor
                                visible: workspaceButton.isActive || workspaceButton.isHovered
                            }

                            MouseArea { cursorShape: Qt.PointingHandCursor;
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + workspaceButton.workspaceNumber + "\" })")
                            }
                        }
                    }
                }
            }
        }

        // RIGHT: battery, volume, brightness, layout, calculator, clock, network, power.
        Row {
            id: rightModules
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Item {
                id: batteryModule
                width: batteryRow.implicitWidth
                height: 32
                Row { id: batteryRow; anchors.centerIn: parent; spacing: 4
                    Text {
                        text: root.batteryState === "charging" ? "" : root.batteryIconForLevel(root.batteryPercent)
                        color: root.batteryPercent <= 5 && root.batteryState !== "charging" ? "#ff0000" : (root.batteryPercent <= 30 && root.batteryState !== "charging" ? "#f17720" : (root.batteryState === "charging" ? "#98FBCB" : root.accent))
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter
                    }
                    Text { text: root.batteryPercent + "%"; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                MouseArea {
                    id: batteryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.ArrowCursor
                    onEntered: {
                        batteryCloseTimer.stop();
                        root.batteryExpansionOpen = true;
                    }
                    onExited: batteryCloseTimer.restart()
                }
            }

            Item {
                width: volumeRow.implicitWidth + 10; height: 32
                Row { id: volumeRow; anchors.centerIn: parent; spacing: 6
                    Text { text: root.volumeIcon; color: root.volumeState === "muted" ? "#8a8a8a" : root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                    Text { visible: root.volumeState !== "muted"; text: root.volumePercent + "%"; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                MouseArea { cursorShape: Qt.PointingHandCursor;
                    anchors.fill: parent
                    onClicked: audioAction.run()
                    onWheel: {
                        var steps = root.wheelSteps(wheel.angleDelta.y);
                        if (steps !== 0)
                            root.adjustVolumeSteps(steps);
                        wheel.accepted = true;
                    }
                }
            }

            Item {
                width: backlightRow.implicitWidth; height: 32
                Row { id: backlightRow; anchors.centerIn: parent; spacing: 4
                    Text { text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                    Text { text: (backlightPoll.value.length ? backlightPoll.value : "0") + "%"; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.ArrowCursor
                    onWheel: {
                        // Accumulate smooth-scroll substeps into full wheel notches.
                        // The helper then debounces them into one brightnessctl call.
                        var steps = root.brightnessWheelSteps(wheel.angleDelta.y);
                        if (steps !== 0)
                            brightnessAdjustAction.request(steps);
                        wheel.accepted = true;
                    }
                }
            }

            Item {
                id: languageModule
                width: root.languageShort.length ? languageText.implicitWidth + 10 : 0; height: 32
                visible: root.languageShort.length > 0
                // Informational only: no tooltip, click handler, or pointing-hand cursor.
                Text { id: languageText; anchors.centerIn: parent; text: root.languageShort; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            }

            Item {
                width: calcText.implicitWidth + 4; height: 32
                Text { id: calcText; anchors.centerIn: parent; text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                MouseArea { cursorShape: Qt.PointingHandCursor; anchors.fill: parent; onClicked: calcAction.run() }
            }

            Item {
                width: clockTextItem.implicitWidth + 10; height: 32
                Text { id: clockTextItem; anchors.centerIn: parent; text: root.clockText; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                MouseArea { cursorShape: Qt.PointingHandCursor; anchors.fill: parent; onClicked: calendarAction.run() }
            }

            Item {
                width: networkText.implicitWidth; height: 32
                Text {
                    id: networkText
                    anchors.centerIn: parent
                    text: root.networkMarkup
                    textFormat: Text.RichText
                    color: root.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }
                MouseArea { cursorShape: Qt.PointingHandCursor; anchors.fill: parent; onClicked: networkAction.run() }
            }

            Item {
                width: powerText.implicitWidth + 7; height: 32
                Text { id: powerText; anchors.centerIn: parent; text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                MouseArea { cursorShape: Qt.PointingHandCursor; anchors.fill: parent; onClicked: powerAction.run() }
            }
        }
    }
}

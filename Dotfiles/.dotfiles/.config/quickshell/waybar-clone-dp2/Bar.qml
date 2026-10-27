import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

Item {
    id: root

    readonly property color barBg: "#1e1f29"
    readonly property color groupBg: "#2a2c39"
    readonly property color textColor: "#C5C8C6"
    readonly property color accent: "#25A487"
    readonly property color onlineColor: "#a6e3a1"
    readonly property color emptyColor: "#878887"

    property string clockText: Qt.formatDateTime(new Date(), "hh:mm:ss")
    property var targetScreen: null
    property var shellWindow: null
    property bool keyboardInputRequested: false
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
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property int brightnessPercentValue: Math.max(0, Math.min(100, parseInt(backlightPoll.value || "0")))
    readonly property int playbackStreamCount: {
        var nodes = Pipewire.nodes.values;
        var count = 0;
        for (var i = 0; i < nodes.length; ++i) {
            var node = nodes[i];
            if (node && node.isStream && !node.isSink && node.audio !== null)
                count++;
        }
        return count;
    }
    property int volumeWheelRemainder: 0
    property int brightnessWheelRemainder: 0
    property bool batteryExpansionOpen: false
    property bool calendarExpansionOpen: false
    property bool calculatorExpansionOpen: false
    property bool powerExpansionOpen: false
    property bool brightnessExpansionOpen: false
    property bool volumeExpansionOpen: false
    property bool musicPreviewOpen: false
    property bool bluetoothExpansionOpen: false
    property bool networkExpansionOpen: false
    property bool appLauncherExpansionOpen: false
    property string launcherQuery: ""
    property var launcherApps: []
    property string launcherAppsOutput: ""
    property bool launcherAppsLoading: false
    property int launcherSelectedIndex: 0
    property int launcherScrollStartIndex: 0
    property bool launcherWheelSelectionLock: false
    property string launcherLoadError: ""
    property var networkState: ({ wifiEnabled: false, connected: false, activeSsid: "", activeConnection: "", activeType: "", wifiDevice: "", wifiConnected: false, networks: [], error: "" })
    property bool bluetoothAvailable: false
    property bool bluetoothPowered: false
    property bool bluetoothDiscovering: false
    property var bluetoothDevices: []
    property string bluetoothMessage: ""
    property string bluetoothActionOutput: ""
    property string bluetoothActionError: ""
    // Prefer a currently playing MPRIS player; if none is playing, keep a controllable
    // player with metadata available so the click-open mixer can still resume it.
    readonly property var activeMediaPlayer: {
        var players = Mpris.players.values || [];
        for (var i = 0; i < players.length; ++i) {
            if (players[i] && players[i].isPlaying)
                return players[i];
        }
        for (var j = 0; j < players.length; ++j) {
            if (players[j] && players[j].trackTitle && players[j].canControl)
                return players[j];
        }
        for (var k = 0; k < players.length; ++k) {
            if (players[k] && players[k].trackTitle)
                return players[k];
        }
        return null;
    }
    readonly property string mediaPlayerName: activeMediaPlayer ? activeMediaPlayer.identity : ""
    readonly property string mediaArtist: activeMediaPlayer ? activeMediaPlayer.trackArtist : ""
    readonly property string mediaTitle: activeMediaPlayer ? activeMediaPlayer.trackTitle : ""
    readonly property bool mediaAvailable: !!activeMediaPlayer && mediaTitle.trim().length > 0
    readonly property bool mediaPlaying: !!activeMediaPlayer && activeMediaPlayer.isPlaying
    property string networkSelectedSsid: ""
    property string networkSelectedSecurity: ""
    property string networkPassword: ""
    property bool networkInfoBusy: false
    property bool networkRefreshQueued: false
    property bool networkQueuedScan: false
    property bool networkScanRequested: false
    property int networkInfoStage: 0
    property string networkInfoOutput: ""
    property string networkCommandOutput: ""
    property string networkCommandError: ""
    property bool networkCommandFallback: false
    property string networkCommandSsid: ""
    property string networkCommandPassword: ""
    property var networkInfoWorking: ({})
    property string brightnessDraft: "0"
    property int pendingBrightnessPercent: -1
    property string calculatorExpression: ""
    onCalculatorExpressionChanged: {
        // Keep the editable field synced when keypad buttons change the expression.
        if (calculatorInput && calculatorInput.text !== calculatorExpression)
            calculatorInput.text = calculatorExpression;
    }
    property var todayDate: new Date()
    property var selectedCalendarDate: new Date()
    property int calendarViewMonth: new Date().getMonth()
    property int calendarViewYear: new Date().getFullYear()
    // Expose only the actual bar and open popups as input areas for PanelWindow.
    // The window is tall enough for the calendar animation, while its remaining
    // transparent area stays click-through.
    property var panelItem: panel
    readonly property real batteryPopupX: panel.x + batteryExpansion.x
    readonly property real batteryPopupY: panel.y + batteryExpansion.y
    readonly property real batteryPopupWidth: batteryExpansion.width
    readonly property real batteryPopupHeight: batteryExpansion.height
    readonly property real calendarPopupX: panel.x + calendarExpansion.x
    readonly property real calendarPopupY: panel.y + calendarExpansion.y
    readonly property real calendarPopupWidth: calendarExpansion.width
    readonly property real calendarPopupHeight: calendarExpansion.height
    readonly property bool calendarPopupVisible: calendarExpansion.visible
    readonly property real calculatorPopupX: panel.x + calculatorExpansion.x
    readonly property real calculatorPopupY: panel.y + calculatorExpansion.y
    readonly property real calculatorPopupWidth: calculatorExpansion.width
    readonly property real calculatorPopupHeight: calculatorExpansion.height
    readonly property bool calculatorPopupVisible: calculatorExpansion.visible
    readonly property real powerPopupX: panel.x + powerExpansion.x
    readonly property real powerPopupY: panel.y + powerExpansion.y
    readonly property real powerPopupWidth: powerExpansion.width
    readonly property real powerPopupHeight: powerExpansion.height
    readonly property bool powerPopupVisible: powerExpansion.visible
    readonly property real brightnessPopupX: panel.x + brightnessExpansion.x
    readonly property real brightnessPopupY: panel.y + brightnessExpansion.y
    readonly property real brightnessPopupWidth: brightnessExpansion.width
    readonly property real brightnessPopupHeight: brightnessExpansion.height
    readonly property bool brightnessPopupVisible: brightnessExpansion.visible
    readonly property real volumePopupX: panel.x + volumeExpansion.x
    readonly property real volumePopupY: panel.y + volumeExpansion.y
    readonly property real volumePopupWidth: volumeExpansion.width
    readonly property real volumePopupHeight: volumeExpansion.height
    readonly property bool volumePopupVisible: volumeExpansion.visible
    readonly property real musicPreviewPopupX: panel.x + musicPreviewExpansion.x
    readonly property real musicPreviewPopupY: panel.y + musicPreviewExpansion.y
    readonly property real musicPreviewPopupWidth: musicPreviewExpansion.width
    readonly property real musicPreviewPopupHeight: musicPreviewExpansion.height
    readonly property bool musicPreviewPopupVisible: musicPreviewExpansion.visible
    readonly property real bluetoothPopupX: panel.x + bluetoothExpansion.x
    readonly property real bluetoothPopupY: panel.y + bluetoothExpansion.y
    readonly property real bluetoothPopupWidth: bluetoothExpansion.width
    readonly property real bluetoothPopupHeight: bluetoothExpansion.height
    readonly property bool bluetoothPopupVisible: bluetoothExpansion.visible
    readonly property real networkPopupX: panel.x + networkExpansion.x
    readonly property real networkPopupY: panel.y + networkExpansion.y
    readonly property real networkPopupWidth: networkExpansion.width
    readonly property real networkPopupHeight: networkExpansion.height
    readonly property bool networkPopupVisible: networkExpansion.visible
    readonly property real appLauncherPopupX: panel.x + appLauncherExpansion.x
    readonly property real appLauncherPopupY: panel.y + appLauncherExpansion.y
    readonly property real appLauncherPopupWidth: appLauncherExpansion.width
    readonly property real appLauncherPopupHeight: appLauncherExpansion.height
    readonly property bool appLauncherPopupVisible: appLauncherExpansion.visible
    readonly property string calculatorResult: evaluateCalculatorExpression(calculatorExpression)
    readonly property var launcherFilteredApps: {
        var query = String(launcherQuery || "").trim().toLocaleLowerCase();
        if (!query.length)
            return launcherApps;
        var result = [];
        for (var i = 0; i < launcherApps.length; ++i) {
            var app = launcherApps[i];
            var haystack = [app.name, app.genericName, app.comment, app.desktopId]
                .join(" ").toLocaleLowerCase();
            if (haystack.indexOf(query) !== -1)
                result.push(app);
        }
        return result;
    }
    readonly property var launcherVisibleApps: launcherFilteredApps.slice(
        launcherScrollStartIndex, launcherScrollStartIndex + 7)
    property string languageValue: "us|English (US)"
    property var languageFields: languageValue.split("|")
    property string languageShort: languageFields.length > 0 && languageFields[0].length > 0 ? languageFields[0] : "??"
    property bool osdInitialized: false
    property bool osdVisible: false
    property string osdMode: "volume"
    property string osdLastLanguageShort: ""
    property string osdLastCapsLockState: ""
    property int osdLastVolumePercent: -1
    property string osdLastVolumeState: ""
    // Each monitor's bar displays its own OSD for the same system-wide event.
    // Do not gate notifications on which monitor currently has keyboard focus.
    readonly property bool osdTargetActive: true
    property var occupiedIds: occupiedPoll.value.length > 0 ? occupiedPoll.value.split(",") : []

    onLanguageShortChanged: {
        if (!osdInitialized) {
            osdLastLanguageShort = languageShort;
            return;
        }
        if (languageShort !== osdLastLanguageShort) {
            osdLastLanguageShort = languageShort;
            showOsd("layout");
        }
    }

    onVolumePercentChanged: {
        if (!osdInitialized || !audioSink || !audioSink.audio) {
            osdLastVolumePercent = volumePercent;
            return;
        }
        if (volumePercent !== osdLastVolumePercent) {
            osdLastVolumePercent = volumePercent;
            showOsd("volume");
        }
    }

    onVolumeStateChanged: {
        if (!osdInitialized || !audioSink || !audioSink.audio) {
            osdLastVolumeState = volumeState;
            return;
        }
        if (volumeState !== osdLastVolumeState) {
            osdLastVolumeState = volumeState;
            showOsd("volume");
        }
    }

    function showOsd(mode) {
        if (!osdInitialized)
            return;
        osdMode = mode;
        osdVisible = true;
        osdCloseTimer.restart();
    }

    function updateCapsLockState(rawState) {
        var nextState = String(rawState || "").trim().toLowerCase();
        if (nextState !== "yes" && nextState !== "no")
            return;
        if (osdLastCapsLockState.length === 0) {
            osdLastCapsLockState = nextState;
            return;
        }
        if (nextState !== osdLastCapsLockState) {
            osdLastCapsLockState = nextState;
            showOsd("caps");
        }
    }

    onBrightnessPercentValueChanged: {
        if (!brightnessPercentInput.activeFocus)
            brightnessDraft = String(brightnessPercentValue);
    }

    onCalculatorExpansionOpenChanged: {
        if (!calculatorExpansionOpen)
            keyboardInputRequested = false;
    }
    onBrightnessExpansionOpenChanged: {
        if (!brightnessExpansionOpen)
            keyboardInputRequested = false;
    }
    onNetworkExpansionOpenChanged: {
        if (!networkExpansionOpen)
            keyboardInputRequested = false;
    }
    onAppLauncherExpansionOpenChanged: {
        if (!appLauncherExpansionOpen)
            keyboardInputRequested = false;
    }
    onLauncherQueryChanged: {
        if (launcherSearchInput && launcherSearchInput.text !== launcherQuery)
            launcherSearchInput.text = launcherQuery;
        launcherSelectedIndex = 0;
        launcherScrollStartIndex = 0;
    }
    onVolumeExpansionOpenChanged: {
        if (volumeExpansionOpen) {
            musicPreviewOpen = false;
            musicPreviewCloseTimer.stop();
        }
    }
    onMediaAvailableChanged: {
        if (!mediaAvailable) {
            musicPreviewOpen = false;
            musicPreviewCloseTimer.stop();
        }
    }
    onMediaPlayingChanged: {
        if (mediaPlaying && volumeMouse.containsMouse && canShowMusicPreview()) {
            musicPreviewOpen = true;
            musicPreviewCloseTimer.stop();
        }
    }

    function toggleAppLauncher() {
        if (appLauncherExpansionOpen) {
            appLauncherExpansionOpen = false;
            keyboardInputRequested = false;
            return;
        }
        // Keep only one interactive popup open at a time.
        batteryExpansionOpen = false;
        calendarExpansionOpen = false;
        calculatorExpansionOpen = false;
        powerExpansionOpen = false;
        brightnessExpansionOpen = false;
        volumeExpansionOpen = false;
        musicPreviewOpen = false;
        bluetoothExpansionOpen = false;
        networkExpansionOpen = false;
        launcherQuery = "";
        if (launcherSearchInput && launcherSearchInput.text !== "")
            launcherSearchInput.text = "";
        launcherSelectedIndex = 0;
        launcherScrollStartIndex = 0;
        launcherWheelSelectionLock = false;
        launcherWheelUnlockTimer.stop();
        launcherLoadError = "";
        launcherAppsLoading = true;
        launcherAppsOutput = "";
        appLauncherExpansionOpen = true;
        if (!launcherAppsProcess.running)
            launcherAppsProcess.running = true;
        launcherFocusTimer.restart();
    }

    function moveLauncherSelection(delta) {
        var count = launcherFilteredApps.length;
        if (count <= 0)
            return;
        launcherSelectedIndex = ((launcherSelectedIndex + delta) % count + count) % count;
        if (launcherSelectedIndex < launcherScrollStartIndex)
            launcherScrollStartIndex = launcherSelectedIndex;
        else if (launcherSelectedIndex >= launcherScrollStartIndex + 7)
            launcherScrollStartIndex = launcherSelectedIndex - 6;
    }

    function launchSelectedApplication(appOverride) {
        var app = appOverride || (launcherSelectedIndex >= 0 && launcherSelectedIndex < launcherFilteredApps.length
            ? launcherFilteredApps[launcherSelectedIndex] : null);
        if (!app || !app.path)
            return;
        appLauncherExpansionOpen = false;
        keyboardInputRequested = false;
        appLaunchProcess.command = ["gio", "launch", String(app.path)];
        appLaunchProcess.running = true;
    }

    function focusTextInput(inputItem, selectAllText) {
        if (!inputItem)
            return;
        keyboardInputRequested = true;
        // Let PanelWindow update WlrLayershell.keyboardFocus first, then ask
        // the compositor to activate the surface and put focus in the editor.
        Qt.callLater(function() {
            if (!root.keyboardInputRequested || !root.shellWindow)
                return;
            root.shellWindow.requestActivate();
            inputItem.forceActiveFocus();
            if (selectAllText) {
                inputItem.selectAll();
            } else if (inputItem.text !== undefined) {
                inputItem.cursorPosition = String(inputItem.text).length;
            }
        });
    }

    function calendarCellDate(cellIndex) {
        var firstOfMonth = new Date(calendarViewYear, calendarViewMonth, 1);
        var mondayOffset = (firstOfMonth.getDay() + 6) % 7;
        return new Date(calendarViewYear, calendarViewMonth, Number(cellIndex) - mondayOffset + 1);
    }

    function calendarSameDate(first, second) {
        return !!first && !!second
            && first.getFullYear() === second.getFullYear()
            && first.getMonth() === second.getMonth()
            && first.getDate() === second.getDate();
    }

    function calendarMonthName(monthIndex) {
        return ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"][monthIndex];
    }

    function formatCalendarDate(value) {
        if (!value)
            return "";
        var day = String(value.getDate()).padStart(2, "0");
        var month = String(value.getMonth() + 1).padStart(2, "0");
        return day + "." + month + "." + value.getFullYear();
    }

    function evaluateCalculatorExpression(expression) {
        var source = String(expression || "").replace(/\s+/g, "").replace(/=$/, "");
        if (!source.length)
            return "";

        // Complete an unfinished parenthesized expression for live preview, e.g. sqrt(9.
        var openCount = 0;
        var closeCount = 0;
        for (var j = 0; j < source.length; ++j) {
            if (source[j] === "(") openCount++;
            else if (source[j] === ")") closeCount++;
        }
        if (closeCount > openCount)
            return "";
        while (openCount > closeCount) {
            source += ")";
            closeCount++;
        }

        var tokens = source.match(/sqrt|\d+(?:\.\d*)?|\.\d+|\*\*|[()+\-*/^]/g);
        if (!tokens || tokens.join("") !== source)
            return "";

        var position = 0;
        function peek() { return position < tokens.length ? tokens[position] : ""; }
        function requireToken(expected) {
            if (peek() !== expected) throw new Error("incomplete expression");
            position++;
        }
        function parsePrimary() {
            var token = peek();
            if (!token) throw new Error("missing operand");
            if (token === "+" || token === "-" || token === "*" || token === "/" || token === "^" || token === "**")
                throw new Error("missing operand");
            if (token === "sqrt") {
                position++;
                var value;
                if (peek() === "(") {
                    position++;
                    value = parseExpression();
                    requireToken(")");
                } else {
                    value = parseUnary();
                }
                return Math.sqrt(value);
            }
            if (token === "(") {
                position++;
                var inner = parseExpression();
                requireToken(")");
                return inner;
            }
            if (/^(?:\d+(?:\.\d*)?|\.\d+)$/.test(token)) {
                position++;
                return Number(token);
            }
            throw new Error("invalid token");
        }
        function parsePower() {
            var value = parsePrimary();
            if (peek() === "^" || peek() === "**") {
                position++;
                value = Math.pow(value, parseUnary());
            }
            return value;
        }
        function parseUnary() {
            if (peek() === "+") { position++; return parseUnary(); }
            if (peek() === "-") { position++; return -parseUnary(); }
            return parsePower();
        }
        function parseTerm() {
            var value = parseUnary();
            while (peek() === "*" || peek() === "/") {
                var op = peek();
                position++;
                var right = parseUnary();
                value = op === "*" ? value * right : value / right;
            }
            return value;
        }
        function parseExpression() {
            var value = parseTerm();
            while (peek() === "+" || peek() === "-") {
                var op = peek();
                position++;
                var right = parseTerm();
                value = op === "+" ? value + right : value - right;
            }
            return value;
        }

        try {
            var result = parseExpression();
            if (position !== tokens.length)
                return "";
            if (!isFinite(result))
                return "Error";
            if (Math.abs(result) < 1e-12) result = 0;
            return Number(result.toPrecision(12)).toString();
        } catch (error) {
            return "";
        }
    }

    function handleCalculatorKey(key) {
        if (key === "C") {
            calculatorExpression = "";
            return;
        }
        if (key === "⌫") {
            calculatorExpression = calculatorExpression.slice(0, -1);
            return;
        }
        if (key === "=") {
            if (calculatorResult.length && calculatorResult !== "Error")
                calculatorExpression = calculatorResult;
            return;
        }
        if (key === "sqrt") {
            if (calculatorExpression.trim().length)
                calculatorExpression = "sqrt(" + calculatorExpression + ")";
            else
                calculatorExpression = "sqrt(";
            return;
        }
        calculatorExpression += key;
    }

    function moveCalendarMonth(delta) {
        var moved = new Date(calendarViewYear, calendarViewMonth + delta, 1);
        calendarViewMonth = moved.getMonth();
        calendarViewYear = moved.getFullYear();
    }

    function moveCalendarYear(delta) {
        calendarViewYear += delta;
    }

    function chooseCalendarDate(value) {
        selectedCalendarDate = new Date(value.getFullYear(), value.getMonth(), value.getDate());
        calendarViewMonth = selectedCalendarDate.getMonth();
        calendarViewYear = selectedCalendarDate.getFullYear();
    }

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

    function requestBrightnessPercent(rawValue) {
        var text = String(rawValue).trim();
        if (!text.length || isNaN(Number(text)))
            return;
        pendingBrightnessPercent = Math.max(0, Math.min(100, Math.round(Number(text))));
        brightnessDraft = String(pendingBrightnessPercent);
        brightnessSetDebounce.restart();
    }

    function dispatchPendingBrightness() {
        if (brightnessSetProcess.running || pendingBrightnessPercent < 0)
            return;
        var percentage = pendingBrightnessPercent;
        pendingBrightnessPercent = -1;
        brightnessSetProcess.command = ["brightnessctl", "-d", "intel_backlight", "set", String(percentage) + "%"];
        brightnessSetProcess.running = true;
    }

    function commitBrightnessInput(rawValue) {
        var text = String(rawValue).trim();
        var value = text.length > 0 && !isNaN(Number(text))
            ? Math.max(0, Math.min(100, Math.round(Number(text))) )
            : brightnessPercentValue;
        brightnessDraft = String(value);
        requestBrightnessPercent(value);
    }

    function audioStreamName(node) {
        if (!node)
            return "Приложение";
        var props = node.properties || {};
        var appName = props["application.name"] || props["media.name"] || "";
        return node.nickname || node.description || appName || node.name || "Приложение";
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

    readonly property string networkModuleText: {
        if (networkState.wifiConnected)
            return "";
        if (networkState.connected)
            return "󰈀";
        return "󰖪";
    }

    readonly property string bluetoothModuleText: bluetoothPowered ? "" : ""

    function parseBluetoothSnapshot(raw) {
        var nextAvailable = false;
        var nextPowered = false;
        var nextDiscovering = false;
        var nextDevices = [];
        var lines = String(raw || "").split("\n");
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim();
            if (!line.length)
                continue;
            if (line.indexOf("STATE|") === 0) {
                var stateParts = line.split("|");
                nextAvailable = stateParts.length > 1 && stateParts[1] === "yes";
                nextPowered = stateParts.length > 2 && stateParts[2] === "yes";
                nextDiscovering = stateParts.length > 3 && stateParts[3] === "yes";
            } else if (line.indexOf("DEVICE|") === 0) {
                var parts = line.split("|");
                if (parts.length >= 5) {
                    nextDevices.push({
                        address: parts[1],
                        connected: parts[2] === "yes",
                        paired: parts[3] === "yes",
                        name: parts.slice(4).join("|").trim() || parts[1]
                    });
                }
            }
        }
        nextDevices.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        bluetoothAvailable = nextAvailable;
        bluetoothPowered = nextPowered;
        bluetoothDiscovering = nextDiscovering;
        bluetoothDevices = nextDevices;
        if (!bluetoothAvailable)
            bluetoothMessage = "Bluetooth adapter unavailable";
        else if (!bluetoothPowered)
            bluetoothMessage = "Bluetooth is off";
        else if (bluetoothMessage === "Bluetooth adapter unavailable" || bluetoothMessage === "Bluetooth is off")
            bluetoothMessage = "";
    }

    function runBluetoothAction(args) {
        if (!bluetoothAvailable || bluetoothActionProcess.running)
            return;
        bluetoothActionOutput = "";
        bluetoothActionError = "";
        bluetoothActionProcess.command = ["bluetoothctl"].concat(args);
        bluetoothActionProcess.running = true;
    }

    function toggleBluetoothScan() {
        if (!bluetoothAvailable || !bluetoothPowered)
            return;
        if (bluetoothDiscovering) {
            bluetoothScanStopTimer.stop();
            runBluetoothAction(["scan", "off"]);
        } else {
            runBluetoothAction(["scan", "on"]);
            bluetoothScanStopTimer.restart();
        }
        bluetoothRefreshTimer.restart();
    }

    function activateBluetoothDevice(device) {
        if (!device || !bluetoothPowered)
            return;
        if (device.connected)
            runBluetoothAction(["disconnect", device.address]);
        else if (device.paired)
            runBluetoothAction(["connect", device.address]);
        else
            runBluetoothAction(["pair", device.address]);
        bluetoothRefreshTimer.restart();
    }

    function toggleMusicPlayback() {
        if (activeMediaPlayer && activeMediaPlayer.canTogglePlaying)
            activeMediaPlayer.togglePlaying();
    }
    function previousMusicTrack() {
        if (activeMediaPlayer && activeMediaPlayer.canGoPrevious)
            activeMediaPlayer.previous();
    }
    function nextMusicTrack() {
        if (activeMediaPlayer && activeMediaPlayer.canGoNext)
            activeMediaPlayer.next();
    }
    function canShowMusicPreview() {
        return mediaPlaying && !volumeExpansionOpen && !batteryExpansionOpen
            && !calendarExpansionOpen && !calculatorExpansionOpen && !powerExpansionOpen
            && !brightnessExpansionOpen && !networkExpansionOpen && !bluetoothExpansionOpen;
    }

    function splitNmcliFields(line) {
        var fields = [];
        var buffer = "";
        var escaped = false;
        for (var i = 0; i < line.length; ++i) {
            var ch = line.charAt(i);
            if (escaped) {
                buffer += ch;
                escaped = false;
            } else if (ch === "\\") {
                escaped = true;
            } else if (ch === ":") {
                fields.push(buffer);
                buffer = "";
            } else {
                buffer += ch;
            }
        }
        if (escaped)
            buffer += "\\";
        fields.push(buffer);
        return fields;
    }

    function runNetworkAction(args) {
        if (!args || args.length === 0)
            return;
        if (args[0] === "status") {
            refreshNetworkList(false);
            return;
        }
        if (networkCommandProcess.running)
            return;

        networkCommandError = "";
        networkCommandOutput = "";
        networkCommandFallback = false;
        networkCommandSsid = "";
        networkCommandPassword = "";

        if (args[0] === "wifi" && args.length >= 2) {
            networkCommandProcess.command = ["nmcli", "radio", "wifi", args[1]];
        } else if (args[0] === "connect" && args.length >= 2) {
            networkCommandSsid = String(args[1]);
            networkCommandPassword = args.length >= 3 ? String(args[2]) : "";
            if (networkCommandPassword.length > 0) {
                networkCommandProcess.command = ["nmcli", "--wait", "12", "device", "wifi", "connect", networkCommandSsid, "password", networkCommandPassword];
            } else {
                // Prefer an already saved connection before attempting an open connection.
                networkCommandFallback = true;
                networkCommandProcess.command = ["nmcli", "--wait", "12", "connection", "up", "id", networkCommandSsid];
            }
        } else if (args[0] === "disconnect") {
            if (!networkState.wifiDevice) {
                var noDeviceState = Object.assign({}, networkState);
                noDeviceState.error = "No active Wi-Fi device";
                networkState = noDeviceState;
                return;
            }
            networkCommandProcess.command = ["nmcli", "device", "disconnect", String(networkState.wifiDevice)];
        } else {
            return;
        }
        networkCommandProcess.running = true;
    }

    function refreshNetworkList(scan) {
        var doScan = scan === true;
        if (networkInfoBusy || networkInfoProcess.running) {
            networkRefreshQueued = true;
            networkQueuedScan = networkQueuedScan || doScan;
            return;
        }
        networkInfoBusy = true;
        networkScanRequested = doScan;
        networkInfoStage = 0;
        networkInfoOutput = "";
        networkInfoWorking = {
            wifiEnabled: false,
            connected: false,
            activeSsid: "",
            activeConnection: "",
            activeType: "",
            wifiDevice: "",
            wifiConnected: false,
            networks: [],
            error: ""
        };
        networkInfoStepTimer.restart();
    }

    function launchNetworkInfoStep() {
        if (!networkInfoBusy || networkInfoProcess.running)
            return;
        networkInfoOutput = "";
        if (networkInfoStage === 0) {
            networkInfoProcess.command = ["nmcli", "radio", "wifi"];
        } else if (networkInfoStage === 1) {
            networkInfoProcess.command = ["nmcli", "--terse", "--escape", "yes", "--fields", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"];
        } else {
            networkInfoProcess.command = ["nmcli", "--terse", "--escape", "yes", "--fields", "IN-USE,SSID,SECURITY,SIGNAL", "device", "wifi", "list", "--rescan", networkScanRequested ? "yes" : "no"];
        }
        networkInfoProcess.running = true;
    }

    function consumeNetworkInfoStep(exitCode, raw) {
        var output = String(raw || "").trim();
        var lines = output.length > 0 ? output.split(/\r?\n/) : [];
        if (networkInfoStage === 0) {
            if (exitCode === 0) {
                networkInfoWorking.wifiEnabled = output.toLowerCase() === "enabled";
            } else {
                networkInfoWorking.error = "NetworkManager unavailable";
            }
            networkInfoStage = 1;
            networkInfoStepTimer.restart();
            return;
        }

        if (networkInfoStage === 1) {
            if (exitCode !== 0 && !networkInfoWorking.error)
                networkInfoWorking.error = output || "Could not read network devices";
            for (var d = 0; d < lines.length; ++d) {
                var device = splitNmcliFields(lines[d]);
                if (device.length < 4)
                    continue;
                var deviceName = device[0];
                var deviceType = String(device[1]).toLowerCase();
                var deviceState = String(device[2]).toLowerCase();
                var connectionName = device[3] === "--" ? "" : device[3];
                if (deviceType === "wifi" && !networkInfoWorking.wifiDevice)
                    networkInfoWorking.wifiDevice = deviceName;
                if (deviceType === "wifi" && deviceState === "connected") {
                    networkInfoWorking.wifiDevice = deviceName;
                    networkInfoWorking.wifiConnected = true;
                }
                if (deviceState === "connected") {
                    networkInfoWorking.connected = true;
                    if (!networkInfoWorking.activeConnection) {
                        networkInfoWorking.activeConnection = connectionName || deviceName;
                        networkInfoWorking.activeType = deviceType;
                    }
                }
            }
            networkInfoStage = 2;
            networkInfoStepTimer.restart();
            return;
        }

        var bySsid = {};
        if (exitCode === 0) {
            for (var n = 0; n < lines.length; ++n) {
                var row = splitNmcliFields(lines[n]);
                if (row.length < 4)
                    continue;
                var inUse = String(row[0]).trim() === "*";
                var ssid = String(row[1] || "");
                var security = String(row[2] || "");
                var signal = parseInt(row[3], 10);
                if (!ssid || ssid === "--")
                    continue;
                if (isNaN(signal)) signal = 0;
                signal = Math.max(0, Math.min(100, signal));
                if (security === "--") security = "";
                var item = { ssid: ssid, security: security, signal: signal, inUse: inUse, secured: security.length > 0 };
                var oldItem = bySsid[ssid];
                if (!oldItem || signal > oldItem.signal || inUse)
                    bySsid[ssid] = item;
                if (inUse) {
                    networkInfoWorking.activeSsid = ssid;
                    networkInfoWorking.wifiConnected = true;
                    networkInfoWorking.connected = true;
                    networkInfoWorking.activeType = "wifi";
                    networkInfoWorking.activeConnection = ssid;
                }
            }
        } else if (networkInfoWorking.wifiEnabled && !networkInfoWorking.error) {
            networkInfoWorking.error = output || "Wi-Fi scan failed";
        }

        var networks = [];
        for (var key in bySsid) {
            if (Object.prototype.hasOwnProperty.call(bySsid, key))
                networks.push(bySsid[key]);
        }
        networks.sort(function(a, b) {
            if (a.inUse !== b.inUse) return a.inUse ? -1 : 1;
            if (a.signal !== b.signal) return b.signal - a.signal;
            return a.ssid.toLowerCase().localeCompare(b.ssid.toLowerCase());
        });
        networkInfoWorking.networks = networks.slice(0, 30);
        if (!networkInfoWorking.activeSsid && networkInfoWorking.wifiConnected)
            networkInfoWorking.activeSsid = networkInfoWorking.activeConnection;
        networkState = networkInfoWorking;

        if (!networkSelectedSsid && networkInfoWorking.activeSsid) {
            networkSelectedSsid = networkInfoWorking.activeSsid;
            for (var k = 0; k < networkInfoWorking.networks.length; ++k) {
                if (networkInfoWorking.networks[k].ssid === networkSelectedSsid) {
                    networkSelectedSecurity = networkInfoWorking.networks[k].security || "";
                    break;
                }
            }
        }
        networkInfoBusy = false;
        if (networkRefreshQueued)
            networkInfoStepTimer.restart();
    }

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

    // Give startup polls and PipeWire initialization time to settle before showing
    // an OSD, so the first values are treated as the baseline rather than a change.
    Timer {
        id: osdInitializationTimer
        interval: 900
        repeat: false
        onTriggered: {
            root.osdLastLanguageShort = root.languageShort;
            root.osdLastVolumePercent = root.volumePercent;
            root.osdLastVolumeState = root.volumeState;
            root.osdInitialized = true;
        }
    }

    Timer {
        id: osdCloseTimer
        interval: 1450
        repeat: false
        onTriggered: root.osdVisible = false
    }

    Component.onCompleted: osdInitializationTimer.start()

    Timer {
        id: calculatorFocusTimer
        interval: 70
        repeat: false
        onTriggered: {
            if (root.calculatorExpansionOpen)
                root.focusTextInput(calculatorInput);
        }
    }

    Timer {
        id: brightnessFocusTimer
        interval: 90
        repeat: false
        onTriggered: {
            if (root.brightnessExpansionOpen)
                root.focusTextInput(brightnessPercentInput, true);
        }
    }

    Timer {
        id: networkPasswordFocusTimer
        interval: 80
        repeat: false
        onTriggered: {
            if (root.networkExpansionOpen && root.networkSelectedSecurity.length > 0)
                root.focusTextInput(networkPasswordInput, true);
        }
    }

    Timer {
        id: launcherFocusTimer
        interval: 80
        repeat: false
        onTriggered: {
            if (root.appLauncherExpansionOpen)
                root.focusTextInput(launcherSearchInput, true);
        }
    }

    // The mouse cursor stays in one physical place while wheel scrolling moves
    // delegate rows beneath it. Ignore synthetic hover changes briefly so the
    // selection follows the wheel, not whichever row happens to slide under it.
    Timer {
        id: launcherWheelUnlockTimer
        interval: 220
        repeat: false
        onTriggered: root.launcherWheelSelectionLock = false
    }

    Process {
        id: launcherAppsProcess
        command: ["python3", Quickshell.shellDir + "/scripts/applications-list.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.launcherAppsOutput = this.text.trim();
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    root.launcherLoadError = this.text.trim();
            }
        }
        onExited: {
            root.launcherAppsLoading = false;
            if (exitCode !== 0) {
                root.launcherLoadError = root.launcherLoadError || "Could not load applications";
                root.launcherApps = [];
                return;
            }
            try {
                var parsedApps = JSON.parse(root.launcherAppsOutput || "[]");
                root.launcherApps = Array.isArray(parsedApps) ? parsedApps : [];
            } catch (error) {
                root.launcherApps = [];
                root.launcherLoadError = "Could not parse the application list";
            }
            root.launcherSelectedIndex = 0;
            root.launcherScrollStartIndex = 0;
        }
    }

    Process {
        id: appLaunchProcess
        command: ["gio", "launch", ""]
        running: false
    }

    Process {
        id: volumeModuleClickProcess
        command: ["bash", Quickshell.shellDir + "/scripts/toggle-audio-ui.sh"]
        running: false
        onExited: {
            if (exitCode === 42) {
                // pwvucontrol was running; the helper has closed it. Do not open the in-bar mixer.
                root.volumeExpansionOpen = false;
                root.musicPreviewOpen = false;
                musicPreviewCloseTimer.stop();
                return;
            }

            var shouldOpen = !root.volumeExpansionOpen;
            root.networkExpansionOpen = false;
            root.bluetoothExpansionOpen = false;
            root.batteryExpansionOpen = false;
            root.calendarExpansionOpen = false;
            root.calculatorExpansionOpen = false;
            root.powerExpansionOpen = false;
            root.brightnessExpansionOpen = false;
            root.musicPreviewOpen = false;
            musicPreviewCloseTimer.stop();
            root.volumeExpansionOpen = shouldOpen;
        }
    }

    // Refresh the current-date highlight at least once a minute; if the user
    // was still viewing/selecting today's date, keep the selection on the new day.
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: {
            var previousToday = root.todayDate;
            var nextToday = new Date();
            if (!root.calendarSameDate(previousToday, nextToday)) {
                var selectionWasToday = root.calendarSameDate(root.selectedCalendarDate, previousToday);
                var viewWasCurrentMonth = root.calendarViewMonth === previousToday.getMonth()
                    && root.calendarViewYear === previousToday.getFullYear();
                root.todayDate = nextToday;
                if (selectionWasToday)
                    root.selectedCalendarDate = nextToday;
                if (viewWasCurrentMonth) {
                    root.calendarViewMonth = nextToday.getMonth();
                    root.calendarViewYear = nextToday.getFullYear();
                }
            }
        }
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

    // Bind all PipeWire nodes so the master, microphone, and per-application sliders
    // can read and write live audio volumes without polling wpctl.
    PwObjectTracker { objects: Pipewire.nodes.values }

    Timer {
        id: brightnessSetDebounce
        interval: 25
        repeat: false
        onTriggered: root.dispatchPendingBrightness()
    }
    Process {
        id: brightnessSetProcess
        command: ["brightnessctl", "-d", "intel_backlight", "set", "0%"]
        running: false
        onExited: {
            if (root.pendingBrightnessPercent >= 0)
                brightnessSetDebounce.restart();
        }
    }

    // Status polls. Avoid polling volume: PipeWire updates it reactively.
    Poll { id: idlePoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "idle"]; interval: 1000 }
    Poll { id: cpuPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "cpu"]; interval: 2000 }
    Poll { id: memoryPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "memory"]; interval: 2000 }
    Poll { id: windowPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "window"]; interval: 1000 }
    Poll { id: occupiedPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "occupied"]; interval: 500 }
    Poll { id: batteryPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "battery"]; interval: 1000 }
    Poll { id: volumePoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "volume"]; interval: 1000 }
    Poll {
        id: capsLockPoll
        command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "capslock"]
        interval: 120
        onValueChanged: root.updateCapsLockState(capsLockPoll.value)
    }
    Poll { id: backlightPoll; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "backlight"]; interval: 100 }
    // Listen for Hyprland's activelayout event instead of polling every 500 ms.
    // The helper falls back to a quick poll if the event socket is unavailable.
    Process {
        id: languageEventProcess
        command: ["/bin/bash", Quickshell.shellDir + "/scripts/language-watch.sh"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var nextValue = String(data).trim()
                if (nextValue.length > 0)
                    root.languageValue = nextValue
            }
        }
        onExited: languageReconnectTimer.restart()
    }
    Timer {
        id: languageReconnectTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (!languageEventProcess.running)
                languageEventProcess.running = true
        }
    }
    Timer {
        id: musicPreviewCloseTimer
        interval: 130
        repeat: false
        onTriggered: {
            if (!volumeMouse.containsMouse && !musicPreviewHoverHandler.hovered)
                root.musicPreviewOpen = false;
        }
    }

    Timer {
        id: bluetoothRefreshTimer
        interval: 650
        repeat: false
        onTriggered: {
            if (!bluetoothStatusProcess.running)
                bluetoothStatusProcess.running = true;
        }
    }

    Timer {
        id: bluetoothScanStopTimer
        interval: 12000
        repeat: false
        onTriggered: {
            if (root.bluetoothDiscovering)
                root.runBluetoothAction(["scan", "off"]);
        }
    }

    // Poll bluetoothctl directly so the module does not depend on a separate helper script.
    Process {
        id: bluetoothStatusProcess
        command: ["/bin/bash", "-lc", "controller=\"$(bluetoothctl show 2>/dev/null)\"; available=$(printf '%s\\n' \"$controller\" | grep -q 'Controller ' && echo yes || echo no); powered=$(printf '%s\\n' \"$controller\" | awk -F': ' '/Powered:/ {print $2; exit}'); discovering=$(printf '%s\\n' \"$controller\" | awk -F': ' '/Discovering:/ {print $2; exit}'); printf 'STATE|%s|%s|%s\\n' \"${available:-no}\" \"${powered:-no}\" \"${discovering:-no}\"; bluetoothctl devices 2>/dev/null | while read -r tag mac name; do [ \"$tag\" = Device ] || continue; info=$(bluetoothctl info \"$mac\" 2>/dev/null); connected=$(printf '%s\\n' \"$info\" | awk -F': ' '/Connected:/ {print $2; exit}'); paired=$(printf '%s\\n' \"$info\" | awk -F': ' '/Paired:/ {print $2; exit}'); printf 'DEVICE|%s|%s|%s|%s\\n' \"$mac\" \"${connected:-no}\" \"${paired:-no}\" \"$name\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parseBluetoothSnapshot(this.text.trim());
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0 && !root.bluetoothAvailable)
                    root.bluetoothMessage = "Bluetooth adapter unavailable";
            }
        }
        onExited: {
            if (root.bluetoothAvailable && root.bluetoothPowered && root.bluetoothMessage === "Bluetooth is off")
                root.bluetoothMessage = "";
        }
    }

    Timer {
        id: bluetoothStatusTimer
        interval: 4500
        repeat: true
        running: true
        onTriggered: {
            if (!bluetoothStatusProcess.running)
                bluetoothStatusProcess.running = true;
        }
    }

    Process {
        id: bluetoothActionProcess
        command: ["bluetoothctl", "show"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.bluetoothActionOutput = this.text.trim() }
        stderr: StdioCollector { onStreamFinished: root.bluetoothActionError = this.text.trim() }
        onExited: {
            if (exitCode !== 0 && root.bluetoothActionError.length > 0)
                root.bluetoothMessage = root.bluetoothActionError;
            else
                root.bluetoothMessage = "";
            bluetoothRefreshTimer.restart();
        }
    }

    Timer {
        id: networkRefreshTimer
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshNetworkList(false)
    }

    Timer {
        id: networkInfoStepTimer
        interval: 1
        repeat: false
        onTriggered: {
            if (root.networkInfoBusy) {
                root.launchNetworkInfoStep();
            } else if (root.networkRefreshQueued) {
                var scanAgain = root.networkQueuedScan;
                root.networkRefreshQueued = false;
                root.networkQueuedScan = false;
                root.refreshNetworkList(scanAgain);
            }
        }
    }

    Process {
        id: networkInfoProcess
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.networkInfoOutput = this.text.trim();
        }
        onExited: root.consumeNetworkInfoStep(exitCode, root.networkInfoOutput)
    }

    Process {
        id: networkCommandProcess
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.networkCommandOutput = this.text.trim();
        }
        stderr: StdioCollector {
            onStreamFinished: root.networkCommandError = this.text.trim();
        }
        onExited: {
            if (root.networkCommandFallback && exitCode !== 0) {
                root.networkCommandFallback = false;
                var fallbackArgs = ["nmcli", "--wait", "12", "device", "wifi", "connect", root.networkCommandSsid];
                if (root.networkCommandPassword.length > 0)
                    fallbackArgs.push("password", root.networkCommandPassword);
                root.networkCommandOutput = "";
                root.networkCommandError = "";
                command = fallbackArgs;
                running = true;
                return;
            }
            root.networkCommandFallback = false;
            if (exitCode !== 0 && root.networkCommandError.length > 0) {
                var stateCopy = Object.assign({}, root.networkState);
                stateCopy.error = root.networkCommandError;
                root.networkState = stateCopy;
            }
            networkAfterActionTimer.restart();
        }
    }

    Timer {
        id: networkAfterActionTimer
        interval: 800
        repeat: false
        onTriggered: root.refreshNetworkList(false)
    }

    // Actions copied from the Waybar module on-click settings.
    Command { id: idleAction; command: ["/bin/bash", Quickshell.shellDir + "/scripts/status.sh", "toggle-idle"] }
    Command { id: missionCenterAction; command: ["/bin/bash", "-lc", "missioncenter"] }
    Command { id: audioAction; command: ["/bin/bash", "-lc", "com.saivert.pwvucontrol >/dev/null 2>&1 &"] }
    Command { id: shutdownAction; command: ["systemctl", "poweroff"] }
    Command { id: rebootAction; command: ["systemctl", "reboot"] }
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
                    duration: 210
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
                    root.calendarExpansionOpen = false;
                    root.calculatorExpansionOpen = false;
                    root.powerExpansionOpen = false;
                    root.brightnessExpansionOpen = false;
                    root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                    root.batteryExpansionOpen = true;
                }
                onExited: batteryCloseTimer.restart()
            }
        }

        // Click-open brightness panel: keyboard percentage entry above a live slider.
        Item {
            id: brightnessExpansion
            property real revealProgress: root.brightnessExpansionOpen ? 1.0 : 0.0
            property real brightnessCenterX: rightModules.x + backlightModule.x + backlightModule.width / 2
            readonly property int shoulderSize: 5
            width: 260
            height: 126
            x: Math.max(4, Math.min(panel.width - width - 4, brightnessCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.brightnessExpansionOpen
            z: root.brightnessExpansionOpen ? 145 : 105

            Behavior on revealProgress {
                NumberAnimation {
                    duration: root.targetScreen && root.targetScreen.name === "eDP-1" ? 160 : 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: brightnessBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: brightnessBubbleShape.width / 2
                    origin.y: 9
                    yScale: brightnessExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 5;
                    var shoulderSize = brightnessExpansion.shoulderSize;
                    var inset = 0.5, left = shoulderSize + inset, right = w - shoulderSize - inset;
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(right + shoulderSize * 0.3, joinY, right, joinY + shoulderSize * 0.3, right, joinY + shoulderSize);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3, left - shoulderSize * 0.3, joinY, left - shoulderSize, joinY);
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5, left + 0.5, joinY + shoulderSize * 0.3, left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(right - 0.5, joinY + shoulderSize * 0.3, right + shoulderSize * 0.3, joinY + 0.5, right + shoulderSize, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString();
                    ctx.lineWidth = 1;
                    ctx.lineCap = "butt";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Rectangle {
                id: brightnessInner
                x: 12; y: 14
                width: parent.width - 24; height: parent.height - 28
                radius: 4
                color: root.barBg
                opacity: Math.max(0, Math.min(1, (brightnessExpansion.revealProgress - 0.28) / 0.55))
                visible: brightnessExpansion.revealProgress > 0.28

                Item {
                    id: brightnessContent
                    anchors.fill: parent
                    anchors.margins: 8

                    Rectangle { x: 0; y: 0; width: parent.width; height: 32; radius: 4; color: root.groupBg }
                    TextInput {
                        id: brightnessPercentInput
                        x: 8; y: 0; width: parent.width - 42; height: 32
                        color: root.textColor
                        selectionColor: root.accent
                        selectedTextColor: root.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        validator: IntValidator { bottom: 0; top: 100 }
                        inputMethodHints: Qt.ImhDigitsOnly
                        onTextEdited: root.brightnessDraft = text
                        onEditingFinished: root.commitBrightnessInput(text)
                        Keys.onReturnPressed: {
                            root.commitBrightnessInput(text);
                            brightnessPercentInput.focus = false;
                        }
                        Keys.onEnterPressed: {
                            root.commitBrightnessInput(text);
                            brightnessPercentInput.focus = false;
                        }
                        Keys.onEscapePressed: root.brightnessExpansionOpen = false
                    }
                    Binding {
                        target: brightnessPercentInput
                        property: "text"
                        value: root.brightnessDraft
                        when: !brightnessPercentInput.activeFocus
                    }
                    Text {
                        x: parent.width - 29; y: 0; width: 22; height: 32
                        text: "%"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle { x: 0; y: 40; width: parent.width; height: 34; radius: 4; color: root.groupBg }
                    Slider {
                        id: brightnessSlider
                        x: 7; y: 40; width: parent.width - 14; height: 34
                        from: 0; to: 100; stepSize: 1
                        onMoved: root.requestBrightnessPercent(value)
                        background: Rectangle {
                            x: brightnessSlider.leftPadding
                            y: brightnessSlider.topPadding + (brightnessSlider.availableHeight - height) / 2
                            width: brightnessSlider.availableWidth
                            height: 4; radius: 2; color: root.barBg
                            Rectangle { width: brightnessSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: root.accent }
                        }
                        handle: Rectangle {
                            width: 12; height: 12; radius: 6
                            x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                            y: brightnessSlider.topPadding + (brightnessSlider.availableHeight - height) / 2
                            color: root.textColor; border.color: root.accent; border.width: 1
                        }
                    }
                    Binding {
                        target: brightnessSlider
                        property: "value"
                        value: root.brightnessPercentValue
                        when: !brightnessSlider.pressed
                    }
                }
            }
        }

        // Hover-only media preview. It shares the volume module anchor and the same attached extension profile.
        Item {
            id: musicPreviewExpansion
            property real revealProgress: root.musicPreviewOpen && root.mediaAvailable && !root.volumeExpansionOpen ? 1.0 : 0.0
            property real volumeCenterX: rightModules.x + volumeModule.x + volumeModule.width / 2
            readonly property int shoulderSize: 5
            width: 330
            height: 112
            x: Math.max(4, Math.min(panel.width - width - 4, volumeCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || (root.musicPreviewOpen && root.mediaAvailable && !root.volumeExpansionOpen)
            z: 147

            Behavior on revealProgress {
                NumberAnimation {
                    duration: root.targetScreen && root.targetScreen.name === "eDP-1" ? 160 : 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: musicPreviewBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: musicPreviewBubbleShape.width / 2
                    origin.y: 9
                    yScale: musicPreviewExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 8;
                    var shoulderSize = musicPreviewExpansion.shoulderSize;
                    var inset = 0.5, left = shoulderSize + inset, right = w - shoulderSize - inset;
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(right + shoulderSize * 0.3, joinY, right, joinY + shoulderSize * 0.3, right, joinY + shoulderSize);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3, left - shoulderSize * 0.3, joinY, left - shoulderSize, joinY);
                    ctx.closePath(); ctx.fillStyle = root.barBg.toString(); ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5, left + 0.5, joinY + shoulderSize * 0.3, left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(right - 0.5, joinY + shoulderSize * 0.3, right + shoulderSize * 0.3, joinY + 0.5, right + shoulderSize, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString(); ctx.lineWidth = 1; ctx.lineCap = "butt"; ctx.lineJoin = "round"; ctx.stroke();
                }
            }

            Rectangle {
                x: 12; y: 14; width: parent.width - 24; height: parent.height - 28
                radius: 4; color: root.barBg
                opacity: Math.max(0, Math.min(1, (musicPreviewExpansion.revealProgress - 0.28) / 0.55))
                visible: musicPreviewExpansion.revealProgress > 0.28
                Rectangle {
                    x: 0; y: 0; width: parent.width; height: parent.height; radius: 4; color: root.groupBg
                }
                Text {
                    x: 8; y: 8; width: parent.width - 116; height: 24
                    text: root.mediaTitle; color: root.textColor
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                    elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                }
                Text {
                    x: 8; y: 33; width: parent.width - 116; height: 20
                    text: root.mediaArtist.length ? root.mediaArtist : root.mediaPlayerName
                    color: root.emptyColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                    elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                }
                Row {
                    x: parent.width - 108; y: 17; spacing: 4
                    Repeater {
                        model: ["", root.mediaPlaying ? "" : "", ""]
                        delegate: Item {
                            width: 30; height: 34
                            property bool isMusicButtonHovered: previewMusicControlMouse.containsMouse
                            Rectangle { anchors.fill: parent; radius: 4; color: isMusicButtonHovered ? root.accent : root.barBg }
                            Text {
                                anchors.fill: parent; text: modelData; color: root.textColor
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            MouseArea {
                                id: previewMusicControlMouse
                                anchors.fill: parent; hoverEnabled: true
                                enabled: root.activeMediaPlayer && (index === 0 ? root.activeMediaPlayer.canGoPrevious
                                    : (index === 1 ? root.activeMediaPlayer.canTogglePlaying : root.activeMediaPlayer.canGoNext))
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (index === 0) root.previousMusicTrack();
                                    else if (index === 1) root.toggleMusicPlayback();
                                    else root.nextMusicTrack();
                                }
                            }
                        }
                    }
                }
            }
            HoverHandler {
                id: musicPreviewHoverHandler
                onHoveredChanged: {
                    if (hovered)
                        musicPreviewCloseTimer.stop();
                    else if (root.musicPreviewOpen)
                        musicPreviewCloseTimer.restart();
                }
            }
        }

        // Click-open mixer: default output, microphone input, and live application playback streams.
        Item {
            id: volumeExpansion
            property real revealProgress: root.volumeExpansionOpen ? 1.0 : 0.0
            property real volumeCenterX: rightModules.x + volumeModule.x + volumeModule.width / 2
            readonly property int shoulderSize: 5
            width: 360
            height: 480
            x: Math.max(4, Math.min(panel.width - width - 4, volumeCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.volumeExpansionOpen
            z: root.volumeExpansionOpen ? 146 : 106

            Behavior on revealProgress {
                NumberAnimation {
                    duration: root.targetScreen && root.targetScreen.name === "eDP-1" ? 160 : 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: volumeBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: volumeBubbleShape.width / 2
                    origin.y: 9
                    yScale: volumeExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 8;
                    var shoulderSize = volumeExpansion.shoulderSize;
                    var inset = 0.5, left = shoulderSize + inset, right = w - shoulderSize - inset;
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(right + shoulderSize * 0.3, joinY, right, joinY + shoulderSize * 0.3, right, joinY + shoulderSize);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3, left - shoulderSize * 0.3, joinY, left - shoulderSize, joinY);
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5, left + 0.5, joinY + shoulderSize * 0.3, left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(right - 0.5, joinY + shoulderSize * 0.3, right + shoulderSize * 0.3, joinY + 0.5, right + shoulderSize, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString();
                    ctx.lineWidth = 1;
                    ctx.lineCap = "butt";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Rectangle {
                id: volumeInner
                x: 12; y: 14
                width: parent.width - 24; height: parent.height - 28
                radius: 4
                color: root.barBg
                opacity: Math.max(0, Math.min(1, (volumeExpansion.revealProgress - 0.28) / 0.55))
                visible: volumeExpansion.revealProgress > 0.28

                Item {
                    id: volumeContent
                    anchors.fill: parent
                    anchors.margins: 8

                    Rectangle {
                        x: 0; y: 0; width: parent.width; height: 70; radius: 4; color: root.groupBg
                    }
                    Text {
                        x: 8; y: 5; width: parent.width - 120; height: 20
                        text: root.mediaAvailable ? root.mediaTitle : "No active player"
                        color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        x: 8; y: 27; width: parent.width - 120; height: 18
                        text: root.mediaAvailable ? (root.mediaArtist.length ? root.mediaArtist : root.mediaPlayerName) : "Play music to see controls"
                        color: root.emptyColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    }
                    Row {
                        x: parent.width - 106; y: 17; spacing: 4
                        Repeater {
                            model: ["", root.mediaPlaying ? "" : "", ""]
                            delegate: Item {
                                width: 30; height: 34
                                property bool isMusicButtonHovered: musicControlMouse.containsMouse
                                Rectangle {
                                    anchors.fill: parent; radius: 4
                                    color: isMusicButtonHovered ? root.accent : root.barBg
                                }
                                Text {
                                    anchors.fill: parent; text: modelData; color: root.textColor
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                                MouseArea {
                                    id: musicControlMouse
                                    anchors.fill: parent; hoverEnabled: true
                                    enabled: root.activeMediaPlayer && (index === 0 ? root.activeMediaPlayer.canGoPrevious
                                        : (index === 1 ? root.activeMediaPlayer.canTogglePlaying : root.activeMediaPlayer.canGoNext))
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (index === 0) root.previousMusicTrack();
                                        else if (index === 1) root.toggleMusicPlayback();
                                        else root.nextMusicTrack();
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { x: 0; y: 78; width: parent.width; height: 58; radius: 4; color: root.groupBg }
                    Text {
                        x: 8; y: 82; width: parent.width - 16; height: 18
                        text: "System Volume"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                    }
                    Slider {
                        id: masterVolumeSlider
                        x: 6; y: 103; width: parent.width - 58; height: 28
                        from: 0; to: 150; stepSize: 1
                        onMoved: {
                            if (root.audioSink && root.audioSink.audio)
                                root.audioSink.audio.volume = value / 100;
                        }
                        background: Rectangle {
                            x: masterVolumeSlider.leftPadding
                            y: masterVolumeSlider.topPadding + (masterVolumeSlider.availableHeight - height) / 2
                            width: masterVolumeSlider.availableWidth; height: 4; radius: 2; color: root.barBg
                            Rectangle { width: masterVolumeSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: root.accent }
                        }
                        handle: Rectangle {
                            width: 12; height: 12; radius: 6
                            x: masterVolumeSlider.leftPadding + masterVolumeSlider.visualPosition * (masterVolumeSlider.availableWidth - width)
                            y: masterVolumeSlider.topPadding + (masterVolumeSlider.availableHeight - height) / 2
                            color: root.textColor; border.color: root.accent; border.width: 1
                        }
                    }
                    Binding {
                        target: masterVolumeSlider
                        property: "value"
                        value: root.volumePercent
                        when: !masterVolumeSlider.pressed
                    }
                    Text {
                        x: parent.width - 48; y: 103; width: 42; height: 28
                        text: root.volumePercent + "%"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }

                    Item {
                        id: microphoneVolumeRow
                        x: 0; y: 142; width: parent.width; height: root.audioSource && root.audioSource.audio ? 48 : 0
                        visible: root.audioSource && root.audioSource.audio
                        Rectangle { anchors.fill: parent; radius: 4; color: root.groupBg }
                        Text {
                            x: 8; y: 1; width: parent.width - 16; height: 16
                            text: "Microphone"; color: root.textColor
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        Slider {
                            id: microphoneVolumeSlider
                            x: 5; y: 17; width: parent.width - 52; height: 28
                            from: 0; to: 150; stepSize: 1
                            onMoved: {
                                if (root.audioSource && root.audioSource.audio)
                                    root.audioSource.audio.volume = value / 100;
                            }
                            background: Rectangle {
                                x: microphoneVolumeSlider.leftPadding
                                y: microphoneVolumeSlider.topPadding + (microphoneVolumeSlider.availableHeight - height) / 2
                                width: microphoneVolumeSlider.availableWidth; height: 4; radius: 2; color: root.barBg
                                Rectangle { width: microphoneVolumeSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: root.accent }
                            }
                            handle: Rectangle {
                                width: 12; height: 12; radius: 6
                                x: microphoneVolumeSlider.leftPadding + microphoneVolumeSlider.visualPosition * (microphoneVolumeSlider.availableWidth - width)
                                y: microphoneVolumeSlider.topPadding + (microphoneVolumeSlider.availableHeight - height) / 2
                                color: root.textColor; border.color: root.accent; border.width: 1
                            }
                        }
                        Binding {
                            target: microphoneVolumeSlider
                            property: "value"
                            value: root.audioSource && root.audioSource.audio ? Math.round(root.audioSource.audio.volume * 100) : 0
                            when: !microphoneVolumeSlider.pressed && root.audioSource && root.audioSource.audio
                        }
                        Text {
                            x: parent.width - 43; y: 17; width: 37; height: 28
                            text: root.audioSource && root.audioSource.audio ? Math.round(root.audioSource.audio.volume * 100) + "%" : ""
                            color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        x: 0; y: microphoneVolumeRow.visible ? 194 : 142
                        width: parent.width; height: 18
                        text: "Application Streams"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                    }

                    Flickable {
                        id: audioStreamsFlickable
                        x: 0
                        y: microphoneVolumeRow.visible ? 214 : 162
                        width: parent.width
                        height: Math.max(45, parent.height - y - 46)
                        clip: true
                        contentWidth: width
                        contentHeight: Math.max(audioStreamColumn.height, 34)

                        Text {
                            x: 5; y: 0; width: parent.width - 10; height: 30
                            visible: root.playbackStreamCount === 0
                            text: "No active applications"
                            color: root.emptyColor
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                        }

                        Column {
                            id: audioStreamColumn
                            width: audioStreamsFlickable.width
                            height: childrenRect.height
                            spacing: 5

                            Repeater {
                                id: audioStreamsRepeater
                                model: Pipewire.nodes
                                delegate: Item {
                                    id: audioStreamRow
                                    property var node: modelData
                                    property bool isPlaybackStream: node && node.isStream && !node.isSink && node.audio !== null
                                    property int pendingStreamVolumePercent: -1
                                    width: audioStreamColumn.width
                                    height: isPlaybackStream ? 48 : 0
                                    visible: isPlaybackStream

                                    // Keep the stream bound so its live volume is reflected in the UI.
                                    PwObjectTracker {
                                        objects: audioStreamRow.isPlaybackStream ? [audioStreamRow.node] : []
                                    }

                                    // Some PipeWire application streams expose a volume property that
                                    // appears writable in QML but does not actually change the stream
                                    // on all WirePlumber setups. Use wpctl with this exact node ID.
                                    function requestStreamVolume(percent) {
                                        pendingStreamVolumePercent = Math.max(0, Math.min(150, Math.round(percent)));
                                        // Try Quickshell's native PipeWire control and also update the
                                        // PulseAudio sink-input through the helper (many apps use pipewire-pulse).
                                        if (node && node.audio)
                                            node.audio.volume = pendingStreamVolumePercent / 100;
                                        streamVolumeDebounce.restart();
                                    }

                                    function dispatchPendingStreamVolume() {
                                        if (!node || pendingStreamVolumePercent < 0 || streamVolumeProcess.running)
                                            return;
                                        var requestedPercent = pendingStreamVolumePercent;
                                        pendingStreamVolumePercent = -1;
                                        var props = node.properties || {};
                                        streamVolumeProcess.command = [
                                            "python3", Quickshell.shellDir + "/scripts/audio-stream-volume.py",
                                            String(node.id), String(requestedPercent),
                                            String(props["application.process.id"] || ""),
                                            String(props["application.name"] || ""),
                                            String(props["media.name"] || ""),
                                            String(node.name || ""),
                                            String(props["pulse.id"] || "")
                                        ];
                                        streamVolumeProcess.running = true;
                                    }

                                    Timer {
                                        id: streamVolumeDebounce
                                        interval: 35
                                        repeat: false
                                        onTriggered: audioStreamRow.dispatchPendingStreamVolume()
                                    }

                                    Process {
                                        id: streamVolumeProcess
                                        command: ["python3", Quickshell.shellDir + "/scripts/audio-stream-volume.py", "0", "100"]
                                        running: false
                                        onExited: {
                                            if (audioStreamRow.pendingStreamVolumePercent >= 0)
                                                streamVolumeDebounce.restart();
                                        }
                                    }

                                    Rectangle { anchors.fill: parent; radius: 4; color: root.groupBg }
                                    Text {
                                        x: 8; y: 1; width: parent.width - 16; height: 16
                                        text: root.audioStreamName(audioStreamRow.node)
                                        color: root.textColor
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                    Slider {
                                        id: streamVolumeSlider
                                        x: 5; y: 17; width: parent.width - 52; height: 28
                                        from: 0; to: 150; stepSize: 1
                                        onMoved: audioStreamRow.requestStreamVolume(value)
                                        background: Rectangle {
                                            x: streamVolumeSlider.leftPadding
                                            y: streamVolumeSlider.topPadding + (streamVolumeSlider.availableHeight - height) / 2
                                            width: streamVolumeSlider.availableWidth; height: 4; radius: 2; color: root.barBg
                                            Rectangle { width: streamVolumeSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: root.accent }
                                        }
                                        handle: Rectangle {
                                            width: 12; height: 12; radius: 6
                                            x: streamVolumeSlider.leftPadding + streamVolumeSlider.visualPosition * (streamVolumeSlider.availableWidth - width)
                                            y: streamVolumeSlider.topPadding + (streamVolumeSlider.availableHeight - height) / 2
                                            color: root.textColor; border.color: root.accent; border.width: 1
                                        }
                                    }
                                    Binding {
                                        target: streamVolumeSlider
                                        property: "value"
                                        value: audioStreamRow.node && audioStreamRow.node.audio ? Math.round(audioStreamRow.node.audio.volume * 100) : 0
                                        when: !streamVolumeSlider.pressed && audioStreamRow.node && audioStreamRow.node.audio
                                    }
                                    Text {
                                        x: parent.width - 43; y: 17; width: 37; height: 28
                                        text: audioStreamRow.node && audioStreamRow.node.audio ? Math.round(audioStreamRow.node.audio.volume * 100) + "%" : ""
                                        color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                                        horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: openPwvucontrolButton
                        x: 0; y: parent.height - 38; width: parent.width; height: 34
                        Rectangle {
                            anchors.fill: parent; radius: 4
                            color: pwvucontrolMouse.containsMouse ? root.accent : root.groupBg
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "Open pwvucontrol"
                            color: root.textColor
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        }
                        MouseArea {
                            id: pwvucontrolMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                                audioAction.run();
                            }
                        }
                    }
                }
            }
        }

        // Click-open application launcher, using the same .desktop inventory and
        // Rofi's drun history cache to keep familiar entries near the top.
        Item {
            id: appLauncherExpansion
            property real revealProgress: root.appLauncherExpansionOpen ? 1.0 : 0.0
            readonly property int shoulderSize: 5
            readonly property real anchorCenterX: centerModules.x + rofiCapsule.x + rofiCapsule.width / 2
            width: 350
            height: 450
            x: Math.max(4, Math.min(panel.width - width - 4, anchorCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.appLauncherExpansionOpen
            z: 190

            Behavior on revealProgress {
                NumberAnimation {
                    duration: 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: appLauncherBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: appLauncherBubbleShape.width / 2
                    origin.y: 9
                    yScale: appLauncherExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 5;
                    var shoulder = appLauncherExpansion.shoulderSize;
                    var left = shoulder + 0.5, right = w - shoulder - 0.5;
                    ctx.beginPath();
                    ctx.moveTo(left - shoulder, joinY);
                    ctx.lineTo(right + shoulder, joinY);
                    ctx.bezierCurveTo(right + shoulder * 0.3, joinY, right, joinY + shoulder * 0.3, right, joinY + shoulder);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulder);
                    ctx.bezierCurveTo(left, joinY + shoulder * 0.3, left - shoulder * 0.3, joinY, left - shoulder, joinY);
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();
                }
            }

            Item {
                id: appLauncherInner
                x: 0; y: 9
                width: parent.width; height: parent.height - 9
                opacity: Math.max(0, Math.min(1, (appLauncherExpansion.revealProgress - 0.28) / 0.55))
                visible: appLauncherExpansion.revealProgress > 0.28

                Item {
                    id: appLauncherContent
                    anchors.fill: parent
                    anchors.margins: 10

                    Rectangle {
                        id: appLauncherSearchBackground
                        // Match the application row's inset and height so this reads as one selected-sized item.
                        x: 10; y: 0
                        width: parent.width - 20; height: 46
                        radius: 5
                        color: root.groupBg

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: "#e4f3f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                        }
                        TextInput {
                            id: launcherSearchInput
                            anchors.left: parent.left
                            anchors.leftMargin: 34
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            text: root.launcherQuery
                            color: "#e4f3f0"
                            selectionColor: root.accent
                            selectedTextColor: "#e4f3f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            onTextChanged: {
                                if (root.launcherQuery !== text)
                                    root.launcherQuery = text;
                            }
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Down) {
                                    root.moveLauncherSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveLauncherSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    root.appLauncherExpansionOpen = false;
                                    root.keyboardInputRequested = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.launchSelectedApplication(null);
                                    event.accepted = true;
                                }
                            }
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 34
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search"
                            color: "#e4f3f0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            visible: launcherSearchInput.text.length === 0
                        }
                    }

                    Item {
                        id: appLauncherList
                        x: 0; y: 56
                        width: parent.width
                        height: parent.height - 61

                        Text {
                            anchors.centerIn: parent
                            visible: root.launcherAppsLoading
                            text: "Loading applications…"
                            color: root.emptyColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !root.launcherAppsLoading && root.launcherFilteredApps.length === 0
                            text: root.launcherLoadError.length ? root.launcherLoadError : "No matching applications"
                            color: root.emptyColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }

                        Column {
                            id: appLauncherRows
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 5
                            visible: !root.launcherAppsLoading && root.launcherFilteredApps.length > 0

                            Repeater {
                                model: root.launcherVisibleApps
                                delegate: Item {
                                    id: launcherAppRow
                                    required property int index
                                    required property var modelData
                                    readonly property int appIndex: root.launcherScrollStartIndex + index
                                    width: appLauncherRows.width
                                    height: 46

                                    Rectangle {
                                        x: 10; y: 0
                                        width: parent.width - 20; height: parent.height
                                        radius: 5
                                        color: root.launcherSelectedIndex === launcherAppRow.appIndex ? root.accent : root.barBg
                                    }
                                    Image {
                                        id: launcherAppIcon
                                        anchors.left: parent.left
                                        anchors.leftMargin: 18
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 32
                                        height: 32
                                        asynchronous: true
                                        smooth: true
                                        mipmap: true
                                        sourceSize.width: 64
                                        sourceSize.height: 64
                                        fillMode: Image.PreserveAspectFit
                                        source: String(launcherAppRow.modelData.icon || "").startsWith("/")
                                            ? launcherAppRow.modelData.icon
                                            : Quickshell.iconPath(launcherAppRow.modelData.icon || "application-x-executable", "application-x-executable")
                                    }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 60
                                        anchors.right: parent.right
                                        anchors.rightMargin: 18
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: launcherAppRow.modelData.name || launcherAppRow.modelData.desktopId
                                        color: "#e4f3f0"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 16
                                        elide: Text.ElideRight
                                    }
                                    MouseArea {
                                        id: launcherRowMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            if (!root.launcherWheelSelectionLock)
                                                root.launcherSelectedIndex = launcherAppRow.appIndex;
                                        }
                                        onPositionChanged: function(mouse) {
                                            if (!root.launcherWheelSelectionLock)
                                                root.launcherSelectedIndex = launcherAppRow.appIndex;
                                        }
                                        onClicked: root.launchSelectedApplication(launcherAppRow.modelData)
                                        onWheel: function(wheel) {
                                            root.launcherWheelSelectionLock = true;
                                            launcherWheelUnlockTimer.restart();
                                            root.moveLauncherSelection(wheel.angleDelta.y > 0 ? -1 : 1);
                                            wheel.accepted = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Click-open calendar. The outer shape uses the battery popup's attached
        // bracket profile and animation curve; the inner calendar uses groupBg.
        Item {
            id: calendarExpansion
            property real revealProgress: root.calendarExpansionOpen ? 1.0 : 0.0
            property real calendarCenterX: rightModules.x + clockModule.x + clockModule.width / 2
            readonly property int shoulderSize: 5
            width: 300
            height: 330
            x: Math.max(4, Math.min(panel.width - width - 4, calendarCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.calendarExpansionOpen
            z: 110

            Behavior on revealProgress {
                NumberAnimation {
                    duration: 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: calendarBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: calendarBubbleShape.width / 2
                    origin.y: 9
                    yScale: calendarExpansion.revealProgress
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
                    var joinY = 9;
                    var radius = 8;
                    var shoulderSize = calendarExpansion.shoulderSize;
                    var inset = 0.5;
                    var left = shoulderSize + inset;
                    var right = w - shoulderSize - inset;

                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(right + shoulderSize * 0.3, joinY,
                                      right, joinY + shoulderSize * 0.3,
                                      right, joinY + shoulderSize);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3,
                                      left - shoulderSize * 0.3, joinY,
                                      left - shoulderSize, joinY);
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();

                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5,
                                      left + 0.5, joinY + shoulderSize * 0.3,
                                      left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(right - 0.5, joinY + shoulderSize * 0.3,
                                      right + shoulderSize * 0.3, joinY + 0.5,
                                      right + shoulderSize, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString();
                    ctx.lineWidth = 1;
                    ctx.lineCap = "butt";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Rectangle {
                id: calendarInner
                x: 12
                y: 14
                width: parent.width - 24
                height: parent.height - 28
                radius: 4
                color: root.groupBg
                opacity: Math.max(0, Math.min(1, (calendarExpansion.revealProgress - 0.28) / 0.55))
                visible: calendarExpansion.revealProgress > 0.28

                Item {
                    id: calendarContent
                    anchors.fill: parent
                    anchors.margins: 8

                    Row {
                        id: calendarNavigation
                        x: 0
                        y: 4
                        width: parent.width
                        height: 25
                        spacing: 3

                        Repeater {
                            model: ["«", "‹"]
                            delegate: Item {
                                width: 22
                                height: 25
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: previousNavMouse.containsMouse ? root.barBg : "transparent"
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.textColor
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 17
                                }
                                MouseArea {
                                    id: previousNavMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (index === 0) root.moveCalendarYear(-1);
                                        else root.moveCalendarMonth(-1);
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width - (4 * 22) - (4 * parent.spacing)
                            height: 25
                            Text {
                                anchors.centerIn: parent
                                text: root.calendarMonthName(root.calendarViewMonth) + " " + root.calendarViewYear
                                color: root.textColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                        }

                        Repeater {
                            model: ["›", "»"]
                            delegate: Item {
                                width: 22
                                height: 25
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: nextNavMouse.containsMouse ? root.barBg : "transparent"
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.textColor
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 17
                                }
                                MouseArea {
                                    id: nextNavMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (index === 0) root.moveCalendarMonth(1);
                                        else root.moveCalendarYear(1);
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        id: calendarWeekdays
                        x: 0
                        y: 38
                        width: parent.width
                        height: 18
                        spacing: 3
                        Repeater {
                            model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
                            delegate: Item {
                                width: (calendarWeekdays.width - 18) / 7
                                height: 18
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.emptyColor
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    Grid {
                        id: calendarDayGrid
                        x: 0
                        y: 59
                        width: parent.width
                        height: (6 * 28) + (5 * 3)
                        columns: 7
                        rowSpacing: 3
                        columnSpacing: 3

                        Repeater {
                            model: 42
                            delegate: Item {
                                id: calendarDayCell
                                property var cellDate: root.calendarCellDate(index)
                                readonly property bool isToday: root.calendarSameDate(cellDate, root.todayDate)
                                readonly property bool isSelected: root.calendarSameDate(cellDate, root.selectedCalendarDate)
                                readonly property bool inShownMonth: cellDate.getMonth() === root.calendarViewMonth
                                    && cellDate.getFullYear() === root.calendarViewYear
                                width: (calendarDayGrid.width - 18) / 7
                                height: 28

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: calendarDayCell.isToday ? root.accent : "transparent"
                                    border.width: calendarDayCell.isSelected && !calendarDayCell.isToday ? 1 : 0
                                    border.color: root.textColor
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: calendarDayCell.cellDate.getDate()
                                    color: (calendarDayCell.isToday || calendarDayCell.inShownMonth) ? root.textColor : root.emptyColor
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.chooseCalendarDate(calendarDayCell.cellDate)
                                }
                            }
                        }
                    }

                    Rectangle {
                        x: 0
                        y: 249
                        width: parent.width
                        height: 1
                        color: "#414352"
                    }

                    Text {
                        x: 0
                        y: 260
                        width: parent.width
                        height: 24
                        text: root.formatCalendarDate(root.selectedCalendarDate)
                        color: root.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }
            }
        }

        // Native NetworkManager popup, attached to the network module.
        Item {
            id: networkExpansion
            property real revealProgress: root.networkExpansionOpen ? 1.0 : 0.0
            property real networkCenterX: rightModules.x + networkModule.x + networkModule.width / 2
            readonly property int shoulderSize: 5
            width: 370
            height: 430
            x: Math.max(4, Math.min(panel.width - width - 4, networkCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.networkExpansionOpen
            z: root.networkExpansionOpen ? 150 : 109

            Behavior on revealProgress {
                NumberAnimation {
                    duration: root.targetScreen && root.targetScreen.name === "eDP-1" ? 160 : 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: networkBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: networkBubbleShape.width / 2
                    origin.y: 9
                    yScale: networkExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 8;
                    var shoulderSize = networkExpansion.shoulderSize;
                    var inset = 0.5, left = shoulderSize + inset, right = w - shoulderSize - inset;
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(right + shoulderSize * 0.3, joinY, right, joinY + shoulderSize * 0.3, right, joinY + shoulderSize);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3, left - shoulderSize * 0.3, joinY, left - shoulderSize, joinY);
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5, left + 0.5, joinY + shoulderSize * 0.3, left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(right - 0.5, joinY + shoulderSize * 0.3, right + shoulderSize * 0.3, joinY + 0.5, right + shoulderSize, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString();
                    ctx.lineWidth = 1;
                    ctx.lineCap = "butt";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Rectangle {
                id: networkInner
                x: 12; y: 14
                width: parent.width - 24; height: parent.height - 28
                radius: 4
                color: root.barBg
                opacity: Math.max(0, Math.min(1, (networkExpansion.revealProgress - 0.28) / 0.55))
                visible: networkExpansion.revealProgress > 0.28

                Item {
                    id: networkContent
                    anchors.fill: parent
                    anchors.margins: 8

                    Text {
                        x: 0; y: 0; width: 110; height: 30
                        text: "Network"
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                    Rectangle {
                        x: parent.width - 126; y: 1; width: 91; height: 28; radius: 4
                        color: wifiToggleMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        x: parent.width - 126; y: 1; width: 91; height: 28
                        text: root.networkState.wifiEnabled ? "Wi-Fi: On" : "Wi-Fi: Off"
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        id: wifiToggleMouse
                        x: parent.width - 126; y: 1; width: 91; height: 28
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.runNetworkAction(["wifi", root.networkState.wifiEnabled ? "off" : "on"])
                    }
                    Rectangle {
                        x: parent.width - 29; y: 1; width: 28; height: 28; radius: 4
                        color: networkRefreshMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        x: parent.width - 29; y: 1; width: 28; height: 28
                        text: "↻"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        id: networkRefreshMouse
                        x: parent.width - 29; y: 1; width: 28; height: 28
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshNetworkList(true)
                    }

                    Rectangle {
                        x: 0; y: 36; width: parent.width; height: 52; radius: 4
                        color: root.groupBg
                    }
                    Text {
                        x: 8; y: 39; width: parent.width - 16; height: 23
                        text: root.networkState.wifiConnected && root.networkState.activeSsid
                              ? root.networkState.activeSsid
                              : (root.networkState.connected ? (root.networkState.activeConnection || "Connected") : "Not connected")
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        x: 8; y: 61; width: parent.width - 16; height: 20
                        text: root.networkState.error ? root.networkState.error
                              : (root.networkState.wifiConnected ? "Wi-Fi connected" : (root.networkState.connected ? "Network connected" : (root.networkState.wifiEnabled ? "Choose a network below" : "Enable Wi-Fi to scan networks")))
                        color: root.networkState.error ? "#f38ba8" : root.emptyColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        x: 0; y: 94; width: parent.width; height: 18
                        text: "Available Wi-Fi networks"
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                    }
                    Rectangle {
                        x: 0; y: 116; width: parent.width; height: 168; radius: 4
                        color: root.groupBg
                    }
                    ListView {
                        id: availableNetworksList
                        x: 5; y: 121; width: parent.width - 10; height: 158
                        clip: true
                        spacing: 2
                        model: root.networkState.networks || []
                        delegate: Item {
                            id: availableNetworkRow
                            property var network: modelData
                            width: availableNetworksList.width
                            height: 32
                            Rectangle {
                                anchors.fill: parent; radius: 3
                                color: root.networkSelectedSsid === availableNetworkRow.network.ssid
                                       ? "#414352"
                                       : (availableNetworkRow.network.inUse ? "#303844" : "transparent")
                            }
                            Text {
                                x: 8; y: 0; width: parent.width - 84; height: parent.height
                                text: (availableNetworkRow.network.secured ? " " : " ") + availableNetworkRow.network.ssid
                                color: root.networkSelectedSsid === availableNetworkRow.network.ssid ? root.accent : root.textColor
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                                elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                x: parent.width - 70; y: 0; width: 35; height: parent.height
                                text: String(availableNetworkRow.network.signal) + "%"
                                color: root.emptyColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                                horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                x: parent.width - 31; y: 0; width: 24; height: parent.height
                                text: availableNetworkRow.network.inUse ? "✓" : ""
                                color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.networkSelectedSsid = availableNetworkRow.network.ssid;
                                    root.networkSelectedSecurity = availableNetworkRow.network.security || "";
                                    root.networkPassword = "";
                                    if (root.networkSelectedSecurity.length > 0)
                                        networkPasswordFocusTimer.restart();
                                    else
                                        networkPasswordFocusTimer.stop();
                                }
                            }
                        }
                    }
                    Text {
                        x: 0; y: 289; width: parent.width; height: 16
                        text: root.networkSelectedSsid
                              ? (root.networkSelectedSecurity ? "Password for " + root.networkSelectedSsid : "Selected: " + root.networkSelectedSsid)
                              : "Select a network"
                        color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    }
                    Rectangle {
                        x: 0; y: 306; width: parent.width; height: 30; radius: 4
                        color: root.groupBg
                        visible: !!root.networkSelectedSsid && !!root.networkSelectedSecurity
                    }
                    TextInput {
                        id: networkPasswordInput
                        x: 7; y: 306; width: parent.width - 14; height: 30
                        visible: !!root.networkSelectedSsid && !!root.networkSelectedSecurity
                        text: root.networkPassword
                        onTextEdited: root.networkPassword = text
                        color: root.textColor; selectionColor: root.accent; selectedTextColor: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        selectByMouse: true
                        Keys.onReturnPressed: root.runNetworkAction(["connect", root.networkSelectedSsid, root.networkPassword])
                        Keys.onEnterPressed: root.runNetworkAction(["connect", root.networkSelectedSsid, root.networkPassword])
                    }
                    Text {
                        x: 7; y: 306; width: parent.width - 14; height: 30
                        visible: !!root.networkSelectedSsid && !!root.networkSelectedSecurity && !networkPasswordInput.text.length && !networkPasswordInput.activeFocus
                        text: "Wi-Fi password"
                        color: root.emptyColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        enabled: false
                    }
                    Rectangle {
                        x: 0; y: 343; width: (parent.width - 6) / 2; height: 34; radius: 4
                        color: disconnectNetworkMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        x: 0; y: 343; width: (parent.width - 6) / 2; height: 34
                        text: "Disconnect Wi-Fi"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        id: disconnectNetworkMouse
                        x: 0; y: 343; width: (parent.width - 6) / 2; height: 34
                        enabled: !!root.networkState.wifiConnected
                        hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.runNetworkAction(["disconnect"])
                    }
                    Rectangle {
                        x: (parent.width + 6) / 2; y: 343; width: (parent.width - 6) / 2; height: 34; radius: 4
                        color: connectNetworkMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        x: (parent.width + 6) / 2; y: 343; width: (parent.width - 6) / 2; height: 34
                        text: "Connect"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        id: connectNetworkMouse
                        x: (parent.width + 6) / 2; y: 343; width: (parent.width - 6) / 2; height: 34
                        enabled: !!root.networkSelectedSsid
                        hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.runNetworkAction(["connect", root.networkSelectedSsid, root.networkPassword]);
                            root.networkPassword = "";
                        }
                    }
                }
            }
        }

        // Bluetooth manager, anchored to the Bluetooth module and using the bar's attached-popup shape.
        Item {
            id: bluetoothExpansion
            property real revealProgress: root.bluetoothExpansionOpen ? 1.0 : 0.0
            property real bluetoothCenterX: rightModules.x + bluetoothModule.x + bluetoothModule.width / 2
            readonly property int shoulderSize: 5
            width: 320
            height: 370
            x: Math.max(4, Math.min(panel.width - width - 4, bluetoothCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.bluetoothExpansionOpen
            z: root.bluetoothExpansionOpen ? 151 : 108

            Behavior on revealProgress {
                NumberAnimation {
                    duration: root.targetScreen && root.targetScreen.name === "eDP-1" ? 160 : 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: bluetoothBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: bluetoothBubbleShape.width / 2
                    origin.y: 9
                    yScale: bluetoothExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 8;
                    var shoulderSize = bluetoothExpansion.shoulderSize;
                    var inset = 0.5, left = shoulderSize + inset, right = w - shoulderSize - inset;
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(right + shoulderSize * 0.3, joinY, right, joinY + shoulderSize * 0.3, right, joinY + shoulderSize);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3, left - shoulderSize * 0.3, joinY, left - shoulderSize, joinY);
                    ctx.closePath(); ctx.fillStyle = root.barBg.toString(); ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5, left + 0.5, joinY + shoulderSize * 0.3, left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(right - 0.5, joinY + shoulderSize * 0.3, right + shoulderSize * 0.3, joinY + 0.5, right + shoulderSize, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString(); ctx.lineWidth = 1; ctx.lineCap = "butt"; ctx.lineJoin = "round"; ctx.stroke();
                }
            }

            Rectangle {
                x: 12; y: 14; width: parent.width - 24; height: parent.height - 28
                radius: 4; color: root.barBg
                opacity: Math.max(0, Math.min(1, (bluetoothExpansion.revealProgress - 0.28) / 0.55))
                visible: bluetoothExpansion.revealProgress > 0.28
                Item {
                    anchors.fill: parent
                    anchors.margins: 8
                    Text {
                        x: 0; y: 0; width: 112; height: 28
                        text: "Bluetooth"; color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                    Rectangle {
                        x: parent.width - 126; y: 1; width: 80; height: 27; radius: 4
                        color: bluetoothPowerMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        x: parent.width - 126; y: 1; width: 80; height: 27
                        text: root.bluetoothPowered ? "Power: On" : "Power: Off"
                        color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        id: bluetoothPowerMouse
                        x: parent.width - 126; y: 1; width: 80; height: 27
                        enabled: root.bluetoothAvailable
                        hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.runBluetoothAction(["power", root.bluetoothPowered ? "off" : "on"])
                    }
                    Rectangle {
                        x: parent.width - 39; y: 1; width: 32; height: 27; radius: 4
                        color: bluetoothScanMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        x: parent.width - 39; y: 1; width: 32; height: 27
                        text: root.bluetoothDiscovering ? "■" : "↻"
                        color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        id: bluetoothScanMouse
                        x: parent.width - 39; y: 1; width: 32; height: 27
                        enabled: root.bluetoothAvailable && root.bluetoothPowered
                        hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.toggleBluetoothScan()
                    }

                    Rectangle { x: 0; y: 35; width: parent.width; height: 28; radius: 4; color: root.groupBg }
                    Text {
                        x: 7; y: 35; width: parent.width - 14; height: 28
                        text: !root.bluetoothAvailable ? "Bluetooth adapter unavailable"
                              : (!root.bluetoothPowered ? "Turn Bluetooth on to see devices"
                              : (root.bluetoothDiscovering ? "Scanning for devices…" : "Known and discovered devices"))
                        color: root.bluetoothAvailable && root.bluetoothPowered ? root.emptyColor : root.textColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    }

                    Flickable {
                        id: bluetoothDevicesFlickable
                        x: 0; y: 70; width: parent.width; height: parent.height - 106
                        clip: true; contentWidth: width
                        contentHeight: Math.max(bluetoothDevicesColumn.height, 30)
                        Text {
                            x: 5; y: 0; width: parent.width - 10; height: 34
                            visible: root.bluetoothDevices.length === 0
                            text: root.bluetoothPowered ? "No devices found yet — press scan" : ""
                            color: root.emptyColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                            verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap
                        }
                        Column {
                            id: bluetoothDevicesColumn
                            width: bluetoothDevicesFlickable.width
                            height: childrenRect.height
                            spacing: 5
                            Repeater {
                                model: root.bluetoothDevices
                                delegate: Item {
                                    id: bluetoothDeviceRow
                                    property var device: modelData
                                    width: bluetoothDevicesColumn.width; height: 46
                                    Rectangle { anchors.fill: parent; radius: 4; color: root.groupBg }
                                    Text {
                                        x: 7; y: 3; width: parent.width - 91; height: 19
                                        text: bluetoothDeviceRow.device.name
                                        color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                                    }
                                    Text {
                                        x: 7; y: 23; width: parent.width - 91; height: 16
                                        text: bluetoothDeviceRow.device.connected ? "Connected" : (bluetoothDeviceRow.device.paired ? "Paired" : bluetoothDeviceRow.device.address)
                                        color: bluetoothDeviceRow.device.connected ? root.onlineColor : root.emptyColor
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                                    }
                                    Rectangle {
                                        x: parent.width - 79; y: 8; width: 72; height: 30; radius: 4
                                        color: bluetoothDeviceActionMouse.containsMouse ? root.accent : root.barBg
                                    }
                                    Text {
                                        x: parent.width - 79; y: 8; width: 72; height: 30
                                        text: bluetoothDeviceRow.device.connected ? "Disconnect" : (bluetoothDeviceRow.device.paired ? "Connect" : "Pair")
                                        color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        id: bluetoothDeviceActionMouse
                                        x: parent.width - 79; y: 8; width: 72; height: 30
                                        enabled: root.bluetoothPowered
                                        hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.activateBluetoothDevice(bluetoothDeviceRow.device)
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        x: 0; y: parent.height - 27; width: parent.width; height: 22
                        text: root.bluetoothMessage; color: root.emptyColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Square off only the bar's lower-right corner while the power popup
        // touches it. The outer upper-right corner remains rounded, but there is
        // no rounded transparent wedge at the bar/popup seam.
        Rectangle {
            id: powerCornerJoinPatch
            x: panel.width - 6
            y: panel.height - 6
            width: 6
            height: 6
            color: root.barBg
            visible: powerExpansion.revealProgress > 0.001
            z: 125
        }

        // Small power panel: the hovered action gets the accent background, while
        // both labels keep the same text color used by the rest of the bar.
        Item {
            id: powerExpansion
            property real revealProgress: root.powerExpansionOpen ? 1.0 : 0.0
            property real powerCenterX: rightModules.x + powerModule.x + powerModule.width / 2
            readonly property int shoulderSize: 5
            width: 230
            height: 78
            // Align the attached popup's upper-right join with the bar's right edge.
            x: Math.max(0, panel.width - width)
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.powerExpansionOpen
            z: 130

            Behavior on revealProgress {
                NumberAnimation {
                    duration: 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: powerBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: powerBubbleShape.width / 2
                    origin.y: 9
                    yScale: powerExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 8;
                    var shoulderSize = powerExpansion.shoulderSize;
                    var inset = 0.5, left = shoulderSize + inset;

                    // Flush right edge; the curved attachment remains only on the left.
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(w, joinY);
                    ctx.lineTo(w, h - radius);
                    ctx.quadraticCurveTo(w, h, w - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3,
                                      left - shoulderSize * 0.3, joinY,
                                      left - shoulderSize, joinY);
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();

                    // Left attachment and bottom contour; right edge is a straight line.
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5,
                                      left + 0.5, joinY + shoulderSize * 0.3,
                                      left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5,
                                         left + radius, h - 0.5);
                    ctx.lineTo(w - radius, h - 0.5);
                    ctx.quadraticCurveTo(w - 0.5, h - 0.5,
                                         w - 0.5, h - radius);
                    ctx.lineTo(w - 0.5, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString();
                    ctx.lineWidth = 1;
                    ctx.lineCap = "butt";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Row {
                // The attached shape has a curved left shoulder, so center the
                // controls within its visible body rather than the full canvas.
                width: parent.width - 24
                x: powerExpansion.shoulderSize + 0.5
                    + (powerExpansion.width - powerExpansion.shoulderSize - 0.5 - width) / 2
                y: 22
                height: 44
                spacing: 6
                opacity: Math.max(0, Math.min(1, (powerExpansion.revealProgress - 0.28) / 0.55))
                visible: powerExpansion.revealProgress > 0.28

                Item {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: powerOffMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Power Off"
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: powerOffMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.powerExpansionOpen = false;
                            shutdownAction.run();
                        }
                    }
                }
                Item {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: rebootMouse.containsMouse ? root.accent : root.groupBg
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Reboot"
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.powerExpansionOpen = false;
                            rebootAction.run();
                        }
                    }
                }
            }
        }

        // Compact calculator with a live result and a click keypad.
        Item {
            id: calculatorExpansion
            property real revealProgress: root.calculatorExpansionOpen ? 1.0 : 0.0
            property real calculatorCenterX: rightModules.x + calcModule.x + calcModule.width / 2
            readonly property int shoulderSize: 5
            width: 320
            height: 360
            x: Math.max(4, Math.min(panel.width - width - 4, calculatorCenterX - width / 2))
            y: panel.height - 10
            visible: revealProgress > 0.001 || root.calculatorExpansionOpen
            z: 120

            Behavior on revealProgress {
                NumberAnimation {
                    duration: 210
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                }
            }

            Canvas {
                id: calculatorBubbleShape
                anchors.fill: parent
                transform: Scale {
                    origin.x: calculatorBubbleShape.width / 2
                    origin.y: 9
                    yScale: calculatorExpansion.revealProgress
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width < 2 || height < 18) return;
                    var w = width, h = height, joinY = 9, radius = 8;
                    var shoulderSize = calculatorExpansion.shoulderSize;
                    var inset = 0.5, left = shoulderSize + inset, right = w - shoulderSize - inset;
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY);
                    ctx.lineTo(right + shoulderSize, joinY);
                    ctx.bezierCurveTo(right + shoulderSize * 0.3, joinY, right, joinY + shoulderSize * 0.3, right, joinY + shoulderSize);
                    ctx.lineTo(right, h - radius);
                    ctx.quadraticCurveTo(right, h, right - radius, h);
                    ctx.lineTo(left + radius, h);
                    ctx.quadraticCurveTo(left, h, left, h - radius);
                    ctx.lineTo(left, joinY + shoulderSize);
                    ctx.bezierCurveTo(left, joinY + shoulderSize * 0.3, left - shoulderSize * 0.3, joinY, left - shoulderSize, joinY);
                    ctx.closePath();
                    ctx.fillStyle = root.barBg.toString();
                    ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(left - shoulderSize, joinY + 0.5);
                    ctx.bezierCurveTo(left - shoulderSize * 0.3, joinY + 0.5, left + 0.5, joinY + shoulderSize * 0.3, left + 0.5, joinY + shoulderSize);
                    ctx.lineTo(left + 0.5, h - radius);
                    ctx.quadraticCurveTo(left + 0.5, h - 0.5, left + radius, h - 0.5);
                    ctx.lineTo(right - radius, h - 0.5);
                    ctx.quadraticCurveTo(right - 0.5, h - 0.5, right - 0.5, h - radius);
                    ctx.lineTo(right - 0.5, joinY + shoulderSize);
                    ctx.bezierCurveTo(right - 0.5, joinY + shoulderSize * 0.3, right + shoulderSize * 0.3, joinY + 0.5, right + shoulderSize, joinY + 0.5);
                    ctx.strokeStyle = root.groupBg.toString();
                    ctx.lineWidth = 1;
                    ctx.lineCap = "butt";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Rectangle {
                id: calculatorInner
                x: 12
                y: 14
                width: parent.width - 24
                height: parent.height - 28
                radius: 4
                color: root.barBg
                opacity: Math.max(0, Math.min(1, (calculatorExpansion.revealProgress - 0.28) / 0.55))
                visible: calculatorExpansion.revealProgress > 0.28

                Item {
                    id: calculatorContent
                    anchors.fill: parent
                    anchors.margins: 8

                    Rectangle {
                        x: 0; y: 0
                        width: parent.width; height: 32
                        radius: 4
                        color: root.groupBg
                    }
                    TextInput {
                        id: calculatorInput
                        x: 8; y: 0
                        width: parent.width - 16; height: 32
                        text: root.calculatorExpression
                        color: root.textColor
                        selectionColor: root.accent
                        selectedTextColor: root.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        clip: true
                        onTextEdited: root.calculatorExpression = text
                        Keys.onReturnPressed: root.handleCalculatorKey("=")
                        Keys.onEnterPressed: root.handleCalculatorKey("=")
                        Keys.onEscapePressed: root.calculatorExpansionOpen = false
                    }

                    Rectangle {
                        x: 0; y: 38
                        width: parent.width; height: 32
                        radius: 4
                        color: root.groupBg
                    }
                    Text {
                        x: 8; y: 38
                        width: parent.width - 16; height: 32
                        text: root.calculatorResult.length ? root.calculatorResult : " "
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        x: 0; y: 78
                        width: parent.width; height: parent.height - 78
                        radius: 4
                        color: root.groupBg
                    }
                    Grid {
                        id: calculatorKeyGrid
                        x: 5; y: 83
                        width: parent.width - 10
                        height: parent.height - 88
                        columns: 4
                        rowSpacing: 4
                        columnSpacing: 5

                        Repeater {
                            model: ["C", "sqrt", "^", "/",
                                    "7", "8", "9", "*",
                                    "4", "5", "6", "-",
                                    "1", "2", "3", "+",
                                    ".", "0", "⌫", "="]
                            delegate: Item {
                                id: calculatorKey
                                property string keyLabel: modelData
                                width: (calculatorKeyGrid.width - calculatorKeyGrid.columnSpacing * 3) / 4
                                height: (calculatorKeyGrid.height - calculatorKeyGrid.rowSpacing * 4) / 5

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: calculatorKeyMouse.containsMouse ? root.barBg : "transparent"
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: calculatorKey.keyLabel
                                    color: root.textColor
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: calculatorKey.keyLabel === "sqrt" ? 11 : 14
                                }
                                MouseArea {
                                    id: calculatorKeyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.handleCalculatorKey(calculatorKey.keyLabel)
                                }
                            }
                        }
                    }
                }
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
                MouseArea { cursorShape: Qt.PointingHandCursor; id: launcherMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.toggleAppLauncher() }
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
                            property bool hoverTrailVisible: false
                            property real hoverTrailOpacity: 0.0
                            width: workspaceLabel.implicitWidth + 16
                            height: 24

                            onIsHoveredChanged: {
                                if (isHovered) {
                                    hoverTrailFade.stop();
                                    hoverTrailVisible = true;
                                    hoverTrailOpacity = 1.0;
                                } else if (hoverTrailVisible) {
                                    // Fade immediately after leaving, so a fast pointer
                                    // sweep leaves a brief trail instead of a long-lived row.
                                    hoverTrailFade.restart();
                                }
                            }

                            NumberAnimation {
                                id: hoverTrailFade
                                target: workspaceButton
                                property: "hoverTrailOpacity"
                                to: 0.0
                                duration: 150
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.33, 0, 0.25, 1, 1, 1]
                                onFinished: {
                                    if (!workspaceButton.isHovered)
                                        workspaceButton.hoverTrailVisible = false;
                                }
                            }

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

                            // Persistent active-workspace underline.
                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.bottom: parent.bottom
                                height: 2
                                color: root.accent
                                visible: workspaceButton.isActive
                            }

                            // Hover trail uses the text color; only the active workspace is green.
                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.bottom: parent.bottom
                                height: 2
                                color: root.textColor
                                visible: !workspaceButton.isActive && (workspaceButton.hoverTrailVisible || workspaceButton.isHovered)
                                opacity: workspaceButton.hoverTrailOpacity
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

        // RIGHT: battery, volume, brightness, layout, calculator, clock, Wi-Fi, Bluetooth, power.
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
                        root.calendarExpansionOpen = false;
                        root.calculatorExpansionOpen = false;
                        root.powerExpansionOpen = false;
                        root.brightnessExpansionOpen = false;
                        root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                        root.batteryExpansionOpen = true;
                    }
                    onExited: batteryCloseTimer.restart()
                }
            }

            Item {
                id: volumeModule
                // Fixed width prevents the popup anchor shifting between e.g. 99% and 100%.
                width: 66; height: 32
                Row { id: volumeRow; anchors.centerIn: parent; spacing: 6
                    Text { text: root.volumeIcon; color: root.volumeState === "muted" ? "#8a8a8a" : root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                    Text { visible: root.volumeState !== "muted"; text: root.volumePercent + "%"; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                MouseArea {
                    id: volumeMouse
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        if (root.canShowMusicPreview()) {
                            root.musicPreviewOpen = true;
                            musicPreviewCloseTimer.stop();
                        }
                    }
                    onExited: {
                        if (root.musicPreviewOpen)
                            musicPreviewCloseTimer.restart();
                    }
                    onClicked: {
                        // Resolve the external mixer state first; this avoids briefly opening
                        // the Quickshell mixer on top of an already-running pwvucontrol window.
                        if (!volumeModuleClickProcess.running)
                            volumeModuleClickProcess.running = true;
                    }
                    onWheel: {
                        var steps = root.wheelSteps(wheel.angleDelta.y);
                        if (steps !== 0)
                            root.adjustVolumeSteps(steps);
                        wheel.accepted = true;
                    }
                }
            }

            Item {
                id: backlightModule
                width: backlightRow.implicitWidth; height: 32
                Row { id: backlightRow; anchors.centerIn: parent; spacing: 4
                    Text { text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                    Text { text: (backlightPoll.value.length ? backlightPoll.value : "0") + "%"; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var shouldOpen = !root.brightnessExpansionOpen;
                        root.batteryExpansionOpen = false;
                        root.calendarExpansionOpen = false;
                        root.calculatorExpansionOpen = false;
                        root.powerExpansionOpen = false;
                        root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                        root.brightnessExpansionOpen = shouldOpen;
                        if (shouldOpen) brightnessFocusTimer.restart();
                        else brightnessFocusTimer.stop();
                    }
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
                id: calcModule
                width: calcText.implicitWidth + 4; height: 32
                Text { id: calcText; anchors.centerIn: parent; text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        var shouldOpen = !root.calculatorExpansionOpen;
                        root.batteryExpansionOpen = false;
                        root.calendarExpansionOpen = false;
                        root.powerExpansionOpen = false;
                        root.brightnessExpansionOpen = false;
                        root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                        root.calculatorExpansionOpen = shouldOpen;
                        if (shouldOpen) calculatorFocusTimer.restart();
                        else calculatorFocusTimer.stop();
                    }
                }
            }

            Item {
                id: clockModule
                width: clockTextItem.implicitWidth + 10; height: 32
                Text { id: clockTextItem; anchors.centerIn: parent; text: root.clockText; color: root.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        if (root.calendarExpansionOpen) {
                            root.calendarExpansionOpen = false;
                        } else {
                            batteryCloseTimer.stop();
                            root.batteryExpansionOpen = false;
                            root.calculatorExpansionOpen = false;
                            root.powerExpansionOpen = false;
                            root.brightnessExpansionOpen = false;
                            root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                            root.calendarExpansionOpen = true;
                        }
                    }
                }
            }

            Item {
                id: networkModule
                // Narrower cell reduces the visual gap between the clock and Wi-Fi icon.
                width: 26; height: 32
                Text {
                    id: networkText
                    anchors.fill: parent
                    text: root.networkModuleText
                    color: root.networkState.connected ? root.onlineColor : root.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        var shouldOpen = !root.networkExpansionOpen;
                        root.batteryExpansionOpen = false;
                        root.calendarExpansionOpen = false;
                        root.calculatorExpansionOpen = false;
                        root.powerExpansionOpen = false;
                        root.brightnessExpansionOpen = false;
                        root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                        root.networkExpansionOpen = shouldOpen;
                        if (shouldOpen) root.refreshNetworkList(true);
                    }
                }
            }

            Item {
                id: bluetoothModule
                width: 26; height: 32
                Text {
                    anchors.fill: parent
                    text: root.bluetoothModuleText
                    color: !root.bluetoothAvailable ? root.emptyColor : (root.bluetoothPowered ? root.onlineColor : root.textColor)
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var shouldOpen = !root.bluetoothExpansionOpen;
                        root.batteryExpansionOpen = false;
                        root.calendarExpansionOpen = false;
                        root.calculatorExpansionOpen = false;
                        root.powerExpansionOpen = false;
                        root.brightnessExpansionOpen = false;
                        root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = shouldOpen;
                        if (shouldOpen && !root.bluetoothAvailable)
                            bluetoothRefreshTimer.restart();
                    }
                }
            }

            Item {
                id: powerModule
                width: powerText.implicitWidth + 7; height: 32
                Text { id: powerText; anchors.centerIn: parent; text: ""; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        var shouldOpen = !root.powerExpansionOpen;
                        root.batteryExpansionOpen = false;
                        root.calendarExpansionOpen = false;
                        root.calculatorExpansionOpen = false;
                        root.brightnessExpansionOpen = false;
                        root.volumeExpansionOpen = false;
                        root.musicPreviewOpen = false;
                        root.networkExpansionOpen = false;
                        root.bluetoothExpansionOpen = false;
                        root.powerExpansionOpen = shouldOpen;
                    }
                }
            }
        }

    }

    // Passive, animated on-screen display. It is deliberately outside the bar's
    // input mask: the OSD is visible but does not steal pointer clicks from apps.
    Item {
        id: osdToast
        width: 300
        height: root.osdMode === "volume" ? 88 : 78
        x: (root.width - width) / 2
        // Keep every OSD (layout, Caps Lock, and volume) centered in the
        // lower half of the monitor: the toast's center sits at 75% screen height.
        y: Math.round(root.height * 0.75 - height / 2)
        opacity: root.osdVisible ? 1 : 0
        scale: root.osdVisible ? 1 : 0.96
        visible: opacity > 0.01
        z: 10000

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: root.barBg
            border.width: 1
            border.color: root.groupBg
        }

        // Volume OSD
        Row {
            visible: root.osdMode === "volume"
            x: 17
            y: 12
            width: parent.width - 34
            height: 36
            spacing: 12
            Text {
                width: 32
                height: parent.height
                text: root.volumeIcon
                color: root.volumeState === "muted" ? root.emptyColor : root.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 24
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text {
                    text: "Volume"
                    color: root.textColor
                    opacity: 0.72
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
                Text {
                    text: root.volumeState === "muted" ? "Muted" : root.volumePercent + "%"
                    color: root.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                }
            }
        }
        Rectangle {
            visible: root.osdMode === "volume"
            x: 17
            y: 63
            width: parent.width - 34
            height: 5
            radius: 3
            color: root.groupBg
            Rectangle {
                width: parent.width * (root.volumeState === "muted" ? 0 : Math.max(0, Math.min(100, root.volumePercent)) / 100)
                height: parent.height
                radius: 3
                color: root.accent
                Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            }
        }

        // Keyboard layout OSD
        Row {
            visible: root.osdMode === "layout"
            x: 18
            y: 9
            width: parent.width - 36
            height: parent.height - 18
            spacing: 16
            Text {
                width: 72
                height: parent.height
                text: root.languageShort.toUpperCase()
                color: root.textColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 28
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    text: "Keyboard Layout"
                    color: root.textColor
                    opacity: 0.72
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
                Text {
                    text: root.languageFields.length > 1 ? root.languageFields[1] : root.languageShort.toUpperCase()
                    color: root.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    width: 176
                }
            }
        }

        // Caps Lock OSD
        Row {
            visible: root.osdMode === "caps"
            x: 18
            y: 8
            width: parent.width - 36
            height: parent.height - 16
            spacing: 16
            Text {
                width: 72
                height: parent.height
                text: "⇪"
                color: root.osdLastCapsLockState === "yes" ? root.accent : root.textColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 30
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    text: "Caps Lock"
                    color: root.textColor
                    opacity: 0.72
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
                Text {
                    text: root.osdLastCapsLockState === "yes" ? "ON" : "OFF"
                    color: root.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                }
            }
        }
    }
}

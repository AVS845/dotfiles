import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import "./colors" as Colors

Scope {
    id: root

    property bool launcherVisible: false
    property string launcherScreenName: ""
    property string launcherQuery: ""
    property real cpuUsage: 0
    property real ramUsage: 0
    property real gpu0Usage: 0
    property real gpu1Usage: 0
    property real cpuTemp: 0
    property real gpu0Temp: 0
    property real gpu1Temp: 0
    property real lastCpuTotal: 0
    property real lastCpuIdle: 0
    property int wifiQuality: -1
    property int focusedWorkspaceId: -1
    property int lastActiveWorkspace: -1

    ListModel {
        id: workspaceModel
    }
    property color bg: "#1a0f1019"
    property color bgSolid: "#ee0f0a19"
    property color bgSoft: "#331c1529"
    property color meterTrack: "#00000000"
    property color border: "#00cba6f7"
    property color accent: Colors.Wal.color5
    property color accentSoft: Colors.Wal.color1
    property color text: "#f5efff"
    property color muted: "#b6a8c9"

    function currentScreenName(): string {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    }

    function showLauncher(screenName: string): void {
        launcherScreenName = screenName || currentScreenName();
        launcherQuery = "";
        launcherVisible = true;
    }

    function toggleLauncher(screenName: string): void {
        const target = screenName || currentScreenName();
        if (launcherVisible && launcherScreenName === target) {
            launcherVisible = false;
        } else {
            showLauncher(target);
        }
    }

    function hideLauncher(): void {
        launcherVisible = false;
    }

    function matchesApp(app, query: string): bool {
        const needle = query.toLowerCase().trim();
        if (needle.length === 0) return true;

        const haystack = [
            app.name,
            app.genericName,
            app.comment,
            app.id,
            (app.categories || []).join(" "),
            (app.keywords || []).join(" ")
        ].join(" ").toLowerCase();

        return haystack.indexOf(needle) !== -1;
    }

    function filteredApps(): var {
        return DesktopEntries.applications.values
            .filter(app => matchesApp(app, launcherQuery))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 80);
    }

    function appIconSource(icon: string): string {
        const source = Quickshell.iconPath(icon || "", true);
        return source || Quickshell.iconPath("application-x-executable", true);
    }

    function batteryLabel(): string {
        const battery = UPower.displayDevice;
        if (!battery || !battery.ready) return "AC";
        return Math.round(battery.percentage * 100) + "%";
    }

    function batteryPercent(): real {
        const battery = UPower.displayDevice;
        if (!battery || !battery.ready) return 1;
        return Math.max(0, Math.min(1, battery.percentage));
    }

    function batteryIcon(): string {
        const battery = UPower.displayDevice;
        if (!battery || !battery.ready) return "plug";
        const pct = battery.percentage;
        return "BAT";
    }

    function lock(): void {
        launcherVisible = false;
        Quickshell.execDetached(["hyprlock"]);
    }

    function applyStats(line: string): void {
        const parts = line.trim().split(/\s+/).map(Number);
        if (parts.length < 5 || parts.some(isNaN)) return;

        const total = parts[0];
        const idle = parts[1];
        if (lastCpuTotal > 0 && total > lastCpuTotal) {
            const totalDelta = total - lastCpuTotal;
            const idleDelta = idle - lastCpuIdle;
            cpuUsage = Math.max(0, Math.min(1, 1 - idleDelta / totalDelta));
        }

        lastCpuTotal = total;
        lastCpuIdle = idle;
        ramUsage = Math.max(0, Math.min(1, parts[2]));
        gpu0Usage = Math.max(0, Math.min(1, parts[3]));
        gpu1Usage = Math.max(0, Math.min(1, parts[4]));

        // Parse temperatures (indices 5, 6, 7)
        if (parts.length >= 6 && Number.isFinite(parts[5])) {
            cpuTemp = Math.max(0, Math.min(100, parts[5]));
        }
        if (parts.length >= 7 && Number.isFinite(parts[6])) {
            gpu0Temp = Math.max(0, Math.min(100, parts[6]));
        }
        if (parts.length >= 8 && Number.isFinite(parts[7])) {
            gpu1Temp = Math.max(0, Math.min(100, parts[7]));
        }
    }

    function applyWorkspaces(json: string): void {
        try {
            const newWorkspaces = JSON.parse(json)
                .map(ws => ws.id)
                .filter(id => id > 0)
                .sort((a, b) => a - b);

            // Get current workspace IDs from the model
            const currentIds = [];
            for (let i = 0; i < workspaceModel.count; i++) {
                currentIds.push(workspaceModel.get(i).workspace);
            }

            const oldSet = new Set(currentIds);
            const newSet = new Set(newWorkspaces);

            // Remove workspaces that no longer exist
            const toRemove = currentIds.filter(id => !newSet.has(id));
            toRemove.forEach(id => {
                for (let i = 0; i < workspaceModel.count; i++) {
                    if (workspaceModel.get(i).workspace === id) {
                        workspaceModel.remove(i);
                        break;
                    }
                }
            });

            // Add new workspaces
            const toAdd = newWorkspaces.filter(id => !oldSet.has(id));
            toAdd.forEach(id => {
                workspaceModel.append({ workspace: id });
            });

            // Handle reordering - move items to correct positions
            for (let i = 0; i < newWorkspaces.length; i++) {
                const targetId = newWorkspaces[i];
                // Find current index of this workspace
                let currentIdx = -1;
                for (let j = 0; j < workspaceModel.count; j++) {
                    if (workspaceModel.get(j).workspace === targetId) {
                        currentIdx = j;
                        break;
                    }
                }
                if (currentIdx !== -1 && currentIdx !== i) {
                    workspaceModel.move(currentIdx, i, 1);
                }
            }
        } catch (error) {
            workspaceModel.clear();
        }
    }

    property int wifiUpdateTrigger: 0

    function applyWifi(line: string): void {
        const value = Number(line.trim());
        wifiQuality = Number.isFinite(value) ? Math.max(0, Math.min(100, value)) : -1;
        wifiUpdateTrigger++;
    }

    function wifiLabel(): string {
        if (wifiQuality < 0) return "wifi --";
        return "wifi " + wifiQuality + "%";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        id: statsProc
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.applyStats(data)
        }
    }

    Process {
        id: workspacesProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyWorkspaces(text)
        }
    }

    Process {
        id: wifiProc
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.applyWifi(data)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsProc.running) statsProc.exec([Quickshell.shellDir + "/scripts/system-stats.sh"]);
            if (!wifiProc.running) {
                wifiProc.exec(["sh", "-c", "awk 'NR>2 { q=$3; gsub(/\\./, \"\", q); print int(q * 100 / 70); found=1; exit } END { if (!found) print -1 }' /proc/net/wireless"]);
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!workspacesProc.running) workspacesProc.exec(["hyprctl", "workspaces", "-j"])
    }

    // Track focused workspace for animation triggers
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            const currentId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
            if (currentId !== focusedWorkspaceId) {
                lastActiveWorkspace = focusedWorkspaceId;
                focusedWorkspaceId = currentId;
            }
        }
    }

    IpcHandler {
        target: "desktop"

        function toggleLauncher(): void {
            root.toggleLauncher(root.currentScreenName());
        }

        function showLauncher(): void {
            root.showLauncher(root.currentScreenName());
        }

        function hideLauncher(): void {
            root.hideLauncher();
        }

        function lock(): void {
            root.lock();
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Toggle Quickshell launcher"
        onPressed: root.toggleLauncher(root.currentScreenName())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "lock"
        description: "Lock session"
        onPressed: root.lock()
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: bar
                required property var modelData

                screen: modelData
                implicitHeight: 44
                color: "transparent"

                anchors {
                    top: true
                    left: true
                    right: true
                }

                margins {
                    top: 6
                    left: 10
                    right: 10
                }

                Rectangle {
                    id: barBg
                    anchors.fill: parent
                    color: "transparent"

                    BarGroup {
                        width: 150
                        height: 42
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.formatDateTime(clock.date, "h:mm A")
                                color: root.text
                                font.pixelSize: 16
                                font.family: "Inter"
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                // Custom WiFi icon - dot with curved waves
                                Canvas {
                                    id: wifiCanvas
                                    width: 20
                                    height: 16
                                    // Force repaint when root.wifiUpdateTrigger changes
                                    Connections {
                                        target: root
                                        function onWifiUpdateTriggerChanged() {
                                            wifiCanvas.requestPaint();
                                        }
                                    }

                                    onPaint: {
                                        const ctx = getContext("2d");
                                        const cx = 10;
                                        const cy = 13;
                                        const active = root.wifiQuality >= 0;

                                        ctx.clearRect(0, 0, width, height);
                                        ctx.lineWidth = 1.5;
                                        ctx.lineCap = "round";
                                        ctx.strokeStyle = active ? root.accent : root.muted;

                                        // Draw dot
                                        ctx.beginPath();
                                        ctx.arc(cx, cy, 1.75, 0, Math.PI * 2);
                                        ctx.fillStyle = active ? root.accent : root.muted;
                                        ctx.fill();

                                        // Draw waves based on signal quality
                                        if (active) {
                                            const levels = root.wifiQuality >= 75 ? 3 : (root.wifiQuality >= 50 ? 2 : 1);

                                            // Wave 1 (inner)
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, 4.5, -Math.PI * 0.75, -Math.PI * 0.25);
                                            ctx.stroke();

                                            if (levels >= 2) {
                                                // Wave 2 (middle)
                                                ctx.beginPath();
                                                ctx.arc(cx, cy, 8, -Math.PI * 0.75, -Math.PI * 0.25);
                                                ctx.stroke();
                                            }

                                            if (levels >= 3) {
                                                // Wave 3 (outer)
                                                ctx.beginPath();
                                                ctx.arc(cx, cy, 11.5, -Math.PI * 0.75, -Math.PI * 0.25);
                                                ctx.stroke();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    BarGroup {
                        id: barGroup
                        height: 42
                        anchors.centerIn: parent

                        // Ghost Row to provide implicit width
                        Row {
                            id: ghostRow
                            visible: false
                            spacing: 8

                            Repeater {
                              model: workspaceModel

                              delegate: Rectangle {
                                required property var modelData

                                width: (typeof modelData === "number" ? modelData : modelData.workspace) === root.focusedWorkspaceId ? 16 : 9
                                height: 9
                                }
                              }
                        }

                        width: Math.max(70, workspaceDots.contentWidth + 28)
                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.InOutQuad
                            }
                        }

ListView {
    id: workspaceDots

    anchors.centerIn: parent

    orientation: ListView.Horizontal

    interactive: false
    clip: false

    spacing: 8

    implicitWidth: contentWidth
    implicitHeight: 12

    model: workspaceModel

    delegate: WorkspaceDot {
        required property var modelData
        workspace: typeof modelData === "number" ? modelData : (modelData.workspace || 0)
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 400
            }

            NumberAnimation {
                property: "scale"
                from: 0.6
                to: 1.0
                duration: 400
                easing.type: Easing.OutQuad
            }
        }
    }

    remove: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 400
            }

            NumberAnimation {
                property: "scale"
                to: 0.6
                duration: 400
                easing.type: Easing.OutQuad
            }
        }
    }

    displaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 400
            easing.type: Easing.OutQuad
        }
    }
}
                        }

                    // Blurred background behind meters (behind everything)
                    Rectangle {
                        id: meterBg
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        property real targetWidth: 210
                        width: targetWidth
                        height: 48
                        radius: 24
                        color: root.bgSoft
                        opacity: 0.7
                        z: -1

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 10

                        CircularMeter { value: root.ramUsage; label: "MEM"; tooltip: Math.round(root.ramUsage * 100) + "%" }
                        CircularMeter { value: root.cpuUsage; label: "CPU"; tooltip: Math.round(root.cpuUsage * 100) + "%"; temperature: root.cpuTemp }
                        CircularMeter { value: root.gpu1Usage; label: "GPU"; tooltip: Math.round(root.gpu1Usage * 100) + "%"; temperature: root.gpu1Temp }
                        CircularMeter {
                            value: root.batteryPercent()
                            label: root.batteryIcon()
                            tooltip: root.batteryLabel()
                            accentColor: root.batteryPercent() < 0.2 ? "#f38ba8" : root.accent
                        }
                    }
                }

                PopupWindow {
                    id: launcher
                    anchor.window: bar
                    implicitWidth: Math.min(620, Math.max(460, bar.width * 0.34))
                    implicitHeight: 470
                    anchor.rect.x: Math.max(0, (bar.width - 500) / 2)
                    anchor.rect.y: bar.height + 14
                    grabFocus: true
                    color: "transparent"
                    visible: root.launcherVisible && root.launcherScreenName === bar.modelData.name

                    onVisibleChanged: {
                        if (visible) search.forceActiveFocus();
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: root.bgSolid
                        border.color: root.border
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Rectangle {
                                width: parent.width
                                height: 48
                                radius: 12
                                color: root.accentSoft
                                border.color: "#55cba6f7"
                                border.width: 1

                                TextInput {
                                    id: search
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: root.text
                                    selectionColor: root.accent
                                    selectedTextColor: "#0f0a19"
                                    font.pixelSize: 16
                                    font.family: "JetBrains Mono Nerd Font"
                                    clip: true
                                    text: root.launcherQuery
                                    onTextChanged: root.launcherQuery = text
                                    onAccepted: {
                                        if (appList.count > 0) {
                                            appList.itemAtIndex(0).launch();
                                        }
                                    }
                                    Keys.onEscapePressed: root.hideLauncher()

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: search.text.length === 0
                                        text: "Search apps"
                                        color: root.muted
                                        font.pixelSize: 16
                                        font.family: "JetBrains Mono Nerd Font"
                                    }
                                }
                            }

                            ListView {
                                id: appList
                                width: parent.width
                                height: parent.height - 60
                                clip: true
                                spacing: 6
                                model: root.filteredApps()
                                currentIndex: 0

                                Keys.onEscapePressed: root.hideLauncher()
                                Keys.onReturnPressed: if (currentItem) currentItem.launch()
                                Keys.onEnterPressed: if (currentItem) currentItem.launch()

                                delegate: Rectangle {
                                    id: appRow
                                    required property var modelData

                                    width: appList.width
                                    height: 54
                                    radius: 10
                                    color: mouse.containsMouse || ListView.isCurrentItem ? root.accentSoft : "transparent"
                                    border.color: mouse.containsMouse || ListView.isCurrentItem ? "#44cba6f7" : "transparent"
                                    border.width: 1

                                    function launch(): void {
                                        modelData.execute();
                                        root.hideLauncher();
                                    }

                                    MouseArea {
                                        id: mouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: appRow.launch()
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        Image {
                                            width: 30
                                            height: 30
                                            anchors.verticalCenter: parent.verticalCenter
                                            source: root.appIconSource(appRow.modelData.icon)
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 54
                                            spacing: 2

                                            Text {
                                                width: parent.width
                                                text: appRow.modelData.name
                                                color: root.text
                                                elide: Text.ElideRight
                                                font.pixelSize: 14
                                                font.family: "JetBrains Mono Nerd Font"
                                            }

                                            Text {
                                                width: parent.width
                                                text: appRow.modelData.comment || appRow.modelData.genericName || appRow.modelData.id
                                                color: root.muted
                                                elide: Text.ElideRight
                                                font.pixelSize: 11
                                                font.family: "JetBrains Mono Nerd Font"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component BarGroup: Rectangle {
        radius: height / 2
        color: root.bg
        border.width: 0
    }

    component CircularMeter: Item {
        id: meter
        property real value: 0
        property real shownValue: value
        property string label: ""
        property string tooltip: ""
        property color accentColor: root.accent
        property real temperature: -1  // -1 means no temperature display
        property real shownTemperature: temperature

        width: 44
        height: 44

        Behavior on shownValue {
            NumberAnimation {
                duration: 360
                easing.type: Easing.OutCubic
            }
        }

        Behavior on shownTemperature {
            NumberAnimation {
                duration: 360
                easing.type: Easing.OutCubic
            }
        }

        onShownValueChanged: ring.requestPaint()
        onAccentColorChanged: ring.requestPaint()
        onShownTemperatureChanged: ring.requestPaint()

        onTemperatureChanged: {
            if (temperature >= 0) {
                shownTemperature = temperature;
            }
        }

        Canvas {
            id: ring
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d");
                const size = Math.min(width, height);
                const line = 4;
                const center = size / 2;
                const radius = center - line / 2 - 1;

                ctx.clearRect(0, 0, width, height);
                ctx.lineWidth = line;
                ctx.lineCap = "round";

                // Draw main value ring
                ctx.beginPath();
                ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, meter.shownValue)));
                ctx.strokeStyle = meter.accentColor;
                ctx.stroke();

                // Draw temperature ring (inner, darker/paler color)
                if (meter.shownTemperature >= 0) {
                    const tempLine = 3;
                    const tempRadius = radius - line - 2;
                    const tempColor = meter.shownTemperature > 80 ? "#eba0ac" : (meter.shownTemperature > 60 ? "#f9e2af" : root.accentSoft);


                    ctx.lineWidth = tempLine;
                    ctx.beginPath();
                    ctx.arc(center, center, tempRadius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, meter.shownTemperature / 100)));
                    ctx.strokeStyle = tempColor;
                    ctx.stroke();
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: meter.label
            color: root.text
            font.pixelSize: meter.label.length > 3 ? 8 : 9
            font.family: "JetBrains Mono Nerd Font"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
component WorkspaceDot: Rectangle {
    id: dot

    property int workspace: 0

    property bool active:
    Hyprland.focusedWorkspace &&
    Hyprland.focusedWorkspace.id === workspace

    width: active ? 16 : 9
    height: 9

    radius: height / 2

    color: active ? root.accent : "#66ffffff"

    scale: active ? 1.1 : 1.0

    Behavior on width {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutQuad
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutQuad
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 350
        }
    }


    MouseArea {
        anchors.fill: parent

        onClicked: {
            Quickshell.execDetached([
                "hyprctl",
                "dispatch",
                "workspace",
                String(dot.workspace)
            ])
        }
    }
}
}


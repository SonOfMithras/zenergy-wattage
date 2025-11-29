import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.ksvg as KSvg

PlasmoidItem {
    id: root
    width: 300
    height: 200

    property string wattage: "..."
    property string logPath: "PLACEHOLDER_LOG_PATH"
    // Resolve path to bundled monitor.py (relative to contents/ui/main.qml -> ../scripts/monitor.py)
    property string monitorScriptPath: Qt.resolvedUrl("../scripts/monitor.py").toString().replace(/^file:\/\//, "")
    
    Component.onCompleted: {
        console.log("Resolved Monitor Path: " + monitorScriptPath);
    }

    property double lastUpdateTimestamp: new Date().getTime()
    property bool isMonitorActive: true
    
    // Configuration Properties
    readonly property int bgMode: Plasmoid.configuration.backgroundColorMode
    readonly property int appletBgMode: Plasmoid.configuration.appletBackgroundMode // 0=Default, 1=Transparent, 2=Shadow
    readonly property color customBgColor: Plasmoid.configuration.customBackgroundColor
    readonly property int bgOpacity: Plasmoid.configuration.backgroundOpacity
    readonly property string cfgFontFamily: Plasmoid.configuration.fontFamily
    readonly property int cfgFontSize: Plasmoid.configuration.fontSize
    readonly property bool cfgTextBold: Plasmoid.configuration.textBold
    readonly property bool cfgTextItalic: Plasmoid.configuration.textItalic
    readonly property bool cfgTextUnderline: Plasmoid.configuration.textUnderline
    readonly property int cfgTextPosition: Plasmoid.configuration.textPosition // 0=Overlay, 1=Below, 2=Above
    readonly property bool showGraph: Plasmoid.configuration.showGraph
    readonly property int graphDuration: Plasmoid.configuration.graphDuration
    readonly property int cfgGraphColorMode: Plasmoid.configuration.graphColorMode
    readonly property color cfgGraphLineColor: Plasmoid.configuration.graphLineColor
    readonly property int cfgGraphLineWidth: Plasmoid.configuration.graphLineWidth
    readonly property int cfgTextColorMode: Plasmoid.configuration.textColorMode
    readonly property color cfgCustomTextColor: Plasmoid.configuration.customTextColor

    // Helper for colors
    // Removed effective properties in favor of States

    // Heartbeat Timer
    Timer {
        interval: 2000 // Check every 2 seconds
        running: true
        repeat: true
        onTriggered: {
            var now = new Date().getTime();
            var diff = now - root.lastUpdateTimestamp;
            
            // If no update for 5 seconds, mark inactive
            if (diff > 5000) {
                if (root.isMonitorActive) {
                    root.isMonitorActive = false;
                }
            }
        }
    }

    Plasma5Support.DataSource {
        id: executableSource
        engine: "executable"
        connectedSources: ["/usr/bin/tail -n 1 " + root.logPath]
        interval: 1000
        onNewData: function(sourceName, data) {
            var stdout = data["stdout"]
            
            if (stdout) {
                var lines = stdout.trim().split("\n");
                if (lines.length > 0) {
                    // With tail -n 1, we only get one line
                    var lastLine = lines[0];
                    var parts = lastLine.split(" - ");
                    
                    if (parts.length > 1) {
                        // Parse Timestamp: "2025-11-29 11:41:14"
                        // Replace space with T for ISO parsing: "2025-11-29T11:41:14"
                        var timeStr = parts[0].replace(" ", "T");
                        var logTime = Date.parse(timeStr);
                        
                        if (!isNaN(logTime)) {
                            root.lastUpdateTimestamp = logTime;
                            
                            var now = new Date().getTime();
                            var diff = now - logTime;
                            
                            // Check if data is fresh immediately
                            root.isMonitorActive = diff < 5000;
                        } else {
                            console.log("Failed to parse time: " + parts[0]);
                        }

                        var valStr = parts[1].replace(" W", "");
                        var val = parseFloat(valStr);
                        root.wattage = parts[1];
                        
                        // Update Graph Data
                        if (!isNaN(val)) {
                            var now = new Date().getTime();
                            root.wattageHistory.push({t: now, v: val});
                            
                            // Prune old data
                            var cutoff = now - (root.graphDuration * 60 * 1000);
                            while (root.wattageHistory.length > 0 && root.wattageHistory[0].t < cutoff) {
                                root.wattageHistory.shift();
                            }
                            root.wattageHistoryChanged(); // Trigger repaint
                            
                            // Update Max for scaling
                            if (val > root.maxWattage) root.maxWattage = val * 1.2;
                        }
                    }
                }
            }
        }
    }

    // Inactive Warning Overlay
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.8
        visible: !root.isMonitorActive
        z: 100 // On top of everything
        radius: 10

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 20
            spacing: 5
            
            PlasmaComponents.Label {
                text: "⚠️ Monitor Inactive"
                color: "#ff5555" // Reddish
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            PlasmaComponents.Label {
                text: "No data received."
                color: "white"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }

            PlasmaComponents.Label {
                text: "Run this command to start monitor:"
                color: "#cccccc"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignHCenter
            }

            PlasmaComponents.TextArea {
                text: "python3 " + root.monitorScriptPath
                color: "#88ff88" // Greenish
                font.family: "Monospace"
                font.pixelSize: 10
                wrapMode: Text.WrapAnywhere
                readOnly: true
                background: null
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }


    // Graph Data
    property var wattageHistory: []
    property real maxWattage: 100.0 // Dynamic max

    // Background Hints Logic
    Plasmoid.backgroundHints: {
        if (appletBgMode === 0) return 1; // Standard
        if (appletBgMode === 1) return 0; // NoBackground
        if (appletBgMode === 2) return 4; // ShadowBackground
        return 1;
    }

    // System Background (Manual)
    KSvg.FrameSvgItem {
        anchors.fill: parent
        imagePath: "widgets/background"
        visible: root.bgMode === 0 && root.appletBgMode !== 0 
        z: -1
    }

    // Custom Background Rectangle
    Rectangle {
        anchors.fill: parent
        color: root.customBgColor
        opacity: root.bgOpacity / 100.0
        visible: root.bgMode === 2 // Custom
        radius: 10
        z: -1
    }

    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4 // Add small margin
        spacing: 0

        // Above Text (Visible if Position=Above)
        PlasmaComponents.Label {
            id: aboveLabel
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.wattage
            visible: root.cfgTextPosition === 2
            
            font.pixelSize: root.cfgFontSize
            font.family: root.cfgFontFamily !== "" ? root.cfgFontFamily : font.family
            font.bold: root.cfgTextBold
            font.italic: root.cfgTextItalic
            font.underline: root.cfgTextUnderline

            states: [
                State {
                    name: "customColor"
                    when: root.cfgTextColorMode === 1
                    PropertyChanges {
                        target: aboveLabel
                        color: root.cfgCustomTextColor
                    }
                }
            ]
        }

        // Graph Container
        Item {
            id: graphContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.showGraph
            
            Shape {
                anchors.fill: parent
                // layer.enabled: true // Removed to prevent caching issues with color updates
                // layer.samples: 4
                
                // layer.enabled: true // Removed to prevent caching issues with color updates
                // layer.samples: 4

                ShapePath {
                    id: graphShapePath
                    // strokeColor handled by Binding objects below
                    strokeWidth: root.cfgGraphLineWidth
                    fillColor: "transparent"
                    startX: 0
                    startY: graphContainer.height
                    PathPolyline { id: graphLine }
                }

                // Explicit Bindings for Graph Color
                Binding {
                    target: graphShapePath
                    property: "strokeColor"
                    value: root.cfgGraphLineColor
                    when: root.cfgGraphColorMode === 1
                }
                Binding {
                    target: graphShapePath
                    property: "strokeColor"
                    value: PlasmaComponents.Theme.highlightColor
                    when: root.cfgGraphColorMode === 0
                }
            }
            
            // Overlay Text (Visible if Position=Overlay AND Graph is shown)
            PlasmaComponents.Label {
                id: overlayLabel
                anchors.centerIn: parent
                text: root.wattage
                visible: root.cfgTextPosition === 0
                
                font.pixelSize: root.cfgFontSize
                font.family: root.cfgFontFamily !== "" ? root.cfgFontFamily : font.family
                font.bold: root.cfgTextBold
                font.italic: root.cfgTextItalic
                font.underline: root.cfgTextUnderline
                
                // Fix Border Artifact: Only show outline if background is visible (opacity > 0)
                // And use the background color for the outline
                style: (root.bgMode === 2 && root.bgOpacity > 0) ? Text.Outline : Text.Normal
                styleColor: root.bgMode === 2 ? root.customBgColor : "transparent" 

                states: [
                    State {
                        name: "customColor"
                        when: root.cfgTextColorMode === 1
                        PropertyChanges {
                            target: overlayLabel
                            color: root.cfgCustomTextColor
                        }
                    }
                ]
            }

            // Rebuild graph logic ...
            Connections {
                target: root
                function onWattageHistoryChanged() {
                    var points = [];
                    if (root.wattageHistory.length < 2) return;

                    var w = graphContainer.width;
                    var h = graphContainer.height;
                    var now = new Date().getTime();
                    var duration = root.graphDuration * 60 * 1000;
                    var startTime = now - duration;

                    for (var i = 0; i < root.wattageHistory.length; i++) {
                        var pt = root.wattageHistory[i];
                        var x = ((pt.t - startTime) / duration) * w;
                        var y = h - ((pt.v / root.maxWattage) * h);
                        points.push(Qt.point(x, y));
                    }
                    graphLine.path = points;
                }
            }
        }

        // Below Text (Visible if Position=Below OR Graph is hidden)
        PlasmaComponents.Label {
            id: belowLabel
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.wattage
            visible: root.cfgTextPosition === 1 || !root.showGraph
            
            font.pixelSize: root.cfgFontSize
            font.family: root.cfgFontFamily !== "" ? root.cfgFontFamily : font.family
            font.bold: root.cfgTextBold
            font.italic: root.cfgTextItalic
            font.underline: root.cfgTextUnderline

            states: [
                State {
                    name: "customColor"
                    when: root.cfgTextColorMode === 1
                    PropertyChanges {
                        target: belowLabel
                        color: root.cfgCustomTextColor
                    }
                }
            ]
        }
    }
}

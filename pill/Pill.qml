import QtQuick

Item {
    id: root

    property string daemonState: "idle"
    property var audio: null
    property var theme: null
    property var recipe: null
    property string assetRoot: ""

    readonly property int barCount: 9
    readonly property var envelope: [0.35, 0.55, 0.75, 0.92, 1.0, 0.92, 0.75, 0.55, 0.35]
    readonly property bool active: daemonState !== "idle" && daemonState !== ""
    readonly property bool working: daemonState === "transcribing"

    property real peak: 0.0
    property real level: 0.0
    property real phase: 0.0
    property var jitter: [0, 0, 0, 0, 0, 0, 0, 0, 0]

    Connections {
        target: root.audio
        enabled: root.audio !== null
        function onFrameReceived(framePeak, frameRms, vad, tsMs) {
            root.peak = Math.min(1.0, Math.max(0.0, framePeak));
        }
        function onDisconnected() { root.peak = 0.0; }
    }

    onDaemonStateChanged: if (!active) { peak = 0.0; level = 0.0; }

    Timer {
        interval: 16
        repeat: true
        running: root.active
        onTriggered: {
            root.phase += 0.016;
            const target = Math.min(1.0, Math.sqrt(Math.max(0.0, root.peak - 0.004) * 6.0));
            root.level += (target - root.level) * (target > root.level ? 0.6 : 0.18);
            const j = root.jitter.slice();
            for (let i = 0; i < root.barCount; i++) {
                j[i] += ((0.35 + Math.random() * 0.65) - j[i]) * 0.35;
            }
            root.jitter = j;
        }
    }

    Rectangle {
        id: pill
        width: 112
        height: 34
        radius: height / 2
        x: (root.width - width) / 2
        y: root.height - height - 36
        color: "#E6101012"
        border.width: 1
        border.color: "#26FFFFFF"
        opacity: root.active ? 1.0 : 0.0
        scale: root.active ? 1.0 : 0.85
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        Row {
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.barCount
                delegate: Rectangle {
                    required property int index
                    readonly property real wave: 0.5 + 0.5 * Math.sin(root.phase * 6.0 - index * 0.7)
                    readonly property real amount: root.working
                        ? 0.15 + 0.35 * wave
                        : root.envelope[index] * root.level * root.jitter[index]
                    width: 3
                    radius: 1.5
                    height: Math.max(3, 3 + amount * 22)
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#FFFFFF"
                    opacity: root.working ? 0.55 : 0.92
                    Behavior on height { NumberAnimation { duration: 60 } }
                }
            }
        }
    }
}

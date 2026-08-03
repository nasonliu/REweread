import QtQuick

Item {
    required property var appRoot
    required property var answerHoldTimer
    property alias inkCanvas: magicInk
    property alias replyInkCanvas: magicReplyInk
    property alias menuDot: magicMenuDot

    id: magicPage
    anchors.fill: parent
    visible: appRoot.screenName === "magic"
    Rectangle { anchors.fill: parent; color: appRoot.paperColor }
    // A quiet ruled-paper layer: it stays behind both live pen ink and
    // the answer, while the answer baseline follows the same pitch.
    Item {
        id: magicNotebookRules
        anchors.fill: parent
        z: 0
        Repeater {
            model: Math.max(0, Math.ceil((parent.height - appRoot.magicNotebookFirstBaselineY - 40)
                                          / appRoot.magicNotebookLinePitch))
            Item {
                x: 48
                y: appRoot.magicNotebookFirstBaselineY + index * appRoot.magicNotebookLinePitch
                width: parent.width - 96
                height: 2
                Repeater {
                    model: Math.ceil(parent.width / 15)
                    Rectangle {
                        x: index * 15
                        y: 0
                        width: 7
                        height: 1
                        // Keep a real dark source colour: some monochrome
                        // compositor builds quantise a pale source plus
                        // alpha to paper white.  The result is still a
                        // quiet, transparent-looking notebook rule.
                        color: "#303030"
                        opacity: 0.42
                    }
                }
            }
        }
    }
    // The diary starts as an unframed sheet of paper.  The upper half is
    // the writing field; the reply appears beneath it without status UI.
    InkCanvas {
        id: magicInk
        x: 0
        y: 0
        width: appRoot.width
        height: appRoot.magicWritingHeight
        strokes: appRoot.magicStrokeRecords
        opacity: appRoot.magicQuestionOpacity
    }
    MouseArea {
        anchors.left: magicInk.left
        anchors.top: magicInk.top
        width: magicInk.width
        height: magicInk.height
        acceptedButtons: Qt.LeftButton
        // On-device pen strokes come from StylusStore.  Keeping this
        // fallback disabled while it is active prevents a finger/palm
        // from becoming a second handwriting source.
        enabled: !stylusStore.active && !appRoot.magicMenuOpen
        onPressed: function(m) { appRoot.magicBegin(m.x + magicInk.x, m.y + magicInk.y) }
        onPositionChanged: function(m) { appRoot.magicAppend(m.x + magicInk.x, m.y + magicInk.y) }
        onReleased: function(m) { appRoot.magicEnd(m.x + magicInk.x, m.y + magicInk.y) }
    }
    Text {
        id: magicReplyText
        x: 62
        y: appRoot.magicNotebookAnswerTop
        width: appRoot.width - 124
        height: appRoot.height - y - 106
        // The native MagicReplyInk item renders the answer directly into
        // the e-paper buffer.  Keeping this item invisible prevents QML
        // from coalescing glyph updates into word-sized refreshes.
        text: ""
        visible: false
        color: appRoot.inkColor
        opacity: appRoot.magicAnswerOpacity
        font.family: appRoot.magicFontFamily
        font.pixelSize: appRoot.magicNotebookAnswerFontPixels
        wrapMode: Text.WordWrap
        lineHeight: 1.08
        maximumLineCount: 13
        rotation: appRoot.magicReplyTilt
        transformOrigin: Item.TopLeft
    }
    MagicReplyInk {
        id: magicReplyInk
        x: magicReplyText.x
        y: magicReplyText.y
        width: magicReplyText.width
        height: magicReplyText.height
        onFinished: {
            if (appRoot.magicReplyComplete) answerHoldTimer.restart()
        }
        onFaded: appRoot.clearMagicPage()
    }
    // The only persistent control is a pen-triggered, low-chrome
    // settings affordance.  It is large enough to find without turning
    // the paper into a conventional app screen.
    Rectangle {
        id: magicMenuDot
        x: appRoot.width - 104
        y: appRoot.height - 92
        width: 70
        height: 34
        radius: height / 2
        color: appRoot.surfaceColor
        border.color: appRoot.mutedInk
        border.width: 1
        opacity: appRoot.magicMenuOpen ? 0.92 : 0.72
        z: 21
        Text { anchors.centerIn: parent; text: "设置"; color: appRoot.mutedInk; font.pixelSize: 16 }
    }
    Rectangle {
        id: magicMenuPanel
        x: 34
        y: appRoot.height - height - 56
        width: appRoot.width - 68
        height: 366
        visible: appRoot.magicMenuOpen
        z: 20
        color: appRoot.surfaceColor
        opacity: 0.96
        radius: 10

        Text { x: 24; y: 14; text: "字形"; color: appRoot.mutedInk; font.pixelSize: 16 }
        Row {
            x: 22
            y: 40
            spacing: 8
            Repeater {
                model: ["霞鹜文楷", "马善政", "刘建毛草", "智勇行", "龙藏体", "站酷快乐"]
                Rectangle {
                    width: 130
                    height: 44
                    radius: 6
                    color: appRoot.magicFontChoice === modelData ? appRoot.inkColor : "transparent"
                    Text { anchors.centerIn: parent; text: modelData; color: appRoot.magicFontChoice === modelData ? appRoot.paperColor : appRoot.inkColor; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; onClicked: appRoot.magicFontChoice = modelData }
                }
            }
        }
        Rectangle { x: 22; y: 98; width: parent.width - 44; height: 1; color: appRoot.quietLine; opacity: 0.2 }
        Text { x: 24; y: 110; text: "人设"; color: appRoot.mutedInk; font.pixelSize: 16 }
        Grid {
            x: 22
            y: 136
            columns: 3
            columnSpacing: 8
            rowSpacing: 8
            Repeater {
                model: ["温柔笔友", "神秘日记", "福尔摩斯·贝克街", "林黛玉·潇湘馆", "苏轼·东坡居士", "居里夫人·巴黎", "爱丽丝·梦游仙境"]
                Rectangle {
                    width: 280
                    height: 40
                    radius: 6
                    color: appRoot.magicPersonaChoice === modelData ? appRoot.inkColor : "transparent"
                    Text { anchors.centerIn: parent; text: modelData; color: appRoot.magicPersonaChoice === modelData ? appRoot.paperColor : appRoot.inkColor; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; onClicked: appRoot.magicPersonaChoice = modelData }
                }
            }
        }
        Rectangle { x: 22; y: 286; width: parent.width - 44; height: 1; color: appRoot.quietLine; opacity: 0.2 }
        Row {
            x: 22
            y: 304
            spacing: 14
            Repeater {
                model: ["清空纸页", "返回书架", "收起"]
                Rectangle {
                    width: modelData === "返回书架" ? 150 : 118
                    height: 48
                    radius: 6
                    color: "transparent"
                    Text { anchors.centerIn: parent; text: modelData; color: appRoot.inkColor; font.pixelSize: 18 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData === "清空纸页") {
                                appRoot.clearMagicPage()
                                appRoot.magicMenuOpen = false
                            } else if (modelData === "返回书架") {
                                appRoot.magicMenuOpen = false
                                appRoot.screenName = "shelf"
                            } else {
                                appRoot.magicMenuOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
    // The raw stylus input remains active under this layer; it only
    // consumes touch while the pen is in range so a palm cannot clear
    // the page or trigger any of its controls.
    MouseArea {
        anchors.fill: parent
        z: 20
        visible: stylusStore.palmRejectionActive && !appRoot.magicMenuOpen
        preventStealing: true
        onPressed: function(mouse) { mouse.accepted = true }
        onPositionChanged: function(mouse) { mouse.accepted = true }
        onReleased: function(mouse) { mouse.accepted = true }
    }
}


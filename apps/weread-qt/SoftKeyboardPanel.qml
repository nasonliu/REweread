import QtQuick

Rectangle {
    required property var appRoot
    property alias handwritingPad: keyboardHandwritingPad
    property alias handwritingInk: keyboardHandwritingInk

    id: softKeyboardPanel
    x: 0
    y: appRoot.height - height
    width: appRoot.width
    height: 500
    visible: appRoot.showSoftKeyboard
    z: 35
    color: appRoot.paperColor
    border.color: appRoot.inkColor
    border.width: 2

    Column {
        x: 22
        y: 10
        width: parent.width - 44
        spacing: 6

        Row {
            width: parent.width
            height: 44
            spacing: 12

            Text {
                width: parent.width - 170
                height: parent.height
                text: appRoot.keyboardTarget ? String(appRoot.keyboardTarget.text || "") : ""
                color: appRoot.inkColor
                font.pixelSize: 22
                font.bold: true
                elide: Text.ElideLeft
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: 72
                height: parent.height
                radius: 4
                color: appRoot.surfaceColor
                border.color: appRoot.inkColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "关闭"
                    color: appRoot.inkColor
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appRoot.closeSoftKeyboard()
                }
            }

            Rectangle {
                width: 78
                height: parent.height
                radius: 4
                color: appRoot.brandGreenDark
                border.color: appRoot.inkColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "确认"
                    color: "#ffffff"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appRoot.keyboardSubmit()
                }
            }
        }

        Row {
            width: parent.width
            height: 44
            spacing: 8

            Repeater {
                model: [
                    {"mode": "pinyin", "label": "拼音"},
                    {"mode": "handwriting", "label": "手写"},
                    {"mode": "english", "label": "英文"}
                ]

                Rectangle {
                    property bool selected: (modelData.mode === "pinyin" && appRoot.keyboardPinyinMode)
                        || (modelData.mode === "handwriting" && appRoot.keyboardHandwritingMode)
                        || (modelData.mode === "english"
                            && !appRoot.keyboardPinyinMode && !appRoot.keyboardHandwritingMode)
                    property bool permitted: !appRoot.keyboardTarget
                        || appRoot.keyboardTarget.echoMode !== TextInput.Password
                        || modelData.mode === "english"
                    width: 94
                    height: parent.height
                    radius: 4
                    color: selected ? appRoot.inkColor : appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 1
                    opacity: permitted ? 1 : 0.42

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.selected ? appRoot.paperColor : appRoot.inkColor
                        font.pixelSize: 19
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.permitted
                        onClicked: appRoot.setKeyboardInputMode(modelData.mode)
                    }
                }
            }

            Text {
                width: parent.width - 94 * 3 - 8 * 3
                height: parent.height
                text: appRoot.keyboardHandwritingMode
                    ? (appRoot.keyboardCandidatePageCount() > 1
                        ? "候选 " + (appRoot.keyboardCandidatePage + 1) + "/" + appRoot.keyboardCandidatePageCount()
                        : (ocrStore.configured ? "百度 OCR · 手动识别" : "百度 OCR 尚未配置"))
                    : (appRoot.keyboardPinyinMode
                        ? (appRoot.keyboardCandidatePageCount() > 1
                            ? "候选 " + (appRoot.keyboardCandidatePage + 1) + "/" + appRoot.keyboardCandidatePageCount()
                            : "拼音候选")
                        : "直接输入")
                color: appRoot.mutedInk
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Row {
            width: parent.width
            height: 50
            spacing: 8
            clip: true

            Rectangle {
                property bool canMove: appRoot.keyboardCandidatePage > 0
                width: appRoot.keyboardCandidatePageCount() > 1 ? 58 : 0
                height: parent.height
                visible: width > 0
                radius: 4
                color: appRoot.surfaceColor
                border.color: appRoot.inkColor
                border.width: 1
                opacity: canMove ? 1 : 0.42

                Text {
                    anchors.centerIn: parent
                    text: "上页"
                    color: appRoot.inkColor
                    font.pixelSize: 17
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.canMove
                    onClicked: appRoot.keyboardChangeCandidatePage(-1)
                }
            }

            Text {
                width: appRoot.keyboardPinyinMode && !appRoot.keyboardHandwritingMode ? 98 : 0
                height: parent.height
                visible: width > 0
                text: appRoot.keyboardPinyinBuffer === "" ? "输入拼音" : appRoot.keyboardPinyinBuffer
                color: appRoot.mutedInk
                font.pixelSize: 19
                font.bold: true
                elide: Text.ElideLeft
                verticalAlignment: Text.AlignVCenter
            }

            Repeater {
                model: appRoot.keyboardPinyinMode && !appRoot.keyboardHandwritingMode
                    ? appRoot.keyboardPagedPinyinCandidates() : []

                Rectangle {
                    width: 108
                    height: parent.height
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        anchors.margins: 6
                        text: modelData.text
                        color: appRoot.inkColor
                        font.pixelSize: 21
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: appRoot.keyboardChooseCandidate(modelData)
                    }
                }
            }

            Repeater {
                model: appRoot.keyboardHandwritingMode
                    ? appRoot.keyboardPagedHandwritingCandidates() : []

                Rectangle {
                    width: Math.min(136, Math.max(108, handwritingCandidateText.implicitWidth + 24))
                    height: parent.height
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 1

                    Text {
                        id: handwritingCandidateText
                        anchors.fill: parent
                        anchors.margins: 6
                        text: modelData
                        color: appRoot.inkColor
                        font.pixelSize: 21
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: appRoot.keyboardChooseHandwritingCandidate(modelData)
                    }
                }
            }

            Text {
                width: appRoot.keyboardHandwritingMode
                    && appRoot.keyboardHandwritingCandidates.length === 0 ? parent.width : 0
                height: parent.height
                visible: width > 0
                text: appRoot.keyboardHandwritingStatus
                color: appRoot.mutedInk
                font.pixelSize: 19
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle {
                property bool canMove: appRoot.keyboardCandidatePage
                    < appRoot.keyboardCandidatePageCount() - 1
                width: appRoot.keyboardCandidatePageCount() > 1 ? 58 : 0
                height: parent.height
                visible: width > 0
                radius: 4
                color: appRoot.surfaceColor
                border.color: appRoot.inkColor
                border.width: 1
                opacity: canMove ? 1 : 0.42

                Text {
                    anchors.centerIn: parent
                    text: "下页"
                    color: appRoot.inkColor
                    font.pixelSize: 17
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.canMove
                    onClicked: appRoot.keyboardChangeCandidatePage(1)
                }
            }
        }

        Rectangle {
            id: keyboardHandwritingPad
            width: parent.width
            height: 268
            visible: appRoot.keyboardHandwritingMode
            color: "#ffffff"
            border.color: appRoot.inkColor
            border.width: 2
            radius: 4
            clip: true

            Rectangle {
                x: 12
                y: Math.round(parent.height / 2)
                width: parent.width - 24
                height: 1
                color: appRoot.quietLine
                opacity: 0.45
            }

            Text {
                anchors.centerIn: parent
                text: appRoot.keyboardHandwritingStrokes.length === 0
                    && appRoot.keyboardHandwritingCurrentStroke.length === 0
                    ? "在这里连续手写，写完后点“识别”" : ""
                color: appRoot.mutedInk
                opacity: 0.52
                font.pixelSize: 20
                font.bold: true
            }

            InkCanvas {
                id: keyboardHandwritingInk
                anchors.fill: parent
                strokes: appRoot.keyboardHandwritingStoredStrokes()
            }

            MouseArea {
                anchors.fill: parent
                z: 2
                preventStealing: true
                onPressed: function(mouse) {
                    mouse.accepted = true
                    if (stylusStore.palmRejectionActive) {
                        return
                    }
                    var point = keyboardHandwritingPad.mapToItem(appRoot.contentItem,
                                                                mouse.x, mouse.y)
                    appRoot.beginKeyboardHandwritingStroke(point.x, point.y)
                }
                onPositionChanged: function(mouse) {
                    if (pressed && !stylusStore.palmRejectionActive) {
                        var point = keyboardHandwritingPad.mapToItem(appRoot.contentItem,
                                                                    mouse.x, mouse.y)
                        appRoot.appendKeyboardHandwritingStroke(point.x, point.y)
                    }
                }
                onReleased: function(mouse) {
                    var point = keyboardHandwritingPad.mapToItem(appRoot.contentItem,
                                                                mouse.x, mouse.y)
                    appRoot.endKeyboardHandwritingStroke(point.x, point.y)
                }
                onCanceled: {
                    appRoot.cancelKeyboardHandwritingStroke()
                }
            }
        }

        Repeater {
            model: appRoot.keyboardHandwritingMode ? [] : appRoot.keyboardRows

            Row {
                id: keyRow
                property int keyCount: modelData.length
                width: parent.width
                height: 46
                spacing: 8

                Repeater {
                    model: modelData

                    Rectangle {
                        width: Math.floor((parent.width - (keyRow.keyCount - 1) * 8) / keyRow.keyCount)
                        height: parent.height
                        radius: 4
                        color: appRoot.surfaceColor
                        border.color: appRoot.inkColor
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: appRoot.inkColor
                            font.pixelSize: 20
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: appRoot.keyboardTypeKey(modelData)
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 48
            spacing: 10
            visible: !appRoot.keyboardHandwritingMode

            Rectangle {
                width: Math.floor(parent.width * 0.26)
                height: parent.height
                radius: 4
                color: appRoot.surfaceColor
                border.color: appRoot.inkColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "退格"
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appRoot.keyboardBackspace()
                }
            }

            Rectangle {
                width: Math.floor(parent.width * 0.34)
                height: parent.height
                radius: 4
                color: appRoot.surfaceColor
                border.color: appRoot.inkColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "空格"
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (appRoot.keyboardPinyinMode && appRoot.keyboardCandidates.length > 0) {
                            appRoot.keyboardChooseCandidate(appRoot.keyboardCandidates[0])
                        } else {
                            appRoot.keyboardInsert(" ")
                        }
                    }
                }
            }

            Rectangle {
                width: Math.floor(parent.width * 0.18)
                height: parent.height
                radius: 4
                color: appRoot.surfaceColor
                border.color: appRoot.inkColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "清空"
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (appRoot.keyboardTarget) {
                            appRoot.keyboardTarget.text = ""
                            appRoot.keyboardTarget.cursorPosition = 0
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 48
            spacing: 8
            visible: appRoot.keyboardHandwritingMode

            Repeater {
                model: [
                    {"action": "undo", "label": "撤一笔"},
                    {"action": "clear", "label": "清笔迹"},
                    {"action": "recognize", "label": ocrStore.busy ? "识别中" : "识别"},
                    {"action": "backspace", "label": "退格"}
                ]

                Rectangle {
                    property bool recognitionButton: modelData.action === "recognize"
                    property bool recognitionReady: recognitionButton
                        && ocrStore.configured
                        && appRoot.keyboardHandwritingStrokes.length > 0
                        && !ocrStore.busy
                    width: Math.floor((parent.width - 24) / 4)
                    height: parent.height
                    radius: 4
                    color: recognitionReady ? appRoot.brandGreenDark : appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 1
                    opacity: recognitionButton && !recognitionReady ? 0.52 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.recognitionReady ? "#ffffff" : appRoot.inkColor
                        font.pixelSize: 19
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !parent.recognitionButton || parent.recognitionReady
                        onClicked: {
                            if (modelData.action === "undo") {
                                appRoot.keyboardUndoHandwritingStroke()
                            } else if (modelData.action === "clear") {
                                appRoot.keyboardClearHandwriting()
                                appRoot.keyboardHandwritingStatus = ocrStore.configured
                                    ? "写完后点“识别”" : "需联网使用百度 OCR"
                            } else if (modelData.action === "recognize") {
                                appRoot.keyboardRecognizeHandwriting()
                            } else {
                                appRoot.keyboardBackspace()
                            }
                        }
                    }
                }
            }
        }
    }
}


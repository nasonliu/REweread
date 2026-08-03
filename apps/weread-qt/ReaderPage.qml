import QtQuick

Item {
    required property var appRoot
    required property string replyFontFamily
    required property bool replyFontReady
    property alias pageMeasure: readerPageMeasure
    property alias bodyText: readerBodyText
    property alias inkCanvas: readerInkCanvas
    property alias stylusToolBar: readerStylusToolBar
    property alias settingsPanel: readerSettingsPanel

    id: readerPage
    anchors.fill: parent
    visible: appRoot.screenName === "reader"
    onVisibleChanged: {
        if (visible) {
            powerStore.reloadBattery()
            frontlightStore.reload()
        }
    }

    property var book: shelfStore.books[appRoot.selectedIndex] || ({})

    MouseArea {
        id: catalogOpenGestureArea
        x: 0
        y: 170
        width: 96
        height: appRoot.height - appRoot.readerBottomGestureHeight - 170
        z: 8
        enabled: !appRoot.showReaderCatalog && !appRoot.showReaderSettings
        property real startX: 0
        property real startY: 0
        onPressed: function(mouse) {
            startX = mouse.x
            startY = mouse.y
        }
        onReleased: function(mouse) {
            if (mouse.x - startX > 56 && Math.abs(mouse.y - startY) < 96) {
                appRoot.closeReaderSettings()
                appRoot.showReaderCatalog = true
            }
        }
    }

    MouseArea {
        id: readerBackGestureArea
        x: 0
        y: 0
        width: 150
        height: 170
        z: 7
        property real startY: 0
        onPressed: function(mouse) {
            startY = mouse.y
        }
        onReleased: function(mouse) {
            if (mouse.y - startY > 66) {
                appRoot.syncCurrentReaderProgress()
                shelfStore.reload()
                appRoot.screenName = "detail"
            }
        }
    }

    MouseArea {
        id: readerBookmarkGestureArea
        x: appRoot.width - 292
        y: 0
        width: 86
        height: 132
        z: 7
        onClicked: appRoot.toggleReaderBookmark()
    }

    MouseArea {
        id: readerInkGestureArea
        x: appRoot.width - 430
        y: 0
        width: 112
        height: 132
        z: 7
        property real startX: 0
        onPressed: function(mouse) {
            startX = mouse.x
        }
        onReleased: function(mouse) {
            if (startX - mouse.x > 36 || mouse.x - startX > 36) {
                appRoot.annotationMode = !appRoot.annotationMode
            }
        }
    }

    Rectangle {
        id: readerQuickFrontlight
        x: appRoot.width - 370
        y: 28
        width: 260
        height: 42
        z: 10
        radius: height / 2
        color: appRoot.paperColor
        border.color: appRoot.inkColor
        border.width: 2
        clip: true
        property int currentPercent: frontlightStore.powered
            ? Math.round(frontlightStore.brightness / Math.max(1, frontlightStore.maxBrightness) * 100)
            : 0

        Repeater {
            model: appRoot.readerQuickFrontlightLevels

            Rectangle {
                x: index * 52
                y: 0
                width: 52
                height: 42
                property bool selected: Math.abs(readerQuickFrontlight.currentPercent - modelData) <= 13
                color: selected ? appRoot.inkColor : appRoot.paperColor

                Rectangle {
                    x: 0
                    y: 7
                    width: 1
                    height: parent.height - 14
                    visible: index > 0
                    color: parent.selected ? appRoot.paperColor : appRoot.inkColor
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData === 0 ? "关" : modelData
                    color: parent.selected ? appRoot.paperColor : appRoot.inkColor
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appRoot.applyFrontlightPercent(modelData)
                }
            }
        }
    }

    Item {
        id: readerBatteryIndicator
        x: appRoot.width - 92
        y: 34
        width: 58
        height: 30
        z: 10

        Rectangle {
            x: 0
            y: 2
            width: 50
            height: 26
            radius: 3
            color: appRoot.paperColor
            border.color: appRoot.inkColor
            border.width: 2

            Repeater {
                model: 4

                Rectangle {
                    x: 5 + index * 10
                    y: 5
                    width: 8
                    height: 16
                    color: appRoot.inkColor
                    visible: powerStore.batteryLevel >= 10 + index * 25
                }
            }
        }

        Rectangle {
            x: 50
            y: 9
            width: 5
            height: 12
            radius: 1
            color: appRoot.inkColor
        }
    }

    Image {
        x: appRoot.readerMargin
        y: appRoot.readerImageTopMargin
        width: appRoot.width - appRoot.readerMargin * 2
        height: appRoot.currentReaderImageSource === "" ? 0 : appRoot.readerImageTextTopY - appRoot.readerImageTopMargin - 8
        source: appRoot.currentReaderImageSource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: appRoot.currentReaderImageSource !== ""
        onStatusChanged: {
            if (status === Image.Error) {
                appRoot.readerImageLoadFailed = true
                console.log("reader-image-error=" + source)
            }
        }
    }

    // Keep a hidden QTextDocument in the same scene and font path as the
    // visible reader. Pagination uses its painted height to choose a safe
    // page end before any text is clipped near the footer.
    TextEdit {
        id: readerPageMeasure
        x: -appRoot.width - 32
        y: -appRoot.height - 32
        width: appRoot.readerTextWidth()
        height: Math.max(1, appRoot.readerTextViewportHeight(appRoot.readerTextTopMargin))
        opacity: 0
        enabled: false
        readOnly: true
        activeFocusOnPress: false
        selectByMouse: false
        selectByKeyboard: false
        cursorVisible: false
        focus: false
        textFormat: TextEdit.RichText
        color: appRoot.paperColor
        font.pixelSize: appRoot.readerFontSize
        font.family: appRoot.readerFontFamily
        font.weight: appRoot.readerFontWeight
        wrapMode: TextEdit.Wrap
    }

    TextEdit {
        id: readerBodyText
        x: appRoot.readerMargin
        y: appRoot.currentReaderTextTopY
        z: 2
        width: appRoot.readerTextWidth()
        height: appRoot.readerTextViewportHeight(appRoot.currentReaderTextTopY)
        text: appRoot.formatReaderText(appRoot.currentReaderPageText, appRoot.currentReaderTextStart, appRoot.currentReaderTextEnd) + "<!--" + appRoot.forceReaderRefresh + "-->"
        textFormat: TextEdit.RichText
        color: "#111111"
        font.pixelSize: appRoot.readerFontSize
        font.family: appRoot.readerFontFamily
        font.weight: appRoot.readerFontWeight
        readOnly: true
        activeFocusOnPress: false
        selectByMouse: false
        selectByKeyboard: false
        cursorVisible: false
        focus: false
        wrapMode: TextEdit.Wrap
        clip: true
        onLinkActivated: appRoot.handleReaderLink(link)
    }

    Rectangle {
        x: appRoot.readerMargin
        y: appRoot.readerFooterTop
        width: appRoot.readerTextWidth()
        height: 1
        z: 3
        color: appRoot.inkColor
    }

    Text {
        x: appRoot.readerMargin
        y: appRoot.readerFooterTop + 9
        width: (appRoot.width - appRoot.readerMargin * 2) / 2
        height: appRoot.readerFooterHeight - 9
        z: 3
        text: "第 " + (appRoot.pageIndex + 1) + " / " + Math.max(1, appRoot.readerCachedPageCount) + " 页"
        color: appRoot.inkColor
        font.pixelSize: 18
        font.family: appRoot.readerFontFamily
        font.bold: true
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        x: appRoot.width / 2
        y: appRoot.readerFooterTop + 9
        width: appRoot.width / 2 - appRoot.readerMargin
        height: appRoot.readerFooterHeight - 9
        z: 3
        text: "进度 " + Math.round(appRoot.currentReaderProgressPercent()) + "%"
        color: appRoot.inkColor
        font.pixelSize: 18
        font.family: appRoot.readerFontFamily
        font.bold: true
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }

    Repeater {
        id: readerFootnoteTouchLayer
        model: appRoot.readerFootnoteHitRectsForPage()

        MouseArea {
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
            z: 8.5
            enabled: !appRoot.showReaderSettings && !appRoot.showReaderCatalog && !appRoot.showReaderSocialPopup
            preventStealing: true
            onClicked: {}
        }
    }

    Repeater {
        id: readerSocialTouchLayer
        model: appRoot.readerSocialHitRects

        Item {
            id: socialUnderlineDelegate
            property int socialIndex: Math.max(0, Math.floor(Number(modelData.socialIndex) || 0))
            property real dashX: Number(modelData.dashX) || 0
            property real dashY: Number(modelData.dashY) || 0
            property real dashWidth: Math.max(0, Number(modelData.dashWidth) || 0)
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
            z: 8.7

            Repeater {
                model: Math.max(1, Math.ceil(socialUnderlineDelegate.dashWidth / 16))

                Rectangle {
                    x: socialUnderlineDelegate.dashX - socialUnderlineDelegate.x + index * 16
                    y: socialUnderlineDelegate.dashY - socialUnderlineDelegate.y
                    width: Math.min(9, Math.max(0, socialUnderlineDelegate.dashWidth - index * 16))
                    height: 3
                    color: appRoot.inkColor
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !appRoot.showReaderSettings && !appRoot.showReaderCatalog && !appRoot.showReaderSocialPopup
                preventStealing: true
                onPressed: function(mouse) { mouse.accepted = true }
                onReleased: appRoot.openReaderSocialPopup(socialUnderlineDelegate.socialIndex)
            }
        }
    }

    Rectangle {
        id: readerFootnotePanel
        x: 48
        y: Math.round((appRoot.height - height) / 2)
        width: appRoot.width - 96
        height: Math.round(appRoot.height * 0.62)
        z: 9
        visible: appRoot.showReaderFootnote
        color: appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 2
        radius: 8

        Text {
            x: 34
            y: 28
            width: parent.width - 68
            text: String(appRoot.readerActiveFootnote.marker || "注释")
            color: "#9b2226"
            font.pixelSize: 32
            font.weight: Font.Bold
        }

        Text {
            x: 34
            y: 92
            width: parent.width - 68
            height: parent.height - 170
            text: String(appRoot.readerActiveFootnote.text || "")
            color: appRoot.inkColor
            font.pixelSize: Math.max(28, Math.round(appRoot.readerFontSize * 0.80))
            font.family: appRoot.readerFontFamily
            font.weight: Font.Normal
            wrapMode: Text.WordWrap
            clip: true
        }

        Text {
            x: parent.width - width - 34
            y: parent.height - 54
            text: "返回正文"
            color: appRoot.inkColor
            font.pixelSize: 24
            font.weight: Font.DemiBold
        }

        MouseArea {
            anchors.fill: parent
            onClicked: appRoot.closeReaderFootnote()
        }
    }

    MouseArea {
        id: readerSocialPopupOutsideCloseArea
        anchors.fill: parent
        z: 10
        visible: appRoot.showReaderSocialPopup
        enabled: appRoot.showReaderSocialPopup
        onPressed: appRoot.closeReaderSocialPopup()
    }

    Rectangle {
        id: readerSocialPopupPanel
        x: 40
        y: Math.round((appRoot.height - height) / 2)
        width: appRoot.width - 80
        height: Math.round(appRoot.height * 0.80)
        z: 11
        visible: appRoot.showReaderSocialPopup
        color: appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 2
        radius: 8

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Text {
            x: 32
            y: 28
            width: parent.width - 120
            text: "读者评论"
            color: appRoot.inkColor
            font.pixelSize: 34
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Text {
            x: parent.width - 78
            y: 18
            width: 58
            height: 58
            text: "×"
            color: appRoot.inkColor
            font.pixelSize: 40
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                anchors.fill: parent
                onClicked: appRoot.closeReaderSocialPopup()
            }
        }

        Text {
            x: 32
            y: 94
            width: parent.width - 64
            height: 104
            text: appRoot.readerSocialDisplayText(appRoot.readerActiveSocialMark)
            color: appRoot.inkColor
            font.pixelSize: Math.max(27, Math.round(appRoot.readerFontSize * 0.72))
            font.family: appRoot.readerFontFamily
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        Rectangle {
            x: 32
            y: 214
            width: parent.width - 64
            height: 1
            color: appRoot.inkColor
        }

        Text {
            x: 32
            y: 232
            width: parent.width - 64
            height: 42
            text: {
                var reviews = appRoot.readerActiveSocialMark.reviews || []
                var total = Math.max(reviews.length, Math.floor(Number(appRoot.readerActiveSocialMark.totalCount) || 0))
                if (reviews.length === 0 && notesStore.running) {
                    return "评论正在加载..."
                }
                return total > 0 ? (total + " 人在这里有想法") : "暂时没有评论详情"
            }
            color: appRoot.inkColor
            font.pixelSize: 24
            font.bold: true
            elide: Text.ElideRight
        }

        Flickable {
            x: 32
            y: 292
            width: parent.width - 64
            height: parent.height - 324
            contentHeight: socialCommentsColumn.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: socialCommentsColumn
                width: parent.width
                spacing: 0

                Repeater {
                    model: appRoot.readerActiveSocialMark.reviews || []

                    Rectangle {
                        width: socialCommentsColumn.width
                        height: 150
                        color: appRoot.surfaceColor

                        Text {
                            x: 0
                            y: 12
                            width: parent.width
                            height: 32
                            text: modelData.author || "微信读书用户"
                            color: appRoot.inkColor
                            font.pixelSize: 24
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            x: 0
                            y: 50
                            width: parent.width
                            height: 88
                            text: modelData.content || modelData.text || ""
                            color: appRoot.inkColor
                            font.pixelSize: 30
                            font.weight: Font.Normal
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            x: 0
                            y: parent.height - 1
                            width: parent.width
                            height: 1
                            color: appRoot.inkColor
                            opacity: 0.3
                        }
                    }
                }
            }
        }
    }

    Item {
        id: readerInkLayer
        anchors.fill: parent
        z: 8
        visible: appRoot.screenName === "reader"

        InkCanvas {
            id: readerInkCanvas
            anchors.fill: parent
            strokes: appRoot.readerVisibleInkStrokes()
        }

        MouseArea {
            anchors.fill: parent
            visible: appRoot.readerOcrBlockSelection
            z: 3
            onClicked: {
                appRoot.readerOcrBlockSelection = false
                appRoot.readerSuppressPageTurnUntilMs = Date.now() + 500
            }
        }

        Repeater {
            model: readerStore.pageInkBlocks

            Item {
                property var inkBlock: modelData || ({})
                anchors.fill: parent

                MouseArea {
                    x: Math.max(8, Number(inkBlock.x || 0) - 18)
                    y: Math.max(appRoot.readerTextTopMargin, Number(inkBlock.y || 0) - 18)
                    width: Math.min(appRoot.width - x - 8, Number(inkBlock.width || 1) + 36)
                    height: Math.min(appRoot.readerContentBottom - y, Number(inkBlock.height || 1) + 36)
                    enabled: !appRoot.readerOcrBlockSelection
                    z: 1
                    onClicked: appRoot.selectReaderInkBlock(inkBlock)
                }

                Rectangle {
                    x: Math.max(8, Number(inkBlock.x || 0) - 14)
                    y: Math.max(appRoot.readerTextTopMargin, Number(inkBlock.y || 0) - 14)
                    width: Math.min(appRoot.width - x - 8, Number(inkBlock.width || 1) + 28)
                    height: Math.min(appRoot.readerContentBottom - y, Number(inkBlock.height || 1) + 28)
                    visible: appRoot.readerOcrBlockSelection
                             || appRoot.readerSelectedInkBlockId === String(inkBlock.blockId || "")
                    radius: 6
                    color: "transparent"
                    border.color: appRoot.brandGreenDark
                    border.width: 3
                    z: 4

                    Text {
                        x: 5
                        y: -28
                        height: 26
                        text: appRoot.readerOcrBlockSelection ? "点此识别" : "已选中"
                        color: appRoot.brandGreenDark
                        font.pixelSize: 17
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: appRoot.recognizeReaderInkBlock(inkBlock)
                    }
                }

                Rectangle {
                    visible: !!inkBlock.ocrText && !appRoot.readerOcrBlockSelection
                    x: appRoot.clamp(Number(inkBlock.x || 0), 18, appRoot.width - 378)
                    y: appRoot.clamp(Number(inkBlock.y || 0) + Number(inkBlock.height || 0) + 10,
                                  appRoot.readerTextTopMargin, appRoot.readerContentBottom - 54)
                    width: Math.min(360, appRoot.width - x - 18)
                    height: 46
                    radius: 7
                    color: appRoot.paperColor
                    border.color: appRoot.readerMarkerColor
                    border.width: 2
                    z: 2

                    Text {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: "识别：" + (inkBlock.ocrText || "")
                        color: appRoot.inkColor
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: appRoot.recognizeReaderInkBlock(inkBlock)
                    }
                }

                Rectangle {
                    id: readerAiReplyCard
                    property string renderedReply: appRoot.readerAiReplyDisplay(inkBlock)
                    visible: renderedReply !== "" && !appRoot.readerOcrBlockSelection
                    x: appRoot.clamp(Number(inkBlock.x || 0), 18, appRoot.width - 378)
                    y: appRoot.clamp(Number(inkBlock.y || 0) + Number(inkBlock.height || 0)
                                  + (inkBlock.ocrText ? 66 : 12),
                                  appRoot.readerTextTopMargin, appRoot.readerContentBottom - height)
                    width: Math.min(360, appRoot.width - x - 18)
                    height: Math.min(176, Math.max(58, readerAiReplyText.contentHeight + 18))
                    radius: 7
                    color: appRoot.paperColor
                    border.color: appRoot.readerMarkerColor
                    border.width: 1
                    z: 2
                    clip: true

                    Text {
                        id: readerAiReplyText
                        anchors.fill: parent
                        anchors.margins: 9
                        text: readerAiReplyCard.renderedReply
                        color: "#34302a"
                        font.family: readerPage.replyFontReady
                            ? readerPage.replyFontFamily : appRoot.readerFontFamily
                        font.pixelSize: 21
                        wrapMode: Text.WordWrap
                        lineHeight: 1.22
                        maximumLineCount: 5
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Rectangle {
            id: readerInkBlockActions
            property var inkBlock: appRoot.selectedReaderInkBlock()
            visible: !!inkBlock.blockId
            x: appRoot.clamp(Number(inkBlock.x || 0), 18, appRoot.width - width - 18)
            y: {
                var above = Number(inkBlock.y || 0) - height - 18
                if (above >= appRoot.readerTextTopMargin) {
                    return above
                }
                return appRoot.clamp(Number(inkBlock.y || 0) + Number(inkBlock.height || 0) + 18,
                                  appRoot.readerTextTopMargin, appRoot.readerContentBottom - height)
            }
            width: 408
            height: 58
            radius: 10
            color: appRoot.paperColor
            border.color: appRoot.inkColor
            border.width: 2
            z: 6

            Row {
                anchors.fill: parent

                Repeater {
                    model: [
                        {"label": "识别", "action": "ocr"},
                        {"label": "AI 回复", "action": "ai"},
                        {"label": "删除", "action": "delete"},
                        {"label": "取消", "action": "cancel"}
                    ]

                    Rectangle {
                        width: readerInkBlockActions.width / 4
                        height: readerInkBlockActions.height
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: appRoot.inkColor
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Rectangle {
                            anchors.right: parent.right
                            width: 1
                            height: parent.height - 16
                            anchors.verticalCenter: parent.verticalCenter
                            visible: index < 3
                            color: appRoot.quietLine
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.action === "ocr") {
                                    appRoot.recognizeReaderInkBlock(readerInkBlockActions.inkBlock)
                                } else if (modelData.action === "ai") {
                                    appRoot.askReaderInkBlockAi(readerInkBlockActions.inkBlock)
                                } else if (modelData.action === "delete") {
                                    appRoot.deleteSelectedReaderInkBlock()
                                } else {
                                    appRoot.readerSelectedInkBlockId = ""
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: readerInlineOcrToast
            visible: appRoot.readerInlineOcrStatus !== ""
            x: Math.round((appRoot.width - width) / 2)
            y: 108
            width: Math.min(560, appRoot.width - 72)
            height: 58
            radius: 10
            color: appRoot.paperColor
            border.color: appRoot.inkColor
            border.width: 2
            z: 10

            Text {
                anchors.fill: parent
                anchors.margins: 10
                text: appRoot.readerInlineOcrStatus
                color: appRoot.inkColor
                font.pixelSize: 20
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: appRoot.readerOcrBlockSelection
            x: Math.round((appRoot.width - width) / 2)
            y: 108
            width: Math.min(520, appRoot.width - 80)
            height: 54
            radius: 10
            color: appRoot.paperColor
            border.color: appRoot.inkColor
            border.width: 2
            z: 5

            Text {
                anchors.centerIn: parent
                text: "点选要 OCR 的手写块；点空白处取消"
                color: appRoot.inkColor
                font.pixelSize: 20
                font.bold: true
            }
        }

        Repeater {
            model: readerStore.paragraphNotes

            Item {
                property var note: modelData || ({})
                property var placement: appRoot.readerParagraphNotePlacements()[String(note.noteId || "")] || ({ "visible": false })
                visible: appRoot.showHandwrittenNotes && placement.visible
                x: placement.x || 0
                y: placement.y || 0
                width: placement.width || 0
                height: placement.height || 0

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: appRoot.paperColor
                    border.color: note.colorValue || appRoot.inkColor
                    border.width: 2
                }

                Text {
                    x: 7
                    y: 4
                    width: parent.width - 42
                    text: (placement.kind === "page-free" ? "本页笔记" : "段落笔记") + (note.ocrText ? " · 已识别" : "")
                    color: appRoot.mutedInk
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    x: parent.width - 30
                    y: 3
                    width: 26
                    height: 26
                    radius: 13
                    color: appRoot.paperColor
                    border.color: appRoot.inkColor
                    border.width: 1
                    z: 3

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: appRoot.inkColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: readerStore.removeParagraphNote(appRoot.currentBookId, String(note.noteId || ""))
                    }
                }

                Canvas {
                    x: 6
                    y: 21
                    width: parent.width - 12
                    height: parent.height - 27
                    visible: !note.ocrText
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.globalAlpha = 1
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"
                        ctx.lineWidth = 3
                        ctx.strokeStyle = note.colorValue || appRoot.inkColor
                        var strokes = note.strokes || (note.points ? [note.points] : [])
                        for (var strokeIndex = 0; strokeIndex < strokes.length; strokeIndex++) {
                            var points = strokes[strokeIndex] || []
                            if (points.length < 2) {
                                continue
                            }
                            ctx.beginPath()
                            ctx.moveTo((points[0].x || 0) * width, (points[0].y || 0) * height)
                            for (var pointIndex = 1; pointIndex < points.length; pointIndex++) {
                                ctx.lineTo((points[pointIndex].x || 0) * width, (points[pointIndex].y || 0) * height)
                            }
                            ctx.stroke()
                        }
                    }
                    Component.onCompleted: requestPaint()
                }

                Text {
                    x: 7
                    y: 22
                    width: parent.width - 14
                    height: parent.height - 27
                    visible: !!note.ocrText
                    text: note.ocrText || ""
                    color: note.colorValue || appRoot.inkColor
                    font.pixelSize: 16
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appRoot.recognizeParagraphNote(note)
                }
            }
        }

    }

    Item {
        id: readerStylusToolBar
        x: appRoot.width - width - 12
        y: Math.max(178, Math.round(appRoot.height * 0.29))
        width: appRoot.readerStylusToolsExpanded ? appRoot.readerStylusToolBarWidth : 38
        height: appRoot.readerStylusToolsExpanded
                ? appRoot.readerStylusToolBarPadding * 2
                + appRoot.readerStylusTools.length * appRoot.readerStylusToolDotSize
                + Math.max(0, appRoot.readerStylusTools.length - 1) * appRoot.readerStylusToolGap
                + appRoot.readerStylusSectionGap
                : 74
        z: 9
        visible: appRoot.screenName === "reader"
                 && !appRoot.showReaderSettings
                 && !appRoot.showReaderCatalog
                 && !appRoot.showReaderSocialPopup

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: appRoot.paperColor
            border.color: appRoot.inkColor
            border.width: 2
            opacity: 1
        }

        Rectangle {
            id: readerStylusCollapsedHandle
            anchors.centerIn: parent
            width: 26
            height: 26
            radius: 13
            visible: !appRoot.readerStylusToolsExpanded
            color: appRoot.readerMarkerTool === "eraser" ? appRoot.paperColor : appRoot.readerMarkerColor
            border.color: appRoot.inkColor
            border.width: appRoot.readerMarkerTool === "eraser" ? 3 : 1

            Text {
                anchors.centerIn: parent
                text: appRoot.readerAiHandwritingMode ? "AI" : (appRoot.readerMarkerTool === "free" ? "写" : (appRoot.readerMarkerTool === "eraser" ? "擦" : "划"))
                color: appRoot.readerMarkerTool === "eraser" ? appRoot.inkColor : "#ffffff"
                font.pixelSize: 13
                font.bold: true
            }
        }

        Rectangle {
            x: 12
            y: appRoot.readerStylusToolY(4) - Math.round(appRoot.readerStylusSectionGap / 2) - Math.round(appRoot.readerStylusToolGap / 2)
            width: parent.width - 24
            height: 2
            visible: appRoot.readerStylusToolsExpanded
            color: appRoot.quietLine
            opacity: 0.55
        }

        Repeater {
            model: appRoot.readerStylusTools

            Rectangle {
                x: appRoot.readerStylusToolBarPadding
                   + (readerStylusToolBar.width - appRoot.readerStylusToolBarPadding * 2 - appRoot.readerStylusToolDotSize) / 2
                y: appRoot.readerStylusToolY(index)
                width: appRoot.readerStylusToolDotSize
                height: appRoot.readerStylusToolDotSize
                radius: width / 2
                visible: appRoot.readerStylusToolsExpanded
                color: modelData.tool === "color" ? modelData.value : appRoot.paperColor
                border.color: appRoot.readerStylusToolSelected(modelData) ? appRoot.inkColor : appRoot.quietLine
                border.width: appRoot.readerStylusToolSelected(modelData) ? 4 : 1

                Text {
                    anchors.centerIn: parent
                    text: modelData.tool === "clear" && appRoot.readerClearArmed ? "确" : (modelData.label || "")
                    color: appRoot.inkColor
                    font.pixelSize: 18
                    font.bold: true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    MouseArea {
        id: readerPalmRejectionLayer
        anchors.fill: parent
        z: 10
        visible: (appRoot.screenName === "reader" || appRoot.screenName === "magic")
                 && stylusStore.palmRejectionActive
        preventStealing: true
        onPressed: function(mouse) { mouse.accepted = true }
        onPositionChanged: function(mouse) { mouse.accepted = true }
        onReleased: function(mouse) { mouse.accepted = true }
        onCanceled: {}
    }

    MouseArea {
        id: readerLeftPageTurnArea
        x: 0
        y: 90
        width: appRoot.width / 2
        height: Math.max(0, appRoot.readerContentBottom - 90)
        z: 6
        enabled: !appRoot.showReaderSettings && !appRoot.showReaderCatalog && !appRoot.showReaderSocialPopup
        property real startX: 0
        property real startY: 0
        onPressed: function(mouse) {
            startX = mouse.x
            startY = mouse.y
        }
        onReleased: function(mouse) {
            appRoot.handleReaderPageTurnGesture("left", startX, startY, mouse.x, mouse.y)
        }
    }

    MouseArea {
        id: readerRightPageTurnArea
        x: appRoot.width / 2
        y: 90
        width: appRoot.width / 2
        height: Math.max(0, appRoot.readerContentBottom - 90)
        z: 6
        enabled: !appRoot.showReaderSettings && !appRoot.showReaderCatalog && !appRoot.showReaderSocialPopup
        property real startX: 0
        property real startY: 0
        onPressed: function(mouse) {
            startX = mouse.x
            startY = mouse.y
        }
        onReleased: function(mouse) {
            appRoot.handleReaderPageTurnGesture("right", startX, startY, mouse.x, mouse.y)
        }
    }

    MouseArea {
        id: gestureOpenArea
        x: 0
        y: appRoot.height - appRoot.readerBottomGestureHeight
        width: appRoot.width
        height: appRoot.readerBottomGestureHeight
        property real startY: 0
        onPressed: function(mouse) {
            startY = mouse.y
        }
        onReleased: function(mouse) {
            if (startY - mouse.y > 44) {
                appRoot.settingsDragOffset = 0
                appRoot.openReaderSettings()
            }
        }
    }

    Rectangle {
        id: readerSettingsBackdrop
        x: 0
        y: appRoot.height - appRoot.readerSettingsPanelHeight + appRoot.settingsDragOffset
        width: appRoot.width
        height: appRoot.readerSettingsPanelHeight
        visible: appRoot.showReaderSettings
        z: 11
        color: appRoot.paperColor
        opacity: 1
    }

    Rectangle {
        id: readerSettingsPanel
        x: 0
        y: appRoot.height - height + appRoot.settingsDragOffset
        width: appRoot.width
        height: appRoot.readerSettingsPanelHeight
        visible: appRoot.showReaderSettings
        z: 12
        color: appRoot.surfaceColor
        opacity: 1
        radius: 10
        border.color: appRoot.inkColor
        border.width: 1
        clip: true
        onVisibleChanged: if (!visible) appRoot.settingsDragOffset = 0

        Rectangle {
            x: (parent.width - width) / 2
            y: 12
            width: 54
            height: 6
            radius: 3
            color: "#111111"
        }

        MouseArea {
            id: gestureCloseArea
            x: 0
            y: 0
            width: parent.width
            height: 96
            z: 4
            preventStealing: true
            property real startY: 0
            onPressed: function(mouse) {
                startY = mouse.y
                appRoot.settingsDragOffset = 0
            }
            onPositionChanged: function(mouse) {
                appRoot.handleSettingsPanelDownDrag(mouse.y - startY)
            }
            onReleased: function(mouse) {
                if (appRoot.settingsDragOffset > 86 || appRoot.handleSettingsPanelDownDrag(mouse.y - startY) || mouse.y - startY > 72) {
                    appRoot.closeReaderSettings()
                }
                appRoot.settingsDragOffset = 0
            }
        }

        DragHandler {
            id: settingsPanelDragHandler
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            xAxis.enabled: false
            yAxis.enabled: true
            onTranslationChanged: {
                if (active && translation.y > 0) {
                    appRoot.handleSettingsPanelDownDrag(translation.y)
                }
            }
            onActiveChanged: {
                if (!active) {
                    if (appRoot.handleSettingsPanelDownDrag(translation.y)) {
                        appRoot.closeReaderSettings()
                    }
                    appRoot.settingsDragOffset = 0
                }
            }
        }

        function adjust(prop, delta, minValue, maxValue) {
            appRoot[prop] = appRoot.clamp(appRoot[prop] + delta, minValue, maxValue)
            appRoot.scheduleReaderPaginationRebuild()
            appRoot.forceReaderRefresh += 1
        }

        Rectangle {
            x: 0
            y: 78
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.35
        }

        Text {
            x: 0
            y: 34
            width: parent.width
            text: "阅读设置"
            color: appRoot.inkColor
            font.pixelSize: 23
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            x: parent.width - 62
            y: 32
            width: 44
            height: 44
            z: 5
            text: "×"
            color: appRoot.inkColor
            font.pixelSize: 28
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

	            MouseArea {
	                anchors.fill: parent
	                    onClicked: {
	                        appRoot.settingsDragOffset = 0
	                        appRoot.closeReaderSettings()
	                    }
	                }
	            }

        Text {
            x: 24
            y: 98
            text: "字号"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        Text {
            x: 48
            y: 140
            text: "A"
            color: appRoot.inkColor
            font.pixelSize: 27
            font.bold: true
        }

        Rectangle {
            x: (parent.width - width) / 2
            y: 126
            width: 246
            height: 52
            radius: 7
            color: appRoot.surfaceColor
            border.color: appRoot.inkColor
            border.width: 1

            Rectangle {
                x: 78
                y: 0
                width: 1
                height: parent.height
                color: appRoot.inkColor
                opacity: 0.35
            }

            Rectangle {
                x: 168
                y: 0
                width: 1
                height: parent.height
                color: appRoot.inkColor
                opacity: 0.35
            }

            Text {
                x: 0
                y: 0
                width: 78
                height: parent.height
                text: "-"
                color: appRoot.inkColor
                font.pixelSize: 27
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                x: 0
                y: 0
                width: 78
                height: parent.height
                onClicked: readerSettingsPanel.adjust("readerFontSize", -4, 30, 38)
            }

            Text {
                x: 78
                y: 0
                width: 90
                height: parent.height
                text: appRoot.readerFontSize
                color: appRoot.inkColor
                font.pixelSize: 20
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                x: 168
                y: 0
                width: 78
                height: parent.height
                text: "+"
                color: appRoot.inkColor
                font.pixelSize: 25
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                x: 168
                y: 0
                width: 78
                height: parent.height
                onClicked: readerSettingsPanel.adjust("readerFontSize", 4, 30, 38)
            }
        }

        Text {
            x: parent.width - 82
            y: 132
            text: "A"
            color: appRoot.inkColor
            font.pixelSize: 38
            font.bold: true
        }

        Rectangle {
            x: 0
            y: 198
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
        }

        Text {
            x: 24
            y: 218
            text: "行距"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        Row {
            x: 122
            y: 246
            spacing: 12

            Repeater {
                model: appRoot.readerLineHeightSteps
                Rectangle {
                    width: 132
                    height: 58
                    radius: height / 2
                    property bool selected: Math.abs(appRoot.readerLineHeight - modelData.value) < 0.01
                    color: selected ? appRoot.inkColor : appRoot.paperColor
                    border.color: appRoot.inkColor
                    border.width: selected ? 3 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.selected ? appRoot.paperColor : appRoot.inkColor
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            appRoot.readerLineHeight = modelData.value
                            appRoot.applyReaderSettingChange(true)
                        }
                    }
                }
            }
        }

        Rectangle {
            x: 0
            y: 306
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
        }

        Text {
            x: 24
            y: 326
            text: "段距"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        Row {
            x: 122
            y: 354
            spacing: 12

            Repeater {
                model: appRoot.readerParagraphSpacingSteps
                Rectangle {
                    width: 132
                    height: 58
                    radius: height / 2
                    property bool selected: appRoot.readerParagraphSpacing === modelData.value
                    color: selected ? appRoot.inkColor : appRoot.paperColor
                    border.color: appRoot.inkColor
                    border.width: selected ? 3 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.selected ? appRoot.paperColor : appRoot.inkColor
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            appRoot.readerParagraphSpacing = modelData.value
                            appRoot.applyReaderSettingChange(true)
                        }
                    }
                }
            }
        }

        Rectangle {
            x: 0
            y: 414
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
        }

        Text {
            x: 24
            y: 432
            text: "页边距"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        Row {
            x: 132
            y: 422
            spacing: 20

            Repeater {
                model: [
                    { label: "窄", value: 48 },
                    { label: "标准", value: 72 },
                    { label: "宽", value: 104 },
                    { label: "特宽", value: 136 }
                ]

                Rectangle {
                    width: 78
                    height: 52
                    radius: 7
                    color: appRoot.surfaceColor
                    border.color: appRoot.readerMargin === modelData.value ? appRoot.brandGreenDark : appRoot.inkColor
                    border.width: appRoot.readerMargin === modelData.value ? 2 : 1

                    Rectangle {
                        anchors.centerIn: parent
                        width: modelData.value === 48 ? 34 : modelData.value === 72 ? 28 : modelData.value === 104 ? 22 : 16
                        height: 32
                        color: "transparent"
                        border.color: appRoot.readerMargin === modelData.value ? appRoot.brandGreenDark : appRoot.inkColor
                        border.width: 2
                    }

                    MouseArea {
                        anchors.fill: parent
	                            onClicked: {
	                                appRoot.readerMargin = modelData.value
	                                appRoot.markReaderPaginationDirty()
	                                appRoot.rebuildReaderPagination()
	                                appRoot.forceReaderRefresh += 1
	                            }
                    }
                }
            }
        }

        Text {
            x: 24
            y: 496
            text: "首行"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        Row {
            x: 132
            y: 486
            spacing: 14

            Repeater {
                model: [
                    { label: "无", value: 0 },
                    { label: "一字", value: 1 },
                    { label: "两字", value: 2 },
                    { label: "三字", value: 3 }
                ]

                Rectangle {
                    width: 86
                    height: 44
                    radius: 7
                    color: appRoot.surfaceColor
                    border.color: appRoot.readerFirstLineIndentChars === modelData.value ? appRoot.brandGreenDark : appRoot.inkColor
                    border.width: appRoot.readerFirstLineIndentChars === modelData.value ? 2 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: appRoot.readerFirstLineIndentChars === modelData.value ? appRoot.brandGreenDark : appRoot.inkColor
                        font.pixelSize: 17
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
	                            onClicked: {
	                                appRoot.readerFirstLineIndentChars = modelData.value
	                                appRoot.markReaderPaginationDirty()
	                                appRoot.rebuildReaderPagination()
	                                appRoot.forceReaderRefresh += 1
	                            }
                    }
                }
            }
        }

        Rectangle {
            x: 0
            y: 548
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
        }

        Text {
            x: 24
            y: 566
            text: "字体"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        Row {
            x: 124
            y: 558
            spacing: 3

            Repeater {
                model: ["系统", "微米黑", "正黑", "霞鹜文楷", "思源黑体", "思源宋体", "寒蝉正楷", "寒蝉活宋"]
                Rectangle {
                    width: 78
                    height: 42
                    radius: 7
                    color: appRoot.surfaceColor
                    border.color: appRoot.readerFontChoice === modelData ? appRoot.brandGreenDark : appRoot.inkColor
                    border.width: appRoot.readerFontChoice === modelData ? 2 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: appRoot.readerFontChoice === modelData ? appRoot.brandGreenDark : appRoot.inkColor
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            appRoot.readerFontChoice = modelData
                            appRoot.scheduleReaderPaginationRebuild()
                            appRoot.forceReaderRefresh += 1
                        }
                    }
                }
            }
        }

        Text {
            x: 778
            y: 566
            text: "字重"
            color: appRoot.inkColor
            font.pixelSize: 18
            font.bold: true
        }

        Row {
            x: 840
            y: 558
            spacing: 6

            Repeater {
                model: [
                    { label: "加黑", value: Font.DemiBold },
                    { label: "浓黑", value: Font.Bold }
                ]
                Rectangle {
                    width: 52
                    height: 42
                    radius: 7
                    color: appRoot.surfaceColor
                    border.color: appRoot.readerFontWeight === modelData.value ? appRoot.brandGreenDark : appRoot.inkColor
                    border.width: appRoot.readerFontWeight === modelData.value ? 2 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: appRoot.readerFontWeight === modelData.value ? appRoot.brandGreenDark : appRoot.inkColor
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            appRoot.readerFontWeight = modelData.value
                            appRoot.scheduleReaderPaginationRebuild()
                            appRoot.forceReaderRefresh += 1
                        }
                    }
                }
            }
        }

        Rectangle {
            x: 0
            y: 612
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
        }

        Text {
            x: 24
            y: 630
            text: "灯光"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        Row {
            x: 102
            y: 620
            spacing: 10

            Repeater {
                model: appRoot.frontlightLevels
                Rectangle {
                    width: 88
                    height: 48
                    radius: height / 2
                    property int currentPercent: Math.round(frontlightStore.brightness / Math.max(1, frontlightStore.maxBrightness) * 100)
                    property bool selected: Math.abs(currentPercent - modelData) <= 10
                    color: selected ? appRoot.inkColor : appRoot.paperColor
                    border.color: appRoot.inkColor
                    border.width: Math.abs(currentPercent - modelData) <= 10 ? 2 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "关" : modelData + "%"
                        color: parent.selected ? appRoot.paperColor : appRoot.inkColor
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: appRoot.applyFrontlightPercent(modelData)
                    }
                }
            }
        }

        Rectangle {
            x: 0
            y: 682
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
            visible: parent.height > 720
        }

        Text {
            x: 24
            y: 696
            text: "跳转进度"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
            visible: parent.height > 720
        }

        Rectangle {
            id: progressJumpSlider
            x: 150
            y: 709
            width: parent.width - 270
            height: 12
            radius: 6
            color: appRoot.surfaceColor
            border.color: appRoot.inkColor
            border.width: 1
            visible: parent.height > 720

	                Rectangle {
	                    x: 0
	                    y: 0
	                    width: parent.width * appRoot.currentReaderProgressValue / 100
	                    height: parent.height
	                    radius: 6
	                    color: appRoot.brandGreenDark
            }

            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) {
                    appRoot.setReaderProgressPercent(mouse.x / progressJumpSlider.width * 100)
                }
                onPositionChanged: function(mouse) {
                    if (pressed) {
                        appRoot.setReaderProgressPercent(mouse.x / progressJumpSlider.width * 100)
                    }
                }
            }
        }

        Text {
            x: parent.width - 102
	                y: 694
	                width: 76
	                height: 42
	                text: Math.round(appRoot.currentReaderProgressValue) + "%"
            color: appRoot.inkColor
            font.pixelSize: 18
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            visible: parent.height > 720
        }

        Rectangle {
            x: 0
            y: 744
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
            visible: parent.height > 780
        }

        Text {
            x: 24
            y: 758
            text: "网络"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
            visible: parent.height > 780
        }

        Text {
            x: 102
            y: 758
            width: parent.width - 278
            height: 42
            text: networkStore.summary
            color: appRoot.inkColor
            font.pixelSize: 15
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            visible: parent.height > 780
        }

        Rectangle {
            x: parent.width - 154
            y: 754
            width: 112
            height: 42
            radius: 7
            color: appRoot.surfaceColor
            border.color: appRoot.inkColor
            border.width: 1
            visible: parent.height > 780

            Text {
                anchors.centerIn: parent
                text: "刷新"
                color: appRoot.inkColor
                font.pixelSize: 16
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: networkStore.reload()
            }
        }

        Rectangle {
            x: 0
            y: 788
            width: parent.width
            height: 1
            color: appRoot.inkColor
            opacity: 0.22
            visible: parent.height > 812
        }

        Rectangle {
            x: 24
            y: 798
            width: 128
            height: 42
            radius: 7
            color: appRoot.inkColor
            border.color: appRoot.inkColor
            border.width: 1
            visible: parent.height > 812

            Text {
                anchors.centerIn: parent
                text: "退出到书架"
                color: appRoot.paperColor
                font.pixelSize: 16
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: appRoot.exitReaderToShelf()
            }
        }

        Rectangle {
            x: 164
            y: 798
            width: 128
            height: 42
            radius: 7
            color: appRoot.surfaceColor
            border.color: appRoot.inkColor
            border.width: 1
            visible: parent.height > 812

            Text {
                anchors.centerIn: parent
                text: "重绘本页"
                color: appRoot.inkColor
                font.pixelSize: 16
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: appRoot.forceReaderRefresh += 1
            }
        }

        Rectangle {
            x: 304
            y: 798
            width: 128
            height: 42
            radius: 7
            color: progressSyncStore.running ? appRoot.inkColor : appRoot.surfaceColor
            border.color: appRoot.inkColor
            border.width: 1
            visible: parent.height > 812

            Text {
                anchors.centerIn: parent
                text: "同步进度"
                color: progressSyncStore.running ? "#ffffff" : appRoot.inkColor
                font.pixelSize: 16
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                enabled: !progressSyncStore.running
                onClicked: progressSyncStore.syncProgress(appRoot.currentBookId, appRoot.currentReaderProgressPercent(), appRoot.currentReaderSummaryText(), appRoot.currentReaderElapsedSeconds())
            }
        }

        Rectangle {
            x: 444
            y: 798
            width: 128
            height: 42
            radius: 7
            color: progressSyncStore.running ? appRoot.inkColor : appRoot.surfaceColor
            border.color: appRoot.inkColor
            border.width: 1
            visible: parent.height > 812

            Text {
                anchors.centerIn: parent
                text: "拉取进度"
                color: progressSyncStore.running ? "#ffffff" : appRoot.inkColor
                font.pixelSize: 16
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                enabled: !progressSyncStore.running
                onClicked: progressSyncStore.pullProgress(appRoot.currentBookId)
            }
        }

        Text {
            x: 588
            y: 798
            width: parent.width - 612
            height: 42
            text: progressSyncStore.statusText
            color: appRoot.inkColor
            font.pixelSize: 15
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            visible: parent.height > 812
        }

        MouseArea {
            id: settingsPanelBottomCloseArea
            x: parent.width - 92
            y: parent.height - 190
            width: 92
            height: 190
            z: 8
            preventStealing: true
            property real startY: 0
            onPressed: function(mouse) {
                startY = mouse.y
                appRoot.settingsDragOffset = 0
            }
            onPositionChanged: function(mouse) {
                appRoot.handleSettingsPanelDownDrag(mouse.y - startY)
            }
            onReleased: function(mouse) {
                if (appRoot.settingsDragOffset > 86 || appRoot.handleSettingsPanelDownDrag(mouse.y - startY)) {
                    appRoot.closeReaderSettings()
                }
                appRoot.settingsDragOffset = 0
            }
        }

    }

    MouseArea {
        id: catalogCloseGestureArea
        x: appRoot.readerCatalogPanelWidth
        y: 0
        width: appRoot.width - appRoot.readerCatalogPanelWidth
        height: appRoot.height
        visible: appRoot.showReaderCatalog
        enabled: appRoot.showReaderCatalog
        z: 13
        preventStealing: true
        property real startX: 0
        onPressed: function(mouse) {
            startX = mouse.x
        }
        onReleased: function(mouse) {
            if (Math.abs(mouse.x - startX) > 56) {
                appRoot.closeReaderCatalog()
                return
            }
            appRoot.closeReaderCatalog()
        }
    }

    Rectangle {
        id: readerCatalogPanel
        x: 0
        y: 0
        width: appRoot.readerCatalogPanelWidth
        height: appRoot.height
        visible: appRoot.showReaderCatalog
        z: 14
        color: appRoot.surfaceColor

        DragHandler {
            id: catalogCloseDragHandler
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            onActiveChanged: {
                if (!active && Math.abs(translation.x) > 56) {
                    appRoot.closeReaderCatalog()
                }
            }
        }

        Text {
            x: 44
            y: 34
            width: parent.width - 160
            text: "目录"
            color: appRoot.inkColor
            font.pixelSize: 34
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            x: parent.width - 86
            y: 30
            width: 54
            height: 54
            text: "×"
            color: appRoot.inkColor
            font.pixelSize: 34
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                anchors.fill: parent
                onClicked: appRoot.closeReaderCatalog()
            }
        }

        Rectangle {
            x: 44
            y: 96
            width: parent.width - 88
            height: 1
            color: appRoot.inkColor
        }

        Row {
            x: 44
            y: 122
            width: parent.width - 88
            height: 58
            spacing: 12

            Rectangle {
                width: Math.floor((parent.width - 12) / 2)
                height: 48
                radius: 24
                color: appRoot.surfaceColor
                border.color: appRoot.inkColor
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "回到书架"
                    color: appRoot.inkColor
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appRoot.exitReaderToShelf()
                }
            }

            Rectangle {
                width: Math.floor((parent.width - 12) / 2)
                height: 48
                radius: 24
                color: downloadStore.running ? appRoot.goldAccent : appRoot.brandGreenDark
                border.color: appRoot.inkColor
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: downloadStore.running ? "下载中" : "下载整本"
                    color: downloadStore.running ? appRoot.inkColor : "#ffffff"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !downloadStore.running && appRoot.currentBookId !== ""
                    onClicked: downloadStore.downloadBook(appRoot.currentBookId, readerStore.title)
                }
            }
        }

        Text {
            x: 44
            y: 202
            width: parent.width - 88
            height: 44
            text: "章节"
            color: appRoot.inkColor
            font.pixelSize: 22
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        ListView {
            id: readerCatalogList
            x: 44
            y: 254
            width: parent.width - 88
            height: parent.height - 288
            model: readerStore.chapters
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: height * 2
            clip: true

            delegate: Rectangle {
                width: readerCatalogList.width
                height: 74
                color: appRoot.surfaceColor

                Text {
                    x: 0
                    y: 0
                    width: parent.width - 150
                    height: parent.height
                    text: modelData.title || ("第 " + (index + 1) + " 章")
                    color: appRoot.inkColor
                    font.pixelSize: 23
                    font.bold: true
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    x: parent.width - 124
                    y: 0
                    width: 118
                    height: parent.height
                    text: appRoot.readerChapterPageLabel(modelData)
                    color: appRoot.inkColor
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    x: 0
                    y: parent.height - 1
                    width: parent.width
                    height: 1
                    color: appRoot.inkColor
                    opacity: 0.28
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appRoot.jumpToChapter(modelData)
                }
            }
        }
    }
}


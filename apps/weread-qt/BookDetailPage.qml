import QtQuick

Item {
    required property var appRoot

    id: detailPage
    anchors.fill: parent
    visible: appRoot.screenName === "detail"

    property var book: appRoot.currentDetailBook()

    Text {
        x: 34
        y: 34
        width: 120
        text: "返回"
        color: appRoot.inkColor
        font.pixelSize: 23
        font.bold: true

        MouseArea {
            anchors.fill: parent
            onClicked: {
                appRoot.showDetailCatalog = false
                appRoot.screenName = "shelf"
            }
        }
    }

    Rectangle {
        id: detailCover
        x: 52
        y: 124
        width: 306
        height: width / appRoot.coverAspectRatio
        radius: 3
        color: detailPage.book.colorA
        border.color: appRoot.inkColor
        border.width: 1
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.42
            color: detailPage.book.colorB
        }

        Image {
            anchors.fill: parent
            source: detailPage.book.coverSource || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: source !== ""
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 44
            text: "封面"
            color: "#111111"
            font.pixelSize: 28
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: detailPage.book.coverSource === ""
        }
    }

    Text {
        x: 394
        y: 130
        width: appRoot.width - 448
        text: detailPage.book.title
        color: appRoot.inkColor
        font.pixelSize: 40
        font.bold: true
        wrapMode: Text.WordWrap
        maximumLineCount: 3
    }

    Text {
        x: 396
        y: 252
        width: appRoot.width - 450
        text: detailPage.book.author + " · " + detailPage.book.categoryName
        color: appRoot.mutedInk
        font.pixelSize: 24
        font.bold: true
        elide: Text.ElideRight
    }

    Text {
        x: 396
        y: 298
        width: appRoot.width - 450
        text: detailPage.book.ratingLine || "微信读书"
        color: appRoot.inkColor
        font.pixelSize: 24
        font.bold: true
    }

    Text {
        x: 396
        y: 350
        width: appRoot.width - 450
        text: detailPage.book.intro
        color: appRoot.inkColor
        font.pixelSize: 23
        lineHeight: 1.22
        wrapMode: Text.WordWrap
        maximumLineCount: 5
        elide: Text.ElideRight
    }

    Text {
        x: 52
        y: 600
        width: appRoot.width - 104
        text: "阅读进度"
        color: appRoot.inkColor
        font.pixelSize: 24
        font.bold: true
    }

    Rectangle {
        id: detailProgressBar
        x: 52
        y: 640
        width: appRoot.width - 104
        height: 12
        radius: 2
        color: "#ffffff"
        border.color: appRoot.inkColor
        border.width: 1
        Rectangle {
            x: 0
            y: 0
            width: parent.width * (detailPage.book.progressRatio || 0)
            height: parent.height
            radius: 2
            color: appRoot.brandGreenDark
        }
    }

    Text {
        x: 52
        y: 670
        width: appRoot.width - 104
        text: detailPage.book.progressLabel || detailPage.book.progress
        color: appRoot.inkColor
        font.pixelSize: 21
        font.bold: true
    }

    Rectangle {
        x: 52
        y: 718
        width: Math.round((appRoot.width - 122) * 0.58)
        height: 68
        radius: 4
        color: appRoot.brandGreenDark
        border.color: appRoot.inkColor
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: "继续阅读"
            color: "#ffffff"
            font.pixelSize: 24
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                appRoot.openOrDownloadBook(detailPage.book)
            }
        }
    }

    Rectangle {
        x: 70 + Math.round((appRoot.width - 122) * 0.58)
        y: 718
        width: appRoot.width - x - 52
        height: 68
        radius: 4
        color: downloadStore.running ? appRoot.goldAccent : appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 2
        Text {
            anchors.centerIn: parent
            text: downloadStore.running ? "取消下载" : detailPage.book.downloadActionText
            color: appRoot.inkColor
            font.pixelSize: 23
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (downloadStore.running) {
                    downloadStore.cancelDownload()
                } else if (detailPage.book.downloadState === "full") {
                    appRoot.openOrDownloadBook(detailPage.book)
                } else {
                    downloadStore.downloadBook(detailPage.book.bookId, detailPage.book.title)
                }
            }
        }
    }

    Text {
        x: 52
        y: 806
        width: appRoot.width - 104
        text: shelfStore.refreshingDetails
            ? shelfStore.detailProgress
            : (downloadStore.queuedCount > 0
                ? downloadStore.progressText + " · 队列 " + downloadStore.queuedCount + " 本"
                : downloadStore.progressText)
        color: downloadStore.state === "error" ? "#8b1e1e" : "#111111"
        font.pixelSize: 21
        font.bold: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        x: 52
        y: 836
        width: (appRoot.width - 104) / 3
        height: 30
        text: "目录"
        color: appRoot.inkColor
        font.pixelSize: 19
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        MouseArea {
            anchors.fill: parent
            onClicked: {
                appRoot.showDetailCatalog = true
                bookCatalogStore.loadCatalog(detailPage.book.bookId, detailPage.book.title)
            }
        }
    }

    Text {
        x: 52 + (appRoot.width - 104) / 3
        y: 836
        width: (appRoot.width - 104) / 3
        height: 30
        visible: !downloadStore.running && (detailPage.book.downloadState === "full" || detailPage.book.localEpubPath !== "")
        text: "删除下载"
        color: appRoot.inkColor
        font.pixelSize: 19
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        MouseArea {
            anchors.fill: parent
            onClicked: {
                downloadStore.deleteDownload(detailPage.book.bookId, detailPage.book.title)
                shelfStore.reload()
                shelfStore.refreshBookDetails(detailPage.book.bookId)
            }
        }
    }

    Text {
        x: 52 + (appRoot.width - 104) / 3 * 2
        y: 836
        width: (appRoot.width - 104) / 3
        height: 30
        visible: !downloadStore.running && (detailPage.book.downloadState === "full" || detailPage.book.localEpubPath !== "")
        text: "修复插图"
        color: appRoot.inkColor
        font.pixelSize: 19
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        MouseArea {
            anchors.fill: parent
            onClicked: downloadStore.repairBookImages(detailPage.book.bookId, detailPage.book.title)
        }
    }

    Text {
        x: 52
        y: 872
        width: appRoot.width - 104
        height: 30
        visible: downloadStore.queuedCount > 0
        text: "清空队列"
        color: appRoot.inkColor
        font.pixelSize: 19
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        MouseArea {
            anchors.fill: parent
            onClicked: downloadStore.clearDownloadQueue()
        }
    }

    Text {
        x: 52
        y: 912
        width: appRoot.width - 104
        text: "书评"
        color: appRoot.inkColor
        font.pixelSize: 30
        font.bold: true
    }

    Rectangle {
        x: 52
        y: 960
        width: appRoot.width - 104
        height: Math.min(116, appRoot.height - 980)
        radius: 4
        color: appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            Repeater {
                model: detailPage.book.reviewSnippets || []

                Text {
                    id: reviewSnippetText
                    width: parent.width
                    text: modelData
                    color: appRoot.inkColor
                    font.pixelSize: 22
                    font.bold: true
                    lineHeight: 1.18
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }

    Item {
        id: detailRedesign
        anchors.fill: parent
        z: 13

        Rectangle {
            anchors.fill: parent
            color: appRoot.paperColor
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Text {
            x: 42
            y: 32
            width: 150
            height: 54
            text: "‹  书架"
            color: appRoot.inkColor
            font.pixelSize: 28
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    appRoot.showDetailCatalog = false
                    appRoot.screenName = "shelf"
                }
            }
        }

        Text {
            x: 250
            y: 34
            width: appRoot.width - 500
            height: 52
            text: "书籍详情"
            color: appRoot.inkColor
            font.pixelSize: 28
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            x: 40
            y: 96
            width: appRoot.width - 80
            height: 2
            color: appRoot.inkColor
        }

        Item {
            id: detailHero
            x: 48
            y: 124
            width: appRoot.width - 96
            height: 472

            Rectangle {
                id: detailHeroCover
                x: 0
                y: 0
                width: 286
                height: Math.round(width / appRoot.coverAspectRatio)
                radius: 3
                color: detailPage.book.colorA || appRoot.paperColor
                border.color: appRoot.inkColor
                border.width: 2
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: detailPage.book.coverSource || ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: source !== ""
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 44
                    text: detailPage.book.title || "微信读书"
                    color: appRoot.inkColor
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: detailPage.book.coverSource === ""
                }
            }

            Text {
                x: 326
                y: 0
                width: parent.width - 326
                height: 124
                text: detailPage.book.title || "未命名书籍"
                color: appRoot.inkColor
                font.pixelSize: 44
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            Text {
                x: 326
                y: 140
                width: parent.width - 326
                height: 38
                text: detailPage.book.author || "作者未知"
                color: appRoot.inkColor
                font.pixelSize: 27
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                x: 326
                y: 190
                width: parent.width - 326
                height: 36
                text: {
                    var parts = [detailPage.book.ratingLine || "微信读书"]
                    if (detailPage.book.categoryName) parts.push(detailPage.book.categoryName)
                    if (Number(detailPage.book.wordCount) > 0) parts.push(Math.round(Number(detailPage.book.wordCount) / 10000) + " 万字")
                    return parts.join("  ·  ")
                }
                color: appRoot.inkColor
                font.pixelSize: 23
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                x: 326
                y: 246
                width: parent.width - 326
                height: 30
                text: "内容简介"
                color: appRoot.inkColor
                font.pixelSize: 23
                font.weight: Font.Bold
            }

            Text {
                x: 326
                y: 286
                width: parent.width - 326
                height: 180
                text: detailPage.book.intro || "暂无简介"
                color: appRoot.inkColor
                font.pixelSize: 26
                font.family: appRoot.readerFontFamily
                font.weight: Font.Normal
                lineHeight: 1.22
                wrapMode: Text.WordWrap
                maximumLineCount: 6
                elide: Text.ElideRight
            }
        }

        Text {
            x: 48
            y: 624
            width: 240
            height: 46
            text: "阅读进度"
            color: appRoot.inkColor
            font.pixelSize: 27
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: detailProgressPercent
            x: appRoot.width - 218
            y: 610
            width: 170
            height: 62
            text: Math.round((detailPage.book.progressRatio || 0) * 100) + "%"
            color: appRoot.brandGreenDark
            font.pixelSize: 42
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            x: 48
            y: 682
            width: appRoot.width - 96
            height: 16
            radius: 3
            color: appRoot.paperColor
            border.color: appRoot.inkColor
            border.width: 2
            Rectangle {
                x: 2
                y: 2
                width: Math.max(0, (parent.width - 4) * (detailPage.book.progressRatio || 0))
                height: parent.height - 4
                radius: 2
                color: appRoot.brandGreenDark
            }
        }

        Rectangle {
            id: detailPrimaryAction
            x: 48
            y: 744
            width: 560
            height: 78
            radius: 4
            color: appRoot.brandGreenDark
            border.color: appRoot.inkColor
            border.width: 2
            Text {
                anchors.centerIn: parent
                text: "继续阅读"
                color: "#ffffff"
                font.pixelSize: 28
                font.weight: Font.Bold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: appRoot.openOrDownloadBook(detailPage.book)
            }
        }

        Rectangle {
            x: 628
            y: 744
            width: appRoot.width - 676
            height: 78
            radius: 4
            color: downloadStore.running ? appRoot.goldAccent : appRoot.paperColor
            border.color: appRoot.inkColor
            border.width: 2
            Text {
                anchors.centerIn: parent
                text: downloadStore.running ? "取消下载" : detailPage.book.downloadActionText
                color: appRoot.inkColor
                font.pixelSize: 26
                font.weight: Font.Bold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (downloadStore.running) {
                        downloadStore.cancelDownload()
                    } else if (detailPage.book.downloadState === "full") {
                        appRoot.openOrDownloadBook(detailPage.book)
                    } else {
                        downloadStore.downloadBook(detailPage.book.bookId, detailPage.book.title)
                    }
                }
            }
        }

        Row {
            x: 48
            y: 850
            width: appRoot.width - 96
            height: 58
            spacing: 0

            Repeater {
                model: ["目录", "删除下载", "修复插图"]
                Rectangle {
                    width: (appRoot.width - 96) / 3
                    height: 58
                    color: appRoot.paperColor
                    border.color: appRoot.inkColor
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: appRoot.inkColor
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (index === 0) {
                                appRoot.showDetailCatalog = true
                                bookCatalogStore.loadCatalog(detailPage.book.bookId, detailPage.book.title)
                            } else if (index === 1) {
                                downloadStore.deleteDownload(detailPage.book.bookId, detailPage.book.title)
                                shelfStore.reload()
                                shelfStore.refreshBookDetails(detailPage.book.bookId)
                            } else {
                                downloadStore.repairBookImages(detailPage.book.bookId, detailPage.book.title)
                            }
                        }
                    }
                }
            }
        }

        Text {
            x: 48
            y: 928
            width: appRoot.width - 96
            height: 42
            text: shelfStore.refreshingDetails
                ? shelfStore.detailProgress
                : (downloadStore.queuedCount > 0
                    ? downloadStore.progressText + " · 队列 " + downloadStore.queuedCount + " 本"
                    : downloadStore.progressText)
            color: downloadStore.state === "error" ? "#8b1e1e" : appRoot.inkColor
            font.pixelSize: 22
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Rectangle {
            x: 48
            y: 990
            width: appRoot.width - 96
            height: 2
            color: appRoot.inkColor
        }

        Text {
            x: 48
            y: 1018
            width: appRoot.width - 96
            height: 52
            text: "推荐书评"
            color: appRoot.inkColor
            font.pixelSize: 34
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
        }

        Flickable {
            id: detailReviewList
            x: 48
            y: 1084
            width: appRoot.width - 96
            height: appRoot.height - 1120
            contentHeight: detailReviewColumn.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: detailReviewColumn
                width: parent.width
                spacing: 0

                Repeater {
                    model: detailPage.book.reviewSnippets || []
                    Item {
                        width: detailReviewColumn.width
                        height: 166
                        Text {
                            x: 0
                            y: 18
                            width: parent.width
                            height: 126
                            text: modelData
                            color: appRoot.inkColor
                            font.pixelSize: 28
                            font.family: appRoot.readerFontFamily
                            font.weight: Font.Normal
                            lineHeight: 1.20
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            x: 0
                            y: parent.height - 2
                            width: parent.width
                            height: 2
                            color: appRoot.inkColor
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: detailCatalogPanel
        x: 86
        y: 160
        width: appRoot.width - 172
        height: appRoot.height - 260
        radius: 4
        color: appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 2
        visible: appRoot.showDetailCatalog
        z: 14

        Text {
            x: 24
            y: 18
            width: parent.width - 168
            height: 44
            text: "目录"
            color: appRoot.inkColor
            font.pixelSize: 30
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            x: 24
            y: 64
            width: parent.width - 168
            height: 34
            text: bookCatalogStore.statusText
            color: appRoot.inkColor
            font.pixelSize: 18
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            x: parent.width - 106
            y: 22
            width: 82
            height: 42
            text: "关闭"
            color: appRoot.inkColor
            font.pixelSize: 21
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                anchors.fill: parent
                onClicked: appRoot.showDetailCatalog = false
            }
        }

        Flickable {
            x: 24
            y: 112
            width: parent.width - 48
            height: parent.height - 136
            contentHeight: detailCatalogColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: detailCatalogColumn
                width: parent.width
                spacing: 0

                Text {
                    width: parent.width
                    height: 58
                    text: bookCatalogStore.running ? "正在加载..." : "暂无目录"
                    color: appRoot.inkColor
                    font.pixelSize: 22
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    visible: bookCatalogStore.chapters.length === 0
                }

                Repeater {
                    model: bookCatalogStore.chapters

                    Rectangle {
                        width: detailCatalogColumn.width
                        height: 70
                        color: appRoot.surfaceColor

                        Text {
                            x: Math.min(28, (modelData.level || 0) * 18)
                            y: 0
                            width: parent.width - 170
                            height: parent.height
                            text: modelData.label || modelData.title
                            color: appRoot.inkColor
                            font.pixelSize: 22
                            font.bold: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            x: parent.width - 138
                            y: 0
                            width: 128
                            height: parent.height
                            text: (modelData.wordCount || 0) > 0 ? (modelData.wordCount + " 字") : ""
                            color: appRoot.inkColor
                            font.pixelSize: 17
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
                            onClicked: {
                                appRoot.showDetailCatalog = false
                                if (detailPage.book.downloadState === "full" || detailPage.book.localEpubPath !== "") {
                                    appRoot.enterReaderForCatalogChapter(detailPage.book, modelData)
                                } else {
                                    appRoot.downloadCatalogChapter(detailPage.book, modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


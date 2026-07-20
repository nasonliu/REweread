import QtQuick

Item {
    required property var appRoot
    property alias discoverSearchInputField: discoverSearchInput

    id: shelfPage
    anchors.fill: parent
    visible: appRoot.screenName === "shelf"

    Rectangle {
        x: 0
        y: 0
        width: appRoot.width
        height: appRoot.height
        color: appRoot.paperColor
    }

    Text {
        id: shelfTitle
        x: 44
        y: 54
        width: 350
        text: "书架"
        color: appRoot.inkColor
        font.pixelSize: 44
        font.bold: true
    }

    Text {
        x: 46
        y: 112
        width: appRoot.width - 260
        text: shelfStore.shelfProgress !== "" ? shelfStore.shelfProgress : "微信读书 · 已同步 " + shelfStore.books.length + " 本"
        color: appRoot.mutedInk
        font.pixelSize: 23
        font.bold: true
    }

    Rectangle {
        x: appRoot.width - 242
        y: 56
        width: 104
        height: 46
        radius: 4
        color: shelfStore.refreshingShelf ? appRoot.inkColor : appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: shelfStore.refreshingShelf ? "同步中" : "同步"
            color: shelfStore.refreshingShelf ? "#ffffff" : appRoot.inkColor
            font.pixelSize: 22
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            enabled: !shelfStore.refreshingShelf
            onClicked: shelfStore.refreshShelf()
        }
    }

    Rectangle {
        x: appRoot.width - 370
        y: 56
        width: 116
        height: 46
        radius: 4
        color: downloadStore.running ? appRoot.goldAccent : appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: "下载本页"
            color: appRoot.inkColor
            font.pixelSize: 19
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: downloadStore.downloadBooks(appRoot.currentShelfPageBooks())
        }
    }

    Rectangle {
        x: appRoot.width - 522
        y: 56
        width: 140
        height: 46
        radius: 4
        visible: shelfStore.recentBook.bookId !== undefined && shelfStore.recentBook.bookId !== ""
        color: appRoot.brandGreenDark
        border.color: appRoot.inkColor
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: "继续阅读"
            color: "#ffffff"
            font.pixelSize: 19
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: appRoot.openOrDownloadBook(shelfStore.recentBook)
        }
    }

    Rectangle {
        id: shelfExitSystemButton
        x: appRoot.width - 126
        y: 56
        width: 82
        height: 46
        radius: 4
        color: appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: "退出"
            color: appRoot.inkColor
            font.pixelSize: 20
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: appControl.quitToSystem()
        }
    }

    Item {
        id: shelfGrid
        x: 44
        y: 142
        width: appRoot.width - 88
        height: appRoot.height - 232
        visible: appRoot.shelfTab === "书架" && shelfStore.books.length > 0
        property real cellWidth: width / appRoot.shelfColumns
        property real cellHeight: height / 3
        property real coverWidth: Math.min(cellWidth - 24, (cellHeight - 76) * appRoot.coverAspectRatio)

        DragHandler {
            id: shelfPageSwipeHandler
            target: null
            acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Mouse
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            dragThreshold: 18

            onActiveChanged: {
                if (active) {
                    return
                }
                var dx = translation.x
                var dy = translation.y
                if (Math.abs(dx) < 92 || Math.abs(dx) < Math.abs(dy) * 1.35) {
                    return
                }
                if (dx < 0 && appRoot.shelfPageIndex < appRoot.shelfPageCount - 1) {
                    appRoot.goShelfPage(1)
                } else if (dx > 0 && appRoot.shelfPageIndex > 0) {
                    appRoot.goShelfPage(-1)
                }
            }
        }

        Repeater {
            model: 9

            delegate: Item {
            property int bookIndex: appRoot.shelfPageIndex * 9 + index
            property var book: shelfStore.books[bookIndex] || ({})
            visible: book.bookId !== undefined && book.bookId !== ""
            width: shelfGrid.cellWidth
            height: shelfGrid.cellHeight
            x: (index % appRoot.shelfColumns) * shelfGrid.cellWidth
            y: Math.floor(index / appRoot.shelfColumns) * shelfGrid.cellHeight

            Rectangle {
                id: cover
                width: shelfGrid.coverWidth
                height: width / appRoot.coverAspectRatio
                x: (parent.width - width) / 2
                y: 4
                radius: 3
                color: parent.book.colorA
                border.color: appRoot.inkColor
                border.width: 1
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * 0.42
                    color: parent.parent.book.colorB
                    opacity: 0.88
                }

                Image {
                    anchors.fill: parent
                    source: parent.parent.book.coverSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: source !== ""
                }

                TapHandler {
                    acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Mouse | PointerDevice.Stylus
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: {
                        appRoot.detailBookOverride = ({})
                        appRoot.selectedIndex = bookIndex
                        appRoot.screenName = "detail"
                        shelfStore.refreshBookDetails(book.bookId)
                    }
                }
            }

            Text {
                x: 14
                y: cover.y + cover.height + 14
                width: parent.width - 28
                text: parent.book.title
                color: appRoot.inkColor
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                x: 14
                y: cover.y + cover.height + 44
                width: parent.width - 28
                text: parent.book.status + "  " + parent.book.progress
                color: appRoot.mutedInk
                font.pixelSize: 17
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                visible: false
            }
        }
        }
    }

    Item {
        id: emptyShelfState
        x: 44
        y: 228
        width: appRoot.width - 88
        height: appRoot.height - 360
        visible: appRoot.shelfTab === "书架" && shelfStore.books.length === 0

        Text {
            x: 0
            y: 24
            width: parent.width
            text: shelfStore.refreshingShelf ? "正在同步微信读书书架" : "还没有书架缓存"
            color: appRoot.inkColor
            font.pixelSize: 32
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            x: 0
            y: 86
            width: parent.width
            text: shelfStore.shelfProgress !== "" ? shelfStore.shelfProgress : "连接 Wi-Fi 后同步你的微信读书书架。"
            color: appRoot.inkColor
            font.pixelSize: 23
            font.bold: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            x: (parent.width - width) / 2
            y: 158
            width: 240
            height: 66
            radius: 4
            color: shelfStore.refreshingShelf ? appRoot.goldAccent : appRoot.brandGreenDark
            border.color: appRoot.inkColor
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: shelfStore.refreshingShelf ? "同步中" : "同步书架"
                color: shelfStore.refreshingShelf ? appRoot.inkColor : "#ffffff"
                font.pixelSize: 24
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                enabled: !shelfStore.refreshingShelf
                onClicked: shelfStore.refreshShelf()
            }
        }
    }

    Rectangle {
        x: 0
        y: 154
        width: 44
        height: appRoot.height - 250
        color: "transparent"
        visible: appRoot.shelfTab === "书架" && appRoot.shelfPageIndex > 0
        MouseArea {
            anchors.fill: parent
            onClicked: appRoot.goShelfPage(-1)
        }
    }

    Rectangle {
        x: appRoot.width - 44
        y: 154
        width: 44
        height: appRoot.height - 250
        color: "transparent"
        visible: appRoot.shelfTab === "书架" && appRoot.shelfPageIndex < appRoot.shelfPageCount - 1
        MouseArea {
            anchors.fill: parent
            onClicked: appRoot.goShelfPage(1)
        }
    }

    Text {
        x: appRoot.width - 258
        y: 116
        width: 96
        text: (appRoot.shelfPageIndex + 1) + " / " + appRoot.shelfPageCount
        color: appRoot.inkColor
        font.pixelSize: 20
        font.bold: true
        horizontalAlignment: Text.AlignRight
        visible: appRoot.shelfTab === "书架" && appRoot.shelfPageCount > 1
    }

    Item {
        id: discoverTabPage
        x: 44
        y: 154
        width: appRoot.width - 88
        height: appRoot.height - 250
        visible: appRoot.shelfTab === "发现"

        Flickable {
            anchors.fill: parent
            contentHeight: discoverColumn.height + 24
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: discoverColumn
                x: 8
                width: parent.width - 16
                spacing: 16

                Text {
                    width: parent.width
                    height: 48
                    text: "发现"
                    color: appRoot.inkColor
                    font.pixelSize: 34
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    text: discoverStore.statusText + " · " + (shelfStore.shelfProgress !== "" ? shelfStore.shelfProgress : "书架 " + shelfStore.books.length + " 本")
                    color: appRoot.inkColor
                    font.pixelSize: 21
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    height: 38
                    text: "搜索书城"
                    color: appRoot.inkColor
                    font.pixelSize: 28
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    TextInput {
                        id: discoverSearchInput
                        x: 16
                        y: 0
                        width: parent.width - 146
                        height: parent.height
                        color: appRoot.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        selectByMouse: true
                        onActiveFocusChanged: if (activeFocus) appRoot.openSoftKeyboard(discoverSearchInput)
                        onAccepted: discoverStore.search(text)
                    }

                    MouseArea {
                        x: 0
                        y: 0
                        width: parent.width - 130
                        height: parent.height
                        onClicked: appRoot.openSoftKeyboard(discoverSearchInput)
                    }

                    Text {
                        x: 16
                        y: 0
                        width: parent.width - 146
                        height: parent.height
                        text: "输入书名"
                        color: appRoot.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        visible: discoverSearchInput.text.length === 0
                    }

                    Rectangle {
                        x: parent.width - 120
                        y: 8
                        width: 108
                        height: parent.height - 16
                        radius: 4
                        color: discoverStore.running ? appRoot.goldAccent : appRoot.brandGreenDark
                        border.color: appRoot.inkColor
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "搜索"
                            color: discoverStore.running ? appRoot.inkColor : "#ffffff"
                            font.pixelSize: 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !discoverStore.running
                            onClicked: discoverStore.search(discoverSearchInput.text)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 56
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "手写识别后搜索"
                        color: appRoot.inkColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            appRoot.openSoftKeyboard(discoverSearchInput)
                            appRoot.setKeyboardInputMode("handwriting")
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10

                    Text {
                        width: parent.width
                        text: "暂无搜索结果"
                        color: appRoot.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        visible: discoverStore.searchResults.length === 0
                    }

                    Repeater {
                        model: discoverStore.searchResults

                        Rectangle {
                            width: parent.width
                            height: 86
                            radius: 4
                            color: appRoot.surfaceColor
                            border.color: appRoot.inkColor
                            border.width: 1

                            Text {
                                x: 16
                                y: 9
                                width: parent.width - 142
                                text: modelData.title || modelData.bookId
                                color: appRoot.inkColor
                                font.pixelSize: 21
                                font.bold: true
                                elide: Text.ElideRight
                            }

	                                Text {
	                                    x: 16
	                                    y: 43
	                                    width: parent.width - 142
	                                    text: modelData.author || modelData.category || "微信读书"
	                                    color: appRoot.inkColor
	                                    font.pixelSize: 18
	                                    font.bold: true
	                                    elide: Text.ElideRight
	                                }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: appRoot.openDiscoverBookDetail(modelData)
                            }

	                                Rectangle {
	                                    x: parent.width - 112
	                                    y: 18
                                width: 96
                                height: 50
                                radius: 4
                                color: appRoot.brandGreenDark
                                border.color: appRoot.inkColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "下载"
                                    color: "#ffffff"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: downloadStore.downloadBook(modelData.bookId, modelData.title)
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 38
                    text: "书城推荐"
                    color: appRoot.inkColor
                    font.pixelSize: 28
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: discoverStore.running ? appRoot.goldAccent : appRoot.brandGreenDark
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: discoverStore.running ? "加载中" : "刷新推荐"
                        color: discoverStore.running ? appRoot.inkColor : "#ffffff"
                        font.pixelSize: 23
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !discoverStore.running
                        onClicked: discoverStore.refreshRecommendations()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10

                    Text {
                        width: parent.width
                        text: "点上面的书城推荐刷新"
                        color: appRoot.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        visible: discoverStore.recommendations.length === 0
                    }

                    Repeater {
                        model: discoverStore.recommendations

                        Rectangle {
                            width: parent.width
                            height: 94
                            radius: 4
                            color: appRoot.surfaceColor
                            border.color: appRoot.inkColor
                            border.width: 1

                            Text {
                                x: 16
                                y: 9
                                width: parent.width - 142
                                text: modelData.title || modelData.bookId
                                color: appRoot.inkColor
                                font.pixelSize: 21
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                x: 16
                                y: 40
                                width: parent.width - 142
                                text: modelData.author || modelData.category || "推荐"
                                color: appRoot.inkColor
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight
                            }

	                                Text {
	                                    x: 16
	                                    y: 66
	                                    width: parent.width - 142
	                                    text: modelData.reason || modelData.intro || ""
	                                    color: appRoot.inkColor
	                                    font.pixelSize: 16
	                                    font.bold: true
	                                    elide: Text.ElideRight
	                                }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: appRoot.openDiscoverBookDetail(modelData)
                            }

	                                Rectangle {
	                                    x: parent.width - 112
                                y: 22
                                width: 96
                                height: 50
                                radius: 4
                                color: appRoot.brandGreenDark
                                border.color: appRoot.inkColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "下载"
                                    color: "#ffffff"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: downloadStore.downloadBook(modelData.bookId, modelData.title)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: shelfStore.refreshingShelf ? appRoot.goldAccent : appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: shelfStore.refreshingShelf ? "同步中" : "同步书架 · 已缓存封面 " + shelfStore.cachedCoverCount + " / " + shelfStore.books.length + " 本"
                        color: appRoot.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !shelfStore.refreshingShelf
                        onClicked: shelfStore.refreshShelf()
                    }
                }

                Text {
                    width: parent.width
                    height: 38
                    text: "下载记录"
                    color: appRoot.inkColor
                    font.pixelSize: 28
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: parent.width
                    height: 58
                    radius: 4
                    visible: downloadStore.queuedCount > 0 && !downloadStore.running
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "恢复队列"
                        color: appRoot.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: downloadStore.resumeDownloadQueue()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10

                    Text {
                        width: parent.width
                        text: "暂无下载记录"
                        color: appRoot.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        visible: downloadStore.downloads.length === 0
                    }

                    Repeater {
                        model: downloadStore.downloads

                        Rectangle {
                            width: parent.width
                            height: 78
                            radius: 4
                            color: appRoot.surfaceColor
                            border.color: appRoot.inkColor
                            border.width: 1

                            Text {
                                x: 18
                                y: 9
                                width: parent.width - 150
                                text: modelData.title || modelData.bookId
                                color: appRoot.inkColor
                                font.pixelSize: 21
                                font.bold: true
                                elide: Text.ElideRight
                            }

	                                Text {
	                                    x: 18
	                                    y: 42
	                                    width: parent.width - 150
	                                    text: modelData.progressText || modelData.state
	                                    color: appRoot.inkColor
	                                    font.pixelSize: 18
	                                    font.bold: true
	                                    elide: Text.ElideRight
	                                }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: appRoot.openDownloadRecord(modelData)
                            }

                            Rectangle {
                                x: parent.width - 116
                                y: 14
                                width: 98
                                height: 50
                                radius: 4
                                color: appRoot.surfaceColor
                                border.color: appRoot.inkColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "删除下载"
                                    color: appRoot.inkColor
                                    font.pixelSize: 15
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        downloadStore.deleteDownload(modelData.bookId, modelData.title || modelData.bookId)
                                        shelfStore.reload()
                                    }
                                }
                            }
	                            }
	                        }
                }
            }
        }
    }

    Item {
        id: profileTabPage
        x: 44
        y: 154
        width: appRoot.width - 88
        height: appRoot.height - 250
        visible: appRoot.shelfTab === "我的"

        Flickable {
            anchors.fill: parent
            contentHeight: profileColumn.height + 24
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: profileColumn
                x: 8
                width: parent.width - 16
                spacing: 16

                Text {
                    width: parent.width
                    height: 48
                    text: "设备状态"
                    color: appRoot.inkColor
                    font.pixelSize: 34
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    text: networkStore.summary
                    color: appRoot.inkColor
                    font.pixelSize: 24
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: "前光 " + frontlightStore.brightness + " / " + frontlightStore.maxBrightness
                    color: appRoot.inkColor
                    font.pixelSize: 24
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "刷新状态"
                        color: appRoot.inkColor
                        font.pixelSize: 24
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            networkStore.reload()
                            frontlightStore.reload()
                            accountStore.refresh()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: 4
                    color: accountStore.cookieConfigured ? appRoot.surfaceColor : appRoot.brandGreenDark
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.fill: parent
                        text: accountStore.cookieConfigured ? "切换微信读书账号" : "登录微信读书"
                        color: accountStore.cookieConfigured ? appRoot.inkColor : "#ffffff"
                        font.pixelSize: 23
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: appRoot.openQrLogin()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: accountStore.cookieConfigured ? 64 : 0
                    visible: accountStore.cookieConfigured
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.fill: parent
                        text: "退出当前账号"
                        color: appRoot.inkColor
                        font.pixelSize: 23
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !accountStore.running && !accountStore.loginRunning && !accountStore.renewingCookie
                        onClicked: accountStore.logout()
                    }
                }

                Text {
                    width: parent.width
                    height: 44
                    text: "云端识别与 AI 手写回复"
                    color: appRoot.inkColor
                    font.pixelSize: 28
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    text: ocrStore.status
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: aiReplyStore.status
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: 4
                    color: ocrSetupServer.running ? appRoot.surfaceColor : appRoot.brandGreenDark
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.fill: parent
                        text: ocrSetupServer.running ? "浏览器配置服务已开启" : "开启浏览器配置（百度 OCR / DeepSeek）"
                        color: ocrSetupServer.running ? appRoot.inkColor : "#ffffff"
                        font.pixelSize: 23
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !ocrSetupServer.running && !ocrStore.busy && !aiReplyStore.busy
                        onClicked: ocrSetupServer.start()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: ocrSetupServer.running

                    Text {
                        width: parent.width
                        text: "浏览器地址：" + ocrSetupServer.setupUrl
                        color: appRoot.inkColor
                        font.pixelSize: 19
                        font.bold: true
                        wrapMode: Text.WrapAnywhere
                    }

                    Text {
                        width: parent.width
                        text: "配对码：" + ocrSetupServer.pairingCode
                        color: appRoot.inkColor
                        font.pixelSize: 28
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: "本次配置将在 " + ocrSetupServer.secondsRemaining + " 秒后自动关闭"
                        color: appRoot.inkColor
                        font.pixelSize: 19
                    }

                    Text {
                        width: parent.width
                        text: ocrSetupServer.status
                        color: appRoot.inkColor
                        font.pixelSize: 19
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 56
                        radius: 4
                        color: appRoot.surfaceColor
                        border.color: appRoot.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "关闭浏览器配置"
                            color: appRoot.inkColor
                            font.pixelSize: 21
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: ocrSetupServer.cancel()
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: !ocrSetupServer.running
                    text: "只在你点开启后临时运行。一次只更新你提交的百度 OCR 或 DeepSeek 配置；另一项不会被清除。浏览器首次会提示临时安全证书。"
                    color: appRoot.inkColor
                    font.pixelSize: 18
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    height: 44
                    text: "Wi-Fi 管理"
                    color: appRoot.inkColor
                    font.pixelSize: 28
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    text: networkStore.actionStatus
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.WordWrap
                    visible: networkStore.actionStatus !== ""
                }

                Row {
                    width: parent.width
                    height: 58
                    spacing: 12

                    Rectangle {
                        width: (parent.width - 24) / 3
                        height: parent.height
                        radius: 4
                        color: appRoot.surfaceColor
                        border.color: appRoot.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "扫描 Wi-Fi"
                            color: appRoot.inkColor
                            font.pixelSize: 19
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: networkStore.scan()
                        }
                    }

                    Rectangle {
                        width: (parent.width - 24) / 3
                        height: parent.height
                        radius: 4
                        color: appRoot.surfaceColor
                        border.color: appRoot.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "刷新网络"
                            color: appRoot.inkColor
                            font.pixelSize: 19
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: networkStore.reload()
                        }
                    }

                    Rectangle {
                        width: (parent.width - 24) / 3
                        height: parent.height
                        radius: 4
                        color: appRoot.surfaceColor
                        border.color: appRoot.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "断开 Wi-Fi"
                            color: appRoot.inkColor
                            font.pixelSize: 19
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: networkStore.disconnectWifi()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 60
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    TextInput {
                        id: wifiPasswordInput
                        x: 16
                        y: 0
                        width: parent.width - 32
                        height: parent.height
                        color: appRoot.inkColor
                        font.pixelSize: 21
                        font.bold: true
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        clip: true
                        selectByMouse: true
                        onActiveFocusChanged: if (activeFocus) appRoot.openSoftKeyboard(wifiPasswordInput)
                    }

                    Text {
                        x: 16
                        y: 0
                        width: parent.width - 32
                        height: parent.height
                        text: "输入 Wi-Fi 密码"
                        color: appRoot.inkColor
                        font.pixelSize: 21
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        visible: wifiPasswordInput.text.length === 0 && !wifiPasswordInput.activeFocus
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: appRoot.openSoftKeyboard(wifiPasswordInput)
                    }
                }

                Text {
                    width: parent.width
                    height: 38
                    text: "已保存网络"
                    color: appRoot.inkColor
                    font.pixelSize: 22
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    height: 42
                    text: "暂无已保存网络"
                    color: appRoot.inkColor
                    font.pixelSize: 19
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    visible: networkStore.savedNetworks.length === 0
                }

                Repeater {
                    model: networkStore.savedNetworks

                    Rectangle {
                        width: profileColumn.width
                        height: 72
                        color: appRoot.surfaceColor

                        Text {
                            x: 0
                            y: 0
                            width: parent.width - 236
                            height: parent.height
                            text: (modelData.current ? "当前 · " : "") + (modelData.ssid || "未命名网络")
                            color: appRoot.inkColor
                            font.pixelSize: 21
                            font.bold: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            x: parent.width - 224
                            y: 12
                            width: 102
                            height: 48
                            radius: 4
                            color: appRoot.surfaceColor
                            border.color: appRoot.inkColor
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "连接"
                                color: appRoot.inkColor
                                font.pixelSize: 18
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: networkStore.connectSaved(modelData.id)
                            }
                        }

                        Rectangle {
                            x: parent.width - 110
                            y: 12
                            width: 102
                            height: 48
                            radius: 4
                            color: appRoot.surfaceColor
                            border.color: appRoot.inkColor
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "忘记"
                                color: appRoot.inkColor
                                font.pixelSize: 18
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: networkStore.forgetNetwork(modelData.id)
                            }
                        }

                        Rectangle {
                            x: 0
                            y: parent.height - 1
                            width: parent.width
                            height: 1
                            color: appRoot.inkColor
                            opacity: 0.28
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 38
                    text: "附近网络"
                    color: appRoot.inkColor
                    font.pixelSize: 22
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    height: 42
                    text: "点“扫描 Wi-Fi”查找附近网络"
                    color: appRoot.inkColor
                    font.pixelSize: 19
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    visible: networkStore.availableNetworks.length === 0
                }

                Repeater {
                    model: networkStore.availableNetworks

                    Rectangle {
                        width: profileColumn.width
                        height: 72
                        color: appRoot.surfaceColor

                        Text {
                            x: 0
                            y: 0
                            width: parent.width - 142
                            height: parent.height
                            text: (modelData.current ? "当前 · " : "") + (modelData.ssid || "未命名网络") + (modelData.secure ? " · 加密" : " · 开放")
                            color: appRoot.inkColor
                            font.pixelSize: 21
                            font.bold: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            x: parent.width - 128
                            y: 12
                            width: 120
                            height: 48
                            radius: 4
                            color: appRoot.surfaceColor
                            border.color: appRoot.inkColor
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "连接"
                                color: appRoot.inkColor
                                font.pixelSize: 18
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: networkStore.connectToSsid(modelData.ssid, wifiPasswordInput.text)
                            }
                        }

                        Rectangle {
                            x: 0
                            y: parent.height - 1
                            width: parent.width
                            height: 1
                            color: appRoot.inkColor
                            opacity: 0.28
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 44
                    text: "账号状态"
                    color: appRoot.inkColor
                    font.pixelSize: 28
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    text: accountStore.statusText
                    color: appRoot.inkColor
                    font.pixelSize: 22
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: accountStore.apiConfigured ? "API Key 已配置" : "API Key 未配置"
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: accountStore.cookieConfigured ? "登录 Cookie 已配置" : "登录 Cookie 未配置"
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: accountStore.configPath
                    color: appRoot.inkColor
                    font.pixelSize: 17
                    font.bold: true
                    wrapMode: Text.WordWrap
                    visible: accountStore.configPath !== ""
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: accountStore.running ? appRoot.goldAccent : appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: accountStore.running ? "检查中" : "检查账号"
                        color: appRoot.inkColor
                        font.pixelSize: 22
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !accountStore.running
                        onClicked: accountStore.refresh()
                    }
                }

                Text {
                    width: parent.width
                    text: accountStore.renewalStatusText
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: accountStore.renewingCookie ? appRoot.goldAccent : appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.fill: parent
                        text: accountStore.renewingCookie ? "续期中" : "续期 Cookie"
                        color: appRoot.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !accountStore.running && !accountStore.renewingCookie
                        onClicked: accountStore.renewCookie()
                    }
                }

                Text {
                    width: parent.width
                    text: accountStore.loginStatusText
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: accountStore.loginConfirmUrl === "" ? 0 : loginQrImage.height + loginConfirmText.implicitHeight + 48
                    visible: accountStore.loginConfirmUrl !== ""
                    radius: 4
                    color: appRoot.paperColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Image {
                        id: loginQrImage
                        width: Math.min(parent.width - 36, 310)
                        height: width
                        anchors.top: parent.top
                        anchors.topMargin: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: accountStore.loginConfirmUrl === "" ? "" : "image://wereadqr/" + encodeURIComponent(accountStore.loginConfirmUrl)
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        smooth: false
                    }

                    Text {
                        id: loginConfirmText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: loginQrImage.bottom
                        anchors.margins: 15
                        text: accountStore.loginConfirmUrl
                        color: appRoot.inkColor
                        font.pixelSize: 18
                        font.bold: true
                        wrapMode: Text.WrapAnywhere
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: accountStore.loginRunning ? appRoot.goldAccent : appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.fill: parent
                        text: accountStore.loginRunning ? "取消登录" : "扫码登录"
                        color: appRoot.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !accountStore.running && !accountStore.renewingCookie
                        onClicked: accountStore.loginRunning ? appRoot.closeQrLogin() : appRoot.openQrLogin()
                    }
                }

                Text {
                    width: parent.width
                    text: downloadStore.cacheStatusText
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: appRoot.surfaceColor
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "清理阅读缓存"
                        color: appRoot.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: downloadStore.clearReaderCache()
                    }
                }

                Text {
                    width: parent.width
                    height: 44
                    text: "微信笔记"
                    color: appRoot.inkColor
                    font.pixelSize: 28
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    text: notesStore.statusText
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 62
                    radius: 4
                    color: notesStore.running ? appRoot.goldAccent : appRoot.brandGreenDark
                    border.color: appRoot.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: notesStore.running ? "同步中" : "同步笔记"
                        color: notesStore.running ? appRoot.inkColor : "#ffffff"
                        font.pixelSize: 22
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !notesStore.running
                        onClicked: notesStore.refreshNotebooks()
                    }
                }

                Text {
                    width: parent.width
                    text: "暂无微信笔记"
                    color: appRoot.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    visible: notesStore.notebooks.length === 0
                }

                Repeater {
                    model: notesStore.notebooks

                    Rectangle {
                        width: profileColumn.width
                        height: 82
                        radius: 4
                        color: appRoot.surfaceColor
                        border.color: appRoot.inkColor
                        border.width: 1

                        Text {
                            x: 16
                            y: 8
                            width: parent.width - 32
                            text: modelData.title || modelData.bookId
                            color: appRoot.inkColor
                            font.pixelSize: 21
                            font.bold: true
                            elide: Text.ElideRight
                        }

	                            Text {
	                                x: 16
	                                y: 42
	                                width: parent.width - 32
	                                text: (modelData.author || "微信读书") + " · " + (modelData.totalNotes || 0) + " 条"
	                                color: appRoot.inkColor
	                                font.pixelSize: 18
	                                font.bold: true
	                                elide: Text.ElideRight
	                            }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: appRoot.openNotebookBookDetail(modelData)
                        }
	                        }
                }
            }
        }
    }

    Rectangle {
        x: 0
        y: appRoot.height - 88
        width: appRoot.width
        height: 88
        color: appRoot.surfaceColor
        border.color: appRoot.inkColor
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 48
            Repeater {
                model: ["书架", "发现", "我的", "魔法笔记本"]
                Text {
                    width: 116
                    text: modelData
                    color: appRoot.shelfTab === modelData ? appRoot.brandGreenDark : appRoot.inkColor
                    font.pixelSize: 24
                    font.bold: appRoot.shelfTab === modelData
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData === "魔法笔记本") {
                                appRoot.openMagicBook()
                            } else {
                                appRoot.shelfTab = modelData
                            }
                        }
                    }
                }
            }
        }
    }
}


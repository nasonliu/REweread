import QtQuick

Rectangle {
    required property color inkColor
    required property color brandGreenDark
    required property string loginConfirmUrl
    required property bool loginRunning
    required property string loginStatusText
    property alias qrImage: fullScreenLoginQrImage

    signal cancelRequested()
    signal retryRequested()

    color: "#ffffff"

    MouseArea {
        anchors.fill: parent
    }

    Text {
        x: 56
        y: 72
        width: parent.width - 112
        height: 64
        text: "登录微信读书"
        color: inkColor
        font.pixelSize: 42
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        x: 56
        y: 142
        width: parent.width - 112
        height: 54
        text: loginConfirmUrl === "" ? "正在生成二维码" : "请使用微信扫描二维码"
        color: inkColor
        font.pixelSize: 27
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Image {
        id: fullScreenLoginQrImage
        x: Math.round((parent.width - width) / 2)
        y: 226
        width: 560
        height: 560
        source: loginConfirmUrl === "" ? "" : "image://wereadqr/" + encodeURIComponent(loginConfirmUrl)
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: false
        visible: source !== ""
    }

    Rectangle {
        x: Math.round((parent.width - width) / 2)
        y: 226
        width: 560
        height: 560
        visible: loginConfirmUrl === ""
        color: "#ffffff"
        border.color: inkColor
        border.width: 3

        Text {
            anchors.centerIn: parent
            text: loginRunning ? "请稍候" : "二维码生成失败"
            color: inkColor
            font.pixelSize: 30
            font.bold: true
        }
    }

    Text {
        x: 72
        y: 824
        width: parent.width - 144
        height: 92
        text: loginStatusText
        color: inkColor
        font.pixelSize: 25
        font.bold: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        x: 72
        y: 928
        width: parent.width - 144
        height: 64
        text: "扫码后在手机上确认登录"
        color: inkColor
        font.pixelSize: 23
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Row {
        x: 96
        y: parent.height - 154
        width: parent.width - 192
        height: 66
        spacing: 18

        Rectangle {
            width: loginRunning ? parent.width : Math.floor((parent.width - 18) / 2)
            height: parent.height
            radius: 4
            color: "#ffffff"
            border.color: inkColor
            border.width: 2

            Text {
                anchors.fill: parent
                text: "取消"
                color: inkColor
                font.pixelSize: 24
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: cancelRequested()
            }
        }

        Rectangle {
            width: Math.floor((parent.width - 18) / 2)
            height: parent.height
            visible: !loginRunning
            radius: 4
            color: brandGreenDark
            border.color: inkColor
            border.width: 2

            Text {
                anchors.fill: parent
                text: "重新生成"
                color: "#ffffff"
                font.pixelSize: 24
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: retryRequested()
            }
        }
    }
}

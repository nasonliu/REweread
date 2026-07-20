import QtQuick

Rectangle {
    required property string coverSource
    required property string bookTitle
    required property string readerFontFamily
    required property color inkColor
    required property real coverAspectRatio

    color: "#ffffff"

    Image {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, Math.round((parent.height - 132) * coverAspectRatio))
        height: Math.min(parent.height - 132, Math.round(width / coverAspectRatio))
        source: coverSource
        fillMode: Image.PreserveAspectFit
        cache: true
        asynchronous: false
        visible: source !== ""
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 128
        height: 420
        visible: coverSource === ""
        color: "#ffffff"
        border.color: inkColor
        border.width: 3

        Text {
            anchors.fill: parent
            anchors.margins: 48
            text: bookTitle
            color: inkColor
            font.family: readerFontFamily
            font.pixelSize: 44
            font.bold: true
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}

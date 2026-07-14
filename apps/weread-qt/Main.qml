import QtQuick
import QtQuick.Window
import QtCore
import "SocialAnchor.js" as SocialAnchor
import "PinyinEngine.js" as PinyinEngine
import "FreeNoteAnchor.js" as FreeNoteAnchor

Window {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    color: root.paperColor

    onClosing: function(close) {
        root.flushPendingFreeInkStrokes()
    }

    property color paperColor: "#ffffff"
    property color surfaceColor: "#ffffff"
    property color brandGreen: "#17885b"
    property color brandGreenDark: "#0f5f42"
    property color inkColor: "#111111"
    property color mutedInk: "#222222"
    property color quietLine: "#1d1a15"
    property color warmControl: "#ffffff"
    property color goldAccent: "#e4b84e"
    property int shelfColumns: 3
    property real coverAspectRatio: 0.68
    property int selectedIndex: 0
    property var detailBookOverride: ({})
    property string screenName: "shelf"
    property int pageIndex: 0
    property string currentBookId: ""
    property int shelfPageIndex: 0
    property int shelfPageCount: Math.max(1, Math.ceil(shelfStore.books.length / 9))
    property int readerBottomGestureHeight: 56
    property int readerFooterHeight: 46
    property int readerFooterGap: root.readerLinePixels()
    property int readerFooterTop: root.height - root.readerBottomGestureHeight - root.readerFooterHeight
    property int readerContentBottom: root.readerFooterTop - root.readerFooterGap
    property int readerCatalogPanelWidth: Math.round(root.width * 0.56)
    property int readerTextTopMargin: 96
    property int readerImageTopMargin: 72
    property int readerImageTextTopY: Math.round(root.height * 0.78)
    property int readerFontSize: 38
    property real readerLineHeight: 1.26
    property int readerParagraphSpacing: 12
    property int readerFontWeight: Font.DemiBold
    property int readerFirstLineIndentChars: 2
    property int readerHangingIndent: Math.round(readerFontSize * readerFirstLineIndentChars)
    property int readerMargin: 64
    property int readerMinOrphanLines: 1
    property int readerMinWidowLines: 1
    property int readerCaptionParagraphLimit: 3
    property int forceReaderRefresh: 0
    property int readerSocialGeometryToken: 0
    property var readerSocialDashRects: []
    property var readerSocialHitRects: []
    property string readerSocialGeometryDataKey: ""
    property bool showReaderSettings: false
    property int readerSettingsPanelHeight: Math.min(840, root.height - 76)
    property bool showReaderCatalog: false
    property bool showReaderFootnote: false
    property bool showDetailCatalog: false
    property bool showSoftKeyboard: false
    property bool keyboardPinyinMode: true
    property bool keyboardHandwritingMode: false
    property string keyboardPinyinBuffer: ""
    property var keyboardCandidates: []
    property int keyboardCandidatePage: 0
    property int keyboardCandidatePageSize: 5
    property var keyboardHandwritingStrokes: []
    property var keyboardHandwritingCurrentStroke: []
    property var keyboardHandwritingCandidates: []
    property string keyboardHandwritingStatus: ""
    property bool keyboardHandwritingDrawing: false
    property bool annotationMode: false
    property string readerMarkerTool: "marker"
    property string readerMarkerColorName: "金"
    property string readerMarkerColor: "#b98218"
    property int readerMarkerLineWidth: Math.max(24, Math.round(readerFontSize * 0.72))
    property var currentStrokePoints: []
    property var currentFreeNotePoints: []
    property var currentFreeNoteStrokes: []
    property var pendingFreeInkStrokes: []
    property string pendingFreeInkBookId: ""
    property string pendingFreeInkTitle: ""
    property int pendingFreeInkPageIndex: -1
    property int pendingFreeInkPageCount: 1
    property int pendingFreeInkSequence: 0
    property bool showHandwrittenNotes: false
    property int readerNotesGutterWidth: 190
    property var readerCurrentLineBoxes: []
    property bool readerStylusToolsExpanded: false
    property bool readerStylusStrokeInToolbar: false
    property bool readerStylusCollapsePending: false
    property bool readerClearArmed: false
    property bool readerOcrBlockSelection: false
    property string readerSelectedInkBlockId: ""
    property double readerSuppressPageTurnUntilMs: 0
    property int readerStylusToolBarWidth: 68
    property int readerStylusToolBarPadding: 10
    property int readerStylusToolDotSize: 44
    property int readerStylusToolGap: 14
    property int readerStylusSectionGap: 16
    property var keyboardTarget: null
    property string pendingDirectOcrKind: ""
    property string pendingDirectOcrBookId: ""
    property int pendingDirectOcrPageIndex: -1
    property string pendingDirectOcrItemId: ""
    property string readerInlineOcrStatus: ""
    property string pendingCatalogBookId: ""
    property var pendingCatalogChapter: ({})
    property real settingsDragOffset: 0
    property string readerFontChoice: "霞鹜文楷"
    property string shelfTab: "书架"
    property string readerPageBreakCharacters: "。！？；：…」』）)”"
    property string readerLeadingPunctuationCharacters: "，。！？；：、…」』）)”》〉】〕〗〙〛"
    property string readerEndingPunctuationCharacters: "“‘（《〈【〔〖〘〚「『"
    property var frontlightLevels: [0, 10, 20, 40, 60, 80, 100]
    property var readerQuickFrontlightLevels: [0, 25, 50, 75, 100]
    property var keyboardRows: [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    ]
    property var highlightColors: [
        {"name": "绿", "value": "#17885b"},
        {"name": "金", "value": "#b98218"},
        {"name": "红", "value": "#9b2226"},
        {"name": "蓝", "value": "#1d5f99"}
    ]
    property var readerStylusTools: [
        {"id": "green", "tool": "color", "name": "绿", "value": "#17885b", "label": ""},
        {"id": "gold", "tool": "color", "name": "金", "value": "#b98218", "label": ""},
        {"id": "red", "tool": "color", "name": "红", "value": "#9b2226", "label": ""},
        {"id": "blue", "tool": "color", "name": "蓝", "value": "#1d5f99", "label": ""},
        {"id": "marker", "tool": "marker", "name": "荧光笔", "value": "", "label": "划"},
        {"id": "free", "tool": "free", "name": "自由写", "value": "", "label": "写"},
        {"id": "notes", "tool": "notes", "name": "旧笔记", "value": "", "label": "笔"},
        {"id": "ocr", "tool": "ocr", "name": "识别", "value": "", "label": "识"},
        {"id": "eraser", "tool": "eraser", "name": "橡皮", "value": "#ffffff", "label": "擦"},
        {"id": "clear", "tool": "clear", "name": "清除本页", "value": "", "label": "清"}
    ]
    property var readerLineHeightSteps: [
        {"label": "紧", "value": 1.16},
        {"label": "标准", "value": 1.26},
        {"label": "舒", "value": 1.36},
        {"label": "宽", "value": 1.46}
    ]
    property var readerParagraphSpacingSteps: [
        {"label": "无", "value": 0},
        {"label": "紧", "value": 8},
        {"label": "标准", "value": 12},
        {"label": "宽", "value": 20}
    ]
    property string readerFontFamily: readerFontChoice === "微米黑" && microHeiFont.status === FontLoader.Ready
        ? microHeiFont.name
        : readerFontChoice === "正黑" && zenHeiFont.status === FontLoader.Ready
            ? zenHeiFont.name
            : readerFontChoice === "霞鹜文楷" && lxgwWenKaiFont.status === FontLoader.Ready
                ? lxgwWenKaiFont.name
                : ""
    property var readerPageStarts: [0]
    property var readerPageImages: [""]
    property var readerChapterPageLabels: ({})
    property int readerCachedPageCount: 1
    property bool readerPaginationDirty: true
    property string readerPaginationSignature: ""
    property int readerPaginationBatchSize: 6
    property bool readerPaginationBuilding: false
    property bool readerFastOpenMode: false
    property int readerFastOpenAnchorOffset: 0
    property int readerFastOpenMinPagesAfterAnchor: 8
    property var readerPaginationDraftStarts: []
    property var readerPaginationDraftImages: []
    property int readerPaginationDraftOffset: 0
    property int readerPaginationDraftGuard: 0
    property double readerPaginationStartedMs: 0
    property string currentReaderImageSource: ""
    property string currentReaderImageCaption: ""
    property int currentReaderTextTopY: readerTextTopMargin
    property string currentReaderPageText: ""
    property int currentReaderTextStart: 0
    property int currentReaderTextEnd: 0
    property real currentReaderProgressValue: 0
    property int readerReflowAnchorOffset: 0
    property bool readerReflowRestorePending: false
    property int readerReturnTextOffset: -1
    property var readerActiveFootnote: ({})
    property bool showReaderSocialPopup: false
    property var readerActiveSocialMark: ({})
    property string readerSocialPrefetchKey: ""
    property int readerSocialPageToken: 0
    property int readerKnownPopularMarkCount: 0
    property int readerPendingPopularMarkCount: 0
    property bool readerOpenedWithLocalProgress: false
    property string readerSocialReviewRequestKey: ""
    property bool readerPendingContinueDownload: false
    property string readerPendingContinueBookId: ""
    property string readerPendingContinueTitle: ""
    property string readerPendingContinueSnippet: ""
    property int readerLastPulledRemoteProgress: -1
    property int readerSessionStartedMs: 0
    property bool readerImageLoadFailed: false
    property var readerLayoutSelfTestPages: []
    property int readerLayoutSelfTestCursor: 0
    property var readerSelfTestSavedSettings: ({})
    property bool sleepOverlayVisible: false
    property string sleepCoverSource: ""
    property string sleepBookTitle: ""
    property string sleepRequestReason: ""
    property bool showQrLogin: false
    property bool accountInitialCheckComplete: false
    property bool accountAutoPromptHandled: false

    onReaderFontSizeChanged: root.markReaderPaginationDirty()
    onReaderFontWeightChanged: root.markReaderPaginationDirty()
    onReaderFontChoiceChanged: root.markReaderPaginationDirty()
    onReaderLineHeightChanged: root.markReaderPaginationDirty()
    onReaderParagraphSpacingChanged: root.markReaderPaginationDirty()
    onReaderFirstLineIndentCharsChanged: root.markReaderPaginationDirty()
    onReaderMarginChanged: root.markReaderPaginationDirty()
    onWidthChanged: root.markReaderPaginationDirty()
    onHeightChanged: root.markReaderPaginationDirty()

    onShowReaderSettingsChanged: {
        if (!showReaderSettings) {
            settingsDragOffset = 0
        }
    }

    Settings {
        id: persistedReaderSettings
        category: "reader"
        property alias fontSize: root.readerFontSize
        property alias lineHeight: root.readerLineHeight
        property alias paragraphSpacing: root.readerParagraphSpacing
        property alias fontWeight: root.readerFontWeight
        property alias firstLineIndentChars: root.readerFirstLineIndentChars
        property alias margin: root.readerMargin
        property alias fontChoice: root.readerFontChoice
        property alias markerColorName: root.readerMarkerColorName
        property alias markerColor: root.readerMarkerColor
        property bool paragraphSpacingDefaultMigrated: false
        property bool typographyTuningMigrated: false
        property bool wenkaiDefaultMigrated: false
    }

    Component.onCompleted: {
        root.migrateReaderDefaults()
        accountStore.refresh()
    }

    FontLoader {
        id: microHeiFont
        source: "file:///home/root/weread-qt/fonts/wqy-microhei.ttc"
    }

    FontLoader {
        id: zenHeiFont
        source: "file:///home/root/weread-qt/fonts/wqy-zenhei.ttc"
    }

    FontLoader {
        id: lxgwWenKaiFont
        source: "file:///home/root/weread-qt/fonts/lxgw-wenkai.ttf"
    }

    function htmlEscape(value) {
        return String(value || "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
    }

    function isParagraphContinuation(textStart) {
        var fullText = String(readerStore.bodyText || "")
        var start = Math.max(0, Math.floor(Number(textStart) || 0))
        if (start <= 0 || start >= fullText.length) {
            return false
        }
        return fullText.charAt(start - 1) !== "\n"
    }

    function isReaderChapterStart(offset) {
        var target = Math.max(0, Math.floor(Number(offset) || 0))
        var chapters = readerStore.chapters || []
        for (var i = 0; i < chapters.length; i++) {
            if (Math.max(0, Math.floor(Number(chapters[i].textStart) || 0)) === target) {
                return true
            }
        }
        return false
    }

    function isReaderChapterEnd(offset) {
        var target = Math.max(0, Math.floor(Number(offset) || 0))
        var body = String(readerStore.bodyText || "")
        if (target <= 0) {
            return false
        }
        var chapters = readerStore.chapters || []
        for (var i = 0; i < chapters.length; i++) {
            var start = Math.max(0, Math.floor(Number(chapters[i].textStart) || 0))
            if (start === target) {
                return true
            }
        }
        return target >= body.length
    }

    function isReaderNearChapterEnd(start, end) {
        var safeStart = Math.max(0, Math.floor(Number(start) || 0))
        var safeEnd = Math.max(safeStart, Math.floor(Number(end) || 0))
        var nextStart = root.nextReaderChapterStartAfter(safeStart)
        if (nextStart <= safeStart) {
            return false
        }
        var tolerance = Math.max(12, root.readerEstimatedCharsPerLine() * 2)
        return nextStart <= safeEnd + tolerance
    }

    function nextReaderChapterStartAfter(offset) {
        var target = Math.max(0, Math.floor(Number(offset) || 0))
        var answer = -1
        var chapters = readerStore.chapters || []
        for (var i = 0; i < chapters.length; i++) {
            var start = Math.max(0, Math.floor(Number(chapters[i].textStart) || 0))
            if (start > target && (answer < 0 || start < answer)) {
                answer = start
            }
        }
        return answer
    }

    function readerChapterForOffset(offset) {
        var target = Math.max(0, Math.floor(Number(offset) || 0))
        var chapters = readerStore.chapters || []
        var current = ({ "index": -1, "title": "", "textStart": 0 })
        for (var i = 0; i < chapters.length; i++) {
            var start = Math.max(0, Math.floor(Number(chapters[i].textStart) || 0))
            if (start <= target) {
                current = chapters[i]
                current.index = i
            } else {
                break
            }
        }
        return current
    }

    function readerDefaultStartOffset() {
        var chapters = readerStore.chapters || []
        if (chapters.length === 0) {
            return 0
        }
        for (var i = 0; i < chapters.length; i++) {
            var title = String(chapters[i].title || "").replace(/\s+/g, "")
            if (title !== ""
                    && title.indexOf("版权") < 0
                    && title.indexOf("目录") < 0
                    && title.indexOf("封面") < 0
                    && title.indexOf("书名") < 0
                    && title.indexOf("扉页") < 0
                    && title.indexOf("出版") < 0
                    && title.indexOf("插图") < 0
                    && title.indexOf("前言") < 0
                    && title.indexOf("Copyright") < 0) {
                return Math.max(0, Math.floor(Number(chapters[i].textStart) || 0))
            }
        }
        return Math.max(0, Math.floor(Number(chapters[0].textStart) || 0))
    }

    function isReaderImageCaptionParagraph(value, paragraphIndex) {
        if (root.currentReaderImageSource === "" || paragraphIndex >= root.readerCaptionParagraphLimit) {
            return false
        }
        var para = String(value || "").replace(/\s+/g, " ").trim()
        if (para.length === 0 || para.length > 120) {
            return false
        }
        if (/^(图|表|插图|地图|照片|Figure|Fig\\.|Table)\\s*([0-9一二三四五六七八九十]+|[A-Z])?[\\.．、：:]/.test(para)) {
            return true
        }
        if (paragraphIndex > 0 && /^(来源|资料来源|图片来源|图像来源|藏于|收藏|Source|From)[:：]?/.test(para)) {
            return true
        }
        return paragraphIndex === 0 && para.length <= 48 && /[。；;:：]?$/.test(para)
    }

    function readerHighlightsForRange(start, end) {
        var rows = readerStore.highlights || []
        var matches = []
        var rangeStart = Math.max(0, Math.floor(Number(start) || 0))
        var rangeEnd = Math.max(rangeStart, Math.floor(Number(end) || 0))
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i]
            if (row.kind !== "text") {
                continue
            }
            var textStart = Math.max(0, Math.floor(Number(row.textStart) || 0))
            var textEnd = Math.max(textStart, Math.floor(Number(row.textEnd) || 0))
            if (textStart < rangeEnd && textEnd > rangeStart) {
                matches.push(row)
            }
        }
        return matches
    }

    function socialAnchorForPopularMark(mark) {
        var body = String(readerStore.bodyText || "")
        var bounds = root.readerPopularMarkSearchBounds(mark)
        var chapter = root.readerChapterForOffset(bounds.start)
        return SocialAnchor.resolve(body, mark || ({}), {
            "currentStart": root.currentReaderTextStart,
            "currentEnd": root.currentReaderTextEnd,
            "chapterStart": bounds.start,
            "chapterEnd": bounds.end,
            "chapterTitle": String((mark || {}).chapter || chapter.title || "")
        })
    }

    function textOffsetForPopularMark(mark) {
        return root.socialAnchorForPopularMark(mark).start
    }

    function readerWeReadRangeParts(mark) {
        var raw = String((mark || {}).range || "")
        var match = raw.match(/(\d+)\s*[-:]\s*(\d+)/)
        if (!match) {
            return ({ "start": -1, "end": -1 })
        }
        var start = Math.max(0, Math.floor(Number(match[1]) || 0))
        var end = Math.max(start + 1, Math.floor(Number(match[2]) || 0))
        return ({ "start": start, "end": end })
    }

    function textOffsetForWeReadRange(mark) {
        var body = String(readerStore.bodyText || "")
        var bounds = root.readerPopularMarkSearchBounds(mark)
        var parts = root.readerWeReadRangeParts(mark)
        if (parts.start < 0) {
            return -1
        }
        var offset = bounds.start + parts.start
        if (offset < bounds.start || offset >= bounds.end || offset >= body.length) {
            return -1
        }
        return offset
    }

    function textEndForWeReadRange(mark, startOffset) {
        var body = String(readerStore.bodyText || "")
        var bounds = root.readerPopularMarkSearchBounds(mark)
        var parts = root.readerWeReadRangeParts(mark)
        if (parts.start < 0 || startOffset < 0) {
            return Math.min(body.length, Math.max(startOffset + 1, startOffset + String((mark || {}).text || "").replace(/\s+/g, " ").trim().length))
        }
        var length = Math.max(1, parts.end - parts.start)
        return root.clamp(startOffset + length, startOffset + 1, Math.min(bounds.end, body.length))
    }

    function textEndForPopularMark(mark, startOffset) {
        var anchor = root.socialAnchorForPopularMark(mark)
        return anchor.start === startOffset && anchor.end > startOffset ? anchor.end : -1
    }

    function readerSocialDisplayText(mark) {
        var text = SocialAnchor.cleanAnchorText((mark || {}).anchorText || (mark || {}).text)
        if (text.length > 0) {
            return text
        }
        var start = root.textOffsetForPopularMark(mark)
        if (start < 0) {
            return "这处划线"
        }
        var end = root.textEndForPopularMark(mark, start)
        return String(readerStore.bodyText || "").slice(start, end).replace(/\s+/g, " ").trim()
    }

    function textOffsetForNormalizedSnippet(snippet, start, end) {
        var body = String(readerStore.bodyText || "")
        var safeStart = root.clamp(Math.floor(Number(start) || 0), 0, body.length)
        var safeEnd = root.clamp(Math.floor(Number(end) || 0), safeStart, body.length)
        var needle = String(snippet || "").replace(/\s+/g, "")
        if (needle.length < 4) {
            return -1
        }
        needle = needle.slice(0, Math.min(64, needle.length))
        var compact = ""
        var map = []
        for (var i = safeStart; i < safeEnd; i++) {
            var ch = body.charAt(i)
            if (/\s/.test(ch)) {
                continue
            }
            compact += ch
            map.push(i)
        }
        var pos = compact.indexOf(needle)
        if (pos >= 0 && pos < map.length) {
            return map[pos]
        }
        var probe = needle.slice(0, Math.min(18, needle.length))
        if (probe.length >= 6) {
            pos = compact.indexOf(probe)
            if (pos >= 0 && pos < map.length) {
                return map[pos]
            }
        }
        return -1
    }

    function readerPopularMarkSearchBounds(mark) {
        var body = String(readerStore.bodyText || "")
        var chapters = readerStore.chapters || []
        var markChapterUid = String((mark || {}).chapterUid || "")
        var markChapter = String((mark || {}).chapter || "").replace(/\s+/g, " ").trim()
        var current = root.readerChapterForOffset(root.currentReaderTextStart)
        var start = Math.max(0, Math.floor(Number(current.textStart) || 0))
        var chapterIndex = Math.max(0, Math.floor(Number(current.index) || 0))

        for (var i = 0; i < chapters.length; i++) {
            var chapterUid = String(chapters[i].chapterUid || "")
            var title = String(chapters[i].title || "").replace(/\s+/g, " ").trim()
            if ((markChapterUid !== "" && chapterUid === markChapterUid)
                    || (markChapter !== "" && title !== "" && (title.indexOf(markChapter) >= 0 || markChapter.indexOf(title) >= 0))) {
                start = Math.max(0, Math.floor(Number(chapters[i].textStart) || 0))
                chapterIndex = i
                break
            }
        }

        var nextStart = body.length
        for (var j = chapterIndex + 1; j < chapters.length; j++) {
            nextStart = Math.max(start + 1, Math.floor(Number(chapters[j].textStart) || body.length))
            break
        }
        return { "start": start, "end": nextStart }
    }

    function currentReaderSocialPrefetchKey() {
        var chapter = root.readerChapterForOffset(root.currentReaderTextStart)
        var chapterIndex = Math.max(0, Math.floor(Number(chapter.index) || 0))
        var chapterUid = String(chapter.chapterUid || "")
        var chapterStart = Math.max(0, Math.floor(Number(chapter.textStart) || 0))
        var chapterRelativePageStart = Math.max(0, root.currentReaderTextStart - chapterStart)
        var chapterRelativePageEnd = Math.max(chapterRelativePageStart + 1, root.currentReaderTextEnd - chapterStart)
        var pageRange = ":page:" + chapterRelativePageStart + "-" + chapterRelativePageEnd
        if (chapterUid !== "") {
            return "chapterUid:" + chapterUid + pageRange
        }
        return "chapterIndex:" + (chapterIndex + 1) + pageRange
    }

    function readerPopularMarksForRange(start, end) {
        var rows = notesStore.popularMarks || []
        var matches = []
        var rangeStart = Math.max(0, Math.floor(Number(start) || 0))
        var rangeEnd = Math.max(rangeStart, Math.floor(Number(end) || 0))
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i]
            var textStart = root.textOffsetForPopularMark(row)
            if (textStart < 0) {
                continue
            }
            var textEnd = root.textEndForPopularMark(row, textStart)
            if (textEnd <= textStart) {
                continue
            }
            if (textStart < rangeEnd && textEnd > rangeStart) {
                var copy = {}
                for (var key in row) {
                    copy[key] = row[key]
                }
                copy.textStart = textStart
                copy.textEnd = textEnd
                copy.socialIndex = i
                matches.push(copy)
            }
        }
        return matches
    }

    function readerChapterSocialRows() {
        var rows = notesStore.popularMarks || []
        var current = root.readerChapterForOffset(root.currentReaderTextStart)
        var currentUid = String(current.chapterUid || "")
        var currentTitle = String(current.title || "").replace(/\s+/g, " ").trim()
        var matches = []
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i] || ({})
            var rowUid = String(row.chapterUid || "")
            var rowTitle = String(row.chapter || "").replace(/\s+/g, " ").trim()
            if (currentUid !== "" && rowUid !== "" && currentUid !== rowUid) {
                continue
            }
            if (currentUid === "" && currentTitle !== "" && rowTitle !== ""
                    && rowTitle.indexOf(currentTitle) < 0 && currentTitle.indexOf(rowTitle) < 0) {
                continue
            }
            var reviews = row.reviews || []
            if (reviews.length > 0) {
                for (var j = 0; j < reviews.length; j++) {
                    matches.push({
                        "author": reviews[j].author || "微信读书用户",
                        "content": reviews[j].content || reviews[j].text || "",
                        "markText": row.text || ""
                    })
                }
            } else if (String(row.text || "").length > 0) {
                matches.push({
                    "author": "划线",
                    "content": row.text,
                    "markText": row.text || ""
                })
            }
        }
        return matches
    }

    function richReaderText(value, globalStart) {
        var plain = String(value || "")
        var highlights = root.readerHighlightsForRange(globalStart, globalStart + plain.length)
        var noteMarkup = "<span style='color:#9b2226; font-weight:800;'>注</span><sup style='color:#9b2226; font-weight:800; font-size:70%; vertical-align:super;'>$1</sup>"
        if (highlights.length === 0) {
            return htmlEscape(plain).replace(/㊟([0-9]+)/g, noteMarkup)
        }
        var cuts = []
        for (var i = 0; i < highlights.length; i++) {
            var row = highlights[i]
            cuts.push({
                "start": root.clamp(Math.floor(Number(row.textStart) || 0) - globalStart, 0, plain.length),
                "end": root.clamp(Math.floor(Number(row.textEnd) || 0) - globalStart, 0, plain.length),
                "color": row.colorValue || root.readerMarkerColor,
                "kind": "local"
            })
        }
        cuts.sort(function(a, b) { return a.start - b.start })
        var out = ""
        var pos = 0
        for (var j = 0; j < cuts.length; j++) {
            var cut = cuts[j]
            if (cut.end <= pos) {
                continue
            }
            if (cut.start > pos) {
                out += htmlEscape(plain.slice(pos, cut.start))
            }
            var spanStart = Math.max(pos, cut.start)
            var segment = htmlEscape(plain.slice(spanStart, cut.end))
            out += "<span style='background-color:" + cut.color + "; color:#111111;'>" +
                   segment + "</span>"
            pos = cut.end
        }
        if (pos < plain.length) {
            out += htmlEscape(plain.slice(pos))
        }
        return out.replace(/㊟([0-9]+)/g, noteMarkup)
    }

    function readerFootnoteByIndex(index) {
        var notes = readerStore.footnotes || []
        var target = Math.max(0, Math.floor(Number(index) || 0))
        for (var i = 0; i < notes.length; i++) {
            if (Math.max(0, Math.floor(Number(notes[i].index) || 0)) === target) {
                return notes[i]
            }
        }
        return ({})
    }

    function openReaderFootnote(index) {
        var note = root.readerFootnoteByIndex(index)
        if (!note || note.text === undefined || String(note.text).length === 0) {
            return
        }
        root.readerReturnTextOffset = root.currentReaderTextStart
        root.readerActiveFootnote = note
        root.showReaderFootnote = true
    }

    function closeReaderFootnote() {
        root.showReaderFootnote = false
        root.readerActiveFootnote = ({})
        root.readerReturnTextOffset = -1
    }

    function readerFootnoteHitRectsForPage() {
        var notes = readerStore.footnotes || []
        var boxes = root.readerCurrentLineBoxes || []
        var rects = []
        if (notes.length === 0 || boxes.length === 0) {
            return rects
        }
        for (var i = 0; i < notes.length; i++) {
            var note = notes[i]
            var noteStart = Math.floor(Number(note.textStart) || -1)
            if (noteStart < root.currentReaderTextStart || noteStart >= root.currentReaderTextEnd) {
                continue
            }
            for (var j = 0; j < boxes.length; j++) {
                var box = boxes[j]
                if (noteStart >= box.textStart && noteStart <= box.textEnd) {
                    rects.push({
                        "index": Math.max(0, Math.floor(Number(note.index) || 0)),
                        "x": Math.round(box.xStart),
                        "y": Math.round(box.yStart - 18),
                        "width": Math.max(96, Math.round(box.xEnd - box.xStart)),
                        "height": Math.max(72, Math.round(box.yEnd - box.yStart + 28))
                    })
                    break
                }
            }
        }
        return rects
    }

    function readerCompactTextLength(value) {
        return String(value || "").replace(/\s+/g, "").length
    }

    function readerDocumentPositionForTextOffset(globalOffset) {
        if (!readerBodyText || !readerBodyText.getText || !readerBodyText.positionToRectangle) {
            return -1
        }
        var body = String(readerStore.bodyText || "")
        var pageStart = root.clamp(root.currentReaderTextStart, 0, body.length)
        var pageEnd = root.clamp(root.currentReaderTextEnd, pageStart, body.length)
        var pageBody = body.slice(pageStart, pageEnd)
        var leftTrim = pageBody.length - pageBody.replace(/^\s+/, "").length
        var visibleStart = Math.min(pageEnd, pageStart + leftTrim)
        var targetOffset = root.clamp(Math.floor(Number(globalOffset) || 0), visibleStart, pageEnd)
        var captionLength = root.currentReaderImageCaption === ""
            ? 0
            : root.readerCompactTextLength(root.currentReaderImageCaption)
        var targetLength = captionLength + root.readerCompactTextLength(body.slice(visibleStart, targetOffset))
        var low = 0
        var high = Math.max(0, Math.floor(Number(readerBodyText.length) || 0))
        var answer = high
        while (low <= high) {
            var middle = Math.floor((low + high) / 2)
            var visibleLength = root.readerCompactTextLength(readerBodyText.getText(0, middle))
            if (visibleLength >= targetLength) {
                answer = middle
                high = middle - 1
            } else {
                low = middle + 1
            }
        }
        return answer
    }

    function readerRenderedRectsForTextRange(start, end) {
        var safeStart = Math.max(root.currentReaderTextStart, Math.floor(Number(start) || 0))
        var safeEnd = Math.min(root.currentReaderTextEnd, Math.floor(Number(end) || 0))
        var documentStart = root.readerDocumentPositionForTextOffset(safeStart)
        var documentEnd = root.readerDocumentPositionForTextOffset(safeEnd)
        var rects = []
        if (documentStart < 0 || documentEnd <= documentStart || !readerBodyText.positionToRectangle) {
            return rects
        }

        var run = null
        var minimumCharacterWidth = Math.max(5, Math.round(root.readerFontSize * 0.42))
        for (var position = documentStart; position < documentEnd; position++) {
            var glyph = readerBodyText.positionToRectangle(position)
            if (!glyph || glyph.x === undefined || glyph.y === undefined) {
                continue
            }
            var glyphX = Number(glyph.x) || 0
            var glyphY = Number(glyph.y) || 0
            var glyphHeight = Math.max(1, Number(glyph.height) || root.readerLinePixels())
            var nextGlyph = position + 1 <= documentEnd
                ? readerBodyText.positionToRectangle(position + 1)
                : null
            var glyphEndX = glyphX + minimumCharacterWidth
            if (nextGlyph && nextGlyph.x !== undefined && Math.abs((Number(nextGlyph.y) || 0) - glyphY) <= 2
                    && Number(nextGlyph.x) > glyphX) {
                glyphEndX = Number(nextGlyph.x)
            }

            if (!run || Math.abs(run.localY - glyphY) > 2) {
                if (run) {
                    rects.push(run)
                }
                run = {
                    "localY": glyphY,
                    "x": readerBodyText.x + glyphX,
                    "y": readerBodyText.y + glyphY + glyphHeight - 4,
                    "width": Math.max(3, glyphEndX - glyphX),
                    "lineTop": readerBodyText.y + glyphY,
                    "lineHeight": glyphHeight
                }
            } else {
                run.width = Math.max(run.width, readerBodyText.x + glyphEndX - run.x)
                run.lineHeight = Math.max(run.lineHeight, glyphHeight)
                run.y = run.lineTop + run.lineHeight - 4
            }
        }
        if (run) {
            rects.push(run)
        }
        return rects
    }

    function readerSocialDashRectsForPage() {
        var marks = root.readerPopularMarksForRange(root.currentReaderTextStart, root.currentReaderTextEnd)
        var rects = []
        if (marks.length === 0) {
            return rects
        }
        for (var i = 0; i < marks.length; i++) {
            var mark = marks[i] || ({})
            var markStart = Math.max(root.currentReaderTextStart, Math.floor(Number(mark.textStart) || -1))
            var markEnd = Math.min(root.currentReaderTextEnd, Math.floor(Number(mark.textEnd) || -1))
            if (markStart < 0 || markEnd <= markStart) {
                continue
            }
            var rendered = root.readerRenderedRectsForTextRange(markStart, markEnd)
            for (var j = 0; j < rendered.length; j++) {
                var line = rendered[j]
                rects.push({
                    "socialIndex": Math.max(0, Math.floor(Number(mark.socialIndex) || 0)),
                    "x": Math.round(line.x),
                    "y": Math.round(line.y),
                    "width": Math.max(3, Math.round(line.width)),
                    "lineTop": Math.round(line.lineTop),
                    "lineHeight": Math.max(1, Math.round(line.lineHeight))
                })
            }
        }
        return rects
    }

    function readerSocialHitRectsFromDashes(dashes) {
        var rects = []
        for (var i = 0; i < dashes.length; i++) {
            var dash = dashes[i]
            var touchX = Math.max(0, dash.x - 16)
            var touchY = Math.max(0, dash.lineTop - 8)
            rects.push({
                "socialIndex": dash.socialIndex,
                "x": touchX,
                "y": touchY,
                "width": Math.min(root.width - touchX, Math.max(72, dash.width + 32)),
                "height": Math.max(56, dash.lineHeight + 16),
                "dashX": dash.x,
                "dashY": dash.y,
                "dashWidth": dash.width
            })
        }
        return rects
    }

    function readerSocialHitRectsForPage() {
        return root.readerSocialHitRects
    }

    function clearReaderSocialGeometry() {
        root.readerSocialDashRects = []
        root.readerSocialHitRects = []
    }

    function rebuildReaderSocialGeometry() {
        var dashes = root.readerSocialDashRectsForPage()
        var hits = root.readerSocialHitRectsFromDashes(dashes)
        root.readerSocialDashRects = dashes
        root.readerSocialHitRects = hits
        return dashes.length
    }

    function readerSocialMarksGeometryKey() {
        var rows = notesStore.popularMarks || []
        var parts = [root.currentReaderSocialPrefetchKey(), String(rows.length)]
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i] || ({})
            parts.push(String(row.chapterUid || "") + ":" + String(row.range || "") + ":" +
                       String(row.textStart === undefined ? "" : row.textStart) + ":" +
                       String(row.textEnd === undefined ? "" : row.textEnd))
        }
        return parts.join("|")
    }

    function openReaderFootnoteAtPoint(x, y) {
        var rects = root.readerFootnoteHitRectsForPage()
        var px = Math.floor(Number(x) || 0)
        var py = Math.floor(Number(y) || 0)
        for (var i = 0; i < rects.length; i++) {
            var rect = rects[i]
            if (px >= rect.x && px <= rect.x + rect.width && py >= rect.y && py <= rect.y + rect.height) {
                root.openReaderFootnote(rect.index)
                return true
            }
        }
        return false
    }

    function popularMarkByIndex(index) {
        var rows = notesStore.popularMarks || []
        var target = Math.max(0, Math.floor(Number(index) || 0))
        if (target >= rows.length) {
            return ({})
        }
        return rows[target] || ({})
    }

    function refreshActiveReaderSocialMark() {
        if (!root.showReaderSocialPopup) {
            return
        }
        var activeRange = String((root.readerActiveSocialMark || {}).range || "")
        var activeChapterUid = String((root.readerActiveSocialMark || {}).chapterUid || "")
        var rows = notesStore.popularMarks || []
        for (var i = 0; i < rows.length; i++) {
            if (String(rows[i].range || "") === activeRange
                    && String(rows[i].chapterUid || "") === activeChapterUid) {
                root.readerActiveSocialMark = rows[i]
                return
            }
        }
    }

    function openReaderSocialPopup(index) {
        var mark = root.popularMarkByIndex(index)
        if (!mark || root.readerSocialDisplayText(mark).length === 0) {
            return
        }
        root.readerActiveSocialMark = mark
        root.showReaderSocialPopup = true
        console.log("reader-social-open index=" + index +
                    " reviews=" + ((mark.reviews || []).length) +
                    " total=" + Math.floor(Number(mark.totalCount) || 0))
        var reviewKey = root.currentBookId + ":" + String(mark.chapterUid || "") + ":" + String(mark.range || "")
        if ((mark.reviews || []).length === 0 && !notesStore.running
                && String(mark.chapterUid || "") !== "" && String(mark.range || "") !== ""
                && root.readerSocialReviewRequestKey !== reviewKey) {
            root.readerSocialReviewRequestKey = reviewKey
            notesStore.refreshPopularReviews(root.currentBookId, String(mark.chapterUid), String(mark.range))
        }
    }

    function openReaderSocialPopupAtPoint(x, y) {
        var rects = root.readerSocialHitRects
        var px = Math.floor(Number(x) || 0)
        var py = Math.floor(Number(y) || 0)
        for (var i = 0; i < rects.length; i++) {
            var rect = rects[i]
            if (px >= rect.x && px <= rect.x + rect.width && py >= rect.y && py <= rect.y + rect.height) {
                root.openReaderSocialPopup(rect.socialIndex)
                return true
            }
        }
        return false
    }

    function openReaderChapterSocialPopup() {
        var rows = root.readerChapterSocialRows()
        if (rows.length === 0) {
            return
        }
        var chapter = root.readerChapterForOffset(root.currentReaderTextStart)
        root.readerActiveSocialMark = {
            "text": String(chapter.title || "本章") + " · 划线评论",
            "totalCount": rows.length,
            "reviews": rows
        }
        root.showReaderSocialPopup = true
    }

    function closeReaderSocialPopup() {
        if (root.showReaderSocialPopup) {
            console.log("reader-social-close")
        }
        root.showReaderSocialPopup = false
        root.readerActiveSocialMark = ({})
    }

    function handleReaderLink(link) {
        var value = String(link || "")
        if (value.indexOf("note:") === 0) {
            root.openReaderFootnote(parseInt(value.slice(5)))
        } else if (value.indexOf("social:") === 0) {
            root.openReaderSocialPopup(parseInt(value.slice(7)))
        } else if (value === "socialchapter") {
            root.openReaderChapterSocialPopup()
        }
    }

    function formatReaderText(value, textStart, textEnd) {
        var source = String(value || "")
        var paragraphs = source.split(/\n+/)
        var out = []
        var continuation = root.isParagraphContinuation(textStart)
        var chapterStart = root.isReaderChapterStart(textStart)
        var sourceCursor = 0
        var bodyLineHeight = Math.max(1, root.readerLinePixels())
        var imageCaptionPrefix = root.currentReaderImageSource !== "" ? String(root.currentReaderImageCaption || "").replace(/\s+/g, " ").trim() : ""
        var bodySourceStart = imageCaptionPrefix === "" ? 0 : -1
        for (var i = 0; i < paragraphs.length; i++) {
            var rawPara = paragraphs[i]
            var rawIndex = source.indexOf(rawPara, sourceCursor)
            if (rawIndex < 0) {
                rawIndex = sourceCursor
            }
            sourceCursor = rawIndex + rawPara.length
            var para = rawPara.replace(/\s+/g, " ").trim()
            if (para.length === 0) {
                continue
            }
            var trimLeft = rawPara.length - rawPara.replace(/^\s+/, "").length
            if (imageCaptionPrefix !== "" && out.length === 0 && para === imageCaptionPrefix) {
                out.push("<p class='reader-caption' style='margin-top:0; margin-bottom:" + root.readerLinePixels() +
                         "px; text-indent:0; text-align:center; font-size:" +
                         Math.round(root.readerFontSize * 0.82) +
                         "px; line-height:" + Math.round(bodyLineHeight * 0.95) +
                         "px; font-weight:400;'>" +
                         htmlEscape(para) + "</p>")
                continue
            }
            if (bodySourceStart < 0) {
                bodySourceStart = rawIndex
            }
            var paraGlobalStart = textStart + Math.max(0, rawIndex - bodySourceStart) + trimLeft
            if (chapterStart && out.length === 0) {
                out.push("<p class='reader-title' style='margin-top:0; margin-bottom:" +
                         Math.max(root.readerParagraphSpacing * 2, 28) +
                         "px; text-indent:0; text-align:center; font-size:" +
                         Math.round(root.readerFontSize * 1.24) +
                         "px; line-height:" + Math.round(bodyLineHeight * 1.24) +
                         "px; font-weight:800;'>" +
                         root.richReaderText(para, paraGlobalStart) + "</p>")
                continue
            }
            if (root.isReaderImageCaptionParagraph(para, out.length)) {
                out.push("<p class='reader-caption' style='margin-top:0; margin-bottom:" + root.readerLinePixels() +
                         "px; text-indent:0; text-align:center; font-size:" +
                         Math.round(root.readerFontSize * 0.82) +
                         "px; line-height:" + Math.round(bodyLineHeight * 0.95) +
                         "px; font-weight:400;'>" +
                         htmlEscape(para) + "</p>")
                continue
            }
            var firstParagraphIndent = continuation && out.length === 0 ? 0 : readerHangingIndent
            out.push("<p style='margin-top:0; margin-bottom:" + readerParagraphSpacing +
                     "px; line-height:" + bodyLineHeight +
                     "px; text-indent:" + firstParagraphIndent + "px;'>" +
                     root.richReaderText(para, paraGlobalStart) + "</p>")
        }
        if (root.isReaderChapterEnd(textEnd)) {
            var chapterComments = root.readerChapterSocialRows()
            out.push("<p class='reader-chapter-divider' style='margin-top:" +
                     Math.max(root.readerParagraphSpacing * 2, 28) +
                     "px; margin-bottom:0; text-indent:0; text-align:center; font-size:" +
                     Math.round(root.readerFontSize * 0.72) +
                     "px; font-weight:800;'>＊ ＊ ＊</p>")
            if (chapterComments.length > 0) {
                out.push("<p class='reader-chapter-comments' style='margin-top:" +
                         Math.max(root.readerParagraphSpacing, 12) +
                         "px; margin-bottom:0; text-indent:0; text-align:center; font-size:" +
                         Math.round(root.readerFontSize * 0.72) +
                         "px; font-weight:800;'><a href='socialchapter'><span style='color:#111111; border:2px solid #111111; padding:3px 10px;'>○ " +
                         chapterComments.length + " 条划线评论</span></a></p>")
            }
        }
        return out.join("")
    }

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function openReaderSettings() {
        settingsDragOffset = 0
        showReaderSettings = true
    }

    function closeReaderSettings() {
        showReaderSettings = false
        settingsDragOffset = 0
    }

    function closeReaderCatalog() {
        showReaderCatalog = false
    }

    function migrateReaderDefaults() {
        if (!persistedReaderSettings.paragraphSpacingDefaultMigrated) {
            if (root.readerParagraphSpacing <= 0) {
                root.readerParagraphSpacing = 20
                root.markReaderPaginationDirty()
            }
            persistedReaderSettings.paragraphSpacingDefaultMigrated = true
        }
        if (!persistedReaderSettings.typographyTuningMigrated) {
            if (root.readerFontSize === 32 && root.readerLineHeight >= 1.4 && root.readerParagraphSpacing >= 24) {
                root.readerFontSize = 38
                root.readerLineHeight = 1.26
                root.readerParagraphSpacing = 12
                root.readerMargin = 64
                root.readerFontChoice = "霞鹜文楷"
                root.markReaderPaginationDirty()
            }
            persistedReaderSettings.typographyTuningMigrated = true
        }
        if (!persistedReaderSettings.wenkaiDefaultMigrated) {
            if (root.readerFontChoice === "系统") {
                root.readerFontChoice = "霞鹜文楷"
                root.markReaderPaginationDirty()
            }
            if (root.readerFontSize <= 34) {
                root.readerFontSize = 38
                root.markReaderPaginationDirty()
            }
            persistedReaderSettings.wenkaiDefaultMigrated = true
        }
    }

    function readerLinePixels() {
        return Math.ceil(readerFontSize * readerLineHeight)
    }

    function readerEstimatedLinePixels() {
        return root.readerLinePixels()
    }

    function readerBottomSafety() {
        return Math.min(10, Math.max(6, readerParagraphSpacing))
    }

    function readerEstimatedParagraphGap() {
        return Math.min(12, Math.max(0, readerParagraphSpacing))
    }

    function readerChapterEndDecorationHeight(textEnd) {
        if (!root.isReaderChapterEnd(textEnd)) {
            return 0
        }
        var smallLine = Math.max(24, Math.ceil(root.readerLinePixels() * 0.76))
        return Math.max(root.readerParagraphSpacing * 2, 28)
            + smallLine
            + Math.max(root.readerParagraphSpacing, 12)
            + smallLine
    }

    function readerBodyHeight(topY) {
        var usable = Math.max(0, readerContentBottom - topY - readerBottomSafety())
        var linePx = Math.max(1, root.readerEstimatedLinePixels())
        return Math.max(linePx * 2, Math.floor(usable / linePx) * linePx)
    }

    function readerImagePageCount() {
        return 0
    }

    function readerImageEntrySource(image) {
        if (image === undefined || image === null) {
            return ""
        }
        if (typeof image === "string") {
            return image
        }
        return String(image.source || "")
    }

    function readerImageEntryTextStart(image) {
        if (image === undefined || image === null || typeof image === "string") {
            return -1
        }
        return Math.max(0, Math.floor(Number(image.textStart) || 0))
    }

    function readerImageEntryCaption(image) {
        if (image === undefined || image === null || typeof image === "string") {
            return ""
        }
        return String(image.caption || "").replace(/\s+/g, " ").trim()
    }

    function readerImageForTextRange(start, end) {
        var images = readerStore.imageSources || []
        for (var i = 0; i < images.length; i++) {
            var image = images[i]
            var source = root.readerImageEntrySource(image)
            if (source === "") {
                continue
            }
            var imageStart = root.readerImageEntryTextStart(image)
            if (imageStart >= start && imageStart < end) {
                return image
            }
            if (imageStart < 0 && start === 0 && i === 0) {
                return image
            }
        }
        return ({})
    }

    function readerImageForPageRange(start, end) {
        var image = root.readerImageForTextRange(start, end)
        return root.readerImageEntrySource(image) === "" ? ({}) : image
    }

    function readerPageCapacityAtOffset(offset) {
        var start = Math.max(0, Math.floor(Number(offset) || 0))
        var textEnd = root.readerNextPageOffset(start, root.readerTextTopMargin)
        var image = root.readerImageForPageRange(start, textEnd)
        var topY = root.readerImageEntrySource(image) !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
        return Math.max(1, root.readerNextPageOffset(start, topY) - start)
    }

    function readerPaginationBuildSignature() {
        var text = String(readerStore.bodyText || "")
        var images = readerStore.imageSources || []
        return [
            text.length,
            readerStore.status || "",
            images.length,
            root.width,
            root.height,
            root.readerFontSize,
            root.readerFontWeight,
            root.readerLineHeight,
            root.readerParagraphSpacing,
            root.readerMargin
        ].join("|")
    }

    function markReaderPaginationDirty() {
        root.readerPaginationDirty = true
    }

    function beginReaderReflow() {
        if (root.screenName === "reader" && root.currentBookId !== "") {
            root.readerReflowAnchorOffset = root.currentReaderTextStart
            root.readerReflowRestorePending = true
        }
    }

    function scheduleReaderPaginationRebuild() {
        root.beginReaderReflow()
        root.markReaderPaginationDirty()
        if (root.screenName === "reader") {
            readerPaginationDebounceTimer.restart()
        }
    }

    function readerChapterLabelsForStarts(starts) {
        var chapterLabels = {}
        var chapters = readerStore.chapters || []
        for (var chapterIndex = 0; chapterIndex < chapters.length; chapterIndex++) {
            var textStart = Math.max(0, Math.floor(Number(chapters[chapterIndex].textStart) || 0))
            var low = 0
            var high = starts.length - 1
            var page = 0
            while (low <= high) {
                var mid = Math.floor((low + high) / 2)
                if ((starts[mid] || 0) <= textStart) {
                    page = mid
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            chapterLabels[String(textStart)] = "第 " + (page + 1) + " 页"
        }
        return chapterLabels
    }

    function resetReaderPaginationDraft() {
        readerPaginationBatchTimer.stop()
        root.readerPaginationBuilding = true
        root.readerPaginationDraftStarts = []
        root.readerPaginationDraftImages = []
        root.readerPaginationDraftOffset = 0
        root.readerPaginationDraftGuard = 0
        root.readerPaginationStartedMs = Date.now()
    }

    function buildReaderPaginationBatch() {
        if (!root.readerPaginationBuilding) {
            return
        }
        var text = String(readerStore.bodyText || "")
        var starts = root.readerPaginationDraftStarts
        var images = root.readerPaginationDraftImages
        var offset = root.readerPaginationDraftOffset
        var guard = root.readerPaginationDraftGuard
        var batchEnd = guard + root.readerPaginationBatchSize
        while (offset < text.length && guard < 20000 && guard < batchEnd) {
            var textOnlyEnd = root.readerNextPageOffset(offset, root.readerTextTopMargin)
            var image = root.readerImageForPageRange(offset, textOnlyEnd)
            var imageSource = root.readerImageEntrySource(image)
            if (imageSource !== "") {
                var imageEnd = root.readerNextPageOffset(offset, root.readerImageTextTopY)
                var imageStart = root.readerImageEntryTextStart(image)
                if (imageStart >= imageEnd) {
                    image = ({})
                    imageSource = ""
                }
            }
            starts.push(offset)
            images.push(image)
            var topY = imageSource !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
            offset = root.readerNextPageOffset(offset, topY)
            guard += 1
        }
        if (starts.length === 0) {
            starts.push(0)
            images.push("")
        }
        root.readerPaginationDraftOffset = offset
        root.readerPaginationDraftGuard = guard
        var anchorPage = 0
        var anchorReached = !root.readerFastOpenMode
        if (root.readerFastOpenMode) {
            for (var anchorIndex = 0; anchorIndex < starts.length; anchorIndex++) {
                if ((starts[anchorIndex] || 0) <= root.readerFastOpenAnchorOffset) {
                    anchorPage = anchorIndex
                    anchorReached = true
                } else {
                    break
                }
            }
            if (anchorReached && starts.length - anchorPage < root.readerFastOpenMinPagesAfterAnchor) {
                anchorReached = false
            }
        }
        var waitForFastOpenAnchor = root.readerFastOpenMode && !anchorReached
        if (!waitForFastOpenAnchor) {
            root.readerPageStarts = starts
            root.readerPageImages = images
        }
        var done = offset >= text.length || guard >= 20000
        if (!waitForFastOpenAnchor) {
            root.readerCachedPageCount = done
                ? Math.max(1, starts.length)
                : Math.max(root.pageIndex + 1, starts.length)
        }
        if (root.readerFastOpenMode && anchorReached) {
            var fastAnchor = root.currentReaderTextStart > 0
                ? root.currentReaderTextStart
                : root.readerFastOpenAnchorOffset
            root.readerFastOpenMode = false
            root.setReaderPage(root.readerPageForTextOffset(fastAnchor))
        }
        if (done) {
            readerPaginationBatchTimer.stop()
            root.readerChapterPageLabels = root.readerChapterLabelsForStarts(starts)
            root.readerPaginationSignature = root.readerPaginationBuildSignature()
            root.readerPaginationDirty = false
            root.readerPaginationBuilding = false
            console.log("reader-pagination-complete pages=" + starts.length +
                        " elapsedMs=" + Math.max(0, Date.now() - root.readerPaginationStartedMs))
            if (root.pageIndex >= root.readerCachedPageCount) {
                root.pageIndex = root.readerCachedPageCount - 1
            }
            if (root.readerReflowRestorePending) {
                root.readerReflowRestorePending = false
                root.setReaderPage(root.readerPageForTextOffset(root.readerReflowAnchorOffset))
            }
        } else {
            readerPaginationBatchTimer.restart()
        }
        if (!waitForFastOpenAnchor && root.pageIndex < starts.length) {
            root.refreshReaderPageCache()
        }
    }

    function startReaderPaginationBuild() {
        root.resetReaderPaginationDraft()
        root.buildReaderPaginationBatch()
    }

    function rebuildReaderPagination() {
        root.beginReaderReflow()
        root.resetReaderPaginationDraft()
        var guard = 0
        while (root.readerPaginationBuilding && guard < 400) {
            root.buildReaderPaginationBatch()
            guard += 1
        }
    }

    Timer {
        id: readerPaginationBatchTimer
        interval: 20
        repeat: false
        onTriggered: root.buildReaderPaginationBatch()
    }

    Timer {
        id: readerInkPersistTimer
        interval: 900
        repeat: false
        onTriggered: {
            if ((root.currentFreeNotePoints || []).length > 0) {
                readerInkPersistTimer.restart()
                return
            }
            root.flushPendingFreeInkStrokes()
        }
    }

    Timer {
        id: readerPaginationDebounceTimer
        interval: 420
        repeat: false
        onTriggered: {
            var anchor = root.readerReflowAnchorOffset >= 0
                ? root.readerReflowAnchorOffset
                : root.currentReaderTextStart
            root.buildReaderPaginationWindowFromOffset(anchor, 12)
            root.readerReflowRestorePending = false
            root.setReaderPage(0)
        }
    }

    Timer {
        id: readerSocialPrefetchTimer
        property int requestedToken: 0
        interval: 3000
        repeat: false
        onTriggered: {
            if (selfTestMode !== "" || root.screenName !== "reader" || root.currentBookId === "") {
                return
            }
            if (requestedToken !== root.readerSocialPageToken) {
                return
            }
            var key = root.currentReaderSocialPrefetchKey()
            if (notesStore.popularMarksBuffered(root.currentBookId) && root.readerSocialPrefetchKey === key) {
                return
            }
            root.readerSocialPrefetchKey = key
            notesStore.bufferPopularMarksForContext(root.currentBookId, key)
        }
    }

    Connections {
        id: readerSocialRefreshOnNotesChanged
        target: notesStore
        function onChanged() {
            root.refreshActiveReaderSocialMark()
            if (root.screenName !== "reader" || root.currentBookId === "") {
                return
            }
            var count = (notesStore.popularMarks || []).length
            var geometryDataKey = root.readerSocialMarksGeometryKey()
            if (geometryDataKey !== root.readerSocialGeometryDataKey) {
                root.readerSocialGeometryDataKey = geometryDataKey
                root.readerPendingPopularMarkCount = count
                readerSocialRefreshDebounceTimer.restart()
            }
        }
    }

    Timer {
        id: readerSocialRefreshDebounceTimer
        interval: 650
        repeat: false
        onTriggered: {
            if (root.screenName !== "reader" || root.currentBookId === "") {
                return
            }
            root.readerKnownPopularMarkCount = root.readerPendingPopularMarkCount
            root.forceReaderRefresh += 1
            readerSocialGeometryRefreshTimer.restart()
            var visibleRows = root.readerPopularMarksForRange(root.currentReaderTextStart, root.currentReaderTextEnd)
            console.log("reader-social-refresh count=" + root.readerKnownPopularMarkCount +
                        " visible=" + visibleRows.length +
                        " page=" + root.pageIndex +
                        " range=" + root.currentReaderTextStart + "-" + root.currentReaderTextEnd +
                        " key=" + root.readerSocialPrefetchKey)
        }
    }

    Timer {
        id: readerSocialGeometryRefreshTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (root.screenName !== "reader" || root.currentBookId === "") {
                return
            }
            root.readerSocialGeometryToken += 1
            var dashCount = root.rebuildReaderSocialGeometry()
            console.log("reader-social-geometry dashes=" + dashCount +
                        " visible=" + root.readerPopularMarksForRange(root.currentReaderTextStart, root.currentReaderTextEnd).length +
                        " documentLength=" + Math.floor(Number(readerBodyText.length) || 0))
        }
    }

    function ensureReaderPagination() {
        var signature = root.readerPaginationBuildSignature()
        if (root.readerPaginationDirty || root.readerPaginationSignature !== signature) {
            if (root.screenName === "reader") {
                return
            }
            root.rebuildReaderPagination()
        }
    }

    function readerPageStartOffset(page) {
        root.ensureReaderPagination()
        var targetPage = Math.max(0, Math.floor(Number(page) || 0))
        targetPage = root.clamp(targetPage, 0, root.readerCachedPageCount - 1)
        return Math.max(0, root.readerPageStarts[targetPage] || 0)
    }

    function readerTextOffsetForPage(page) {
        return root.readerPageStartOffset(page)
    }

    function readerImageForPage(page) {
        root.ensureReaderPagination()
        var targetPage = root.clamp(Math.floor(Number(page) || 0), 0, root.readerCachedPageCount - 1)
        return root.readerImageEntrySource(root.readerPageImages[targetPage] || ({}))
    }

    function readerFirstPageTopY() {
        return root.readerImageForPage(0) !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
    }

    function readerTextTopY() {
        return root.readerImageForPage(pageIndex) !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
    }

    function readerTextWidth() {
        return Math.max(120, root.width - root.readerMargin * 2)
    }

    function readerTextRight() {
        return root.readerMargin + root.readerTextWidth()
    }

    function readerCharsPerPage(topY) {
        var textWidth = root.readerTextWidth()
        var charWidth = Math.max(1, root.readerFontSize * 0.92)
        var charsPerLine = Math.max(6, Math.floor(textWidth / charWidth))
        var linesPerPage = Math.max(2, Math.floor(root.readerBodyHeight(topY) / Math.max(1, root.readerEstimatedLinePixels())))
        return Math.max(120, Math.floor(charsPerLine * linesPerPage * 0.86))
    }

    function readerEstimatedCharsPerLine() {
        var textWidth = root.readerTextWidth()
        var familySafety = root.readerFontChoice === "霞鹜文楷" ? 0.98 : 0.96
        var charWidth = Math.max(1, root.readerFontSize * familySafety)
        return Math.max(6, Math.floor(textWidth / charWidth))
    }

    function readerEstimatedFirstLineChars(indent) {
        var textWidth = Math.max(120, root.readerTextWidth() - Math.max(0, indent))
        var familySafety = root.readerFontChoice === "霞鹜文楷" ? 0.98 : 0.96
        var charWidth = Math.max(1, root.readerFontSize * familySafety)
        return Math.max(4, Math.floor(textWidth / charWidth))
    }

    function readerLineBoxesForText(value, globalStart, topY) {
        var source = String(value || "")
        var paragraphs = source.split(/\n+/)
        var boxes = []
        var sourceCursor = 0
        var y = Math.max(0, Math.floor(Number(topY) || 0))
        var pageWidth = root.readerTextWidth()
        var continuation = root.isParagraphContinuation(globalStart)
        var chapterStart = root.isReaderChapterStart(globalStart)
        var bodyLinePx = Math.max(1, root.readerLinePixels())

        for (var i = 0; i < paragraphs.length; i++) {
            var rawPara = paragraphs[i]
            var rawIndex = source.indexOf(rawPara, sourceCursor)
            if (rawIndex < 0) {
                rawIndex = sourceCursor
            }
            sourceCursor = rawIndex + rawPara.length
            var para = rawPara.replace(/\s+/g, " ").trim()
            if (para.length === 0) {
                continue
            }
            var trimLeft = rawPara.length - rawPara.replace(/^\s+/, "").length
            var paraGlobalStart = globalStart + rawIndex + trimLeft
            var isTitle = chapterStart && boxes.length === 0
            var isCaption = !isTitle && root.isReaderImageCaptionParagraph(para, boxes.length)
            var fontScale = isTitle ? 1.24 : (isCaption ? 0.82 : 1)
            var linePx = Math.max(1, Math.ceil(root.readerFontSize * fontScale * root.readerLineHeight))
            var charWidth = Math.max(1, root.readerFontSize * fontScale * (root.readerFontChoice === "霞鹜文楷" ? 1.04 : 1.02))
            var local = 0
            var localLine = 0
            while (local < para.length) {
                var indent = (!isTitle && !isCaption && localLine === 0 && !(continuation && boxes.length === 0))
                    ? root.readerHangingIndent
                    : 0
                var lineWidth = Math.max(charWidth * 4, pageWidth - indent)
                var chars = Math.max(1, Math.floor(lineWidth / charWidth))
                var endLocal = Math.min(para.length, local + chars)
                boxes.push({
                    "xStart": root.readerMargin + indent,
                    "xEnd": root.readerMargin + pageWidth,
                    "yStart": y,
                    "yEnd": y + linePx,
                    "textStart": paraGlobalStart + local,
                    "textEnd": paraGlobalStart + endLocal
                })
                y += linePx
                local = endLocal
                localLine += 1
            }
            if (isTitle) {
                y += Math.max(root.readerParagraphSpacing * 2, 28)
            } else if (isCaption) {
                y += bodyLinePx
            } else {
                y += root.readerParagraphSpacing
            }
        }
        return boxes
    }

    function readerLineBoxForPoint(point) {
        var boxes = root.readerCurrentLineBoxes || []
        if (boxes.length === 0) {
            return ({})
        }
        var y = Math.floor(Number(point.y) || 0)
        for (var i = 0; i < boxes.length; i++) {
            var box = boxes[i]
            if (y >= box.yStart && y < box.yEnd) {
                return box
            }
        }
        var best = boxes[0]
        var bestDistance = Math.abs(y - (best.yStart + best.yEnd) / 2)
        for (var j = 1; j < boxes.length; j++) {
            var candidate = boxes[j]
            var distance = Math.abs(y - (candidate.yStart + candidate.yEnd) / 2)
            if (distance < bestDistance) {
                best = candidate
                bestDistance = distance
            }
        }
        return best
    }

    function readerTextOffsetForVisibleText(visiblePrefix) {
        var wanted = String(visiblePrefix || "").replace(/\s+/g, "").length
        if (wanted <= 0) {
            return root.currentReaderTextStart
        }
        var page = String(root.currentReaderPageText || "")
        var seen = 0
        for (var i = 0; i < page.length; i++) {
            var ch = page.charAt(i)
            if (/\s/.test(ch)) {
                continue
            }
            seen += 1
            if (seen >= wanted) {
                return root.clamp(root.currentReaderTextStart + i + 1,
                                  root.currentReaderTextStart,
                                  root.currentReaderTextEnd)
            }
        }
        return root.currentReaderTextEnd
    }

    function readerEstimatedSliceHeight(value, firstLineIndent) {
        var paragraphs = String(value || "").split(/\n+/)
        var linePx = Math.max(1, root.readerEstimatedLinePixels())
        var total = 0
        for (var i = 0; i < paragraphs.length; i++) {
            var para = paragraphs[i].replace(/\s+/g, " ").trim()
            if (para.length === 0) {
                continue
            }
            var indent = total === 0 ? Math.max(0, Math.floor(Number(firstLineIndent) || 0)) : root.readerHangingIndent
            var lines = root.readerEstimatedParagraphLines(para, indent)
            total += lines * linePx + root.readerEstimatedParagraphGap()
        }
        return total
    }

    function readerEstimatedParagraphLines(value, firstLineIndent) {
        var para = String(value || "").replace(/\s+/g, " ").trim()
        return root.readerEstimatedParagraphLinesForLength(para.length, firstLineIndent)
    }

    function readerEstimatedParagraphLinesForLength(length, firstLineIndent) {
        var textLength = Math.max(0, Math.floor(Number(length) || 0))
        if (textLength === 0) {
            return 0
        }
        var firstChars = root.readerEstimatedFirstLineChars(firstLineIndent)
        var restChars = Math.max(1, root.readerEstimatedCharsPerLine())
        if (textLength <= firstChars) {
            return 1
        }
        return 1 + Math.ceil((textLength - firstChars) / restChars)
    }

    function readerEstimatedTitleHeight(value) {
        var para = String(value || "").replace(/\s+/g, " ").trim()
        return root.readerEstimatedTitleHeightForLength(para.length)
    }

    function readerEstimatedTitleHeightForLength(length) {
        var textLength = Math.max(0, Math.floor(Number(length) || 0))
        if (textLength === 0) {
            return 0
        }
        var textWidth = root.readerTextWidth()
        var titleFontSize = root.readerFontSize * 1.24
        var titleLinePx = Math.max(1, Math.ceil(root.readerEstimatedLinePixels() * 1.24))
        var charsPerLine = Math.max(4, Math.floor(textWidth / Math.max(1, titleFontSize * 1.03)))
        var lines = Math.max(1, Math.ceil(textLength / charsPerLine))
        return lines * titleLinePx + Math.max(root.readerParagraphSpacing * 2, 28)
    }

    function readerTrimmedRangeLength(text, start, end) {
        var body = String(text || "")
        var left = root.clamp(Math.floor(Number(start) || 0), 0, body.length)
        var right = root.clamp(Math.floor(Number(end) || 0), left, body.length)
        while (left < right) {
            var leftCode = body.charCodeAt(left)
            if (!((leftCode >= 9 && leftCode <= 13) || leftCode === 32 || leftCode === 160 || leftCode === 12288)) {
                break
            }
            left += 1
        }
        while (right > left) {
            var rightCode = body.charCodeAt(right - 1)
            if (!((rightCode >= 9 && rightCode <= 13) || rightCode === 32 || rightCode === 160 || rightCode === 12288)) {
                break
            }
            right -= 1
        }
        return right - left
    }

    function readerPartialParagraphEnd(text, paragraphStart, paragraphEnd, remainingHeight, topY) {
        var body = String(text || "")
        var safeStart = root.clamp(Math.floor(Number(paragraphStart) || 0), 0, body.length)
        var safeEnd = root.clamp(Math.floor(Number(paragraphEnd) || 0), safeStart, body.length)
        var paragraphLength = root.readerTrimmedRangeLength(body, safeStart, safeEnd)
        if (paragraphLength === 0) {
            return safeStart
        }
        var linePx = Math.max(1, root.readerEstimatedLinePixels())
        var fullAvailableLines = Math.floor(Math.max(0, remainingHeight) / linePx)
        var firstLineIndent = root.isParagraphContinuation(safeStart) ? 0 : root.readerHangingIndent
        var paragraphLines = root.readerEstimatedParagraphLinesForLength(paragraphLength, firstLineIndent)
        if (fullAvailableLines >= paragraphLines) {
            return safeEnd
        }
        var availableLines = Math.floor(Math.max(0, remainingHeight) / linePx)
        if (availableLines < root.readerMinOrphanLines || paragraphLines - availableLines < root.readerMinWidowLines) {
            return safeStart
        }
        var firstLineChars = root.readerEstimatedFirstLineChars(firstLineIndent)
        var restLineChars = Math.max(1, root.readerEstimatedCharsPerLine())
        var charBudget = availableLines <= 1
            ? firstLineChars
            : firstLineChars + (availableLines - 1) * restLineChars
        charBudget = Math.max(1, Math.floor(charBudget))
        return root.clamp(safeStart + charBudget, safeStart + 1, safeEnd)
    }

    function readerPaginationHeightBudget(topY) {
        return root.readerBodyHeight(topY)
    }

    function readerEstimatedPageEnd(start, topY) {
        var body = String(readerStore.bodyText || "")
        var safeStart = root.clamp(Math.floor(Number(start) || 0), 0, body.length)
        if (safeStart >= body.length) {
            return body.length
        }
        var maxHeight = root.readerPaginationHeightBudget(topY)
        var linePx = Math.max(1, root.readerEstimatedLinePixels())
        var charsPerLine = Math.max(1, root.readerEstimatedCharsPerLine())
        var totalHeight = 0
        var cursor = safeStart
        var pageEnd = safeStart
        var guard = 0
        while (cursor < body.length && guard < 5000) {
            guard += 1
            var paragraphEnd = body.indexOf("\n", cursor)
            if (paragraphEnd < 0) {
                paragraphEnd = body.length
            }
            var nextStart = paragraphEnd
            while (nextStart < body.length && body.charAt(nextStart) === "\n") {
                nextStart += 1
            }
            var paragraphLength = root.readerTrimmedRangeLength(body, cursor, paragraphEnd)
            if (paragraphLength === 0) {
                cursor = nextStart
                continue
            }
            var paragraphIndent = root.isParagraphContinuation(cursor) ? 0 : root.readerHangingIndent
            var paragraphHeight = root.isReaderChapterStart(cursor)
                ? root.readerEstimatedTitleHeightForLength(paragraphLength)
                : root.readerEstimatedParagraphLinesForLength(paragraphLength, paragraphIndent) * linePx + root.readerEstimatedParagraphGap()
            var paragraphDecorationHeight = root.readerChapterEndDecorationHeight(nextStart)
            if (totalHeight + paragraphHeight + paragraphDecorationHeight <= maxHeight) {
                totalHeight += paragraphHeight + paragraphDecorationHeight
                pageEnd = nextStart
                cursor = nextStart
                continue
            }
            if (pageEnd === safeStart) {
                var availableLines = Math.max(1, Math.floor(maxHeight / linePx))
                var charBudget = Math.max(1, Math.floor(charsPerLine * availableLines * 0.94))
                return Math.min(body.length, safeStart + charBudget)
            }
            var remainingHeight = maxHeight - totalHeight - paragraphDecorationHeight
            var partialEnd = root.readerPartialParagraphEnd(body, cursor, paragraphEnd, remainingHeight, topY)
            if (partialEnd > cursor) {
                return Math.max(safeStart + 1, partialEnd)
            }
            return Math.max(safeStart + 1, pageEnd)
        }
        return Math.max(safeStart + 1, pageEnd > safeStart ? pageEnd : body.length)
    }

    function readerAvoidLeadingPunctuation(text, start, end) {
        var body = String(text || "")
        var safeStart = root.clamp(Math.floor(Number(start) || 0), 0, body.length)
        var safeEnd = root.clamp(Math.floor(Number(end) || 0), safeStart + 1, body.length)
        while (safeEnd < body.length && root.readerLeadingPunctuationCharacters.indexOf(body.charAt(safeEnd)) >= 0) {
            safeEnd += 1
        }
        return safeEnd
    }

    function readerAvoidEndingPunctuation(text, start, end) {
        var body = String(text || "")
        var safeStart = root.clamp(Math.floor(Number(start) || 0), 0, body.length)
        var safeEnd = root.clamp(Math.floor(Number(end) || 0), safeStart + 1, body.length)
        while (safeEnd > safeStart + 1 && root.readerEndingPunctuationCharacters.indexOf(body.charAt(safeEnd - 1)) >= 0) {
            safeEnd -= 1
        }
        return safeEnd
    }

    function readerCleanPageEnd(text, start, end) {
        var body = String(text || "")
        var safeStart = root.clamp(Math.floor(Number(start) || 0), 0, body.length)
        var adjusted = root.readerAvoidEndingPunctuation(body, safeStart, end)
        return root.readerAvoidLeadingPunctuation(body, safeStart, adjusted)
    }

    function readerPreferredPageEnd(text, start, rawEnd) {
        var body = String(text || "")
        var safeStart = root.clamp(Math.floor(Number(start) || 0), 0, body.length)
        var safeEnd = root.clamp(Math.floor(Number(rawEnd) || 0), safeStart + 1, body.length)
        if (safeEnd >= body.length) {
            return body.length
        }
        var pageSpan = Math.max(1, safeEnd - safeStart)
        var windowStart = Math.max(safeStart + 12, safeEnd - Math.max(4, Math.floor(root.readerEstimatedCharsPerLine() * 0.25)))
        var paragraphBreak = body.lastIndexOf("\n", safeEnd)
        if (paragraphBreak >= windowStart) {
            var next = paragraphBreak + 1
            while (next < body.length && body.charAt(next) === "\n") {
                next += 1
            }
            return root.readerCleanPageEnd(body, safeStart, Math.max(safeStart + 1, next))
        }
        return root.readerCleanPageEnd(body, safeStart, safeEnd)
    }

    function readerNextPageOffset(start, topY) {
        var text = String(readerStore.bodyText || "")
        var safeStart = Math.max(0, Math.floor(Number(start) || 0))
        var rawEnd = root.readerEstimatedPageEnd(safeStart, topY)
        var chapterBreak = root.nextReaderChapterStartAfter(safeStart)
        if (chapterBreak > safeStart && chapterBreak <= rawEnd) {
            return chapterBreak
        }
        return root.readerPreferredPageEnd(text, safeStart, rawEnd)
    }

    function buildReaderPaginationWindowFromOffset(offset, pageCount) {
        var text = String(readerStore.bodyText || "")
        var start = root.clamp(Math.floor(Number(offset) || 0), 0, Math.max(0, text.length - 1))
        var starts = []
        var images = []
        var guard = 0
        while (start < text.length && guard < Math.max(1, pageCount)) {
            var textOnlyEnd = root.readerNextPageOffset(start, root.readerTextTopMargin)
            var image = root.readerImageForPageRange(start, textOnlyEnd)
            var imageSource = root.readerImageEntrySource(image)
            if (imageSource !== "") {
                var imageEnd = root.readerNextPageOffset(start, root.readerImageTextTopY)
                var imageStart = root.readerImageEntryTextStart(image)
                if (imageStart >= imageEnd) {
                    image = ({})
                    imageSource = ""
                }
            }
            starts.push(start)
            images.push(image)
            var topY = imageSource !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
            var next = root.readerNextPageOffset(start, topY)
            if (next <= start) {
                break
            }
            start = next
            guard += 1
        }
        if (starts.length === 0) {
            starts.push(0)
            images.push("")
        }
        root.readerPageStarts = starts
        root.readerPageImages = images
        root.readerCachedPageCount = Math.max(1, starts.length)
        root.readerChapterPageLabels = ({})
        root.readerPaginationSignature = root.readerPaginationBuildSignature()
        root.readerPaginationDirty = false
        root.readerPaginationBuilding = false
        root.readerFastOpenMode = false
        readerPaginationBatchTimer.stop()
        root.pageIndex = 0
        root.refreshReaderPageCache()
        console.log("reader-pagination-window start=" + starts[0] +
                    " pages=" + starts.length +
                    " end=" + root.currentReaderTextEnd)
    }

    function extendReaderPaginationWindow(additionalPages) {
        var text = String(readerStore.bodyText || "")
        var starts = (root.readerPageStarts || []).slice()
        var images = (root.readerPageImages || []).slice()
        if (starts.length === 0 || text.length === 0) {
            return false
        }
        var lastIndex = starts.length - 1
        var lastImage = images[lastIndex] || ({})
        var lastTopY = root.readerImageEntrySource(lastImage) !== ""
            ? root.readerImageTextTopY
            : root.readerTextTopMargin
        var cursor = root.readerNextPageOffset(starts[lastIndex], lastTopY)
        var added = 0
        var target = Math.max(1, Math.floor(Number(additionalPages) || 0))
        while (cursor < text.length && added < target) {
            var textOnlyEnd = root.readerNextPageOffset(cursor, root.readerTextTopMargin)
            var image = root.readerImageForPageRange(cursor, textOnlyEnd)
            var imageSource = root.readerImageEntrySource(image)
            if (imageSource !== "") {
                var imageEnd = root.readerNextPageOffset(cursor, root.readerImageTextTopY)
                if (root.readerImageEntryTextStart(image) >= imageEnd) {
                    image = ({})
                    imageSource = ""
                }
            }
            starts.push(cursor)
            images.push(image)
            var topY = imageSource !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
            var next = root.readerNextPageOffset(cursor, topY)
            if (next <= cursor) {
                break
            }
            cursor = next
            added += 1
        }
        if (added === 0) {
            return false
        }
        root.readerPageStarts = starts
        root.readerPageImages = images
        root.readerCachedPageCount = starts.length
        console.log("reader-pagination-extend added=" + added + " pages=" + starts.length)
        return true
    }

    function ensureReaderPaginationWindowAhead() {
        if (root.readerCachedPageCount - root.pageIndex <= 4) {
            root.extendReaderPaginationWindow(8)
        }
    }

    function rebuildReaderPaginationWindowBackward() {
        var oldStart = root.currentReaderTextStart
        if (oldStart <= 0) {
            return false
        }
        var chapter = root.readerChapterForOffset(Math.max(0, oldStart - 1))
        var chapterStart = Math.max(0, Math.floor(Number(chapter.textStart) || 0))
        var estimatedBack = Math.max(1, root.readerBodyPageChars()) * 8
        var candidate = Math.max(chapterStart, oldStart - estimatedBack)
        root.buildReaderPaginationWindowFromOffset(candidate, 12)
        root.pageIndex = root.readerPageForTextOffset(Math.max(0, oldStart - 1))
        root.refreshReaderPageCache()
        return true
    }

    function goToReaderTextOffset(offset) {
        var text = String(readerStore.bodyText || "")
        var target = root.clamp(Math.floor(Number(offset) || 0), 0, Math.max(0, text.length - 1))
        root.buildReaderPaginationWindowFromOffset(target, 12)
        root.setReaderPage(0)
        root.forceReaderRefresh += 1
    }

    function readerFirstPageChars() {
        return root.readerCharsPerPage(root.readerFirstPageTopY())
    }

    function readerBodyPageChars() {
        return root.readerCharsPerPage(root.readerTextTopMargin)
    }

    function readerPageCountFor(value, topY) {
        root.ensureReaderPagination()
        return root.readerCachedPageCount
    }

    function readerPageText(value, topY) {
        var text = String(value || "")
        var pageCount = root.readerPageCountFor(text, topY)
        var safePage = root.clamp(root.pageIndex, 0, pageCount - 1)
        var start = root.readerPageStartOffset(safePage)
        var nextStart = root.readerPageStarts[safePage + 1] || 0
        var end = nextStart > start
            ? nextStart
            : root.readerNextPageOffset(start, topY)
        return text.slice(start, end).trim()
    }

    function refreshReaderPageCache() {
        var count = Math.max(1, root.readerCachedPageCount)
        if (root.pageIndex >= count) {
            root.pageIndex = count - 1
        }
        if (root.pageIndex < 0) {
            root.pageIndex = 0
        }
        var image = root.readerPageImages[root.pageIndex] || ({})
        var imageSource = root.readerImageEntrySource(image)
        var topY = imageSource !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
        var text = String(readerStore.bodyText || "")
        var start = Math.max(0, root.readerPageStarts[root.pageIndex] || 0)
        var nextStart = root.readerPageStarts[root.pageIndex + 1] || 0
        var end = nextStart > start
            ? nextStart
            : root.readerNextPageOffset(start, topY)
        root.currentReaderImageSource = imageSource
        root.currentReaderImageCaption = root.readerImageEntryCaption(image)
        root.currentReaderTextTopY = topY
        root.currentReaderTextStart = start
        root.currentReaderTextEnd = Math.min(text.length, end)
        root.currentReaderPageText = root.currentReaderImageCaption !== ""
            ? root.currentReaderImageCaption + "\n\n" + text.slice(start, root.currentReaderTextEnd).trim()
            : text.slice(start, root.currentReaderTextEnd).trim()
        root.readerCurrentLineBoxes = root.readerLineBoxesForText(root.currentReaderPageText, root.currentReaderTextStart, root.currentReaderTextTopY)
        root.currentReaderProgressValue = text.length === 0
            ? 0
            : Math.round(root.clamp(root.currentReaderTextStart / Math.max(1, text.length), 0, 1) * 10000) / 100
    }

    function readerPageForTextOffset(offset) {
        var textOffset = Math.max(0, Math.floor(Number(offset) || 0))
        root.ensureReaderPagination()
        var low = 0
        var high = root.readerCachedPageCount - 1
        var answer = 0
        while (low <= high) {
            var mid = Math.floor((low + high) / 2)
            var start = root.readerPageStarts[mid] || 0
            if (start <= textOffset) {
                answer = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return root.clamp(answer, 0, root.readerCachedPageCount - 1)
    }

    function readerChapterPageLabel(chapter) {
        if (!chapter) {
            return ""
        }
        var key = String(Math.max(0, Math.floor(Number(chapter.textStart) || 0)))
        return root.readerChapterPageLabels[key] || ""
    }

    function jumpToChapter(chapter) {
        if (!chapter) {
            return
        }
        root.closeReaderCatalog()
        root.closeReaderSettings()
        root.goToReaderTextOffset(chapter.textStart || 0)
    }

    function jumpToSearchResult(result) {
        if (!result) {
            return
        }
        root.closeReaderCatalog()
        root.closeReaderSettings()
        root.goToReaderTextOffset(result.textStart || 0)
    }

    function textOffsetForWeReadNote(note) {
        if (!note) {
            return 0
        }

        var body = String(readerStore.bodyText || "")
        var markText = String(note.text || "").replace(/\s+/g, " ").trim()
        if (markText.length > 0) {
            var exact = body.indexOf(markText)
            if (exact >= 0) {
                return exact
            }
            var probe = markText.slice(0, Math.min(16, markText.length))
            if (probe.length >= 4) {
                var fuzzy = body.indexOf(probe)
                if (fuzzy >= 0) {
                    return fuzzy
                }
            }
        }

        var chapterName = String(note.chapter || "").replace(/\s+/g, " ").trim()
        var chapters = readerStore.chapters || []
        if (chapterName.length > 0) {
            for (var i = 0; i < chapters.length; i++) {
                var title = String(chapters[i].title || "").replace(/\s+/g, " ").trim()
                if (title.length > 0 && (title.indexOf(chapterName) >= 0 || chapterName.indexOf(title) >= 0)) {
                    return chapters[i].textStart || 0
                }
            }
        }
        return 0
    }

    function textOffsetForSnippet(snippet) {
        var body = String(readerStore.bodyText || "")
        var clean = String(snippet || "").replace(/\s+/g, " ").trim()
        if (clean.length === 0) {
            return -1
        }
        var exact = body.indexOf(clean)
        if (exact >= 0) {
            return exact
        }
        var probe = clean.slice(0, Math.min(24, clean.length))
        return probe.length >= 6 ? body.indexOf(probe) : -1
    }

    function jumpToWeReadNote(note) {
        if (!note) {
            return
        }
        root.closeReaderCatalog()
        root.closeReaderSettings()
        root.goToReaderTextOffset(root.textOffsetForWeReadNote(note))
    }

    function toggleReaderBookmark() {
        var count = root.readerPageCountFor(readerStore.bodyText, root.readerTextTopY())
        readerStore.toggleBookmark(root.currentBookId, readerStore.title, root.pageIndex, count)
        root.forceReaderRefresh += 1
    }

    function toggleReaderHighlight(color) {
        var count = root.readerPageCountFor(readerStore.bodyText, root.readerTextTopY())
        readerStore.toggleHighlight(root.currentBookId, readerStore.title, root.pageIndex, count, color.name, color.value)
        root.forceReaderRefresh += 1
    }

    function saveCurrentStroke() {
        if (root.readerMarkerTool === "free") {
            root.saveCurrentFreeInkStroke()
            return
        }
        if (root.readerMarkerTool === "eraser") {
            root.eraseCurrentMarkerSelection()
            return
        }
        root.saveCurrentMarkerSelection()
    }

    function readerStylusToolAt(x, y) {
        if (root.screenName !== "reader" || !readerStylusToolBar.visible) {
            return ({})
        }
        var localX = x - readerStylusToolBar.x
        var localY = y - readerStylusToolBar.y
        if (localX < 0 || localX > readerStylusToolBar.width || localY < 0 || localY > readerStylusToolBar.height) {
            return ({})
        }
        if (!root.readerStylusToolsExpanded) {
            return ({ "id": "expand", "tool": "expand", "name": "展开" })
        }
        for (var i = 0; i < root.readerStylusTools.length; i++) {
            var dotX = root.readerStylusToolBarPadding + (readerStylusToolBar.width - root.readerStylusToolBarPadding * 2 - root.readerStylusToolDotSize) / 2
            var dotY = root.readerStylusToolY(i)
            if (localX >= dotX && localX <= dotX + root.readerStylusToolDotSize
                    && localY >= dotY && localY <= dotY + root.readerStylusToolDotSize) {
                return root.readerStylusTools[i]
            }
        }
        return ({})
    }

    function readerStylusToolY(index) {
        return root.readerStylusToolBarPadding
            + index * (root.readerStylusToolDotSize + root.readerStylusToolGap)
            + (index >= 4 ? root.readerStylusSectionGap : 0)
    }

    function readerStylusToolSelected(tool) {
        if (!tool) {
            return false
        }
        if (tool.tool === "color") {
            return tool.value === root.readerMarkerColor
        }
        if (tool.tool === "marker" || tool.tool === "free" || tool.tool === "eraser") {
            return tool.tool === root.readerMarkerTool
        }
        if (tool.tool === "notes") {
            return root.showHandwrittenNotes
        }
        if (tool.tool === "clear") {
            return root.readerClearArmed
        }
        return false
    }

    function selectReaderStylusTool(tool) {
        if (!tool || !tool.id) {
            return false
        }
        if (tool.tool === "expand") {
            root.readerStylusToolsExpanded = true
            root.readerStylusCollapsePending = false
            return true
        }
        if (tool.tool !== "ocr") {
            root.readerOcrBlockSelection = false
            root.readerSelectedInkBlockId = ""
        }
        if (tool.tool === "color") {
            root.readerMarkerColorName = tool.name || root.readerMarkerColorName
            root.readerMarkerColor = tool.value || root.readerMarkerColor
            root.annotationMode = true
            root.readerStylusCollapsePending = true
            return true
        }
        if (tool.tool === "notes") {
            root.showHandwrittenNotes = !root.showHandwrittenNotes
            root.readerStylusCollapsePending = true
            return true
        }
        if (tool.tool === "ocr") {
            root.readerClearArmed = false
            readerClearConfirmTimer.stop()
            root.beginReaderInkBlockOcrSelection()
            return true
        }
        if (tool.tool === "clear") {
            if (!root.readerClearArmed) {
                root.readerClearArmed = true
                root.readerStylusToolsExpanded = true
                root.readerStylusCollapsePending = false
                readerClearConfirmTimer.restart()
            } else {
                root.clearCurrentPageInkAndNotes()
            }
            return true
        }
        root.readerMarkerTool = tool.tool || "marker"
        root.readerClearArmed = false
        readerClearConfirmTimer.stop()
        root.readerStylusCollapsePending = true
        root.annotationMode = true
        root.currentStrokePoints = []
        root.currentFreeNotePoints = []
        root.currentFreeNoteStrokes = []
        readerInkCanvas.clearLive()
        return true
    }

    function clearCurrentPageInkAndNotes() {
        root.flushPendingFreeInkStrokes()
        readerInkCanvas.clearLive()
        root.readerOcrBlockSelection = false
        root.readerSelectedInkBlockId = ""
        root.currentStrokePoints = []
        root.currentFreeNotePoints = []
        root.currentFreeNoteStrokes = []
        readerStore.clearPageStrokes(root.currentBookId, root.pageIndex)
        var notes = (readerStore.paragraphNotes || []).slice()
        var placements = root.readerParagraphNotePlacements()
        for (var index = 0; index < notes.length; ++index) {
            var note = notes[index] || ({})
            var noteId = String(note.noteId || "")
            if (noteId !== "" && (placements[noteId] || {}).visible) {
                readerStore.removeParagraphNote(root.currentBookId, noteId)
            }
        }
        root.readerClearArmed = false
        readerClearConfirmTimer.stop()
        root.readerStylusCollapsePending = true
    }

    function markerPointFromStylus(x, y, pressure) {
        var textBottom = root.currentReaderTextTopY + root.readerBodyHeight(root.currentReaderTextTopY) - 1
        return ({
            "x": root.clamp(Math.round(Number(x) || 0), root.readerMargin, root.width - root.readerMargin),
            "y": root.clamp(Math.round(Number(y) || 0), root.currentReaderTextTopY, textBottom),
            "pressure": Math.max(0, Number(pressure) || 0)
        })
    }

    function freeNotePointFromStylus(x, y, pressure) {
        return ({
            "x": root.clamp(Math.round(Number(x) || 0), 12, root.width - 12),
            "y": root.clamp(Math.round(Number(y) || 0), root.readerTextTopMargin, root.readerContentBottom),
            "pressure": Math.max(0, Number(pressure) || 0)
        })
    }

    function beginStylusStroke(x, y, pressure) {
        root.readerStylusStrokeInToolbar = false
        if (root.screenName !== "reader" || root.showReaderSettings || root.showReaderCatalog) {
            return
        }
        var tool = root.readerStylusToolAt(x, y)
        if (root.selectReaderStylusTool(tool)) {
            root.readerStylusStrokeInToolbar = true
            return
        }
        if (root.readerOcrBlockSelection) {
            var inkBlock = root.readerInkBlockAt(x, y)
            root.readerSuppressPageTurnUntilMs = Date.now() + 700
            root.readerStylusStrokeInToolbar = true
            if (inkBlock.blockId) {
                root.recognizeReaderInkBlock(inkBlock)
            } else {
                root.readerOcrBlockSelection = false
            }
            return
        }
        if (!root.annotationMode) {
            return
        }
        if (root.readerMarkerTool === "free") {
            readerInkPersistTimer.stop()
            var freePoint = root.freeNotePointFromStylus(x, y, pressure)
            root.currentFreeNotePoints = [freePoint]
            readerInkCanvas.beginStroke(freePoint.x, freePoint.y, root.readerMarkerColor, 4, 1, true)
        } else {
            var markerPoint = root.markerPointFromStylus(x, y, pressure)
            root.currentStrokePoints = [markerPoint]
            readerInkCanvas.beginStroke(markerPoint.x, markerPoint.y,
                                        root.readerMarkerTool === "eraser" ? root.inkColor : root.readerMarkerColor,
                                        root.readerMarkerTool === "eraser" ? 10 : root.readerMarkerLineWidth,
                                        root.readerMarkerTool === "eraser" ? 0.82 : 0.42,
                                        root.readerMarkerTool !== "eraser")
        }
    }

    function appendStylusStroke(x, y, pressure) {
        var points = root.readerMarkerTool === "free" ? root.currentFreeNotePoints : root.currentStrokePoints
        if (root.readerStylusStrokeInToolbar || !root.annotationMode || points.length < 1) {
            return
        }
        var point = root.readerMarkerTool === "free" ? root.freeNotePointFromStylus(x, y, pressure) : root.markerPointFromStylus(x, y, pressure)
        var last = points[points.length - 1]
        if (Math.abs((last.x || 0) - point.x) + Math.abs((last.y || 0) - point.y) < 1) {
            return
        }
        points.push(point)
        readerInkCanvas.appendPoint(point.x, point.y)
    }

    function endStylusStroke(x, y, pressure) {
        if (root.readerStylusStrokeInToolbar) {
            root.readerStylusStrokeInToolbar = false
            return
        }
        var points = root.readerMarkerTool === "free" ? root.currentFreeNotePoints : root.currentStrokePoints
        if (!root.annotationMode || points.length < 1) {
            return
        }
        root.appendStylusStroke(x, y, pressure)
        if (root.readerMarkerTool === "free") {
            root.saveCurrentFreeInkStroke()
            readerInkCanvas.finishStroke()
            return
        }
        root.saveCurrentStroke()
        readerInkCanvas.finishStroke()
    }

    function saveCurrentFreeInkStroke() {
        var points = (root.currentFreeNotePoints || []).slice()
        if (points.length >= 2 && root.currentBookId !== "") {
            var count = root.readerPageCountFor(readerStore.bodyText, root.readerTextTopY())
            if (root.pendingFreeInkBookId !== ""
                    && (root.pendingFreeInkBookId !== root.currentBookId
                        || root.pendingFreeInkPageIndex !== root.pageIndex)) {
                root.flushPendingFreeInkStrokes()
            }
            root.pendingFreeInkBookId = root.currentBookId
            root.pendingFreeInkTitle = readerStore.title
            root.pendingFreeInkPageIndex = root.pageIndex
            root.pendingFreeInkPageCount = count
            root.pendingFreeInkSequence += 1
            root.pendingFreeInkStrokes = (root.pendingFreeInkStrokes || []).concat([{
                "clientStrokeId": "pending-" + Date.now() + "-" + root.pendingFreeInkSequence,
                "colorName": root.readerMarkerColorName,
                "colorValue": root.readerMarkerColor,
                "points": points,
                "tool": "free",
                "lineWidth": 4
            }])
            readerInkPersistTimer.restart()
        }
        root.currentFreeNotePoints = []
        root.currentFreeNoteStrokes = []
    }

    function readerVisibleInkStrokes() {
        var strokes = (readerStore.pageStrokes || []).slice()
        if (root.pendingFreeInkBookId === root.currentBookId
                && root.pendingFreeInkPageIndex === root.pageIndex) {
            var persistedIds = ({})
            for (var index = 0; index < strokes.length; ++index) {
                var persistedId = String((strokes[index] || {}).clientStrokeId || "")
                if (persistedId !== "") {
                    persistedIds[persistedId] = true
                }
            }
            var pending = root.pendingFreeInkStrokes || []
            for (var pendingIndex = 0; pendingIndex < pending.length; ++pendingIndex) {
                var pendingStroke = pending[pendingIndex] || ({})
                var pendingId = String(pendingStroke.clientStrokeId || "")
                if (pendingId === "" || !persistedIds[pendingId]) {
                    strokes.push(pendingStroke)
                }
            }
        }
        return strokes
    }

    function flushPendingFreeInkStrokes() {
        var strokes = (root.pendingFreeInkStrokes || []).slice()
        if (strokes.length < 1 || root.pendingFreeInkBookId === "") {
            return
        }
        readerInkPersistTimer.stop()
        readerStore.addPageStrokesBatch(root.pendingFreeInkBookId, root.pendingFreeInkTitle,
                                        root.pendingFreeInkPageIndex, root.pendingFreeInkPageCount,
                                        strokes)
        root.pendingFreeInkStrokes = []
        root.pendingFreeInkBookId = ""
        root.pendingFreeInkTitle = ""
        root.pendingFreeInkPageIndex = -1
        root.pendingFreeInkPageCount = 1
    }

    function readerParagraphNotePlacements() {
        var placements = ({})
        var nextY = root.currentReaderTextTopY
        var notes = readerStore.paragraphNotes || []
        for (var index = 0; index < notes.length; index++) {
            var note = notes[index] || ({})
            var noteId = String(note.noteId || "")
            var anchor = note.anchor || ({})
            var fallback = note.fallback || ({})
            var isParagraph = anchor.kind === "paragraph"
                && Number(anchor.textEnd) > root.currentReaderTextStart
                && Number(anchor.textStart) < root.currentReaderTextEnd
            var isPageFree = anchor.kind === "page-free"
                && Number(fallback.pageIndex) === root.pageIndex
            if (!isParagraph && !isPageFree) {
                continue
            }
            var desiredY = root.currentReaderTextTopY
            if (isParagraph) {
                var rects = root.readerRenderedRectsForTextRange(anchor.textStart, anchor.textEnd)
                if (rects.length > 0) {
                    desiredY = rects[0].lineTop
                }
            } else {
                desiredY = root.clamp(Math.round(Number(fallback.y) * root.height), root.currentReaderTextTopY, root.readerFooterTop - 84)
            }
            var y = Math.max(desiredY, nextY)
            if (y > root.readerFooterTop - 78) {
                y = Math.max(root.currentReaderTextTopY, root.readerFooterTop - 78)
            }
            placements[noteId] = ({
                "visible": true,
                "x": isParagraph ? root.readerTextRight() + 10 : root.clamp(Math.round(Number(fallback.x) * root.width), root.readerMargin, root.width - 154),
                "y": y,
                "width": isParagraph ? Math.max(110, root.readerNotesGutterWidth - 18) : 144,
                "height": 70,
                "kind": isParagraph ? "paragraph" : "page-free"
            })
            nextY = y + 78
        }
        return placements
    }

    function readerTextOffsetForPoint(point) {
        if (readerBodyText && readerBodyText.positionAt && readerBodyText.getText) {
            var localX = root.clamp(Math.round(Number(point.x) || 0) - readerBodyText.x, 0, readerBodyText.width)
            var localY = root.clamp(Math.round(Number(point.y) || 0) - readerBodyText.y, 0, readerBodyText.height)
            var documentPosition = readerBodyText.positionAt(localX, localY)
            if (documentPosition >= 0) {
                return root.readerTextOffsetForVisibleText(readerBodyText.getText(0, documentPosition))
            }
        }
        var box = root.readerLineBoxForPoint(point)
        if (box && box.textEnd !== undefined && box.textEnd > box.textStart) {
            var boxX = root.clamp(Math.floor(Number(point.x) || 0), box.xStart, box.xEnd)
            var boxRatio = root.clamp((boxX - box.xStart) / Math.max(1, box.xEnd - box.xStart), 0, 1)
            return root.clamp(Math.floor(box.textStart + boxRatio * Math.max(1, box.textEnd - box.textStart)),
                              box.textStart,
                              Math.max(box.textStart, box.textEnd))
        }
        var x = root.clamp(Math.floor(Number(point.x) || 0), root.readerMargin, root.width - root.readerMargin)
        var y = root.clamp(Math.floor(Number(point.y) || 0), root.currentReaderTextTopY, root.currentReaderTextTopY + root.readerBodyHeight(root.currentReaderTextTopY) - 1)
        var linePx = Math.max(1, root.readerEstimatedLinePixels())
        var line = Math.max(0, Math.floor((y - root.currentReaderTextTopY) / linePx))
        var charsPerLine = Math.max(1, root.readerEstimatedCharsPerLine())
        var textWidth = Math.max(1, root.readerTextWidth())
        var xRatio = root.clamp((x - root.readerMargin) / textWidth, 0, 1)
        var charInLine = Math.floor(xRatio * charsPerLine)
        return root.clamp(root.currentReaderTextStart + line * charsPerLine + charInLine,
                          root.currentReaderTextStart,
                          Math.max(root.currentReaderTextStart, root.currentReaderTextEnd))
    }

    function currentMarkerTextRange() {
        if (root.currentStrokePoints.length < 2) {
            return ({ "start": -1, "end": -1 })
        }
        var minOffset = root.currentReaderTextEnd
        var maxOffset = root.currentReaderTextStart
        for (var i = 0; i < root.currentStrokePoints.length; i++) {
            var offset = root.readerTextOffsetForPoint(root.currentStrokePoints[i])
            minOffset = Math.min(minOffset, offset)
            maxOffset = Math.max(maxOffset, offset)
        }
        if (maxOffset <= minOffset) {
            maxOffset = Math.min(root.currentReaderTextEnd, minOffset + Math.max(2, Math.floor(root.readerEstimatedCharsPerLine() * 0.35)))
        }
        return ({ "start": minOffset, "end": maxOffset })
    }

    function saveCurrentMarkerSelection() {
        if (root.currentStrokePoints.length < 2) {
            root.currentStrokePoints = []
            return
        }
        var range = root.currentMarkerTextRange()
        if (range.start < 0 || range.end <= range.start) {
            root.currentStrokePoints = []
            return
        }
        var count = root.readerPageCountFor(readerStore.bodyText, root.readerTextTopY())
        var excerpt = String(readerStore.bodyText || "").slice(range.start, range.end).replace(/\s+/g, " ").trim().slice(0, 36)
        readerStore.addTextHighlight(root.currentBookId, readerStore.title, root.pageIndex, count, range.start, range.end, root.readerMarkerColorName, root.readerMarkerColor, excerpt)
        root.currentStrokePoints = []
    }

    function eraseCurrentMarkerSelection() {
        if (root.currentStrokePoints.length < 2) {
            root.currentStrokePoints = []
            return
        }
        var range = root.currentMarkerTextRange()
        if (range.start < 0 || range.end <= range.start) {
            root.currentStrokePoints = []
            return
        }
        readerStore.clearTextHighlightsInRange(root.currentBookId, range.start, range.end)
        root.currentStrokePoints = []
    }

    function currentReaderProgressPercent() {
        return root.currentReaderProgressValue
    }

    function currentReaderSummaryText() {
        return root.currentReaderPageText.replace(/\s+/g, " ").trim().slice(0, 80)
    }

    function currentReaderElapsedSeconds() {
        if (root.readerSessionStartedMs <= 0) {
            return 0
        }
        return Math.max(0, Math.floor((Date.now() - root.readerSessionStartedMs) / 1000))
    }

    function requestReaderContinuationDownload() {
        if (!readerStore.openingCache || root.currentBookId === "" || downloadStore.running || root.readerPendingContinueDownload) {
            return
        }
        if (root.currentReaderTextEnd < String(readerStore.bodyText || "").length - 4) {
            return
        }
        root.readerPendingContinueDownload = true
        root.readerPendingContinueBookId = root.currentBookId
        root.readerPendingContinueTitle = readerStore.title
        root.readerPendingContinueSnippet = String(root.currentReaderPageText || "").replace(/\s+/g, " ").trim().slice(0, 48)
        downloadStore.downloadBook(root.currentBookId, readerStore.title)
    }

    function continueReaderAfterFullDownload(bookId, title) {
        var snippet = root.readerPendingContinueSnippet
        root.readerPendingContinueDownload = false
        root.readerPendingContinueBookId = ""
        root.readerPendingContinueTitle = ""
        root.readerPendingContinueSnippet = ""
        root.enterReaderForBook(bookId, title)
        var offset = root.textOffsetForSnippet(snippet)
        if (offset >= 0) {
            root.goToReaderTextOffset(offset)
        }
    }

    function scheduleReaderSocialPrefetch() {
        if (selfTestMode !== "" || root.screenName !== "reader" || root.currentBookId === "") {
            return
        }
        root.clearReaderSocialGeometry()
        root.readerSocialGeometryDataKey = ""
        root.readerSocialPageToken += 1
        root.readerKnownPopularMarkCount = (notesStore.popularMarks || []).length
        notesStore.cancelPopularMarks()
        readerSocialPrefetchTimer.requestedToken = root.readerSocialPageToken
        readerSocialPrefetchTimer.restart()
    }

    function currentReaderHighlightColor() {
        var rows = readerStore.highlights || []
        for (var i = 0; i < rows.length; i++) {
            if ((rows[i].pageIndex || 0) === root.pageIndex) {
                return rows[i].colorValue || ""
            }
        }
        return ""
    }

    function currentReaderTextHighlightCount() {
        var rows = readerStore.highlights || []
        var count = 0
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i]
            if (row.kind === "text" && (row.pageIndex || 0) === root.pageIndex) {
                count += 1
            }
        }
        return count
    }

    function applyFrontlightPercent(percent) {
        if (percent <= 0) {
            frontlightStore.turnOff()
            return
        }
        var value = Math.max(1, Math.round(root.clamp(percent, 0, 100) / 100 * frontlightStore.maxBrightness))
        frontlightStore.setBrightness(value)
    }

    function handleSettingsPanelDownDrag(delta) {
        settingsDragOffset = root.clamp(delta, 0, 220)
        if (settingsDragOffset > 86) {
            root.closeReaderSettings()
            settingsDragOffset = 0
            return true
        }
        return false
    }

    function runSettingsPanelSelfTest() {
        root.openReaderSettings()
        if (!root.showReaderSettings) {
            console.log("settings-panel-selftest=fail open")
            appControl.quitToSystem()
            return
        }
        var closed = root.handleSettingsPanelDownDrag(120)
        if (!closed || root.showReaderSettings || root.settingsDragOffset !== 0) {
            console.log("settings-panel-selftest=fail close")
            appControl.quitToSystem()
            return
        }
        console.log("settings-panel-selftest=ok")
        appControl.quitToSystem()
    }

    function runOcrSetupSelfTest() {
        ocrSetupServer.start()
        ocrSetupSelfTestTimer.attempts = 0
        ocrSetupSelfTestTimer.start()
    }

    function runOcrNetworkSelfTest() {
        ocrStore.runConnectionSelfTest()
        ocrNetworkSelfTestTimer.attempts = 0
        ocrNetworkSelfTestTimer.start()
    }

    function selfTestBook() {
        var recent = shelfStore.recentBook || ({})
        if (String(recent.bookId || "") !== "") {
            return recent
        }
        var books = shelfStore.books || []
        for (var i = 0; i < books.length; i++) {
            if (String(books[i].bookId || "") !== "") {
                return books[i]
            }
        }
        return ({})
    }

    function enterReaderForSelfTest(label) {
        var book = root.selfTestBook()
        var bookId = String(book.bookId || "")
        if (bookId === "") {
            console.log(label + "=fail no-test-book")
            appControl.quitToSystem()
            return false
        }
        root.enterReaderForBook(bookId, String(book.title || ""))
        return true
    }

    function runReaderOpenSelfTest() {
        if (!root.enterReaderForSelfTest("reader-open-selftest")) {
            return
        }
        root.ensureReaderPagination()
        var pageText = root.readerPageText(readerStore.bodyText, root.readerTextTopY())
        var statusText = readerStore.status
        if (statusText === "error" || pageText.length === 0) {
            console.log("reader-open-selftest=fail status=" + statusText + " pages=" + root.readerCachedPageCount)
            appControl.quitToSystem()
            return
        }
        console.log("reader-open-selftest=ok pages=" + root.readerCachedPageCount + " chars=" + String(readerStore.bodyText || "").length)
        appControl.quitToSystem()
    }

    function firstReaderImagePage() {
        root.ensureReaderPagination()
        for (var i = 0; i < root.readerPageImages.length; i++) {
            if ((root.readerPageImages[i] || "") !== "") {
                return i
            }
        }
        return -1
    }

    function runReaderImageSelfTest() {
        root.readerImageLoadFailed = false
        if (!root.enterReaderForSelfTest("reader-image-selftest")) {
            return
        }
        root.rebuildReaderPagination()
        var imagePage = root.firstReaderImagePage()
        if (imagePage < 0) {
            console.log("reader-image-selftest=fail no-image-page images=" + (readerStore.imageSources || []).length)
            appControl.quitToSystem()
            return
        }
        root.setReaderPage(imagePage)
        if (root.currentReaderImageSource === "") {
            console.log("reader-image-selftest=fail empty-source page=" + imagePage)
            appControl.quitToSystem()
            return
        }
        readerImageSelfTestTimer.page = imagePage
        readerImageSelfTestTimer.source = root.currentReaderImageSource
        readerImageSelfTestTimer.restart()
    }

    function runReaderSettingsSelfTest() {
        if (!root.enterReaderForSelfTest("reader-settings-selftest")) {
            return
        }
        root.settingsSelfTestStartMs = Date.now()
        root.openReaderSettings()
        readerSettingsSelfTestTimer.restart()
    }

    function runReaderFontSelfTest() {
        root.readerFontChoice = "霞鹜文楷"
        if (!root.enterReaderForSelfTest("reader-font-selftest")) {
            return
        }
        root.ensureReaderPagination()
        readerFontSelfTestTimer.restart()
    }

    function uniqueReaderLayoutPages(candidates, count) {
        var seen = ({})
        var pages = []
        for (var i = 0; i < candidates.length; i++) {
            var page = root.clamp(Math.floor(Number(candidates[i]) || 0), 0, Math.max(0, count - 1))
            var key = String(page)
            if (!seen[key]) {
                seen[key] = true
                pages.push(page)
            }
        }
        return pages
    }

    function readerLayoutFailure() {
        if (String(root.currentReaderPageText || "").length === 0) {
            return "empty-text page=" + root.pageIndex
        }
        var firstChar = String(root.currentReaderPageText || "").replace(/\s+/g, "").charAt(0)
        if (root.readerLeadingPunctuationCharacters.indexOf(firstChar) >= 0) {
            return "leading-punctuation page=" + root.pageIndex + " char=" + firstChar
        }
        var trimmedText = String(root.currentReaderPageText || "").replace(/\s+$/g, "")
        var lastChar = trimmedText.charAt(Math.max(0, trimmedText.length - 1))
        if (root.readerEndingPunctuationCharacters.indexOf(lastChar) >= 0) {
            return "ending-punctuation page=" + root.pageIndex + " char=" + lastChar
        }
        var linePx = Math.max(1, root.readerEstimatedLinePixels())
        var bodyHeight = Math.ceil(readerBodyText.height)
        var paintedHeight = Math.ceil(readerBodyText.paintedHeight)
        if (bodyHeight % linePx !== 0) {
            return "non-line-height bodyHeight=" + bodyHeight + " linePx=" + linePx
        }
        if (paintedHeight > bodyHeight + 2) {
            return "overflow page=" + root.pageIndex + " painted=" + paintedHeight + " body=" + bodyHeight
        }
        if (readerBodyText.y + paintedHeight > readerBodyText.y + bodyHeight + 2) {
            return "bottom-overlap page=" + root.pageIndex + " paintedBottom=" + (readerBodyText.y + paintedHeight) + " bodyBottom=" + (readerBodyText.y + bodyHeight)
        }
        if (root.currentReaderImageSource === "" && root.pageIndex < root.readerCachedPageCount - 1
                && !root.isReaderChapterEnd(root.currentReaderTextEnd)
                && !root.isReaderNearChapterEnd(root.currentReaderTextStart, root.currentReaderTextEnd)
                && paintedHeight < bodyHeight * 0.97) {
            return "underfilled-page page=" + root.pageIndex + " painted=" + paintedHeight + " body=" + bodyHeight
        }
        return ""
    }

    function runReaderLayoutSelfTest() {
        root.readerSelfTestSavedSettings = root.captureReaderSettings()
        root.readerFontChoice = "霞鹜文楷"
        root.readerFontSize = 38
        root.readerFontWeight = Font.DemiBold
        root.readerLineHeight = 1.26
        root.readerParagraphSpacing = 12
        root.readerFirstLineIndentChars = 2
        root.readerMargin = 64
        if (!root.enterReaderForSelfTest("reader-layout-selftest")) {
            return
        }
        root.rebuildReaderPagination()
        var count = Math.max(1, root.readerCachedPageCount)
        var imagePage = root.firstReaderImagePage()
        root.readerLayoutSelfTestPages = root.uniqueReaderLayoutPages([
            Math.floor(count * 0.08),
            Math.floor(count * 0.33),
            Math.floor(count * 0.66),
            Math.floor(count * 0.9),
            imagePage > Math.floor(count * 0.04) ? imagePage : Math.floor(count * 0.12)
        ], count)
        root.readerLayoutSelfTestCursor = 0
        root.setReaderPage(root.readerLayoutSelfTestPages[0] || 0)
        readerLayoutSelfTestTimer.restart()
    }

    function runReaderDefaultsSelfTest() {
        root.migrateReaderDefaults()
        if (root.readerParagraphSpacing < 8) {
            console.log("reader-defaults-selftest=fail paragraphSpacing=" + root.readerParagraphSpacing)
            appControl.quitToSystem()
            return
        }
        if (root.readerFirstLineIndentChars !== 2) {
            console.log("reader-defaults-selftest=fail firstLineIndentChars=" + root.readerFirstLineIndentChars)
            appControl.quitToSystem()
            return
        }
        if (root.readerLineHeight < 1.2) {
            console.log("reader-defaults-selftest=fail lineHeight=" + root.readerLineHeight)
            appControl.quitToSystem()
            return
        }
        if (root.readerFontWeight < Font.DemiBold) {
            console.log("reader-defaults-selftest=fail fontWeight=" + root.readerFontWeight)
            appControl.quitToSystem()
            return
        }
        console.log("reader-defaults-selftest=ok paragraphSpacing=" + root.readerParagraphSpacing +
                    " firstLineIndentChars=" + root.readerFirstLineIndentChars +
                    " lineHeight=" + root.readerLineHeight +
                    " fontWeight=" + root.readerFontWeight +
                    " fontChoice=" + root.readerFontChoice)
        appControl.quitToSystem()
    }

    function runReaderMarkerSelfTest() {
        if (!root.enterReaderForSelfTest("reader-marker-selftest")) {
            return
        }
        root.rebuildReaderPagination()
        root.setReaderPage(Math.min(2, Math.max(0, root.readerCachedPageCount - 1)))
        readerStore.clearPageStrokes(root.currentBookId, root.pageIndex)
        readerStore.clearPageHighlights(root.currentBookId, root.pageIndex)
        var count = root.readerPageCountFor(readerStore.bodyText, root.readerTextTopY())
        var points = [
            {"x": root.readerMargin + 42, "y": root.currentReaderTextTopY + 72},
            {"x": root.width - root.readerMargin - 42, "y": root.currentReaderTextTopY + 72}
        ]
        root.currentStrokePoints = points
        var range = root.currentMarkerTextRange()
        root.saveCurrentMarkerSelection()
        var textHighlights = root.readerHighlightsForRange(range.start, range.end)
        if (textHighlights.length < 1) {
            console.log("reader-marker-selftest=fail missing-text-highlight range=" + range.start + "-" + range.end)
            appControl.quitToSystem()
            return
        }
        if (textHighlights[0].kind !== "text" || Math.floor(Number(textHighlights[0].textEnd) || 0) <= Math.floor(Number(textHighlights[0].textStart) || 0)) {
            console.log("reader-marker-selftest=fail kind=" + textHighlights[0].kind + " start=" + textHighlights[0].textStart + " end=" + textHighlights[0].textEnd)
            readerStore.clearPageHighlights(root.currentBookId, root.pageIndex)
            appControl.quitToSystem()
            return
        }
        readerStore.clearPageHighlights(root.currentBookId, root.pageIndex)
        console.log("reader-marker-selftest=ok snapped=" + textHighlights[0].textStart + "-" + textHighlights[0].textEnd + " color=" + textHighlights[0].colorName)
        appControl.quitToSystem()
    }

    function runReaderSocialSelfTest() {
        if (!root.enterReaderForSelfTest("reader-social-selftest")) {
            return
        }
        if (root.pageIndex > 0) {
            root.pageIndex -= 1
            root.refreshReaderPageCache()
        }
        var key = root.currentReaderSocialPrefetchKey()
        readerSocialSelfTestTimer.attempts = 0
        readerSocialSelfTestTimer.contextKey = key
        notesStore.bufferPopularMarksForContext(root.currentBookId, key)
        readerSocialSelfTestTimer.start()
    }

    function runDetailUiSelfTest() {
        if ((shelfStore.books || []).length === 0) {
            console.log("detail-ui-selftest=fail empty-shelf")
            return
        }
        root.detailBookOverride = ({})
        root.selectedIndex = 0
        root.screenName = "detail"
        root.forceReaderRefresh += 1
        console.log("detail-ui-selftest=ready index=" + root.selectedIndex)
    }

    function runReaderStylusToolbarSelfTest() {
        if (!root.enterReaderForSelfTest("reader-stylus-toolbar-selftest")) {
            return
        }
        readerStylusToolbarSelfTestTimer.expectedOffset = root.currentReaderTextStart
        root.readerStylusToolsExpanded = true
        root.readerStylusCollapsePending = false
        root.selectReaderStylusTool(root.readerStylusTools[1])
        root.handleStylusTap(root.width - 40, readerStylusToolBar.y + 80)
        root.handleReaderPageTurnGesture("right", 0, 0, 0, 0)
        readerStylusToolbarSelfTestTimer.start()
    }

    function startReaderSocialClicksSelfTest() {
        var rows = root.readerPopularMarksForRange(root.currentReaderTextStart, root.currentReaderTextEnd)
        var seen = ({})
        var indices = []
        for (var i = 0; i < rows.length && indices.length < 3; i++) {
            var socialIndex = Math.max(0, Math.floor(Number(rows[i].socialIndex) || 0))
            var key = String(socialIndex)
            if (!seen[key]) {
                seen[key] = true
                indices.push(socialIndex)
            }
        }
        if (indices.length < 2) {
            console.log("reader-social-clicks-selftest=fail reason=not-enough-marks count=" + indices.length)
            appControl.quitToSystem()
            return
        }
        readerSocialClicksSelfTestTimer.indices = indices
        readerSocialClicksSelfTestTimer.cursor = 0
        readerSocialClicksSelfTestTimer.completed = 0
        readerSocialClicksSelfTestTimer.waitingForReview = false
        readerSocialClicksSelfTestTimer.cooldownTicks = 0
        readerSocialClicksSelfTestTimer.maxLagMs = 0
        readerSocialClicksSelfTestTimer.failedForLag = false
        readerSocialClicksSelfTestTimer.lastTickMs = Date.now()
        readerSocialClicksSelfTestTimer.start()
    }

    function captureReaderSettings() {
        return {
            "fontSize": root.readerFontSize,
            "fontWeight": root.readerFontWeight,
            "lineHeight": root.readerLineHeight,
            "paragraphSpacing": root.readerParagraphSpacing,
            "firstLineIndentChars": root.readerFirstLineIndentChars,
            "margin": root.readerMargin,
            "fontChoice": root.readerFontChoice
        }
    }

    function restoreReaderSettings(settings) {
        if (!settings) {
            return
        }
        root.readerFontSize = settings.fontSize
        root.readerFontWeight = settings.fontWeight === undefined ? Font.DemiBold : settings.fontWeight
        root.readerLineHeight = settings.lineHeight
        root.readerParagraphSpacing = settings.paragraphSpacing
        root.readerFirstLineIndentChars = settings.firstLineIndentChars
        root.readerMargin = settings.margin
        root.readerFontChoice = settings.fontChoice
        root.markReaderPaginationDirty()
    }

    property double settingsSelfTestStartMs: 0

    Timer {
        id: readerSettingsSelfTestTimer
        interval: 900
        repeat: false
        onTriggered: {
            var elapsed = Date.now() - root.settingsSelfTestStartMs
            if (!root.showReaderSettings || elapsed > 5000) {
                console.log("reader-settings-selftest=fail elapsed=" + elapsed + " visible=" + root.showReaderSettings)
                appControl.quitToSystem()
                return
            }
            console.log("reader-settings-selftest=ok elapsed=" + elapsed)
            root.closeReaderSettings()
            appControl.quitToSystem()
        }
    }

    Timer {
        id: readerImageSelfTestTimer
        property int page: -1
        property string source: ""
        interval: 900
        repeat: false
        onTriggered: {
            if (root.readerImageLoadFailed) {
                console.log("reader-image-selftest=fail decode page=" + page + " source=" + source)
                appControl.quitToSystem()
                return
            }
            console.log("reader-image-selftest=ok page=" + page + " source=" + source)
            appControl.quitToSystem()
        }
    }

    Timer {
        id: readerFontSelfTestTimer
        interval: 900
        repeat: false
        onTriggered: {
            if (lxgwWenKaiFont.status !== FontLoader.Ready || root.readerFontFamily === "") {
                console.log("reader-font-selftest=fail status=" + lxgwWenKaiFont.status + " family=" + root.readerFontFamily)
                appControl.quitToSystem()
                return
            }
            console.log("reader-font-selftest=ok family=" + root.readerFontFamily)
            appControl.quitToSystem()
        }
    }

    Timer {
        id: readerLayoutSelfTestTimer
        interval: 700
        repeat: false
        onTriggered: {
        if (lxgwWenKaiFont.status !== FontLoader.Ready || root.readerFontFamily === "") {
                root.restoreReaderSettings(root.readerSelfTestSavedSettings)
                console.log("reader-layout-selftest=fail font-status=" + lxgwWenKaiFont.status + " family=" + root.readerFontFamily)
                appControl.quitToSystem()
                return
            }
            var failure = root.readerLayoutFailure()
            if (failure !== "") {
                root.restoreReaderSettings(root.readerSelfTestSavedSettings)
                console.log("reader-layout-selftest=fail " + failure)
                appControl.quitToSystem()
                return
            }
            root.readerLayoutSelfTestCursor += 1
            if (root.readerLayoutSelfTestCursor >= root.readerLayoutSelfTestPages.length) {
                console.log("reader-layout-selftest=ok pages=" + root.readerLayoutSelfTestPages.join(",") +
                            " linePx=" + root.readerEstimatedLinePixels() +
                            " bodyHeight=" + Math.ceil(readerBodyText.height) +
                            " paintedHeight=" + Math.ceil(readerBodyText.paintedHeight))
                root.restoreReaderSettings(root.readerSelfTestSavedSettings)
                appControl.quitToSystem()
                return
            }
            root.setReaderPage(root.readerLayoutSelfTestPages[root.readerLayoutSelfTestCursor])
            readerLayoutSelfTestTimer.restart()
        }
    }

    Timer {
        id: readerSocialSelfTestTimer
        property int attempts: 0
        property string contextKey: ""
        interval: 1000
        repeat: true
        onTriggered: {
            attempts += 1
            var visibleRows = root.readerPopularMarksForRange(root.currentReaderTextStart, root.currentReaderTextEnd)
            var dashCount = visibleRows.length > 0 ? root.rebuildReaderSocialGeometry() : 0
            if (dashCount > 0 && root.readerSocialHitRects.length > 0 && !notesStore.running) {
                console.log("reader-social-selftest=ok context=" + contextKey +
                            " visible=" + visibleRows.length +
                            " dashes=" + dashCount +
                            " hits=" + root.readerSocialHitRects.length)
                stop()
                if (selfTestMode === "reader-social-clicks") {
                    root.startReaderSocialClicksSelfTest()
                } else {
                    readerSocialSelfTestQuitTimer.start()
                }
                return
            }
            if (attempts >= 30) {
                console.log("reader-social-selftest=fail context=" + contextKey +
                            " visible=" + visibleRows.length +
                            " dashes=" + dashCount +
                            " status=" + notesStore.statusText)
                stop()
                appControl.quitToSystem()
            }
        }
    }

    Timer {
        id: readerSocialClicksSelfTestTimer
        property var indices: []
        property int cursor: 0
        property int completed: 0
        property bool waitingForReview: false
        property int cooldownTicks: 0
        property int maxLagMs: 0
        property bool failedForLag: false
        property double lastTickMs: 0
        interval: 100
        repeat: true
        onTriggered: {
            var now = Date.now()
            if (lastTickMs > 0) {
                var lag = Math.max(0, Math.round(now - lastTickMs - interval))
                maxLagMs = Math.max(maxLagMs, lag)
                if (maxLagMs > 900) {
                    failedForLag = true
                }
            }
            lastTickMs = now

            if (waitingForReview) {
                if (notesStore.running) {
                    return
                }
                waitingForReview = false
                completed += 1
                cursor += 1
                cooldownTicks = 5
                console.log("reader-social-clicks-loaded completed=" + completed +
                            " maxLagMs=" + maxLagMs + " status=" + notesStore.statusText)
                return
            }
            if (cooldownTicks > 0) {
                cooldownTicks -= 1
                return
            }
            if (cursor >= indices.length || completed >= 3) {
                stop()
                if (failedForLag) {
                    console.log("reader-social-clicks-selftest=fail opened=" + completed +
                                " maxLagMs=" + maxLagMs + " reason=heartbeat-stall")
                } else {
                    console.log("reader-social-clicks-selftest=ok opened=" + completed +
                                " maxLagMs=" + maxLagMs)
                }
                readerSocialSelfTestQuitTimer.start()
                return
            }

            var socialIndex = indices[cursor]
            root.readerSocialReviewRequestKey = ""
            root.openReaderSocialPopup(socialIndex)
            root.closeReaderSocialPopup()
            waitingForReview = notesStore.running
            console.log("reader-social-clicks-open cursor=" + cursor +
                        " index=" + socialIndex + " waiting=" + waitingForReview)
            if (!waitingForReview) {
                completed += 1
                cursor += 1
                cooldownTicks = 5
            }
        }
    }

    Timer {
        id: readerSocialSelfTestQuitTimer
        interval: 3000
        repeat: false
        onTriggered: appControl.quitToSystem()
    }

    Timer {
        interval: 250
        running: selfTestMode === "settings-panel"
        repeat: false
        onTriggered: root.runSettingsPanelSelfTest()
    }

    Timer {
        id: ocrSetupSelfTestStartTimer
        interval: 250
        running: selfTestMode === "ocr-setup"
        repeat: false
        onTriggered: root.runOcrSetupSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "ocr-network"
        repeat: false
        onTriggered: root.runOcrNetworkSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "ocr-storage"
        repeat: false
        onTriggered: {
            ocrStore.runStorageSelfTest()
            var passed = String(ocrStore.status || "").indexOf("自检通过") >= 0
            console.log("ocr-storage-selftest=" + (passed ? "ok" : "fail") + " status=" + String(ocrStore.status || ""))
            appControl.quitToSystem()
        }
    }

    Timer {
        id: ocrNetworkSelfTestTimer
        property int attempts: 0
        interval: 400
        repeat: true
        onTriggered: {
            attempts += 1
            if (!ocrStore.busy) {
                var passed = String(ocrStore.status || "").indexOf("网络连接正常") >= 0
                console.log("ocr-network-selftest=" + (passed ? "ok" : "fail") + " status=" + String(ocrStore.status || ""))
                stop()
                appControl.quitToSystem()
                return
            }
            // The device's TLS handshake may take longer than a normal UI
            // interaction.  Keep this diagnostic alive beyond the 15-second
            // request timeout so it can report a meaningful result.
            if (attempts >= 80) {
                console.log("ocr-network-selftest=fail")
                stop()
                appControl.quitToSystem()
            }
        }
    }

    Timer {
        id: ocrSetupSelfTestTimer
        property int attempts: 0
        interval: 400
        repeat: true
        onTriggered: {
            attempts += 1
            var ready = ocrSetupServer.running
                && String(ocrSetupServer.setupUrl || "").indexOf("https://") === 0
                && String(ocrSetupServer.pairingCode || "").length === 6
                && ocrSetupServer.secondsRemaining > 0
            if (ready) {
                console.log("ocr-setup-selftest=ok")
                ocrSetupServer.cancel()
                stop()
                appControl.quitToSystem()
                return
            }
            if (attempts >= 25) {
                console.log("ocr-setup-selftest=fail")
                ocrSetupServer.cancel()
                stop()
                appControl.quitToSystem()
            }
        }
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-open"
        repeat: false
        onTriggered: root.runReaderOpenSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-image"
        repeat: false
        onTriggered: root.runReaderImageSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-settings"
        repeat: false
        onTriggered: root.runReaderSettingsSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-font"
        repeat: false
        onTriggered: root.runReaderFontSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-defaults"
        repeat: false
        onTriggered: root.runReaderDefaultsSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-marker"
        repeat: false
        onTriggered: root.runReaderMarkerSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-social"
        repeat: false
        onTriggered: root.runReaderSocialSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-social-clicks"
        repeat: false
        onTriggered: root.runReaderSocialSelfTest()
    }

    Timer {
        interval: 350
        running: selfTestMode === "detail-ui"
        repeat: false
        onTriggered: root.runDetailUiSelfTest()
    }

    Timer {
        interval: 350
        running: selfTestMode === "reader-stylus-toolbar"
        repeat: false
        onTriggered: root.runReaderStylusToolbarSelfTest()
    }

    Timer {
        interval: 250
        running: selfTestMode === "reader-layout"
        repeat: false
        onTriggered: root.runReaderLayoutSelfTest()
    }

    Timer {
        id: powerSleepSelfTestTimer
        property int phase: 0
        interval: 950
        running: selfTestMode === "power-sleep"
        repeat: true
        onTriggered: {
            if (phase === 0) {
                powerStore.simulatePowerShortPress()
                phase = 1
                interval = 1000
                return
            }
            if (phase === 1) {
                if (!root.sleepOverlayVisible || !powerStore.sleeping || powerStore.wakeLockHeld) {
                    console.log("power-sleep-selftest=fail phase=sleep overlay=" + root.sleepOverlayVisible +
                                " sleeping=" + powerStore.sleeping + " held=" + powerStore.wakeLockHeld)
                    stop()
                    appControl.quitToSystem()
                    return
                }
                powerStore.simulatePowerShortPress()
                phase = 2
                interval = 950
                return
            }
            var passed = !root.sleepOverlayVisible && !powerStore.sleeping && powerStore.wakeLockHeld
            console.log("power-sleep-selftest=" + (passed ? "ok" : "fail") +
                        " phase=resume overlay=" + root.sleepOverlayVisible +
                        " sleeping=" + powerStore.sleeping + " held=" + powerStore.wakeLockHeld)
            stop()
            appControl.quitToSystem()
        }
    }

    Timer {
        id: qrLoginUiSelfTestTimer
        property int attempts: 0
        interval: 500
        running: selfTestMode === "qr-login-ui"
        repeat: true
        onTriggered: {
            attempts += 1
            root.showQrLogin = true
            if (accountStore.loginConfirmUrl !== "" && fullScreenLoginQrImage.status === Image.Ready) {
                console.log("qr-login-ui-selftest=ok urlLength=" + accountStore.loginConfirmUrl.length +
                            " image=" + fullScreenLoginQrImage.width + "x" + fullScreenLoginQrImage.height)
                accountStore.cancelQrLogin()
                stop()
                appControl.quitToSystem()
                return
            }
            if (!accountStore.running && !accountStore.renewingCookie && !accountStore.loginRunning) {
                accountStore.startQrLogin()
            }
            if (attempts >= 40) {
                console.log("qr-login-ui-selftest=fail status=" + accountStore.loginStatusText)
                accountStore.cancelQrLogin()
                stop()
                appControl.quitToSystem()
            }
        }
    }

    function openSoftKeyboard(target) {
        keyboardTarget = target
        var isPassword = target && target.echoMode === TextInput.Password
        keyboardPinyinMode = !isPassword
        keyboardHandwritingMode = false
        keyboardPinyinBuffer = ""
        keyboardCandidates = []
        keyboardCandidatePage = 0
        keyboardClearHandwriting()
        showSoftKeyboard = true
        if (keyboardTarget && keyboardTarget.forceActiveFocus) {
            keyboardTarget.forceActiveFocus()
        }
    }

    function closeSoftKeyboard() {
        showSoftKeyboard = false
        keyboardTarget = null
        keyboardPinyinBuffer = ""
        keyboardCandidates = []
        keyboardCandidatePage = 0
        keyboardClearHandwriting()
    }

    function beginReaderInkBlockOcrSelection() {
        root.readerSelectedInkBlockId = ""
        root.readerOcrBlockSelection = (readerStore.pageInkBlocks || []).length > 0
        root.readerStylusToolsExpanded = false
        root.readerStylusCollapsePending = false
        root.readerSuppressPageTurnUntilMs = Date.now() + 500
    }

    function selectReaderInkBlock(block) {
        if (!block || !block.blockId || Date.now() < root.readerSuppressPageTurnUntilMs) {
            return
        }
        root.readerOcrBlockSelection = false
        root.readerSelectedInkBlockId = String(block.blockId)
    }

    function selectedReaderInkBlock() {
        var blocks = readerStore.pageInkBlocks || []
        for (var index = 0; index < blocks.length; ++index) {
            var block = blocks[index] || ({})
            if (String(block.blockId || "") === root.readerSelectedInkBlockId) {
                return block
            }
        }
        return ({})
    }

    function deleteSelectedReaderInkBlock() {
        if (root.readerSelectedInkBlockId === "") {
            return
        }
        readerStore.removePageInkBlock(root.currentBookId, root.pageIndex,
                                       root.readerSelectedInkBlockId)
        root.readerSelectedInkBlockId = ""
    }

    function readerInkBlockAt(x, y) {
        var blocks = readerStore.pageInkBlocks || []
        for (var index = blocks.length - 1; index >= 0; --index) {
            var block = blocks[index] || ({})
            var padding = 18
            if (x >= Number(block.x || 0) - padding
                    && x <= Number(block.x || 0) + Number(block.width || 0) + padding
                    && y >= Number(block.y || 0) - padding
                    && y <= Number(block.y || 0) + Number(block.height || 0) + padding) {
                return block
            }
        }
        return ({})
    }

    function beginDirectHandwritingOcr(kind, itemId, strokes, pageIndex) {
        if (ocrStore.busy || root.pendingDirectOcrKind !== "") {
            if (kind === "keyboard") {
                root.keyboardHandwritingStatus = "正在识别上一组笔迹…"
            } else {
                root.showReaderOcrStatus("正在识别上一块笔迹…", false)
            }
            return
        }
        if (!ocrStore.configured) {
            if (kind === "keyboard") {
                root.keyboardHandwritingStatus = "请先到“我的”配置百度 OCR"
            } else {
                root.showReaderOcrStatus("请先到“我的”配置百度 OCR", true)
            }
            return
        }
        if (!strokes || strokes.length === 0) {
            if (kind === "keyboard") {
                root.keyboardHandwritingStatus = "请先在书写区写字"
            } else {
                root.showReaderOcrStatus("这块笔迹为空，无法识别", true)
            }
            return
        }
        root.pendingDirectOcrKind = String(kind || "")
        root.pendingDirectOcrBookId = root.currentBookId
        root.pendingDirectOcrPageIndex = Math.max(0, Math.floor(Number(pageIndex) || 0))
        root.pendingDirectOcrItemId = String(itemId || "")
        root.readerOcrBlockSelection = false
        root.readerSuppressPageTurnUntilMs = Date.now() + 700
        if (kind === "keyboard") {
            root.keyboardHandwritingStatus = "正在识别…"
            root.keyboardHandwritingCandidates = []
        } else {
            root.showReaderOcrStatus("正在识别…", false)
        }
        ocrStore.clearCandidates()
        ocrStore.recognizeStrokeBlock(strokes)
    }

    function recognizeReaderInkBlock(block) {
        if (!block || !block.blockId) {
            return
        }
        root.readerSelectedInkBlockId = String(block.blockId)
        root.beginDirectHandwritingOcr("block", String(block.blockId),
                                       block.strokes || [], root.pageIndex)
    }

    function recognizeParagraphNote(note) {
        if (!note || !note.noteId) {
            return
        }
        root.beginDirectHandwritingOcr("note", String(note.noteId),
                                       note.strokes || (note.points ? [note.points] : []),
                                       root.pageIndex)
    }

    function showReaderOcrStatus(message, autoHide) {
        root.readerInlineOcrStatus = String(message || "")
        readerInlineOcrStatusTimer.stop()
        if (autoHide && root.readerInlineOcrStatus !== "") {
            readerInlineOcrStatusTimer.start()
        }
    }

    function finishDirectHandwritingOcr(succeeded) {
        if (root.pendingDirectOcrKind === "") {
            return
        }
        var result = ""
        if (succeeded && ocrStore.candidates && ocrStore.candidates.length > 0) {
            result = ocrStore.candidates.join(" ").trim()
        }
        if (root.pendingDirectOcrKind === "keyboard") {
            if (succeeded && ocrStore.candidates && ocrStore.candidates.length > 0) {
                root.keyboardHandwritingCandidates = ocrStore.candidates.slice()
                root.keyboardCandidatePage = 0
                root.keyboardHandwritingStatus = "点上方结果即可输入"
            } else {
                root.keyboardHandwritingCandidates = []
                root.keyboardCandidatePage = 0
                root.keyboardHandwritingStatus = ocrStore.status || "没有识别到文字"
            }
        } else if (result !== "") {
            if (root.pendingDirectOcrKind === "block") {
                readerStore.setPageInkBlockOcrText(root.pendingDirectOcrBookId,
                                                   root.pendingDirectOcrPageIndex,
                                                   root.pendingDirectOcrItemId, result)
                root.readerSelectedInkBlockId = ""
            } else if (root.pendingDirectOcrKind === "note") {
                readerStore.setParagraphNoteOcrText(root.pendingDirectOcrBookId,
                                                    root.pendingDirectOcrItemId, result)
            }
            root.showReaderOcrStatus("识别完成，文字已附在笔迹旁", true)
        } else {
            root.showReaderOcrStatus(ocrStore.status || "没有识别到文字", true)
        }
        root.pendingDirectOcrKind = ""
        root.pendingDirectOcrBookId = ""
        root.pendingDirectOcrPageIndex = -1
        root.pendingDirectOcrItemId = ""
        Qt.callLater(function() { ocrStore.clearCandidates() })
    }

    Connections {
        target: ocrStore
        function onHandwritingRecognitionFinished(succeeded) {
            root.finishDirectHandwritingOcr(succeeded)
        }
    }

    Timer {
        id: readerInlineOcrStatusTimer
        interval: 2600
        repeat: false
        onTriggered: root.readerInlineOcrStatus = ""
    }

    function refreshKeyboardCandidates() {
        keyboardCandidatePage = 0
        keyboardCandidates = keyboardPinyinMode && !keyboardHandwritingMode
            ? PinyinEngine.candidates(keyboardPinyinBuffer, 50)
            : []
    }

    function keyboardActiveCandidateCount() {
        if (root.keyboardHandwritingMode) {
            return root.keyboardHandwritingCandidates.length
        }
        if (root.keyboardPinyinMode) {
            return root.keyboardCandidates.length
        }
        return 0
    }

    function keyboardCandidatePageCount() {
        return Math.max(1, Math.ceil(root.keyboardActiveCandidateCount()
                                     / root.keyboardCandidatePageSize))
    }

    function keyboardPagedPinyinCandidates() {
        var start = root.keyboardCandidatePage * root.keyboardCandidatePageSize
        return root.keyboardCandidates.slice(start, start + root.keyboardCandidatePageSize)
    }

    function keyboardPagedHandwritingCandidates() {
        var start = root.keyboardCandidatePage * root.keyboardCandidatePageSize
        return root.keyboardHandwritingCandidates.slice(start, start + root.keyboardCandidatePageSize)
    }

    function keyboardChangeCandidatePage(delta) {
        var lastPage = root.keyboardCandidatePageCount() - 1
        root.keyboardCandidatePage = root.clamp(root.keyboardCandidatePage + delta, 0, lastPage)
    }

    function setKeyboardInputMode(mode) {
        var nextMode = String(mode || "pinyin")
        if (keyboardTarget && keyboardTarget.echoMode === TextInput.Password
                && nextMode !== "english") {
            nextMode = "english"
        }
        keyboardPinyinMode = nextMode === "pinyin"
        keyboardHandwritingMode = nextMode === "handwriting"
        keyboardPinyinBuffer = ""
        refreshKeyboardCandidates()
        if (!keyboardHandwritingMode) {
            keyboardClearHandwriting()
        } else if (!ocrStore.configured) {
            keyboardHandwritingStatus = "需联网使用百度 OCR"
        } else {
            keyboardHandwritingStatus = "写完后点“识别”"
        }
    }

    function keyboardHandwritingStoredStrokes() {
        var stored = []
        for (var index = 0; index < root.keyboardHandwritingStrokes.length; ++index) {
            stored.push({
                "tool": "free",
                "colorValue": "#111111",
                "lineWidth": 5,
                "points": root.keyboardHandwritingStrokes[index]
            })
        }
        return stored
    }

    function keyboardHandwritingPoint(x, y) {
        var local = keyboardHandwritingPad.mapFromItem(root.contentItem,
                                                       Number(x) || 0,
                                                       Number(y) || 0)
        return ({
            "x": root.clamp(local.x, 3, Math.max(3, keyboardHandwritingPad.width - 3)),
            "y": root.clamp(local.y, 3, Math.max(3, keyboardHandwritingPad.height - 3))
        })
    }

    function keyboardHandwritingContains(x, y) {
        var local = keyboardHandwritingPad.mapFromItem(root.contentItem,
                                                       Number(x) || 0,
                                                       Number(y) || 0)
        return local.x >= 0 && local.x <= keyboardHandwritingPad.width
            && local.y >= 0 && local.y <= keyboardHandwritingPad.height
    }

    function beginKeyboardHandwritingStroke(x, y) {
        if (!root.showSoftKeyboard || !root.keyboardHandwritingMode
                || !root.keyboardHandwritingContains(x, y)) {
            return false
        }
        var point = root.keyboardHandwritingPoint(x, y)
        root.keyboardHandwritingDrawing = true
        root.keyboardHandwritingCurrentStroke = [point]
        root.keyboardHandwritingCandidates = []
        root.keyboardHandwritingStatus = "书写中…"
        keyboardHandwritingInk.beginStroke(point.x, point.y, "#111111", 5, 1, true)
        return true
    }

    function appendKeyboardHandwritingStroke(x, y) {
        if (!root.keyboardHandwritingDrawing || root.keyboardHandwritingCurrentStroke.length === 0) {
            return false
        }
        var point = root.keyboardHandwritingPoint(x, y)
        var points = root.keyboardHandwritingCurrentStroke
        var last = points[points.length - 1]
        if (Math.abs(last.x - point.x) + Math.abs(last.y - point.y) < 1) {
            return true
        }
        root.keyboardHandwritingCurrentStroke = points.concat([point])
        keyboardHandwritingInk.appendPoint(point.x, point.y)
        return true
    }

    function endKeyboardHandwritingStroke(x, y) {
        if (!root.keyboardHandwritingDrawing) {
            return false
        }
        root.appendKeyboardHandwritingStroke(x, y)
        if (root.keyboardHandwritingCurrentStroke.length > 0) {
            root.keyboardHandwritingStrokes = root.keyboardHandwritingStrokes.concat([
                root.keyboardHandwritingCurrentStroke.slice()
            ])
        }
        root.keyboardHandwritingCurrentStroke = []
        root.keyboardHandwritingDrawing = false
        root.keyboardHandwritingStatus = "继续写，写完后点“识别”"
        keyboardHandwritingInk.finishStroke()
        return true
    }

    function cancelKeyboardHandwritingStroke() {
        if (!root.keyboardHandwritingDrawing) {
            return
        }
        if (root.keyboardHandwritingCurrentStroke.length > 0) {
            root.keyboardHandwritingStrokes = root.keyboardHandwritingStrokes.concat([
                root.keyboardHandwritingCurrentStroke.slice()
            ])
        }
        root.keyboardHandwritingCurrentStroke = []
        root.keyboardHandwritingDrawing = false
        root.keyboardHandwritingStatus = "继续写，写完后点“识别”"
        keyboardHandwritingInk.finishStroke()
    }

    function keyboardClearHandwriting() {
        root.keyboardHandwritingStrokes = []
        root.keyboardHandwritingCurrentStroke = []
        root.keyboardHandwritingCandidates = []
        root.keyboardCandidatePage = 0
        root.keyboardHandwritingStatus = ""
        root.keyboardHandwritingDrawing = false
        if (keyboardHandwritingInk) {
            keyboardHandwritingInk.clearLive()
        }
    }

    function keyboardUndoHandwritingStroke() {
        if (root.keyboardHandwritingStrokes.length === 0) {
            root.keyboardHandwritingStatus = "没有可撤销的笔画"
            return
        }
        keyboardHandwritingInk.clearLive()
        root.keyboardHandwritingStrokes = root.keyboardHandwritingStrokes.slice(
            0, root.keyboardHandwritingStrokes.length - 1)
        root.keyboardHandwritingCandidates = []
        root.keyboardCandidatePage = 0
        root.keyboardHandwritingStatus = root.keyboardHandwritingStrokes.length > 0
            ? "已撤销上一笔"
            : "书写区已清空"
    }

    function keyboardRecognizeHandwriting() {
        root.beginDirectHandwritingOcr("keyboard", "",
                                       root.keyboardHandwritingStrokes, 0)
    }

    function keyboardChooseHandwritingCandidate(candidate) {
        var text = String(candidate || "").trim()
        if (text === "") {
            return
        }
        root.keyboardInsert(text)
        root.keyboardClearHandwriting()
        root.keyboardHandwritingStatus = "已输入，可继续书写"
    }

    function keyboardInsert(value) {
        if (!keyboardTarget || value === undefined || value === null) {
            return
        }
        var textValue = String(value)
        var cursor = Math.max(0, keyboardTarget.cursorPosition || 0)
        var before = String(keyboardTarget.text || "").slice(0, cursor)
        var after = String(keyboardTarget.text || "").slice(cursor)
        keyboardTarget.text = before + textValue + after
        keyboardTarget.cursorPosition = cursor + textValue.length
    }

    function keyboardTypeKey(value) {
        var textValue = String(value || "")
        if (keyboardPinyinMode && !keyboardHandwritingMode && /^[a-z]$/.test(textValue)) {
            keyboardPinyinBuffer += textValue
            refreshKeyboardCandidates()
            return
        }
        keyboardInsert(textValue)
    }

    function keyboardChooseCandidate(candidate) {
        if (!candidate || !candidate.text) {
            return
        }
        keyboardInsert(candidate.text)
        var consume = Math.max(0, Math.floor(Number(candidate.consume) || 0))
        keyboardPinyinBuffer = keyboardPinyinBuffer.slice(consume)
        refreshKeyboardCandidates()
    }

    function keyboardBackspace() {
        if (keyboardPinyinMode && !keyboardHandwritingMode && keyboardPinyinBuffer.length > 0) {
            keyboardPinyinBuffer = keyboardPinyinBuffer.slice(0, -1)
            refreshKeyboardCandidates()
            return
        }
        if (!keyboardTarget) {
            return
        }
        var cursor = Math.max(0, keyboardTarget.cursorPosition || 0)
        if (cursor <= 0) {
            return
        }
        var before = String(keyboardTarget.text || "").slice(0, cursor - 1)
        var after = String(keyboardTarget.text || "").slice(cursor)
        keyboardTarget.text = before + after
        keyboardTarget.cursorPosition = cursor - 1
    }

    function keyboardSubmit() {
        if (keyboardPinyinMode && !keyboardHandwritingMode && keyboardCandidates.length > 0) {
            keyboardChooseCandidate(keyboardCandidates[0])
            if (keyboardPinyinBuffer.length > 0) {
                return
            }
        }
        if (keyboardTarget === discoverSearchInput) {
            discoverStore.search(discoverSearchInput.text)
        }
        closeSoftKeyboard()
    }

    function actionButtonColor(active) {
        return active ? root.inkColor : root.warmControl
    }

    function actionTextColor(active) {
        return active ? "#ffffff" : root.inkColor
    }

    function goShelfPage(delta) {
        shelfPageIndex = clamp(shelfPageIndex + delta, 0, shelfPageCount - 1)
        forceReaderRefresh += 1
    }

    function currentShelfPageBooks() {
        var rows = []
        var start = root.shelfPageIndex * 9
        for (var i = 0; i < 9; i++) {
            var book = shelfStore.books[start + i]
            if (book && book.bookId) {
                rows.push(book)
            }
        }
        return rows
    }

    function enterReaderForBook(bookId, title) {
        if (!bookId || bookId === "") {
            return
        }
        var safeTitle = title || bookId
        readerStore.loadBook(bookId, safeTitle)
            root.currentBookId = bookId
            root.readerSessionStartedMs = Date.now()
            root.readerSocialPrefetchKey = ""
            root.closeReaderSocialPopup()
        var savedOffset = readerStore.savedTextOffset(bookId)
        root.readerOpenedWithLocalProgress = savedOffset >= 0
        if (savedOffset >= 0) {
            root.readerFastOpenAnchorOffset = savedOffset
            root.readerFastOpenMode = false
            root.buildReaderPaginationWindowFromOffset(savedOffset, 12)
            root.screenName = "reader"
        } else {
            root.buildReaderPaginationWindowFromOffset(root.readerDefaultStartOffset(), 12)
            root.screenName = "reader"
        }
        if (selfTestMode === "") {
            progressSyncStore.pullProgress(bookId)
            root.scheduleReaderSocialPrefetch()
        }
    }

    function readerTextOffsetForCatalogChapter(chapter) {
        if (!chapter) {
            return root.currentReaderTextStart
        }
        var chapters = readerStore.chapters || []
        if (chapters.length === 0) {
            return root.currentReaderTextStart
        }

        var rawTitle = String(chapter.title || "").replace(/\s+/g, " ").trim()
        var rawLabel = String(chapter.label || rawTitle).replace(/^\s*\d+[.、]\s*/, "").replace(/\s+/g, " ").trim()
        var candidates = []
        if (rawTitle.length > 0) candidates.push(rawTitle)
        if (rawLabel.length > 0 && rawLabel !== rawTitle) candidates.push(rawLabel)

        for (var i = 0; i < chapters.length; i++) {
            var localTitle = String(chapters[i].title || "").replace(/\s+/g, " ").trim()
            for (var j = 0; j < candidates.length; j++) {
                var candidate = candidates[j]
                if (candidate.length > 0 && localTitle.length > 0 &&
                    (localTitle === candidate || localTitle.indexOf(candidate) >= 0 || candidate.indexOf(localTitle) >= 0)) {
                    return Math.max(0, Math.floor(Number(chapters[i].textStart) || 0))
                }
            }
        }

        var remoteIndex = Math.max(0, Math.floor(Number(chapter.index || chapter.chapterIdx || 1)) - 1)
        var localIndex = Math.min(remoteIndex, chapters.length - 1)
        return Math.max(0, Math.floor(Number(chapters[localIndex].textStart) || 0))
    }

    function readerPageForCatalogChapter(chapter) {
        return root.readerPageForTextOffset(root.readerTextOffsetForCatalogChapter(chapter))
    }

    function enterReaderForCatalogChapter(book, chapter) {
        if (!book || !book.bookId) {
            return
        }
        root.enterReaderForBook(book.bookId, book.title)
        root.goToReaderTextOffset(root.readerTextOffsetForCatalogChapter(chapter))
    }

    function downloadCatalogChapter(book, chapter) {
        if (!book || !book.bookId) {
            return
        }
        root.pendingCatalogBookId = book.bookId
        root.pendingCatalogChapter = chapter || ({})
        downloadStore.downloadBook(book.bookId, book.title)
    }

    function openOrDownloadBook(book) {
        if (!book || !book.bookId) {
            return
        }
        if (book.downloadState === "full" || book.localEpubPath !== "") {
            root.enterReaderForBook(book.bookId, book.title)
            return
        }
        downloadStore.downloadOpeningChapter(book.bookId, book.title)
    }

    function openDownloadRecord(record) {
        if (!record || !record.bookId) {
            return
        }
        var title = record.title || record.bookId
        if (record.localEpubPath && record.localEpubPath !== "" && record.state !== "error") {
            root.enterReaderForBook(record.bookId, title)
            return
        }
        downloadStore.downloadBook(record.bookId, title)
    }

    function openDiscoverBookDetail(book) {
        if (!book || !book.bookId) {
            return
        }
        root.detailBookOverride = {
            "bookId": book.bookId,
            "title": book.title || book.bookId,
            "author": book.author || "微信读书",
            "intro": book.intro || "暂无简介",
            "categoryName": book.category || "",
            "ratingLine": book.rating ? ("评分 " + book.rating) : "微信读书",
            "coverSource": book.cover || "",
            "colorA": root.brandGreenDark,
            "colorB": root.goldAccent,
            "progressRatio": 0,
            "progressLabel": "未开始",
            "progress": "未开始",
            "downloadState": "",
            "localEpubPath": "",
            "downloadActionText": "下载整本",
            "reviewSnippets": book.intro ? [book.intro] : ["暂无公开书评缓存，下载后可阅读。"]
        }
        shelfStore.refreshBookDetails(book.bookId)
        bookCatalogStore.loadCatalog(book.bookId, book.title || book.bookId)
        root.showDetailCatalog = false
        root.screenName = "detail"
    }

    function openNotebookBookDetail(book) {
        if (!book || !book.bookId) {
            return
        }
        root.openDiscoverBookDetail({
            "bookId": book.bookId,
            "title": book.title || book.bookId,
            "author": book.author || "微信读书",
            "cover": book.cover || "",
            "intro": "微信笔记 " + (book.totalNotes || 0) + " 条",
            "category": ""
        })
    }

    function currentDetailBook() {
        var base = root.detailBookOverride && root.detailBookOverride.bookId ? root.detailBookOverride : (shelfStore.books[root.selectedIndex] || ({}))
        var detached = shelfStore.detachedDetailBook || ({})
        if (!base.bookId || detached.bookId !== base.bookId) {
            return base
        }

        var merged = {}
        for (var key in base) {
            merged[key] = base[key]
        }
        for (var detachedKey in detached) {
            var value = detached[detachedKey]
            if (value !== undefined && value !== null && value !== "") {
                merged[detachedKey] = value
            }
        }
        if (!merged.coverSource && base.coverSource) {
            merged.coverSource = base.coverSource
        }
        return merged
    }

    function setReaderPage(value) {
        root.flushPendingFreeInkStrokes()
        root.closeReaderSocialPopup()
        root.readerOcrBlockSelection = false
        root.readerSelectedInkBlockId = ""
        readerInkCanvas.clearLive()
        var count = root.readerPageCountFor(readerStore.bodyText, root.readerTextTopY())
        if (Number(value) < 0 && root.currentReaderTextStart > 0) {
            root.rebuildReaderPaginationWindowBackward()
            count = root.readerCachedPageCount
            value = root.pageIndex
        }
        if (Number(value) >= count) {
            root.extendReaderPaginationWindow(8)
            count = root.readerCachedPageCount
        }
        root.pageIndex = root.clamp(value, 0, count - 1)
        root.refreshReaderPageCache()
        root.ensureReaderPaginationWindowAhead()
        count = root.readerCachedPageCount
        if (root.currentBookId !== "") {
            readerStore.saveProgress(root.currentBookId, root.pageIndex, count, root.currentReaderTextStart)
            readerStore.loadStrokesForPage(root.currentBookId, root.pageIndex)
            root.scheduleReaderSocialPrefetch()
            if (root.pageIndex >= count - 1) {
                root.requestReaderContinuationDownload()
            }
        }
    }

    function handleReaderPageTurnGesture(side, startX, startY, endX, endY) {
        if (Date.now() < root.readerSuppressPageTurnUntilMs) {
            return
        }
        if (root.showReaderSettings || root.showReaderCatalog || root.showReaderSocialPopup) {
            return
        }
        var dx = endX - startX
        var dy = endY - startY
        if (Math.abs(dy) > 108) {
            return
        }
        if (side === "left") {
            if (dx > 42 || Math.abs(dx) < 12) {
                root.setReaderPage(root.pageIndex - 1)
            }
        } else if (dx < -42 || Math.abs(dx) < 12) {
            root.setReaderPage(root.pageIndex + 1)
        }
    }

    function readerPointInRect(x, y, rx, ry, rw, rh) {
        return x >= rx && x <= rx + rw && y >= ry && y <= ry + rh
    }

    function applyReaderSettingChange(needsPagination) {
        if (needsPagination) {
            root.scheduleReaderPaginationRebuild()
        }
        root.forceReaderRefresh += 1
    }

    function handleReaderSettingsStylusTap(x, y) {
        if (!root.showReaderSettings) {
            return false
        }
        var lx = Math.round(Number(x) || 0) - readerSettingsPanel.x
        var ly = Math.round(Number(y) || 0) - readerSettingsPanel.y
        if (lx < 0 || ly < 0 || lx > readerSettingsPanel.width || ly > readerSettingsPanel.height) {
            return false
        }
        if (root.readerPointInRect(lx, ly, readerSettingsPanel.width - 68, 24, 60, 60)) {
            root.closeReaderSettings()
            return true
        }

        var fontStepperX = Math.round((readerSettingsPanel.width - 246) / 2)
        if (root.readerPointInRect(lx, ly, fontStepperX, 118, 90, 70)) {
            root.readerFontSize = root.clamp(root.readerFontSize - 4, 30, 38)
            root.applyReaderSettingChange(true)
            return true
        }
        if (root.readerPointInRect(lx, ly, fontStepperX + 156, 118, 90, 70)) {
            root.readerFontSize = root.clamp(root.readerFontSize + 4, 30, 38)
            root.applyReaderSettingChange(true)
            return true
        }

        for (var lh = 0; lh < root.readerLineHeightSteps.length; lh++) {
            var lineX = 122 + lh * (132 + 12)
            if (root.readerPointInRect(lx, ly, lineX, 246, 132, 58)) {
                root.readerLineHeight = root.readerLineHeightSteps[lh].value
                root.applyReaderSettingChange(true)
                return true
            }
        }
        for (var ps = 0; ps < root.readerParagraphSpacingSteps.length; ps++) {
            var paragraphX = 122 + ps * (132 + 12)
            if (root.readerPointInRect(lx, ly, paragraphX, 354, 132, 58)) {
                root.readerParagraphSpacing = root.readerParagraphSpacingSteps[ps].value
                root.applyReaderSettingChange(true)
                return true
            }
        }

        var marginValues = [48, 72, 104, 136]
        for (var m = 0; m < marginValues.length; m++) {
            var marginX = 132 + m * (78 + 20)
            if (root.readerPointInRect(lx, ly, marginX, 416, 86, 64)) {
                root.readerMargin = marginValues[m]
                root.applyReaderSettingChange(true)
                return true
            }
        }

        var indentValues = [0, 1, 2, 3]
        for (var ind = 0; ind < indentValues.length; ind++) {
            var indentX = 132 + ind * (86 + 14)
            if (root.readerPointInRect(lx, ly, indentX, 480, 94, 58)) {
                root.readerFirstLineIndentChars = indentValues[ind]
                root.applyReaderSettingChange(true)
                return true
            }
        }

        var fontChoices = ["系统", "微米黑", "正黑", "霞鹜文楷"]
        for (var f = 0; f < fontChoices.length; f++) {
            var fontX = 132 + f * (132 + 12)
            if (root.readerPointInRect(lx, ly, fontX, 552, 140, 56)) {
                root.readerFontChoice = fontChoices[f]
                root.applyReaderSettingChange(true)
                return true
            }
        }

        var weightValues = [Font.DemiBold, Font.Bold]
        for (var w = 0; w < weightValues.length; w++) {
            var weightX = 772 + w * (52 + 8)
            if (root.readerPointInRect(lx, ly, weightX, 552, 60, 56)) {
                root.readerFontWeight = weightValues[w]
                root.applyReaderSettingChange(true)
                return true
            }
        }

        for (var b = 0; b < root.frontlightLevels.length; b++) {
            var lightX = 102 + b * (88 + 10)
            if (root.readerPointInRect(lx, ly, lightX, 614, 88, 62)) {
                root.applyFrontlightPercent(root.frontlightLevels[b])
                root.forceReaderRefresh += 1
                return true
            }
        }

        if (readerSettingsPanel.height > 720
                && root.readerPointInRect(lx, ly, 150, 690, readerSettingsPanel.width - 270, 50)) {
            root.setReaderProgressPercent((lx - 150) / Math.max(1, readerSettingsPanel.width - 270) * 100)
            return true
        }
        if (readerSettingsPanel.height > 780
                && root.readerPointInRect(lx, ly, readerSettingsPanel.width - 164, 746, 136, 58)) {
            networkStore.reload()
            return true
        }
        if (readerSettingsPanel.height > 812
                && root.readerPointInRect(lx, ly, 24, 790, 128, 58)) {
            root.exitReaderToShelf()
            return true
        }
        if (readerSettingsPanel.height > 812
                && root.readerPointInRect(lx, ly, 164, 790, 128, 58)) {
            root.forceReaderRefresh += 1
            return true
        }
        if (readerSettingsPanel.height > 812
                && root.readerPointInRect(lx, ly, 304, 790, 128, 58)
                && !progressSyncStore.running) {
            progressSyncStore.syncProgress(root.currentBookId, root.currentReaderProgressPercent(), root.currentReaderSummaryText(), root.currentReaderElapsedSeconds())
            return true
        }
        if (readerSettingsPanel.height > 812
                && root.readerPointInRect(lx, ly, 444, 790, 128, 58)
                && !progressSyncStore.running) {
            progressSyncStore.pullProgress(root.currentBookId)
            return true
        }
        return true
    }

    function handleStylusTap(x, y) {
        root.readerSuppressPageTurnUntilMs = Date.now() + 600
        if (root.readerStylusCollapsePending) {
            readerStylusCollapseTimer.restart()
            return
        }
        if (root.screenName === "reader" && !root.showReaderSettings && !root.showReaderCatalog
                && !root.showReaderSocialPopup && root.openReaderSocialPopupAtPoint(x, y)) {
            return
        }
        if (root.screenName === "reader" && !root.showReaderSettings && !root.showReaderCatalog && root.openReaderFootnoteAtPoint(x, y)) {
            return
        }
        if (root.screenName === "reader" && root.handleReaderSettingsStylusTap(x, y)) {
            return
        }
    }

    function setReaderProgressPercent(percent) {
        var text = String(readerStore.bodyText || "")
        var targetOffset = Math.round(root.clamp(percent, 0, 100) / 100 * Math.max(0, text.length - 1))
        root.goToReaderTextOffset(targetOffset)
    }

    function syncCurrentReaderProgress() {
        if (root.currentBookId === "" || progressSyncStore.running || readerStore.bodyText === "") {
            return
        }
        progressSyncStore.syncProgress(root.currentBookId, root.currentReaderProgressPercent(), root.currentReaderSummaryText(), root.currentReaderElapsedSeconds())
    }

    function openQrLogin() {
        root.accountAutoPromptHandled = true
        root.showQrLogin = true
        if (!accountStore.loginRunning && !accountStore.running && !accountStore.renewingCookie) {
            accountStore.startQrLogin()
        }
    }

    function closeQrLogin() {
        if (accountStore.loginRunning) {
            accountStore.cancelQrLogin()
        }
        root.showQrLogin = false
    }

    function currentSleepBook() {
        var books = shelfStore.books || []
        if (root.currentBookId !== "") {
            for (var i = 0; i < books.length; i++) {
                if (String(books[i].bookId || "") === String(root.currentBookId)) {
                    return books[i]
                }
            }
        }
        if (root.screenName === "detail") {
            return root.currentDetailBook()
        }
        return books[root.selectedIndex] || root.currentDetailBook() || ({})
    }

    function prepareDeviceSleep(reason) {
        if (root.sleepOverlayVisible) {
            return
        }
        if (root.currentBookId !== "" && readerStore.bodyText !== "") {
            var count = root.readerPageCountFor(readerStore.bodyText, root.readerTextTopY())
            readerStore.saveProgress(root.currentBookId, root.pageIndex, count, root.currentReaderTextStart)
            root.syncCurrentReaderProgress()
        }
        root.closeReaderSettings()
        root.closeReaderCatalog()
        root.closeReaderFootnote()
        root.closeReaderSocialPopup()
        root.closeSoftKeyboard()
        var book = root.currentSleepBook()
        root.sleepCoverSource = String(book.coverSource || book.localCover || "")
        root.sleepBookTitle = String(book.title || readerStore.title || "微信读书")
        root.sleepRequestReason = String(reason || "")
        root.sleepOverlayVisible = true
        root.forceReaderRefresh += 1
        networkStore.prepareForSleep()
        sleepCommitTimer.restart()
    }

    function resumeFromDeviceSleep(reason) {
        sleepCommitTimer.stop()
        root.sleepOverlayVisible = false
        root.sleepRequestReason = String(reason || "")
        root.forceReaderRefresh += 1
        networkStore.resumeAfterSleep()
        if (root.screenName === "reader") {
            root.refreshReaderPageCache()
        }
    }

    function exitReaderToShelf() {
        root.syncCurrentReaderProgress()
        root.closeReaderCatalog()
        root.closeReaderSettings()
        root.closeReaderFootnote()
        root.closeReaderSocialPopup()
        shelfStore.reload()
        root.screenName = "shelf"
    }

    Connections {
        target: downloadStore
        function onEpubReady(bookId, title) {
            shelfStore.reload()
            if (root.pendingCatalogBookId === bookId) {
                root.enterReaderForCatalogChapter({ "bookId": bookId, "title": title }, root.pendingCatalogChapter)
                root.pendingCatalogBookId = ""
                root.pendingCatalogChapter = ({})
                return
            }
            if (root.readerPendingContinueDownload && root.readerPendingContinueBookId === bookId) {
                root.continueReaderAfterFullDownload(bookId, title)
                return
            }
            root.enterReaderForBook(bookId, title)
        }
        function onOpeningChapterReady(bookId, title) {
            shelfStore.reload()
            root.enterReaderForBook(bookId, title)
        }
    }

    Connections {
        target: progressSyncStore
        function onProgressPulled(bookId, progress) {
            if (bookId !== root.currentBookId) {
                return
            }
            root.readerLastPulledRemoteProgress = Math.round(root.clamp(progress, 0, 100))
            if (root.readerOpenedWithLocalProgress) {
                console.log("reader-progress-remote-skipped localOffset=" + root.currentReaderTextStart +
                            " remote=" + root.readerLastPulledRemoteProgress)
                return
            }
            if (readerStore.openingCache) {
                return
            }
            var text = String(readerStore.bodyText || "")
            var targetOffset = Math.round(root.clamp(progress, 0, 100) / 100 * Math.max(0, text.length - 1))
            root.goToReaderTextOffset(targetOffset)
        }
    }

    Connections {
        target: readerStore
        function onContentChanged() {
            root.markReaderPaginationDirty()
        }
    }

    Connections {
        target: accountStore
        function onChanged() {
            if (!root.accountInitialCheckComplete && !accountStore.running
                    && !accountStore.renewingCookie && !accountStore.loginRunning
                    && accountStore.statusText !== "账号状态未检查") {
                root.accountInitialCheckComplete = true
                if (!accountStore.cookieConfigured && !root.accountAutoPromptHandled && selfTestMode === "") {
                    root.openQrLogin()
                }
            }
        }
        function onLoginSucceeded() {
            root.showQrLogin = false
            root.shelfTab = "书架"
            shelfStore.refreshShelf()
            accountStore.refresh()
        }
        function onLoggedOut() {
            root.accountAutoPromptHandled = true
            root.showQrLogin = true
            accountStore.startQrLogin()
        }
    }

    Connections {
        target: powerStore
        function onPrepareSleep(reason) {
            root.prepareDeviceSleep(reason)
        }
        function onResumed(reason) {
            root.resumeFromDeviceSleep(reason)
        }
    }

    Binding {
        target: stylusStore
        property: "active"
        value: !root.sleepOverlayVisible
            && (root.screenName === "reader"
                || root.showSoftKeyboard)
    }

    Timer {
        id: sleepCommitTimer
        interval: 750
        repeat: false
        onTriggered: powerStore.commitSleep()
    }

    Connections {
        target: stylusStore
        function onStylusPressed(x, y, pressure) {
            if (!root.beginKeyboardHandwritingStroke(x, y)) {
                root.beginStylusStroke(x, y, pressure)
            }
        }
        function onStylusMoved(x, y, pressure) {
            if (!root.appendKeyboardHandwritingStroke(x, y)) {
                root.appendStylusStroke(x, y, pressure)
            }
        }
        function onStylusReleased(x, y, pressure) {
            if (!root.endKeyboardHandwritingStroke(x, y)) {
                root.endStylusStroke(x, y, pressure)
            }
        }
        function onStylusTapped(x, y) {
            if (!root.showSoftKeyboard || !root.keyboardHandwritingMode) {
                root.handleStylusTap(x, y)
            }
        }
    }

    Timer {
        id: readerStylusCollapseTimer
        interval: 120
        repeat: false
        onTriggered: {
            root.readerStylusToolsExpanded = false
            root.readerStylusCollapsePending = false
        }
    }

    Timer {
        id: readerClearConfirmTimer
        interval: 2600
        repeat: false
        onTriggered: {
            root.readerClearArmed = false
        }
    }

    Timer {
        id: readerStylusToolbarSelfTestTimer
        property int expectedOffset: -1
        interval: 360
        repeat: false
        onTriggered: {
            var passed = !root.readerStylusToolsExpanded
                && !root.readerStylusCollapsePending
                && root.readerMarkerColor === root.readerStylusTools[1].value
                && root.currentReaderTextStart === expectedOffset
            if (passed) {
                console.log("reader-stylus-toolbar-selftest=ok offset=" + expectedOffset)
            } else {
                console.log("reader-stylus-toolbar-selftest=fail offset=" + root.currentReaderTextStart +
                            " expected=" + expectedOffset +
                            " expanded=" + root.readerStylusToolsExpanded)
            }
            appControl.quitToSystem()
        }
    }

    Connections {
        target: shelfStore
        function onBooksChanged() {
            root.shelfPageIndex = root.clamp(root.shelfPageIndex, 0, root.shelfPageCount - 1)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.color
    }

    Item {
        id: shelfPage
        anchors.fill: parent
        visible: root.screenName === "shelf"

        Rectangle {
            x: 0
            y: 0
            width: root.width
            height: root.height
            color: root.paperColor
        }

        Text {
            id: shelfTitle
            x: 44
            y: 54
            width: 350
            text: "书架"
            color: root.inkColor
            font.pixelSize: 44
            font.bold: true
        }

        Text {
            x: 46
            y: 112
            width: root.width - 260
            text: shelfStore.shelfProgress !== "" ? shelfStore.shelfProgress : "微信读书 · 已同步 " + shelfStore.books.length + " 本"
            color: root.mutedInk
            font.pixelSize: 23
            font.bold: true
        }

        Rectangle {
            x: root.width - 242
            y: 56
            width: 104
            height: 46
            radius: 4
            color: shelfStore.refreshingShelf ? root.inkColor : root.surfaceColor
            border.color: root.inkColor
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: shelfStore.refreshingShelf ? "同步中" : "同步"
                color: shelfStore.refreshingShelf ? "#ffffff" : root.inkColor
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
            x: root.width - 370
            y: 56
            width: 116
            height: 46
            radius: 4
            color: downloadStore.running ? root.goldAccent : root.surfaceColor
            border.color: root.inkColor
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "下载本页"
                color: root.inkColor
                font.pixelSize: 19
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: downloadStore.downloadBooks(root.currentShelfPageBooks())
            }
        }

        Rectangle {
            x: root.width - 522
            y: 56
            width: 140
            height: 46
            radius: 4
            visible: shelfStore.recentBook.bookId !== undefined && shelfStore.recentBook.bookId !== ""
            color: root.brandGreenDark
            border.color: root.inkColor
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
                onClicked: root.openOrDownloadBook(shelfStore.recentBook)
            }
        }

        Rectangle {
            id: shelfExitSystemButton
            x: root.width - 126
            y: 56
            width: 82
            height: 46
            radius: 4
            color: root.surfaceColor
            border.color: root.inkColor
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "退出"
                color: root.inkColor
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
            width: root.width - 88
            height: root.height - 232
            visible: root.shelfTab === "书架" && shelfStore.books.length > 0
            property real cellWidth: width / root.shelfColumns
            property real cellHeight: height / 3
            property real coverWidth: Math.min(cellWidth - 24, (cellHeight - 76) * root.coverAspectRatio)

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
                    if (dx < 0 && root.shelfPageIndex < root.shelfPageCount - 1) {
                        root.goShelfPage(1)
                    } else if (dx > 0 && root.shelfPageIndex > 0) {
                        root.goShelfPage(-1)
                    }
                }
            }

            Repeater {
                model: 9

                delegate: Item {
                property int bookIndex: root.shelfPageIndex * 9 + index
                property var book: shelfStore.books[bookIndex] || ({})
                visible: book.bookId !== undefined && book.bookId !== ""
                width: shelfGrid.cellWidth
                height: shelfGrid.cellHeight
                x: (index % root.shelfColumns) * shelfGrid.cellWidth
                y: Math.floor(index / root.shelfColumns) * shelfGrid.cellHeight

                Rectangle {
                    id: cover
                    width: shelfGrid.coverWidth
                    height: width / root.coverAspectRatio
                    x: (parent.width - width) / 2
                    y: 4
                    radius: 3
                    color: parent.book.colorA
                    border.color: root.inkColor
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
                            root.detailBookOverride = ({})
                            root.selectedIndex = bookIndex
                            root.screenName = "detail"
                            shelfStore.refreshBookDetails(book.bookId)
                        }
                    }
                }

                Text {
                    x: 14
                    y: cover.y + cover.height + 14
                    width: parent.width - 28
                    text: parent.book.title
                    color: root.inkColor
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
                    color: root.mutedInk
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
            width: root.width - 88
            height: root.height - 360
            visible: root.shelfTab === "书架" && shelfStore.books.length === 0

            Text {
                x: 0
                y: 24
                width: parent.width
                text: shelfStore.refreshingShelf ? "正在同步微信读书书架" : "还没有书架缓存"
                color: root.inkColor
                font.pixelSize: 32
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                x: 0
                y: 86
                width: parent.width
                text: shelfStore.shelfProgress !== "" ? shelfStore.shelfProgress : "连接 Wi-Fi 后同步你的微信读书书架。"
                color: root.inkColor
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
                color: shelfStore.refreshingShelf ? root.goldAccent : root.brandGreenDark
                border.color: root.inkColor
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: shelfStore.refreshingShelf ? "同步中" : "同步书架"
                    color: shelfStore.refreshingShelf ? root.inkColor : "#ffffff"
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
            height: root.height - 250
            color: "transparent"
            visible: root.shelfTab === "书架" && root.shelfPageIndex > 0
            MouseArea {
                anchors.fill: parent
                onClicked: root.goShelfPage(-1)
            }
        }

        Rectangle {
            x: root.width - 44
            y: 154
            width: 44
            height: root.height - 250
            color: "transparent"
            visible: root.shelfTab === "书架" && root.shelfPageIndex < root.shelfPageCount - 1
            MouseArea {
                anchors.fill: parent
                onClicked: root.goShelfPage(1)
            }
        }

        Text {
            x: root.width - 258
            y: 116
            width: 96
            text: (root.shelfPageIndex + 1) + " / " + root.shelfPageCount
            color: root.inkColor
            font.pixelSize: 20
            font.bold: true
            horizontalAlignment: Text.AlignRight
            visible: root.shelfTab === "书架" && root.shelfPageCount > 1
        }

        Item {
            id: discoverTabPage
            x: 44
            y: 154
            width: root.width - 88
            height: root.height - 250
            visible: root.shelfTab === "发现"

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
                        color: root.inkColor
                        font.pixelSize: 34
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        text: discoverStore.statusText + " · " + (shelfStore.shelfProgress !== "" ? shelfStore.shelfProgress : "书架 " + shelfStore.books.length + " 本")
                        color: root.inkColor
                        font.pixelSize: 21
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        height: 38
                        text: "搜索书城"
                        color: root.inkColor
                        font.pixelSize: 28
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: parent.width
                        height: 62
                        radius: 4
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        TextInput {
                            id: discoverSearchInput
                            x: 16
                            y: 0
                            width: parent.width - 146
                            height: parent.height
                            color: root.inkColor
                            font.pixelSize: 22
                            font.bold: true
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            selectByMouse: true
                            onActiveFocusChanged: if (activeFocus) root.openSoftKeyboard(discoverSearchInput)
                            onAccepted: discoverStore.search(text)
                        }

                        MouseArea {
                            x: 0
                            y: 0
                            width: parent.width - 130
                            height: parent.height
                            onClicked: root.openSoftKeyboard(discoverSearchInput)
                        }

                        Text {
                            x: 16
                            y: 0
                            width: parent.width - 146
                            height: parent.height
                            text: "输入书名"
                            color: root.inkColor
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
                            color: discoverStore.running ? root.goldAccent : root.brandGreenDark
                            border.color: root.inkColor
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "搜索"
                                color: discoverStore.running ? root.inkColor : "#ffffff"
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
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "手写识别后搜索"
                            color: root.inkColor
                            font.pixelSize: 20
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.openSoftKeyboard(discoverSearchInput)
                                root.setKeyboardInputMode("handwriting")
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 10

                        Text {
                            width: parent.width
                            text: "暂无搜索结果"
                            color: root.inkColor
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
                                color: root.surfaceColor
                                border.color: root.inkColor
                                border.width: 1

                                Text {
                                    x: 16
                                    y: 9
                                    width: parent.width - 142
                                    text: modelData.title || modelData.bookId
                                    color: root.inkColor
                                    font.pixelSize: 21
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

	                                Text {
	                                    x: 16
	                                    y: 43
	                                    width: parent.width - 142
	                                    text: modelData.author || modelData.category || "微信读书"
	                                    color: root.inkColor
	                                    font.pixelSize: 18
	                                    font.bold: true
	                                    elide: Text.ElideRight
	                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.openDiscoverBookDetail(modelData)
                                }

	                                Rectangle {
	                                    x: parent.width - 112
	                                    y: 18
                                    width: 96
                                    height: 50
                                    radius: 4
                                    color: root.brandGreenDark
                                    border.color: root.inkColor
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
                        color: root.inkColor
                        font.pixelSize: 28
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: parent.width
                        height: 62
                        radius: 4
                        color: discoverStore.running ? root.goldAccent : root.brandGreenDark
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: discoverStore.running ? "加载中" : "刷新推荐"
                            color: discoverStore.running ? root.inkColor : "#ffffff"
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
                            color: root.inkColor
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
                                color: root.surfaceColor
                                border.color: root.inkColor
                                border.width: 1

                                Text {
                                    x: 16
                                    y: 9
                                    width: parent.width - 142
                                    text: modelData.title || modelData.bookId
                                    color: root.inkColor
                                    font.pixelSize: 21
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    x: 16
                                    y: 40
                                    width: parent.width - 142
                                    text: modelData.author || modelData.category || "推荐"
                                    color: root.inkColor
                                    font.pixelSize: 18
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

	                                Text {
	                                    x: 16
	                                    y: 66
	                                    width: parent.width - 142
	                                    text: modelData.reason || modelData.intro || ""
	                                    color: root.inkColor
	                                    font.pixelSize: 16
	                                    font.bold: true
	                                    elide: Text.ElideRight
	                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.openDiscoverBookDetail(modelData)
                                }

	                                Rectangle {
	                                    x: parent.width - 112
                                    y: 22
                                    width: 96
                                    height: 50
                                    radius: 4
                                    color: root.brandGreenDark
                                    border.color: root.inkColor
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
                        color: shelfStore.refreshingShelf ? root.goldAccent : root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: shelfStore.refreshingShelf ? "同步中" : "同步书架 · 已缓存封面 " + shelfStore.cachedCoverCount + " / " + shelfStore.books.length + " 本"
                            color: root.inkColor
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
                        color: root.inkColor
                        font.pixelSize: 28
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: parent.width
                        height: 58
                        radius: 4
                        visible: downloadStore.queuedCount > 0 && !downloadStore.running
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "恢复队列"
                            color: root.inkColor
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
                            color: root.inkColor
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
                                color: root.surfaceColor
                                border.color: root.inkColor
                                border.width: 1

                                Text {
                                    x: 18
                                    y: 9
                                    width: parent.width - 150
                                    text: modelData.title || modelData.bookId
                                    color: root.inkColor
                                    font.pixelSize: 21
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

	                                Text {
	                                    x: 18
	                                    y: 42
	                                    width: parent.width - 150
	                                    text: modelData.progressText || modelData.state
	                                    color: root.inkColor
	                                    font.pixelSize: 18
	                                    font.bold: true
	                                    elide: Text.ElideRight
	                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.openDownloadRecord(modelData)
                                }

                                Rectangle {
                                    x: parent.width - 116
                                    y: 14
                                    width: 98
                                    height: 50
                                    radius: 4
                                    color: root.surfaceColor
                                    border.color: root.inkColor
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "删除下载"
                                        color: root.inkColor
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
            width: root.width - 88
            height: root.height - 250
            visible: root.shelfTab === "我的"

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
                        color: root.inkColor
                        font.pixelSize: 34
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        text: networkStore.summary
                        color: root.inkColor
                        font.pixelSize: 24
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: "前光 " + frontlightStore.brightness + " / " + frontlightStore.maxBrightness
                        color: root.inkColor
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 64
                        radius: 4
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "刷新状态"
                            color: root.inkColor
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
                        color: accountStore.cookieConfigured ? root.surfaceColor : root.brandGreenDark
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.fill: parent
                            text: accountStore.cookieConfigured ? "切换微信读书账号" : "登录微信读书"
                            color: accountStore.cookieConfigured ? root.inkColor : "#ffffff"
                            font.pixelSize: 23
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.openQrLogin()
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: accountStore.cookieConfigured ? 64 : 0
                        visible: accountStore.cookieConfigured
                        radius: 4
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.fill: parent
                            text: "退出当前账号"
                            color: root.inkColor
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
                        text: "百度 OCR（云端）"
                        color: root.inkColor
                        font.pixelSize: 28
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        text: ocrStore.status
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 64
                        radius: 4
                        color: ocrSetupServer.running ? root.surfaceColor : root.brandGreenDark
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.fill: parent
                            text: ocrSetupServer.running ? "浏览器配置服务已开启" : "开启浏览器配置"
                            color: ocrSetupServer.running ? root.inkColor : "#ffffff"
                            font.pixelSize: 23
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !ocrSetupServer.running && !ocrStore.busy
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
                            color: root.inkColor
                            font.pixelSize: 19
                            font.bold: true
                            wrapMode: Text.WrapAnywhere
                        }

                        Text {
                            width: parent.width
                            text: "配对码：" + ocrSetupServer.pairingCode
                            color: root.inkColor
                            font.pixelSize: 28
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: "本次配置将在 " + ocrSetupServer.secondsRemaining + " 秒后自动关闭"
                            color: root.inkColor
                            font.pixelSize: 19
                        }

                        Text {
                            width: parent.width
                            text: ocrSetupServer.status
                            color: root.inkColor
                            font.pixelSize: 19
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            width: parent.width
                            height: 56
                            radius: 4
                            color: root.surfaceColor
                            border.color: root.inkColor
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "关闭浏览器配置"
                                color: root.inkColor
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
                        text: "只在你点开启后临时运行。浏览器首次会提示临时安全证书；API Key 不会显示在设备或日志中。"
                        color: root.inkColor
                        font.pixelSize: 18
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        height: 44
                        text: "Wi-Fi 管理"
                        color: root.inkColor
                        font.pixelSize: 28
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        text: networkStore.actionStatus
                        color: root.inkColor
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
                            color: root.surfaceColor
                            border.color: root.inkColor
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "扫描 Wi-Fi"
                                color: root.inkColor
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
                            color: root.surfaceColor
                            border.color: root.inkColor
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "刷新网络"
                                color: root.inkColor
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
                            color: root.surfaceColor
                            border.color: root.inkColor
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "断开 Wi-Fi"
                                color: root.inkColor
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
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        TextInput {
                            id: wifiPasswordInput
                            x: 16
                            y: 0
                            width: parent.width - 32
                            height: parent.height
                            color: root.inkColor
                            font.pixelSize: 21
                            font.bold: true
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            clip: true
                            selectByMouse: true
                            onActiveFocusChanged: if (activeFocus) root.openSoftKeyboard(wifiPasswordInput)
                        }

                        Text {
                            x: 16
                            y: 0
                            width: parent.width - 32
                            height: parent.height
                            text: "输入 Wi-Fi 密码"
                            color: root.inkColor
                            font.pixelSize: 21
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            visible: wifiPasswordInput.text.length === 0 && !wifiPasswordInput.activeFocus
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.openSoftKeyboard(wifiPasswordInput)
                        }
                    }

                    Text {
                        width: parent.width
                        height: 38
                        text: "已保存网络"
                        color: root.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        height: 42
                        text: "暂无已保存网络"
                        color: root.inkColor
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
                            color: root.surfaceColor

                            Text {
                                x: 0
                                y: 0
                                width: parent.width - 236
                                height: parent.height
                                text: (modelData.current ? "当前 · " : "") + (modelData.ssid || "未命名网络")
                                color: root.inkColor
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
                                color: root.surfaceColor
                                border.color: root.inkColor
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "连接"
                                    color: root.inkColor
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
                                color: root.surfaceColor
                                border.color: root.inkColor
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "忘记"
                                    color: root.inkColor
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
                                color: root.inkColor
                                opacity: 0.28
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        height: 38
                        text: "附近网络"
                        color: root.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        height: 42
                        text: "点“扫描 Wi-Fi”查找附近网络"
                        color: root.inkColor
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
                            color: root.surfaceColor

                            Text {
                                x: 0
                                y: 0
                                width: parent.width - 142
                                height: parent.height
                                text: (modelData.current ? "当前 · " : "") + (modelData.ssid || "未命名网络") + (modelData.secure ? " · 加密" : " · 开放")
                                color: root.inkColor
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
                                color: root.surfaceColor
                                border.color: root.inkColor
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "连接"
                                    color: root.inkColor
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
                                color: root.inkColor
                                opacity: 0.28
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        height: 44
                        text: "账号状态"
                        color: root.inkColor
                        font.pixelSize: 28
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        text: accountStore.statusText
                        color: root.inkColor
                        font.pixelSize: 22
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: accountStore.apiConfigured ? "API Key 已配置" : "API Key 未配置"
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: accountStore.cookieConfigured ? "登录 Cookie 已配置" : "登录 Cookie 未配置"
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: accountStore.configPath
                        color: root.inkColor
                        font.pixelSize: 17
                        font.bold: true
                        wrapMode: Text.WordWrap
                        visible: accountStore.configPath !== ""
                    }

                    Rectangle {
                        width: parent.width
                        height: 62
                        radius: 4
                        color: accountStore.running ? root.goldAccent : root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: accountStore.running ? "检查中" : "检查账号"
                            color: root.inkColor
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
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 62
                        radius: 4
                        color: accountStore.renewingCookie ? root.goldAccent : root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.fill: parent
                            text: accountStore.renewingCookie ? "续期中" : "续期 Cookie"
                            color: root.inkColor
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
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: accountStore.loginConfirmUrl === "" ? 0 : loginQrImage.height + loginConfirmText.implicitHeight + 48
                        visible: accountStore.loginConfirmUrl !== ""
                        radius: 4
                        color: root.paperColor
                        border.color: root.inkColor
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
                            color: root.inkColor
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
                        color: accountStore.loginRunning ? root.goldAccent : root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.fill: parent
                            text: accountStore.loginRunning ? "取消登录" : "扫码登录"
                            color: root.inkColor
                            font.pixelSize: 22
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !accountStore.running && !accountStore.renewingCookie
                            onClicked: accountStore.loginRunning ? root.closeQrLogin() : root.openQrLogin()
                        }
                    }

                    Text {
                        width: parent.width
                        text: downloadStore.cacheStatusText
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 62
                        radius: 4
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "清理阅读缓存"
                            color: root.inkColor
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
                        color: root.inkColor
                        font.pixelSize: 28
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width
                        text: notesStore.statusText
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 62
                        radius: 4
                        color: notesStore.running ? root.goldAccent : root.brandGreenDark
                        border.color: root.inkColor
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: notesStore.running ? "同步中" : "同步笔记"
                            color: notesStore.running ? root.inkColor : "#ffffff"
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
                        color: root.inkColor
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
                            color: root.surfaceColor
                            border.color: root.inkColor
                            border.width: 1

                            Text {
                                x: 16
                                y: 8
                                width: parent.width - 32
                                text: modelData.title || modelData.bookId
                                color: root.inkColor
                                font.pixelSize: 21
                                font.bold: true
                                elide: Text.ElideRight
                            }

	                            Text {
	                                x: 16
	                                y: 42
	                                width: parent.width - 32
	                                text: (modelData.author || "微信读书") + " · " + (modelData.totalNotes || 0) + " 条"
	                                color: root.inkColor
	                                font.pixelSize: 18
	                                font.bold: true
	                                elide: Text.ElideRight
	                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.openNotebookBookDetail(modelData)
                            }
	                        }
                    }
                }
            }
        }

        Rectangle {
            x: 0
            y: root.height - 88
            width: root.width
            height: 88
            color: root.surfaceColor
            border.color: root.inkColor
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 96
                Repeater {
                    model: ["书架", "发现", "我的"]
                    Text {
                        width: 116
                        text: modelData
                        color: root.shelfTab === modelData ? root.brandGreenDark : root.inkColor
                        font.pixelSize: 24
                        font.bold: root.shelfTab === modelData
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.shelfTab = modelData
                        }
                    }
                }
            }
        }
    }

    Item {
        id: detailPage
        anchors.fill: parent
        visible: root.screenName === "detail"

        property var book: root.currentDetailBook()

        Text {
            x: 34
            y: 34
            width: 120
            text: "返回"
            color: root.inkColor
            font.pixelSize: 23
            font.bold: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.showDetailCatalog = false
                    root.screenName = "shelf"
                }
            }
        }

        Rectangle {
            id: detailCover
            x: 52
            y: 124
            width: 306
            height: width / root.coverAspectRatio
            radius: 3
            color: detailPage.book.colorA
            border.color: root.inkColor
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
            width: root.width - 448
            text: detailPage.book.title
            color: root.inkColor
            font.pixelSize: 40
            font.bold: true
            wrapMode: Text.WordWrap
            maximumLineCount: 3
        }

        Text {
            x: 396
            y: 252
            width: root.width - 450
            text: detailPage.book.author + " · " + detailPage.book.categoryName
            color: root.mutedInk
            font.pixelSize: 24
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            x: 396
            y: 298
            width: root.width - 450
            text: detailPage.book.ratingLine || "微信读书"
            color: root.inkColor
            font.pixelSize: 24
            font.bold: true
        }

        Text {
            x: 396
            y: 350
            width: root.width - 450
            text: detailPage.book.intro
            color: root.inkColor
            font.pixelSize: 23
            lineHeight: 1.22
            wrapMode: Text.WordWrap
            maximumLineCount: 5
            elide: Text.ElideRight
        }

        Text {
            x: 52
            y: 600
            width: root.width - 104
            text: "阅读进度"
            color: root.inkColor
            font.pixelSize: 24
            font.bold: true
        }

        Rectangle {
            id: detailProgressBar
            x: 52
            y: 640
            width: root.width - 104
            height: 12
            radius: 2
            color: "#ffffff"
            border.color: root.inkColor
            border.width: 1
            Rectangle {
                x: 0
                y: 0
                width: parent.width * (detailPage.book.progressRatio || 0)
                height: parent.height
                radius: 2
                color: root.brandGreenDark
            }
        }

        Text {
            x: 52
            y: 670
            width: root.width - 104
            text: detailPage.book.progressLabel || detailPage.book.progress
            color: root.inkColor
            font.pixelSize: 21
            font.bold: true
        }

        Rectangle {
            x: 52
            y: 718
            width: Math.round((root.width - 122) * 0.58)
            height: 68
            radius: 4
            color: root.brandGreenDark
            border.color: root.inkColor
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
                    root.openOrDownloadBook(detailPage.book)
                }
            }
        }

        Rectangle {
            x: 70 + Math.round((root.width - 122) * 0.58)
            y: 718
            width: root.width - x - 52
            height: 68
            radius: 4
            color: downloadStore.running ? root.goldAccent : root.surfaceColor
            border.color: root.inkColor
            border.width: 2
            Text {
                anchors.centerIn: parent
                text: downloadStore.running ? "取消下载" : detailPage.book.downloadActionText
                color: root.inkColor
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
                        root.openOrDownloadBook(detailPage.book)
                    } else {
                        downloadStore.downloadBook(detailPage.book.bookId, detailPage.book.title)
                    }
                }
            }
        }

        Text {
            x: 52
            y: 806
            width: root.width - 104
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
            width: (root.width - 104) / 3
            height: 30
            text: "目录"
            color: root.inkColor
            font.pixelSize: 19
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.showDetailCatalog = true
                    bookCatalogStore.loadCatalog(detailPage.book.bookId, detailPage.book.title)
                }
            }
        }

        Text {
            x: 52 + (root.width - 104) / 3
            y: 836
            width: (root.width - 104) / 3
            height: 30
            visible: !downloadStore.running && (detailPage.book.downloadState === "full" || detailPage.book.localEpubPath !== "")
            text: "删除下载"
            color: root.inkColor
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
            x: 52 + (root.width - 104) / 3 * 2
            y: 836
            width: (root.width - 104) / 3
            height: 30
            visible: !downloadStore.running && (detailPage.book.downloadState === "full" || detailPage.book.localEpubPath !== "")
            text: "修复插图"
            color: root.inkColor
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
            width: root.width - 104
            height: 30
            visible: downloadStore.queuedCount > 0
            text: "清空队列"
            color: root.inkColor
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
            width: root.width - 104
            text: "书评"
            color: root.inkColor
            font.pixelSize: 30
            font.bold: true
        }

        Rectangle {
            x: 52
            y: 960
            width: root.width - 104
            height: Math.min(116, root.height - 980)
            radius: 4
            color: root.surfaceColor
            border.color: root.inkColor
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
                        color: root.inkColor
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
                color: root.paperColor
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
                color: root.inkColor
                font.pixelSize: 28
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.showDetailCatalog = false
                        root.screenName = "shelf"
                    }
                }
            }

            Text {
                x: 250
                y: 34
                width: root.width - 500
                height: 52
                text: "书籍详情"
                color: root.inkColor
                font.pixelSize: 28
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                x: 40
                y: 96
                width: root.width - 80
                height: 2
                color: root.inkColor
            }

            Item {
                id: detailHero
                x: 48
                y: 124
                width: root.width - 96
                height: 472

                Rectangle {
                    id: detailHeroCover
                    x: 0
                    y: 0
                    width: 286
                    height: Math.round(width / root.coverAspectRatio)
                    radius: 3
                    color: detailPage.book.colorA || root.paperColor
                    border.color: root.inkColor
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
                        color: root.inkColor
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
                    color: root.inkColor
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
                    color: root.inkColor
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
                    color: root.inkColor
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
                    color: root.inkColor
                    font.pixelSize: 23
                    font.weight: Font.Bold
                }

                Text {
                    x: 326
                    y: 286
                    width: parent.width - 326
                    height: 180
                    text: detailPage.book.intro || "暂无简介"
                    color: root.inkColor
                    font.pixelSize: 26
                    font.family: root.readerFontFamily
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
                color: root.inkColor
                font.pixelSize: 27
                font.weight: Font.Bold
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: detailProgressPercent
                x: root.width - 218
                y: 610
                width: 170
                height: 62
                text: Math.round((detailPage.book.progressRatio || 0) * 100) + "%"
                color: root.brandGreenDark
                font.pixelSize: 42
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                x: 48
                y: 682
                width: root.width - 96
                height: 16
                radius: 3
                color: root.paperColor
                border.color: root.inkColor
                border.width: 2
                Rectangle {
                    x: 2
                    y: 2
                    width: Math.max(0, (parent.width - 4) * (detailPage.book.progressRatio || 0))
                    height: parent.height - 4
                    radius: 2
                    color: root.brandGreenDark
                }
            }

            Rectangle {
                id: detailPrimaryAction
                x: 48
                y: 744
                width: 560
                height: 78
                radius: 4
                color: root.brandGreenDark
                border.color: root.inkColor
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
                    onClicked: root.openOrDownloadBook(detailPage.book)
                }
            }

            Rectangle {
                x: 628
                y: 744
                width: root.width - 676
                height: 78
                radius: 4
                color: downloadStore.running ? root.goldAccent : root.paperColor
                border.color: root.inkColor
                border.width: 2
                Text {
                    anchors.centerIn: parent
                    text: downloadStore.running ? "取消下载" : detailPage.book.downloadActionText
                    color: root.inkColor
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (downloadStore.running) {
                            downloadStore.cancelDownload()
                        } else if (detailPage.book.downloadState === "full") {
                            root.openOrDownloadBook(detailPage.book)
                        } else {
                            downloadStore.downloadBook(detailPage.book.bookId, detailPage.book.title)
                        }
                    }
                }
            }

            Row {
                x: 48
                y: 850
                width: root.width - 96
                height: 58
                spacing: 0

                Repeater {
                    model: ["目录", "删除下载", "修复插图"]
                    Rectangle {
                        width: (root.width - 96) / 3
                        height: 58
                        color: root.paperColor
                        border.color: root.inkColor
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.inkColor
                            font.pixelSize: 23
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (index === 0) {
                                    root.showDetailCatalog = true
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
                width: root.width - 96
                height: 42
                text: shelfStore.refreshingDetails
                    ? shelfStore.detailProgress
                    : (downloadStore.queuedCount > 0
                        ? downloadStore.progressText + " · 队列 " + downloadStore.queuedCount + " 本"
                        : downloadStore.progressText)
                color: downloadStore.state === "error" ? "#8b1e1e" : root.inkColor
                font.pixelSize: 22
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            Rectangle {
                x: 48
                y: 990
                width: root.width - 96
                height: 2
                color: root.inkColor
            }

            Text {
                x: 48
                y: 1018
                width: root.width - 96
                height: 52
                text: "推荐书评"
                color: root.inkColor
                font.pixelSize: 34
                font.weight: Font.Bold
                verticalAlignment: Text.AlignVCenter
            }

            Flickable {
                id: detailReviewList
                x: 48
                y: 1084
                width: root.width - 96
                height: root.height - 1120
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
                                color: root.inkColor
                                font.pixelSize: 28
                                font.family: root.readerFontFamily
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
                                color: root.inkColor
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
            width: root.width - 172
            height: root.height - 260
            radius: 4
            color: root.surfaceColor
            border.color: root.inkColor
            border.width: 2
            visible: root.showDetailCatalog
            z: 14

            Text {
                x: 24
                y: 18
                width: parent.width - 168
                height: 44
                text: "目录"
                color: root.inkColor
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
                color: root.inkColor
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
                color: root.inkColor
                font.pixelSize: 21
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.showDetailCatalog = false
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
                        color: root.inkColor
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
                            color: root.surfaceColor

                            Text {
                                x: Math.min(28, (modelData.level || 0) * 18)
                                y: 0
                                width: parent.width - 170
                                height: parent.height
                                text: modelData.label || modelData.title
                                color: root.inkColor
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
                                color: root.inkColor
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
                                color: root.inkColor
                                opacity: 0.28
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.showDetailCatalog = false
                                    if (detailPage.book.downloadState === "full" || detailPage.book.localEpubPath !== "") {
                                        root.enterReaderForCatalogChapter(detailPage.book, modelData)
                                    } else {
                                        root.downloadCatalogChapter(detailPage.book, modelData)
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
        id: readerPage
        anchors.fill: parent
        visible: root.screenName === "reader"
        onVisibleChanged: {
            if (visible) {
                powerStore.reloadBattery()
                frontlightStore.reload()
            }
        }

        property var book: shelfStore.books[root.selectedIndex] || ({})

        MouseArea {
            id: catalogOpenGestureArea
            x: 0
            y: 170
            width: 96
            height: root.height - root.readerBottomGestureHeight - 170
            z: 8
            enabled: !root.showReaderCatalog && !root.showReaderSettings
            property real startX: 0
            property real startY: 0
            onPressed: function(mouse) {
                startX = mouse.x
                startY = mouse.y
            }
            onReleased: function(mouse) {
                if (mouse.x - startX > 56 && Math.abs(mouse.y - startY) < 96) {
                    root.closeReaderSettings()
                    root.showReaderCatalog = true
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
                    root.syncCurrentReaderProgress()
                    shelfStore.reload()
                    root.screenName = "detail"
                }
            }
        }

        MouseArea {
            id: readerBookmarkGestureArea
            x: root.width - 292
            y: 0
            width: 86
            height: 132
            z: 7
            onClicked: root.toggleReaderBookmark()
        }

        MouseArea {
            id: readerInkGestureArea
            x: root.width - 430
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
                    root.annotationMode = !root.annotationMode
                }
            }
        }

        Rectangle {
            id: readerQuickFrontlight
            x: root.width - 370
            y: 28
            width: 260
            height: 42
            z: 10
            radius: height / 2
            color: root.paperColor
            border.color: root.inkColor
            border.width: 2
            clip: true
            property int currentPercent: frontlightStore.powered
                ? Math.round(frontlightStore.brightness / Math.max(1, frontlightStore.maxBrightness) * 100)
                : 0

            Repeater {
                model: root.readerQuickFrontlightLevels

                Rectangle {
                    x: index * 52
                    y: 0
                    width: 52
                    height: 42
                    property bool selected: Math.abs(readerQuickFrontlight.currentPercent - modelData) <= 13
                    color: selected ? root.inkColor : root.paperColor

                    Rectangle {
                        x: 0
                        y: 7
                        width: 1
                        height: parent.height - 14
                        visible: index > 0
                        color: parent.selected ? root.paperColor : root.inkColor
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "关" : modelData
                        color: parent.selected ? root.paperColor : root.inkColor
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.applyFrontlightPercent(modelData)
                    }
                }
            }
        }

        Item {
            id: readerBatteryIndicator
            x: root.width - 92
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
                color: root.paperColor
                border.color: root.inkColor
                border.width: 2

                Repeater {
                    model: 4

                    Rectangle {
                        x: 5 + index * 10
                        y: 5
                        width: 8
                        height: 16
                        color: root.inkColor
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
                color: root.inkColor
            }
        }

        Image {
            x: root.readerMargin
            y: root.readerImageTopMargin
            width: root.width - root.readerMargin * 2
            height: root.currentReaderImageSource === "" ? 0 : root.readerImageTextTopY - root.readerImageTopMargin - 8
            source: root.currentReaderImageSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: root.currentReaderImageSource !== ""
            onStatusChanged: {
                if (status === Image.Error) {
                    root.readerImageLoadFailed = true
                    console.log("reader-image-error=" + source)
                }
            }
        }

        TextEdit {
            id: readerBodyText
            x: root.readerMargin
            y: root.currentReaderTextTopY
            z: 2
            width: root.readerTextWidth()
            height: root.readerBodyHeight(root.currentReaderTextTopY)
            text: root.formatReaderText(root.currentReaderPageText, root.currentReaderTextStart, root.currentReaderTextEnd) + "<!--" + root.forceReaderRefresh + "-->"
            textFormat: TextEdit.RichText
            color: "#111111"
            font.pixelSize: root.readerFontSize
            font.family: root.readerFontFamily
            font.weight: root.readerFontWeight
            readOnly: true
            activeFocusOnPress: false
            selectByMouse: false
            selectByKeyboard: false
            cursorVisible: false
            focus: false
            wrapMode: TextEdit.Wrap
            clip: true
            onLinkActivated: root.handleReaderLink(link)
        }

        Rectangle {
            x: root.readerMargin
            y: root.readerFooterTop
            width: root.readerTextWidth()
            height: 1
            z: 3
            color: root.inkColor
        }

        Text {
            x: root.readerMargin
            y: root.readerFooterTop + 9
            width: (root.width - root.readerMargin * 2) / 2
            height: root.readerFooterHeight - 9
            z: 3
            text: "第 " + (root.pageIndex + 1) + " / " + Math.max(1, root.readerCachedPageCount) + " 页"
            color: root.inkColor
            font.pixelSize: 18
            font.family: root.readerFontFamily
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            x: root.width / 2
            y: root.readerFooterTop + 9
            width: root.width / 2 - root.readerMargin
            height: root.readerFooterHeight - 9
            z: 3
            text: "进度 " + Math.round(root.currentReaderProgressPercent()) + "%"
            color: root.inkColor
            font.pixelSize: 18
            font.family: root.readerFontFamily
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }

        Repeater {
            id: readerFootnoteTouchLayer
            model: root.readerFootnoteHitRectsForPage()

            MouseArea {
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                z: 8.5
                enabled: !root.showReaderSettings && !root.showReaderCatalog && !root.showReaderSocialPopup
                preventStealing: true
                onClicked: {}
            }
        }

        Repeater {
            id: readerSocialTouchLayer
            model: root.readerSocialHitRects

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
                        color: root.inkColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.showReaderSettings && !root.showReaderCatalog && !root.showReaderSocialPopup
                    preventStealing: true
                    onPressed: function(mouse) { mouse.accepted = true }
                    onReleased: root.openReaderSocialPopup(socialUnderlineDelegate.socialIndex)
                }
            }
        }

        Rectangle {
            id: readerFootnotePanel
            x: 48
            y: Math.round((root.height - height) / 2)
            width: root.width - 96
            height: Math.round(root.height * 0.62)
            z: 9
            visible: root.showReaderFootnote
            color: root.surfaceColor
            border.color: root.inkColor
            border.width: 2
            radius: 8

            Text {
                x: 34
                y: 28
                width: parent.width - 68
                text: String(root.readerActiveFootnote.marker || "注释")
                color: "#9b2226"
                font.pixelSize: 32
                font.weight: Font.Bold
            }

            Text {
                x: 34
                y: 92
                width: parent.width - 68
                height: parent.height - 170
                text: String(root.readerActiveFootnote.text || "")
                color: root.inkColor
                font.pixelSize: Math.max(28, Math.round(root.readerFontSize * 0.80))
                font.family: root.readerFontFamily
                font.weight: Font.Normal
                wrapMode: Text.WordWrap
                clip: true
            }

            Text {
                x: parent.width - width - 34
                y: parent.height - 54
                text: "返回正文"
                color: root.inkColor
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeReaderFootnote()
            }
        }

        MouseArea {
            id: readerSocialPopupOutsideCloseArea
            anchors.fill: parent
            z: 10
            visible: root.showReaderSocialPopup
            enabled: root.showReaderSocialPopup
            onPressed: root.closeReaderSocialPopup()
        }

        Rectangle {
            id: readerSocialPopupPanel
            x: 40
            y: Math.round((root.height - height) / 2)
            width: root.width - 80
            height: Math.round(root.height * 0.80)
            z: 11
            visible: root.showReaderSocialPopup
            color: root.surfaceColor
            border.color: root.inkColor
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
                color: root.inkColor
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
                color: root.inkColor
                font.pixelSize: 40
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeReaderSocialPopup()
                }
            }

            Text {
                x: 32
                y: 94
                width: parent.width - 64
                height: 104
                text: root.readerSocialDisplayText(root.readerActiveSocialMark)
                color: root.inkColor
                font.pixelSize: Math.max(27, Math.round(root.readerFontSize * 0.72))
                font.family: root.readerFontFamily
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
                color: root.inkColor
            }

            Text {
                x: 32
                y: 232
                width: parent.width - 64
                height: 42
                text: {
                    var reviews = root.readerActiveSocialMark.reviews || []
                    var total = Math.max(reviews.length, Math.floor(Number(root.readerActiveSocialMark.totalCount) || 0))
                    if (reviews.length === 0 && notesStore.running) {
                        return "评论正在加载..."
                    }
                    return total > 0 ? (total + " 人在这里有想法") : "暂时没有评论详情"
                }
                color: root.inkColor
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
                        model: root.readerActiveSocialMark.reviews || []

                        Rectangle {
                            width: socialCommentsColumn.width
                            height: 150
                            color: root.surfaceColor

                            Text {
                                x: 0
                                y: 12
                                width: parent.width
                                height: 32
                                text: modelData.author || "微信读书用户"
                                color: root.inkColor
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
                                color: root.inkColor
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
                                color: root.inkColor
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
            visible: root.screenName === "reader"

            InkCanvas {
                id: readerInkCanvas
                anchors.fill: parent
                strokes: root.readerVisibleInkStrokes()
            }

            MouseArea {
                anchors.fill: parent
                visible: root.readerOcrBlockSelection
                z: 3
                onClicked: {
                    root.readerOcrBlockSelection = false
                    root.readerSuppressPageTurnUntilMs = Date.now() + 500
                }
            }

            Repeater {
                model: readerStore.pageInkBlocks

                Item {
                    property var inkBlock: modelData || ({})
                    anchors.fill: parent

                    MouseArea {
                        x: Math.max(8, Number(inkBlock.x || 0) - 18)
                        y: Math.max(root.readerTextTopMargin, Number(inkBlock.y || 0) - 18)
                        width: Math.min(root.width - x - 8, Number(inkBlock.width || 1) + 36)
                        height: Math.min(root.readerContentBottom - y, Number(inkBlock.height || 1) + 36)
                        enabled: !root.readerOcrBlockSelection
                        z: 1
                        onClicked: root.selectReaderInkBlock(inkBlock)
                    }

                    Rectangle {
                        x: Math.max(8, Number(inkBlock.x || 0) - 14)
                        y: Math.max(root.readerTextTopMargin, Number(inkBlock.y || 0) - 14)
                        width: Math.min(root.width - x - 8, Number(inkBlock.width || 1) + 28)
                        height: Math.min(root.readerContentBottom - y, Number(inkBlock.height || 1) + 28)
                        visible: root.readerOcrBlockSelection
                                 || root.readerSelectedInkBlockId === String(inkBlock.blockId || "")
                        radius: 6
                        color: "transparent"
                        border.color: root.brandGreenDark
                        border.width: 3
                        z: 4

                        Text {
                            x: 5
                            y: -28
                            height: 26
                            text: root.readerOcrBlockSelection ? "点此识别" : "已选中"
                            color: root.brandGreenDark
                            font.pixelSize: 17
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.recognizeReaderInkBlock(inkBlock)
                        }
                    }

                    Rectangle {
                        visible: !!inkBlock.ocrText && !root.readerOcrBlockSelection
                        x: root.clamp(Number(inkBlock.x || 0), 18, root.width - 378)
                        y: root.clamp(Number(inkBlock.y || 0) + Number(inkBlock.height || 0) + 10,
                                      root.readerTextTopMargin, root.readerContentBottom - 54)
                        width: Math.min(360, root.width - x - 18)
                        height: 46
                        radius: 7
                        color: root.paperColor
                        border.color: root.readerMarkerColor
                        border.width: 2
                        z: 2

                        Text {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: "识别：" + (inkBlock.ocrText || "")
                            color: root.inkColor
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.recognizeReaderInkBlock(inkBlock)
                        }
                    }
                }
            }

            Rectangle {
                id: readerInkBlockActions
                property var inkBlock: root.selectedReaderInkBlock()
                visible: !!inkBlock.blockId
                x: root.clamp(Number(inkBlock.x || 0), 18, root.width - width - 18)
                y: {
                    var above = Number(inkBlock.y || 0) - height - 18
                    if (above >= root.readerTextTopMargin) {
                        return above
                    }
                    return root.clamp(Number(inkBlock.y || 0) + Number(inkBlock.height || 0) + 18,
                                      root.readerTextTopMargin, root.readerContentBottom - height)
                }
                width: 318
                height: 58
                radius: 10
                color: root.paperColor
                border.color: root.inkColor
                border.width: 2
                z: 6

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: [
                            {"label": "识别", "action": "ocr"},
                            {"label": "删除", "action": "delete"},
                            {"label": "取消", "action": "cancel"}
                        ]

                        Rectangle {
                            width: readerInkBlockActions.width / 3
                            height: readerInkBlockActions.height
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.inkColor
                                font.pixelSize: 20
                                font.bold: true
                            }

                            Rectangle {
                                anchors.right: parent.right
                                width: 1
                                height: parent.height - 16
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index < 2
                                color: root.quietLine
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.action === "ocr") {
                                        root.recognizeReaderInkBlock(readerInkBlockActions.inkBlock)
                                    } else if (modelData.action === "delete") {
                                        root.deleteSelectedReaderInkBlock()
                                    } else {
                                        root.readerSelectedInkBlockId = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: readerInlineOcrToast
                visible: root.readerInlineOcrStatus !== ""
                x: Math.round((root.width - width) / 2)
                y: 108
                width: Math.min(560, root.width - 72)
                height: 58
                radius: 10
                color: root.paperColor
                border.color: root.inkColor
                border.width: 2
                z: 10

                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    text: root.readerInlineOcrStatus
                    color: root.inkColor
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: root.readerOcrBlockSelection
                x: Math.round((root.width - width) / 2)
                y: 108
                width: Math.min(520, root.width - 80)
                height: 54
                radius: 10
                color: root.paperColor
                border.color: root.inkColor
                border.width: 2
                z: 5

                Text {
                    anchors.centerIn: parent
                    text: "点选要 OCR 的手写块；点空白处取消"
                    color: root.inkColor
                    font.pixelSize: 20
                    font.bold: true
                }
            }

            Repeater {
                model: readerStore.paragraphNotes

                Item {
                    property var note: modelData || ({})
                    property var placement: root.readerParagraphNotePlacements()[String(note.noteId || "")] || ({ "visible": false })
                    visible: root.showHandwrittenNotes && placement.visible
                    x: placement.x || 0
                    y: placement.y || 0
                    width: placement.width || 0
                    height: placement.height || 0

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: root.paperColor
                        border.color: note.colorValue || root.inkColor
                        border.width: 2
                    }

                    Text {
                        x: 7
                        y: 4
                        width: parent.width - 42
                        text: (placement.kind === "page-free" ? "本页笔记" : "段落笔记") + (note.ocrText ? " · 已识别" : "")
                        color: root.mutedInk
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
                        color: root.paperColor
                        border.color: root.inkColor
                        border.width: 1
                        z: 3

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: root.inkColor
                            font.pixelSize: 20
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: readerStore.removeParagraphNote(root.currentBookId, String(note.noteId || ""))
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
                            ctx.strokeStyle = note.colorValue || root.inkColor
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
                        color: note.colorValue || root.inkColor
                        font.pixelSize: 16
                        font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.recognizeParagraphNote(note)
                    }
                }
            }

        }

        Item {
            id: readerStylusToolBar
            x: root.width - width - 12
            y: Math.max(178, Math.round(root.height * 0.29))
            width: root.readerStylusToolsExpanded ? root.readerStylusToolBarWidth : 38
            height: root.readerStylusToolsExpanded
                    ? root.readerStylusToolBarPadding * 2
                    + root.readerStylusTools.length * root.readerStylusToolDotSize
                    + Math.max(0, root.readerStylusTools.length - 1) * root.readerStylusToolGap
                    + root.readerStylusSectionGap
                    : 74
            z: 9
            visible: root.screenName === "reader"
                     && !root.showReaderSettings
                     && !root.showReaderCatalog
                     && !root.showReaderSocialPopup

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.paperColor
                border.color: root.inkColor
                border.width: 2
                opacity: 1
            }

            Rectangle {
                id: readerStylusCollapsedHandle
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: 13
                visible: !root.readerStylusToolsExpanded
                color: root.readerMarkerTool === "eraser" ? root.paperColor : root.readerMarkerColor
                border.color: root.inkColor
                border.width: root.readerMarkerTool === "eraser" ? 3 : 1

                Text {
                    anchors.centerIn: parent
                    text: root.readerMarkerTool === "free" ? "写" : (root.readerMarkerTool === "eraser" ? "擦" : "划")
                    color: root.readerMarkerTool === "eraser" ? root.inkColor : "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                }
            }

            Rectangle {
                x: 12
                y: root.readerStylusToolY(4) - Math.round(root.readerStylusSectionGap / 2) - Math.round(root.readerStylusToolGap / 2)
                width: parent.width - 24
                height: 2
                visible: root.readerStylusToolsExpanded
                color: root.quietLine
                opacity: 0.55
            }

            Repeater {
                model: root.readerStylusTools

                Rectangle {
                    x: root.readerStylusToolBarPadding
                       + (readerStylusToolBar.width - root.readerStylusToolBarPadding * 2 - root.readerStylusToolDotSize) / 2
                    y: root.readerStylusToolY(index)
                    width: root.readerStylusToolDotSize
                    height: root.readerStylusToolDotSize
                    radius: width / 2
                    visible: root.readerStylusToolsExpanded
                    color: modelData.tool === "color" ? modelData.value : root.paperColor
                    border.color: root.readerStylusToolSelected(modelData) ? root.inkColor : root.quietLine
                    border.width: root.readerStylusToolSelected(modelData) ? 4 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.tool === "clear" && root.readerClearArmed ? "确" : (modelData.label || "")
                        color: root.inkColor
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
            visible: root.screenName === "reader" && stylusStore.palmRejectionActive
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
            width: root.width / 2
            height: Math.max(0, root.readerContentBottom - 90)
            z: 6
            enabled: !root.showReaderSettings && !root.showReaderCatalog && !root.showReaderSocialPopup
            property real startX: 0
            property real startY: 0
            onPressed: function(mouse) {
                startX = mouse.x
                startY = mouse.y
            }
            onReleased: function(mouse) {
                root.handleReaderPageTurnGesture("left", startX, startY, mouse.x, mouse.y)
            }
        }

        MouseArea {
            id: readerRightPageTurnArea
            x: root.width / 2
            y: 90
            width: root.width / 2
            height: Math.max(0, root.readerContentBottom - 90)
            z: 6
            enabled: !root.showReaderSettings && !root.showReaderCatalog && !root.showReaderSocialPopup
            property real startX: 0
            property real startY: 0
            onPressed: function(mouse) {
                startX = mouse.x
                startY = mouse.y
            }
            onReleased: function(mouse) {
                root.handleReaderPageTurnGesture("right", startX, startY, mouse.x, mouse.y)
            }
        }

        MouseArea {
            id: gestureOpenArea
            x: 0
            y: root.height - root.readerBottomGestureHeight
            width: root.width
            height: root.readerBottomGestureHeight
            property real startY: 0
            onPressed: function(mouse) {
                startY = mouse.y
            }
            onReleased: function(mouse) {
                if (startY - mouse.y > 44) {
                    root.settingsDragOffset = 0
                    root.openReaderSettings()
                }
            }
        }

        Rectangle {
            id: readerSettingsBackdrop
            x: 0
            y: root.height - root.readerSettingsPanelHeight + root.settingsDragOffset
            width: root.width
            height: root.readerSettingsPanelHeight
            visible: root.showReaderSettings
            z: 11
            color: root.paperColor
            opacity: 1
        }

        Rectangle {
            id: readerSettingsPanel
            x: 0
            y: root.height - height + root.settingsDragOffset
            width: root.width
            height: root.readerSettingsPanelHeight
            visible: root.showReaderSettings
            z: 12
            color: root.surfaceColor
            opacity: 1
            radius: 10
            border.color: root.inkColor
            border.width: 1
            clip: true
            onVisibleChanged: if (!visible) root.settingsDragOffset = 0

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
                    root.settingsDragOffset = 0
                }
                onPositionChanged: function(mouse) {
                    root.handleSettingsPanelDownDrag(mouse.y - startY)
                }
                onReleased: function(mouse) {
                    if (root.settingsDragOffset > 86 || root.handleSettingsPanelDownDrag(mouse.y - startY) || mouse.y - startY > 72) {
                        root.closeReaderSettings()
                    }
                    root.settingsDragOffset = 0
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
                        root.handleSettingsPanelDownDrag(translation.y)
                    }
                }
                onActiveChanged: {
                    if (!active) {
                        if (root.handleSettingsPanelDownDrag(translation.y)) {
                            root.closeReaderSettings()
                        }
                        root.settingsDragOffset = 0
                    }
                }
            }

            function adjust(prop, delta, minValue, maxValue) {
                root[prop] = root.clamp(root[prop] + delta, minValue, maxValue)
                root.scheduleReaderPaginationRebuild()
                root.forceReaderRefresh += 1
            }

            Rectangle {
                x: 0
                y: 78
                width: parent.width
                height: 1
                color: root.inkColor
                opacity: 0.35
            }

            Text {
                x: 0
                y: 34
                width: parent.width
                text: "阅读设置"
                color: root.inkColor
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
                color: root.inkColor
                font.pixelSize: 28
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

	            MouseArea {
	                anchors.fill: parent
	                    onClicked: {
	                        root.settingsDragOffset = 0
	                        root.closeReaderSettings()
	                    }
	                }
	            }

            Text {
                x: 24
                y: 98
                text: "字号"
                color: root.inkColor
                font.pixelSize: 20
                font.bold: true
            }

            Text {
                x: 48
                y: 140
                text: "A"
                color: root.inkColor
                font.pixelSize: 27
                font.bold: true
            }

            Rectangle {
                x: (parent.width - width) / 2
                y: 126
                width: 246
                height: 52
                radius: 7
                color: root.surfaceColor
                border.color: root.inkColor
                border.width: 1

                Rectangle {
                    x: 78
                    y: 0
                    width: 1
                    height: parent.height
                    color: root.inkColor
                    opacity: 0.35
                }

                Rectangle {
                    x: 168
                    y: 0
                    width: 1
                    height: parent.height
                    color: root.inkColor
                    opacity: 0.35
                }

                Text {
                    x: 0
                    y: 0
                    width: 78
                    height: parent.height
                    text: "-"
                    color: root.inkColor
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
                    text: root.readerFontSize
                    color: root.inkColor
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
                    color: root.inkColor
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
                color: root.inkColor
                font.pixelSize: 38
                font.bold: true
            }

            Rectangle {
                x: 0
                y: 198
                width: parent.width
                height: 1
                color: root.inkColor
                opacity: 0.22
            }

            Text {
                x: 24
                y: 218
                text: "行距"
                color: root.inkColor
                font.pixelSize: 20
                font.bold: true
            }

            Row {
                x: 122
                y: 246
                spacing: 12

                Repeater {
                    model: root.readerLineHeightSteps
                    Rectangle {
                        width: 132
                        height: 58
                        radius: height / 2
                        property bool selected: Math.abs(root.readerLineHeight - modelData.value) < 0.01
                        color: selected ? root.inkColor : root.paperColor
                        border.color: root.inkColor
                        border.width: selected ? 3 : 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.selected ? root.paperColor : root.inkColor
                            font.pixelSize: 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.readerLineHeight = modelData.value
                                root.applyReaderSettingChange(true)
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
                color: root.inkColor
                opacity: 0.22
            }

            Text {
                x: 24
                y: 326
                text: "段距"
                color: root.inkColor
                font.pixelSize: 20
                font.bold: true
            }

            Row {
                x: 122
                y: 354
                spacing: 12

                Repeater {
                    model: root.readerParagraphSpacingSteps
                    Rectangle {
                        width: 132
                        height: 58
                        radius: height / 2
                        property bool selected: root.readerParagraphSpacing === modelData.value
                        color: selected ? root.inkColor : root.paperColor
                        border.color: root.inkColor
                        border.width: selected ? 3 : 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.selected ? root.paperColor : root.inkColor
                            font.pixelSize: 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.readerParagraphSpacing = modelData.value
                                root.applyReaderSettingChange(true)
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
                color: root.inkColor
                opacity: 0.22
            }

            Text {
                x: 24
                y: 432
                text: "页边距"
                color: root.inkColor
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
                        color: root.surfaceColor
                        border.color: root.readerMargin === modelData.value ? root.brandGreenDark : root.inkColor
                        border.width: root.readerMargin === modelData.value ? 2 : 1

                        Rectangle {
                            anchors.centerIn: parent
                            width: modelData.value === 48 ? 34 : modelData.value === 72 ? 28 : modelData.value === 104 ? 22 : 16
                            height: 32
                            color: "transparent"
                            border.color: root.readerMargin === modelData.value ? root.brandGreenDark : root.inkColor
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
	                            onClicked: {
	                                root.readerMargin = modelData.value
	                                root.markReaderPaginationDirty()
	                                root.rebuildReaderPagination()
	                                root.forceReaderRefresh += 1
	                            }
                        }
                    }
                }
            }

            Text {
                x: 24
                y: 496
                text: "首行"
                color: root.inkColor
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
                        color: root.surfaceColor
                        border.color: root.readerFirstLineIndentChars === modelData.value ? root.brandGreenDark : root.inkColor
                        border.width: root.readerFirstLineIndentChars === modelData.value ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.readerFirstLineIndentChars === modelData.value ? root.brandGreenDark : root.inkColor
                            font.pixelSize: 17
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
	                            onClicked: {
	                                root.readerFirstLineIndentChars = modelData.value
	                                root.markReaderPaginationDirty()
	                                root.rebuildReaderPagination()
	                                root.forceReaderRefresh += 1
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
                color: root.inkColor
                opacity: 0.22
            }

            Text {
                x: 24
                y: 566
                text: "字体"
                color: root.inkColor
                font.pixelSize: 20
                font.bold: true
            }

            Row {
                x: 132
                y: 558
                spacing: 12

                Repeater {
                    model: ["系统", "微米黑", "正黑", "霞鹜文楷"]
                    Rectangle {
                        width: 132
                        height: 42
                        radius: 7
                        color: root.surfaceColor
                        border.color: root.readerFontChoice === modelData ? root.brandGreenDark : root.inkColor
                        border.width: root.readerFontChoice === modelData ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.readerFontChoice === modelData ? root.brandGreenDark : root.inkColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.readerFontChoice = modelData
                                root.scheduleReaderPaginationRebuild()
                                root.forceReaderRefresh += 1
                            }
                        }
                    }
                }
            }

            Text {
                x: 714
                y: 566
                text: "字重"
                color: root.inkColor
                font.pixelSize: 18
                font.bold: true
            }

            Row {
                x: 772
                y: 558
                spacing: 8

                Repeater {
                    model: [
                        { label: "加黑", value: Font.DemiBold },
                        { label: "浓黑", value: Font.Bold }
                    ]
                    Rectangle {
                        width: 52
                        height: 42
                        radius: 7
                        color: root.surfaceColor
                        border.color: root.readerFontWeight === modelData.value ? root.brandGreenDark : root.inkColor
                        border.width: root.readerFontWeight === modelData.value ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.readerFontWeight === modelData.value ? root.brandGreenDark : root.inkColor
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.readerFontWeight = modelData.value
                                root.scheduleReaderPaginationRebuild()
                                root.forceReaderRefresh += 1
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
                color: root.inkColor
                opacity: 0.22
            }

            Text {
                x: 24
                y: 630
                text: "灯光"
                color: root.inkColor
                font.pixelSize: 20
                font.bold: true
            }

            Row {
                x: 102
                y: 620
                spacing: 10

                Repeater {
                    model: root.frontlightLevels
                    Rectangle {
                        width: 88
                        height: 48
                        radius: height / 2
                        property int currentPercent: Math.round(frontlightStore.brightness / Math.max(1, frontlightStore.maxBrightness) * 100)
                        property bool selected: Math.abs(currentPercent - modelData) <= 10
                        color: selected ? root.inkColor : root.paperColor
                        border.color: root.inkColor
                        border.width: Math.abs(currentPercent - modelData) <= 10 ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData === 0 ? "关" : modelData + "%"
                            color: parent.selected ? root.paperColor : root.inkColor
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.applyFrontlightPercent(modelData)
                        }
                    }
                }
            }

            Rectangle {
                x: 0
                y: 682
                width: parent.width
                height: 1
                color: root.inkColor
                opacity: 0.22
                visible: parent.height > 720
            }

            Text {
                x: 24
                y: 696
                text: "跳转进度"
                color: root.inkColor
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
                color: root.surfaceColor
                border.color: root.inkColor
                border.width: 1
                visible: parent.height > 720

	                Rectangle {
	                    x: 0
	                    y: 0
	                    width: parent.width * root.currentReaderProgressValue / 100
	                    height: parent.height
	                    radius: 6
	                    color: root.brandGreenDark
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: function(mouse) {
                        root.setReaderProgressPercent(mouse.x / progressJumpSlider.width * 100)
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            root.setReaderProgressPercent(mouse.x / progressJumpSlider.width * 100)
                        }
                    }
                }
            }

            Text {
                x: parent.width - 102
	                y: 694
	                width: 76
	                height: 42
	                text: Math.round(root.currentReaderProgressValue) + "%"
                color: root.inkColor
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
                color: root.inkColor
                opacity: 0.22
                visible: parent.height > 780
            }

            Text {
                x: 24
                y: 758
                text: "网络"
                color: root.inkColor
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
                color: root.inkColor
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
                color: root.surfaceColor
                border.color: root.inkColor
                border.width: 1
                visible: parent.height > 780

                Text {
                    anchors.centerIn: parent
                    text: "刷新"
                    color: root.inkColor
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
                color: root.inkColor
                opacity: 0.22
                visible: parent.height > 812
            }

            Rectangle {
                x: 24
                y: 798
                width: 128
                height: 42
                radius: 7
                color: root.inkColor
                border.color: root.inkColor
                border.width: 1
                visible: parent.height > 812

                Text {
                    anchors.centerIn: parent
                    text: "退出到书架"
                    color: root.paperColor
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.exitReaderToShelf()
                }
            }

            Rectangle {
                x: 164
                y: 798
                width: 128
                height: 42
                radius: 7
                color: root.surfaceColor
                border.color: root.inkColor
                border.width: 1
                visible: parent.height > 812

                Text {
                    anchors.centerIn: parent
                    text: "重绘本页"
                    color: root.inkColor
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.forceReaderRefresh += 1
                }
            }

            Rectangle {
                x: 304
                y: 798
                width: 128
                height: 42
                radius: 7
                color: progressSyncStore.running ? root.inkColor : root.surfaceColor
                border.color: root.inkColor
                border.width: 1
                visible: parent.height > 812

                Text {
                    anchors.centerIn: parent
                    text: "同步进度"
                    color: progressSyncStore.running ? "#ffffff" : root.inkColor
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !progressSyncStore.running
                    onClicked: progressSyncStore.syncProgress(root.currentBookId, root.currentReaderProgressPercent(), root.currentReaderSummaryText(), root.currentReaderElapsedSeconds())
                }
            }

            Rectangle {
                x: 444
                y: 798
                width: 128
                height: 42
                radius: 7
                color: progressSyncStore.running ? root.inkColor : root.surfaceColor
                border.color: root.inkColor
                border.width: 1
                visible: parent.height > 812

                Text {
                    anchors.centerIn: parent
                    text: "拉取进度"
                    color: progressSyncStore.running ? "#ffffff" : root.inkColor
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !progressSyncStore.running
                    onClicked: progressSyncStore.pullProgress(root.currentBookId)
                }
            }

            Text {
                x: 588
                y: 798
                width: parent.width - 612
                height: 42
                text: progressSyncStore.statusText
                color: root.inkColor
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
                    root.settingsDragOffset = 0
                }
                onPositionChanged: function(mouse) {
                    root.handleSettingsPanelDownDrag(mouse.y - startY)
                }
                onReleased: function(mouse) {
                    if (root.settingsDragOffset > 86 || root.handleSettingsPanelDownDrag(mouse.y - startY)) {
                        root.closeReaderSettings()
                    }
                    root.settingsDragOffset = 0
                }
            }

        }

        MouseArea {
            id: catalogCloseGestureArea
            x: root.readerCatalogPanelWidth
            y: 0
            width: root.width - root.readerCatalogPanelWidth
            height: root.height
            visible: root.showReaderCatalog
            enabled: root.showReaderCatalog
            z: 13
            preventStealing: true
            property real startX: 0
            onPressed: function(mouse) {
                startX = mouse.x
            }
            onReleased: function(mouse) {
                if (Math.abs(mouse.x - startX) > 56) {
                    root.closeReaderCatalog()
                    return
                }
                root.closeReaderCatalog()
            }
        }

        Rectangle {
            id: readerCatalogPanel
            x: 0
            y: 0
            width: root.readerCatalogPanelWidth
            height: root.height
            visible: root.showReaderCatalog
            z: 14
            color: root.surfaceColor

            DragHandler {
                id: catalogCloseDragHandler
                target: null
                xAxis.enabled: true
                yAxis.enabled: false
                onActiveChanged: {
                    if (!active && Math.abs(translation.x) > 56) {
                        root.closeReaderCatalog()
                    }
                }
            }

            Text {
                x: 44
                y: 34
                width: parent.width - 160
                text: "目录"
                color: root.inkColor
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
                color: root.inkColor
                font.pixelSize: 34
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeReaderCatalog()
                }
            }

            Rectangle {
                x: 44
                y: 96
                width: parent.width - 88
                height: 1
                color: root.inkColor
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
                    color: root.surfaceColor
                    border.color: root.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "回到书架"
                        color: root.inkColor
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.exitReaderToShelf()
                    }
                }

                Rectangle {
                    width: Math.floor((parent.width - 12) / 2)
                    height: 48
                    radius: 24
                    color: downloadStore.running ? root.goldAccent : root.brandGreenDark
                    border.color: root.inkColor
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: downloadStore.running ? "下载中" : "下载整本"
                        color: downloadStore.running ? root.inkColor : "#ffffff"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !downloadStore.running && root.currentBookId !== ""
                        onClicked: downloadStore.downloadBook(root.currentBookId, readerStore.title)
                    }
                }
            }

            Text {
                x: 44
                y: 202
                width: parent.width - 88
                height: 44
                text: "章节"
                color: root.inkColor
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
                    color: root.surfaceColor

                    Text {
                        x: 0
                        y: 0
                        width: parent.width - 150
                        height: parent.height
                        text: modelData.title || ("第 " + (index + 1) + " 章")
                        color: root.inkColor
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
                        text: root.readerChapterPageLabel(modelData)
                        color: root.inkColor
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
                        color: root.inkColor
                        opacity: 0.28
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.jumpToChapter(modelData)
                    }
                }
            }
        }
    }

    Rectangle {
        id: softKeyboardPanel
        x: 0
        y: root.height - height
        width: root.width
        height: 500
        visible: root.showSoftKeyboard
        z: 35
        color: root.paperColor
        border.color: root.inkColor
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
                    text: root.keyboardTarget ? String(root.keyboardTarget.text || "") : ""
                    color: root.inkColor
                    font.pixelSize: 22
                    font.bold: true
                    elide: Text.ElideLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: 72
                    height: parent.height
                    radius: 4
                    color: root.surfaceColor
                    border.color: root.inkColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "关闭"
                        color: root.inkColor
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.closeSoftKeyboard()
                    }
                }

                Rectangle {
                    width: 78
                    height: parent.height
                    radius: 4
                    color: root.brandGreenDark
                    border.color: root.inkColor
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
                        onClicked: root.keyboardSubmit()
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
                        property bool selected: (modelData.mode === "pinyin" && root.keyboardPinyinMode)
                            || (modelData.mode === "handwriting" && root.keyboardHandwritingMode)
                            || (modelData.mode === "english"
                                && !root.keyboardPinyinMode && !root.keyboardHandwritingMode)
                        property bool permitted: !root.keyboardTarget
                            || root.keyboardTarget.echoMode !== TextInput.Password
                            || modelData.mode === "english"
                        width: 94
                        height: parent.height
                        radius: 4
                        color: selected ? root.inkColor : root.surfaceColor
                        border.color: root.inkColor
                        border.width: 1
                        opacity: permitted ? 1 : 0.42

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.selected ? root.paperColor : root.inkColor
                            font.pixelSize: 19
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.permitted
                            onClicked: root.setKeyboardInputMode(modelData.mode)
                        }
                    }
                }

                Text {
                    width: parent.width - 94 * 3 - 8 * 3
                    height: parent.height
                    text: root.keyboardHandwritingMode
                        ? (root.keyboardCandidatePageCount() > 1
                            ? "候选 " + (root.keyboardCandidatePage + 1) + "/" + root.keyboardCandidatePageCount()
                            : (ocrStore.configured ? "百度 OCR · 手动识别" : "百度 OCR 尚未配置"))
                        : (root.keyboardPinyinMode
                            ? (root.keyboardCandidatePageCount() > 1
                                ? "候选 " + (root.keyboardCandidatePage + 1) + "/" + root.keyboardCandidatePageCount()
                                : "拼音候选")
                            : "直接输入")
                    color: root.mutedInk
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
                    property bool canMove: root.keyboardCandidatePage > 0
                    width: root.keyboardCandidatePageCount() > 1 ? 58 : 0
                    height: parent.height
                    visible: width > 0
                    radius: 4
                    color: root.surfaceColor
                    border.color: root.inkColor
                    border.width: 1
                    opacity: canMove ? 1 : 0.42

                    Text {
                        anchors.centerIn: parent
                        text: "上页"
                        color: root.inkColor
                        font.pixelSize: 17
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canMove
                        onClicked: root.keyboardChangeCandidatePage(-1)
                    }
                }

                Text {
                    width: root.keyboardPinyinMode && !root.keyboardHandwritingMode ? 98 : 0
                    height: parent.height
                    visible: width > 0
                    text: root.keyboardPinyinBuffer === "" ? "输入拼音" : root.keyboardPinyinBuffer
                    color: root.mutedInk
                    font.pixelSize: 19
                    font.bold: true
                    elide: Text.ElideLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.keyboardPinyinMode && !root.keyboardHandwritingMode
                        ? root.keyboardPagedPinyinCandidates() : []

                    Rectangle {
                        width: 108
                        height: parent.height
                        radius: 4
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: modelData.text
                            color: root.inkColor
                            font.pixelSize: 21
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.keyboardChooseCandidate(modelData)
                        }
                    }
                }

                Repeater {
                    model: root.keyboardHandwritingMode
                        ? root.keyboardPagedHandwritingCandidates() : []

                    Rectangle {
                        width: Math.min(136, Math.max(108, handwritingCandidateText.implicitWidth + 24))
                        height: parent.height
                        radius: 4
                        color: root.surfaceColor
                        border.color: root.inkColor
                        border.width: 1

                        Text {
                            id: handwritingCandidateText
                            anchors.fill: parent
                            anchors.margins: 6
                            text: modelData
                            color: root.inkColor
                            font.pixelSize: 21
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.keyboardChooseHandwritingCandidate(modelData)
                        }
                    }
                }

                Text {
                    width: root.keyboardHandwritingMode
                        && root.keyboardHandwritingCandidates.length === 0 ? parent.width : 0
                    height: parent.height
                    visible: width > 0
                    text: root.keyboardHandwritingStatus
                    color: root.mutedInk
                    font.pixelSize: 19
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Rectangle {
                    property bool canMove: root.keyboardCandidatePage
                        < root.keyboardCandidatePageCount() - 1
                    width: root.keyboardCandidatePageCount() > 1 ? 58 : 0
                    height: parent.height
                    visible: width > 0
                    radius: 4
                    color: root.surfaceColor
                    border.color: root.inkColor
                    border.width: 1
                    opacity: canMove ? 1 : 0.42

                    Text {
                        anchors.centerIn: parent
                        text: "下页"
                        color: root.inkColor
                        font.pixelSize: 17
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canMove
                        onClicked: root.keyboardChangeCandidatePage(1)
                    }
                }
            }

            Rectangle {
                id: keyboardHandwritingPad
                width: parent.width
                height: 268
                visible: root.keyboardHandwritingMode
                color: "#ffffff"
                border.color: root.inkColor
                border.width: 2
                radius: 4
                clip: true

                Rectangle {
                    x: 12
                    y: Math.round(parent.height / 2)
                    width: parent.width - 24
                    height: 1
                    color: root.quietLine
                    opacity: 0.45
                }

                Text {
                    anchors.centerIn: parent
                    text: root.keyboardHandwritingStrokes.length === 0
                        && root.keyboardHandwritingCurrentStroke.length === 0
                        ? "在这里连续手写，写完后点“识别”" : ""
                    color: root.mutedInk
                    opacity: 0.52
                    font.pixelSize: 20
                    font.bold: true
                }

                InkCanvas {
                    id: keyboardHandwritingInk
                    anchors.fill: parent
                    strokes: root.keyboardHandwritingStoredStrokes()
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
                        var point = keyboardHandwritingPad.mapToItem(root.contentItem,
                                                                    mouse.x, mouse.y)
                        root.beginKeyboardHandwritingStroke(point.x, point.y)
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed && !stylusStore.palmRejectionActive) {
                            var point = keyboardHandwritingPad.mapToItem(root.contentItem,
                                                                        mouse.x, mouse.y)
                            root.appendKeyboardHandwritingStroke(point.x, point.y)
                        }
                    }
                    onReleased: function(mouse) {
                        var point = keyboardHandwritingPad.mapToItem(root.contentItem,
                                                                    mouse.x, mouse.y)
                        root.endKeyboardHandwritingStroke(point.x, point.y)
                    }
                    onCanceled: {
                        root.cancelKeyboardHandwritingStroke()
                    }
                }
            }

            Repeater {
                model: root.keyboardHandwritingMode ? [] : root.keyboardRows

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
                            color: root.surfaceColor
                            border.color: root.inkColor
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: root.inkColor
                                font.pixelSize: 20
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.keyboardTypeKey(modelData)
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 48
                spacing: 10
                visible: !root.keyboardHandwritingMode

                Rectangle {
                    width: Math.floor(parent.width * 0.26)
                    height: parent.height
                    radius: 4
                    color: root.surfaceColor
                    border.color: root.inkColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "退格"
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.keyboardBackspace()
                    }
                }

                Rectangle {
                    width: Math.floor(parent.width * 0.34)
                    height: parent.height
                    radius: 4
                    color: root.surfaceColor
                    border.color: root.inkColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "空格"
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.keyboardPinyinMode && root.keyboardCandidates.length > 0) {
                                root.keyboardChooseCandidate(root.keyboardCandidates[0])
                            } else {
                                root.keyboardInsert(" ")
                            }
                        }
                    }
                }

                Rectangle {
                    width: Math.floor(parent.width * 0.18)
                    height: parent.height
                    radius: 4
                    color: root.surfaceColor
                    border.color: root.inkColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "清空"
                        color: root.inkColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.keyboardTarget) {
                                root.keyboardTarget.text = ""
                                root.keyboardTarget.cursorPosition = 0
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 48
                spacing: 8
                visible: root.keyboardHandwritingMode

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
                            && root.keyboardHandwritingStrokes.length > 0
                            && !ocrStore.busy
                        width: Math.floor((parent.width - 24) / 4)
                        height: parent.height
                        radius: 4
                        color: recognitionReady ? root.brandGreenDark : root.surfaceColor
                        border.color: root.inkColor
                        border.width: 1
                        opacity: recognitionButton && !recognitionReady ? 0.52 : 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.recognitionReady ? "#ffffff" : root.inkColor
                            font.pixelSize: 19
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !parent.recognitionButton || parent.recognitionReady
                            onClicked: {
                                if (modelData.action === "undo") {
                                    root.keyboardUndoHandwritingStroke()
                                } else if (modelData.action === "clear") {
                                    root.keyboardClearHandwriting()
                                    root.keyboardHandwritingStatus = ocrStore.configured
                                        ? "写完后点“识别”" : "需联网使用百度 OCR"
                                } else if (modelData.action === "recognize") {
                                    root.keyboardRecognizeHandwriting()
                                } else {
                                    root.keyboardBackspace()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: sleepCoverScreen
        anchors.fill: parent
        visible: root.sleepOverlayVisible
        z: 100
        color: "#ffffff"

        Image {
            id: sleepCoverImage
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, Math.round((parent.height - 132) * root.coverAspectRatio))
            height: Math.min(parent.height - 132, Math.round(width / root.coverAspectRatio))
            source: root.sleepCoverSource
            fillMode: Image.PreserveAspectFit
            cache: true
            asynchronous: false
            visible: source !== ""
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 128
            height: 420
            visible: root.sleepCoverSource === ""
            color: "#ffffff"
            border.color: root.inkColor
            border.width: 3

            Text {
                anchors.fill: parent
                anchors.margins: 48
                text: root.sleepBookTitle
                color: root.inkColor
                font.family: root.readerFontFamily
                font.pixelSize: 44
                font.bold: true
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Rectangle {
        id: qrLoginScreen
        anchors.fill: parent
        visible: root.showQrLogin
        z: 95
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
            color: root.inkColor
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
            text: accountStore.loginConfirmUrl === "" ? "正在生成二维码" : "请使用微信扫描二维码"
            color: root.inkColor
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
            source: accountStore.loginConfirmUrl === "" ? "" : "image://wereadqr/" + encodeURIComponent(accountStore.loginConfirmUrl)
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
            visible: accountStore.loginConfirmUrl === ""
            color: "#ffffff"
            border.color: root.inkColor
            border.width: 3

            Text {
                anchors.centerIn: parent
                text: accountStore.loginRunning ? "请稍候" : "二维码生成失败"
                color: root.inkColor
                font.pixelSize: 30
                font.bold: true
            }
        }

        Text {
            x: 72
            y: 824
            width: parent.width - 144
            height: 92
            text: accountStore.loginStatusText
            color: root.inkColor
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
            color: root.inkColor
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
                width: accountStore.loginRunning ? parent.width : Math.floor((parent.width - 18) / 2)
                height: parent.height
                radius: 4
                color: "#ffffff"
                border.color: root.inkColor
                border.width: 2

                Text {
                    anchors.fill: parent
                    text: "取消"
                    color: root.inkColor
                    font.pixelSize: 24
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeQrLogin()
                }
            }

            Rectangle {
                width: Math.floor((parent.width - 18) / 2)
                height: parent.height
                visible: !accountStore.loginRunning
                radius: 4
                color: root.brandGreenDark
                border.color: root.inkColor
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
                    onClicked: root.openQrLogin()
                }
            }
        }
    }

}

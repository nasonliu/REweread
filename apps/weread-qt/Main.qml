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
    property var magicStrokes: []
    property var magicCurrentStroke: []
    property var magicStrokeRecords: []
    property string magicAnswer: ""
    // Keep incoming model text separate from the ink already written to the
    // paper. This guarantees a stream chunk can never appear as a whole word.
    property string magicReplyDraft: ""
    property string magicRevealText: ""
    property int magicRevealLength: 0
    property bool magicAwaitingReply: false
    property bool magicReplyComplete: false
    property bool magicPaperCleared: false
    property real magicQuestionOpacity: 1.0
    property real magicAnswerOpacity: 1.0
    property string magicFontChoice: "龙藏体"
    property string magicPersonaChoice: "温柔笔友"
    property int magicAnswerMaxCharacters: 84
    property int magicNotebookAnswerTop: 112
    property int magicNotebookAnswerFontPixels: 104
    property int magicNotebookLinePitch: Math.round(magicNotebookAnswerFontPixels * 1.08)
    property int magicNotebookFirstBaselineY: magicNotebookAnswerTop + Math.round(magicNotebookAnswerFontPixels * 0.84)
    property bool magicMenuOpen: false
    property bool magicMenuPenTap: false
    property int magicWritingHeight: Math.round(root.height * 0.56)
    property real magicInkBottomY: 0
    property real magicReplyTilt: -0.75
    property int pageIndex: 0
    property string currentBookId: ""
    property int shelfPageIndex: 0
    property int shelfPageCount: Math.max(1, Math.ceil(shelfStore.books.length / 9))
    property int readerBottomGestureHeight: 56
    property int readerFooterHeight: 46
    property int readerFooterGap: root.readerLinePixels()
    property int readerFooterTop: root.height - root.readerBottomGestureHeight - root.readerFooterHeight
    property int readerContentBottom: root.readerFooterTop - root.readerFooterGap
    // The page break is line-snapped, while the visible rich-text viewport
    // keeps every remaining safe pixel above the footer. Qt's text document
    // may need a few extra raster rows for a glyph's descent even when its
    // logical line height is an exact multiple.
    property int readerTextBottomGuard: 2
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
    property bool readerAiHandwritingMode: false
    property bool readerForceNewFreeInkGroup: false
    property string readerAiPendingBlockId: ""
    property string readerAiPendingBookId: ""
    property int readerAiPendingPageIndex: -1
    property string readerAiReplyDraft: ""
    property string readerAiRevealBlockId: ""
    property string readerAiRevealText: ""
    property int readerAiRevealLength: 0
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
        {"id": "ai", "tool": "ai", "name": "AI 回信", "value": "", "label": "AI"},
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
                : readerFontChoice === "思源黑体" && sourceHanSansFont.status === FontLoader.Ready
                    ? sourceHanSansFont.name
                    : readerFontChoice === "思源宋体" && sourceHanSerifFont.status === FontLoader.Ready
                        ? sourceHanSerifFont.name
                        : readerFontChoice === "寒蝉正楷" && chillKaiFont.status === FontLoader.Ready
                            ? chillKaiFont.name
                            : readerFontChoice === "寒蝉活宋" && chillHuoSongFont.status === FontLoader.Ready
                                ? chillHuoSongFont.name
                                : readerFontChoice === "马善政" && maShanZhengFont.status === FontLoader.Ready
                                    ? maShanZhengFont.name
                                    : readerFontChoice === "刘建毛草" && liuJianMaoCaoFont.status === FontLoader.Ready
                                        ? liuJianMaoCaoFont.name
                                        : readerFontChoice === "智勇行" && zhiMangXingFont.status === FontLoader.Ready
                                            ? zhiMangXingFont.name
                                            : readerFontChoice === "龙藏体" && longCangFont.status === FontLoader.Ready
                                                ? longCangFont.name
                                                : readerFontChoice === "站酷快乐" && zcoolKuaiLeFont.status === FontLoader.Ready
                                                    ? zcoolKuaiLeFont.name
                                                    : ""
    property string magicFontFamily: magicFontChoice === "马善政" && maShanZhengFont.status === FontLoader.Ready ? maShanZhengFont.name
        : magicFontChoice === "刘建毛草" && liuJianMaoCaoFont.status === FontLoader.Ready ? liuJianMaoCaoFont.name
        : magicFontChoice === "智勇行" && zhiMangXingFont.status === FontLoader.Ready ? zhiMangXingFont.name
        : magicFontChoice === "龙藏体" && longCangFont.status === FontLoader.Ready ? longCangFont.name
        : magicFontChoice === "站酷快乐" && zcoolKuaiLeFont.status === FontLoader.Ready ? zcoolKuaiLeFont.name
        : lxgwWenKaiFont.name
    property string magicFontPath: magicFontChoice === "马善政" ? "/home/root/weread-qt/fonts/ma-shan-zheng.ttf"
        : magicFontChoice === "刘建毛草" ? "/home/root/weread-qt/fonts/liu-jian-mao-cao.ttf"
        : magicFontChoice === "智勇行" ? "/home/root/weread-qt/fonts/zhi-mang-xing.ttf"
        : magicFontChoice === "站酷快乐" ? "/home/root/weread-qt/fonts/zcool-kuaile.ttf"
        : magicFontChoice === "霞鹜文楷" ? "/home/root/weread-qt/fonts/lxgw-wenkai.ttf"
        : "/home/root/weread-qt/fonts/long-cang.ttf"
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
    property var readerLayoutSelfTestCases: []
    property int readerLayoutSelfTestCaseCursor: 0
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
    onReaderFontFamilyChanged: root.markReaderPaginationDirty()
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

    Settings {
        id: persistedMagicBookSettings
        category: "magicBook"
        property alias fontChoice: root.magicFontChoice
        property alias personaChoice: root.magicPersonaChoice
        property bool longCangDefaultMigrated: false
    }

    Component.onCompleted: {
        root.migrateReaderDefaults()
        if (!persistedMagicBookSettings.longCangDefaultMigrated) {
            root.magicFontChoice = "龙藏体"
            persistedMagicBookSettings.longCangDefaultMigrated = true
        }
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

    FontLoader {
        id: sourceHanSansFont
        source: "file:///home/root/weread-qt/fonts/source-han-sans-sc.otf"
    }

    FontLoader {
        id: sourceHanSerifFont
        source: "file:///home/root/weread-qt/fonts/source-han-serif-sc.otf"
    }

    FontLoader {
        id: chillKaiFont
        source: "file:///home/root/weread-qt/fonts/chill-kai.ttf"
    }

    FontLoader {
        id: chillHuoSongFont
        source: "file:///home/root/weread-qt/fonts/chill-huosong.otf"
    }
    FontLoader { id: maShanZhengFont; source: "file:///home/root/weread-qt/fonts/ma-shan-zheng.ttf" }
    FontLoader { id: liuJianMaoCaoFont; source: "file:///home/root/weread-qt/fonts/liu-jian-mao-cao.ttf" }
    FontLoader { id: zhiMangXingFont; source: "file:///home/root/weread-qt/fonts/zhi-mang-xing.ttf" }
    FontLoader { id: longCangFont; source: "file:///home/root/weread-qt/fonts/long-cang.ttf" }
    FontLoader { id: zcoolKuaiLeFont; source: "file:///home/root/weread-qt/fonts/zcool-kuaile.ttf" }

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
        if (!readerPage.bodyText || !readerPage.bodyText.getText || !readerPage.bodyText.positionToRectangle) {
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
        var high = Math.max(0, Math.floor(Number(readerPage.bodyText.length) || 0))
        var answer = high
        while (low <= high) {
            var middle = Math.floor((low + high) / 2)
            var visibleLength = root.readerCompactTextLength(readerPage.bodyText.getText(0, middle))
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
        if (documentStart < 0 || documentEnd <= documentStart || !readerPage.bodyText.positionToRectangle) {
            return rects
        }

        var run = null
        var minimumCharacterWidth = Math.max(5, Math.round(root.readerFontSize * 0.42))
        for (var position = documentStart; position < documentEnd; position++) {
            var glyph = readerPage.bodyText.positionToRectangle(position)
            if (!glyph || glyph.x === undefined || glyph.y === undefined) {
                continue
            }
            var glyphX = Number(glyph.x) || 0
            var glyphY = Number(glyph.y) || 0
            var glyphHeight = Math.max(1, Number(glyph.height) || root.readerLinePixels())
            var nextGlyph = position + 1 <= documentEnd
                ? readerPage.bodyText.positionToRectangle(position + 1)
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
                    "x": readerPage.bodyText.x + glyphX,
                    "y": readerPage.bodyText.y + glyphY + glyphHeight - 4,
                    "width": Math.max(3, glyphEndX - glyphX),
                    "lineTop": readerPage.bodyText.y + glyphY,
                    "lineHeight": glyphHeight
                }
            } else {
                run.width = Math.max(run.width, readerPage.bodyText.x + glyphEndX - run.x)
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

    function formatReaderText(value, textStart, textEnd, imageSource, imageCaption) {
        var source = String(value || "")
        var paragraphs = source.split(/\n+/)
        var out = []
        var continuation = root.isParagraphContinuation(textStart)
        var chapterStart = root.isReaderChapterStart(textStart)
        var sourceCursor = 0
        var bodyLineHeight = Math.max(1, root.readerLinePixels())
        var pageImageSource = imageSource === undefined ? root.currentReaderImageSource : String(imageSource || "")
        var pageImageCaption = imageCaption === undefined ? root.currentReaderImageCaption : String(imageCaption || "")
        var imageCaptionPrefix = pageImageSource !== "" ? pageImageCaption.replace(/\s+/g, " ").trim() : ""
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

    function readerTextViewportHeight(topY) {
        return Math.max(1, root.readerContentBottom - topY)
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
        return Math.max(1, root.readerNextPageOffset(start, topY, image) - start)
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
                var imageEnd = root.readerNextPageOffset(offset, root.readerImageTextTopY, image)
                var imageStart = root.readerImageEntryTextStart(image)
                if (imageStart >= imageEnd) {
                    image = ({})
                    imageSource = ""
                }
            }
            starts.push(offset)
            images.push(image)
            var topY = imageSource !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
            offset = root.readerNextPageOffset(offset, topY, image)
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

    // A pause means the current free-ink block is ready. This timer exists
    // only in the explicit AI tool, so ordinary notes never leave the device.
    Timer {
        id: readerAiHandwritingPauseTimer
        interval: 1400
        repeat: false
        onTriggered: root.beginPausedAiHandwriting()
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
                        " documentLength=" + Math.floor(Number(readerPage.bodyText.length) || 0))
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

    function readerFormattedRangeText(start, end, image) {
        var text = String(readerStore.bodyText || "")
        var caption = root.readerImageEntryCaption(image)
        var body = text.slice(start, end).trim()
        return caption !== "" ? caption + "\n\n" + body : body
    }

    function readerMeasuredPageHeight(start, end, image) {
        if (!readerPage.pageMeasure) {
            return 0
        }
        readerPage.pageMeasure.width = root.readerTextWidth()
        readerPage.pageMeasure.text = root.formatReaderText(
                    root.readerFormattedRangeText(start, end, image),
                    start,
                    end,
                    root.readerImageEntrySource(image),
                    root.readerImageEntryCaption(image))
        return Math.ceil(readerPage.pageMeasure.paintedHeight)
    }

    function readerMeasuredPageFits(start, end, topY, image) {
        var safeHeight = Math.max(1, root.readerTextViewportHeight(topY) - root.readerTextBottomGuard)
        return root.readerMeasuredPageHeight(start, end, image) <= safeHeight
    }

    function readerMeasuredPageEnd(start, candidateEnd, topY, image) {
        var text = String(readerStore.bodyText || "")
        var safeStart = root.clamp(Math.floor(Number(start) || 0), 0, text.length)
        var safeEnd = root.clamp(Math.floor(Number(candidateEnd) || 0), safeStart + 1, text.length)
        if (root.readerMeasuredPageFits(safeStart, safeEnd, topY, image)) {
            return safeEnd
        }
        var low = safeStart + 1
        var high = safeEnd - 1
        var best = safeStart + 1
        var guard = 0
        while (low <= high && guard < 20) {
            guard += 1
            var mid = Math.floor((low + high) / 2)
            var measuredEnd = Math.max(safeStart + 1, root.readerCleanPageEnd(text, safeStart, mid))
            if (root.readerMeasuredPageFits(safeStart, measuredEnd, topY, image)) {
                best = measuredEnd
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        best = root.readerPreferredPageEnd(text, safeStart, best)
        while (best > safeStart + 1 && !root.readerMeasuredPageFits(safeStart, best, topY, image)) {
            best = root.readerCleanPageEnd(text, safeStart, best - 1)
        }
        return Math.max(safeStart + 1, best)
    }

    function readerNextPageOffset(start, topY, image) {
        var text = String(readerStore.bodyText || "")
        var safeStart = Math.max(0, Math.floor(Number(start) || 0))
        var rawEnd = root.readerEstimatedPageEnd(safeStart, topY)
        var chapterBreak = root.nextReaderChapterStartAfter(safeStart)
        var candidateEnd = chapterBreak > safeStart && chapterBreak <= rawEnd
            ? chapterBreak
            : root.readerPreferredPageEnd(text, safeStart, rawEnd)
        return root.readerMeasuredPageEnd(safeStart, candidateEnd, topY, image || ({}))
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
                var imageEnd = root.readerNextPageOffset(start, root.readerImageTextTopY, image)
                var imageStart = root.readerImageEntryTextStart(image)
                if (imageStart >= imageEnd) {
                    image = ({})
                    imageSource = ""
                }
            }
            starts.push(start)
            images.push(image)
            var topY = imageSource !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
            var next = root.readerNextPageOffset(start, topY, image)
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
        var cursor = root.readerNextPageOffset(starts[lastIndex], lastTopY, lastImage)
        var added = 0
        var target = Math.max(1, Math.floor(Number(additionalPages) || 0))
        while (cursor < text.length && added < target) {
            var textOnlyEnd = root.readerNextPageOffset(cursor, root.readerTextTopMargin)
            var image = root.readerImageForPageRange(cursor, textOnlyEnd)
            var imageSource = root.readerImageEntrySource(image)
            if (imageSource !== "") {
                var imageEnd = root.readerNextPageOffset(cursor, root.readerImageTextTopY, image)
                if (root.readerImageEntryTextStart(image) >= imageEnd) {
                    image = ({})
                    imageSource = ""
                }
            }
            starts.push(cursor)
            images.push(image)
            var topY = imageSource !== "" ? root.readerImageTextTopY : root.readerTextTopMargin
            var next = root.readerNextPageOffset(cursor, topY, image)
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
        var image = root.readerPageImages[safePage] || ({})
        var end = nextStart > start
            ? nextStart
            : root.readerNextPageOffset(start, topY, image)
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
            : root.readerNextPageOffset(start, topY, image)
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
        if (root.screenName !== "reader" || !readerPage.stylusToolBar.visible) {
            return ({})
        }
        var localX = x - readerPage.stylusToolBar.x
        var localY = y - readerPage.stylusToolBar.y
        if (localX < 0 || localX > readerPage.stylusToolBar.width || localY < 0 || localY > readerPage.stylusToolBar.height) {
            return ({})
        }
        if (!root.readerStylusToolsExpanded) {
            return ({ "id": "expand", "tool": "expand", "name": "展开" })
        }
        for (var i = 0; i < root.readerStylusTools.length; i++) {
            var dotX = root.readerStylusToolBarPadding + (readerPage.stylusToolBar.width - root.readerStylusToolBarPadding * 2 - root.readerStylusToolDotSize) / 2
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
        if (tool.tool === "ai") {
            return root.readerAiHandwritingMode
        }
        if (tool.tool === "marker" || tool.tool === "free" || tool.tool === "eraser") {
            return tool.tool === root.readerMarkerTool && !root.readerAiHandwritingMode
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
        if (tool.tool === "ai") {
            root.readerMarkerTool = "free"
            root.readerAiHandwritingMode = true
            root.readerClearArmed = false
            readerClearConfirmTimer.stop()
            root.annotationMode = true
            root.readerStylusCollapsePending = true
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
        root.readerAiHandwritingMode = false
        root.readerClearArmed = false
        readerClearConfirmTimer.stop()
        root.readerStylusCollapsePending = true
        root.annotationMode = true
        root.currentStrokePoints = []
        root.currentFreeNotePoints = []
        root.currentFreeNoteStrokes = []
        readerPage.inkCanvas.clearLive()
        return true
    }

    function clearCurrentPageInkAndNotes() {
        root.flushPendingFreeInkStrokes()
        readerPage.inkCanvas.clearLive()
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
            readerPage.inkCanvas.beginStroke(freePoint.x, freePoint.y, root.readerMarkerColor, 4, 1, true)
        } else {
            var markerPoint = root.markerPointFromStylus(x, y, pressure)
            root.currentStrokePoints = [markerPoint]
            readerPage.inkCanvas.beginStroke(markerPoint.x, markerPoint.y,
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
        readerPage.inkCanvas.appendPoint(point.x, point.y)
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
            readerPage.inkCanvas.finishStroke()
            return
        }
        root.saveCurrentStroke()
        readerPage.inkCanvas.finishStroke()
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
                "lineWidth": 4,
                "groupId": root.readerForceNewFreeInkGroup
                    ? "ink-" + Date.now() + "-ai" : ""
            }])
            root.readerForceNewFreeInkGroup = false
            readerInkPersistTimer.restart()
            if (root.readerAiHandwritingMode) {
                readerAiHandwritingPauseTimer.restart()
            }
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
        if (readerPage.bodyText && readerPage.bodyText.positionAt && readerPage.bodyText.getText) {
            var localX = root.clamp(Math.round(Number(point.x) || 0) - readerPage.bodyText.x, 0, readerPage.bodyText.width)
            var localY = root.clamp(Math.round(Number(point.y) || 0) - readerPage.bodyText.y, 0, readerPage.bodyText.height)
            var documentPosition = readerPage.bodyText.positionAt(localX, localY)
            if (documentPosition >= 0) {
                return root.readerTextOffsetForVisibleText(readerPage.bodyText.getText(0, documentPosition))
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
        var paginationHeight = Math.ceil(root.readerBodyHeight(root.currentReaderTextTopY))
        var viewportHeight = Math.ceil(root.readerTextViewportHeight(root.currentReaderTextTopY))
        var paintedHeight = Math.ceil(readerPage.bodyText.paintedHeight)
        if (paginationHeight % linePx !== 0) {
            return "non-line-height paginationHeight=" + paginationHeight + " linePx=" + linePx
        }
        if (paintedHeight > viewportHeight - root.readerTextBottomGuard) {
            return "overflow page=" + root.pageIndex + " painted=" + paintedHeight + " viewport=" + viewportHeight
        }
        if (readerPage.bodyText.y + paintedHeight > root.readerContentBottom - root.readerTextBottomGuard) {
            return "bottom-overlap page=" + root.pageIndex + " paintedBottom=" + (readerPage.bodyText.y + paintedHeight) + " contentBottom=" + root.readerContentBottom
        }
        var measuredHeight = root.readerMeasuredPageHeight(root.currentReaderTextStart,
                                                            root.currentReaderTextEnd,
                                                            root.readerPageImages[root.pageIndex] || ({}))
        if (Math.abs(measuredHeight - paintedHeight) > 2) {
            return "measurement-drift page=" + root.pageIndex + " measure=" + measuredHeight + " painted=" + paintedHeight
        }
        if (root.currentReaderImageSource === "" && root.pageIndex < root.readerCachedPageCount - 1
                && !root.isReaderChapterEnd(root.currentReaderTextEnd)
                && !root.isReaderNearChapterEnd(root.currentReaderTextStart, root.currentReaderTextEnd)
                && paintedHeight < paginationHeight * 0.97) {
            return "underfilled-page page=" + root.pageIndex + " painted=" + paintedHeight + " pagination=" + paginationHeight
        }
        return ""
    }

    function prepareReaderLayoutSelfTestCase() {
        var layoutCase = root.readerLayoutSelfTestCases[root.readerLayoutSelfTestCaseCursor] || ({})
        root.readerFontChoice = String(layoutCase.fontChoice || "霞鹜文楷")
        root.readerLineHeight = Number(layoutCase.lineHeight || 1.26)
        root.rebuildReaderPagination()
        var count = Math.max(1, root.readerCachedPageCount)
        var imagePage = root.firstReaderImagePage()
        root.readerLayoutSelfTestPages = root.uniqueReaderLayoutPages([
            Math.floor(count * 0.08),
            Math.floor(count * 0.52),
            Math.floor(count * 0.88),
            imagePage > Math.floor(count * 0.04) ? imagePage : Math.floor(count * 0.08)
        ], count)
        root.readerLayoutSelfTestCursor = 0
        root.setReaderPage(root.readerLayoutSelfTestPages[0] || 0)
    }

    function runReaderLayoutSelfTest() {
        root.readerSelfTestSavedSettings = root.captureReaderSettings()
        root.readerFontSize = 38
        root.readerFontWeight = Font.DemiBold
        root.readerParagraphSpacing = 12
        root.readerFirstLineIndentChars = 2
        root.readerMargin = 64
        root.readerLayoutSelfTestCases = []
        var fonts = ["微米黑", "正黑", "霞鹜文楷", "思源黑体", "思源宋体", "寒蝉正楷", "寒蝉活宋"]
        var lineHeights = [1.16, 1.26, 1.36, 1.46]
        for (var fontIndex = 0; fontIndex < fonts.length; fontIndex++) {
            for (var lineIndex = 0; lineIndex < lineHeights.length; lineIndex++) {
                root.readerLayoutSelfTestCases.push({ "fontChoice": fonts[fontIndex], "lineHeight": lineHeights[lineIndex] })
            }
        }
        root.readerLayoutSelfTestCaseCursor = 0
        if (!root.enterReaderForSelfTest("reader-layout-selftest")) {
            return
        }
        root.prepareReaderLayoutSelfTestCase()
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
        root.handleStylusTap(root.width - 40, readerPage.stylusToolBar.y + 80)
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
        interval: 350
        repeat: false
        onTriggered: {
        if (root.readerFontFamily === "") {
                root.restoreReaderSettings(root.readerSelfTestSavedSettings)
                console.log("reader-layout-selftest=fail font-family-empty choice=" + root.readerFontChoice)
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
                root.readerLayoutSelfTestCaseCursor += 1
                if (root.readerLayoutSelfTestCaseCursor < root.readerLayoutSelfTestCases.length) {
                    root.prepareReaderLayoutSelfTestCase()
                    readerLayoutSelfTestTimer.restart()
                    return
                }
                console.log("reader-layout-selftest=ok cases=" + root.readerLayoutSelfTestCases.length +
                            " pages=" + root.readerLayoutSelfTestPages.join(",") +
                            " linePx=" + root.readerEstimatedLinePixels() +
                            " paginationHeight=" + Math.ceil(root.readerBodyHeight(root.currentReaderTextTopY)) +
                            " viewportHeight=" + Math.ceil(readerPage.bodyText.height) +
                            " paintedHeight=" + Math.ceil(readerPage.bodyText.paintedHeight))
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
            if (accountStore.loginConfirmUrl !== "" && qrLoginScreen.qrImage.status === Image.Ready) {
                console.log("qr-login-ui-selftest=ok urlLength=" + accountStore.loginConfirmUrl.length +
                            " image=" + qrLoginScreen.qrImage.width + "x" + qrLoginScreen.qrImage.height)
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

    function magicMenuDotHit(x, y) {
        return x >= magicPage.menuDot.x - 14 && x <= magicPage.menuDot.x + magicPage.menuDot.width + 14
            && y >= magicPage.menuDot.y - 14 && y <= magicPage.menuDot.y + magicPage.menuDot.height + 14
    }

    function magicBegin(x, y) {
        if (magicMenuDotHit(x, y)) {
            magicMenuPenTap = true
            return
        }
        if (magicMenuOpen || x < magicPage.inkCanvas.x || x > magicPage.inkCanvas.x + magicPage.inkCanvas.width
                || y < magicPage.inkCanvas.y || y > magicPage.inkCanvas.y + magicPage.inkCanvas.height) {
            return
        }
        // A Chinese character is made from several pen-down strokes, so
        // existing ink alone must never mean "start over".  Only a submitted
        // question or an already-visible answer starts a fresh exchange.
        // This also invalidates a late OCR/AI callback from the previous one.
        if (magicRevealText !== "" || magicAwaitingReply
                || pendingDirectOcrKind === "magic" || magicQuestionFadeTimer.running) {
            clearMagicPage()
        }
        magicQuestionOpacity = 1.0
        var localX = x - magicPage.inkCanvas.x
        var localY = y - magicPage.inkCanvas.y
        magicCurrentStroke = [{"x": localX, "y": localY, "pressure": 1}]
        magicInkBottomY = Math.max(magicInkBottomY, y)
        magicPage.inkCanvas.beginStroke(localX, localY, root.inkColor, 4, 1, true)
    }
    function magicAppend(x, y) {
        if (magicCurrentStroke.length < 1) return
        var localX = x - magicPage.inkCanvas.x
        var localY = y - magicPage.inkCanvas.y
        magicCurrentStroke.push({"x": localX, "y": localY, "pressure": 1})
        magicInkBottomY = Math.max(magicInkBottomY, y)
        magicPage.inkCanvas.appendPoint(localX, localY)
    }
    function magicEnd(x, y) {
        if (magicMenuPenTap) return
        if (magicCurrentStroke.length < 1) return
        magicAppend(x, y)
        if (magicCurrentStroke.length > 1) {
            magicStrokes = magicStrokes.concat([magicCurrentStroke])
            magicStrokeRecords = magicStrokeRecords.concat([{
                "tool": "free", "colorValue": root.inkColor,
                "lineWidth": 4, "points": magicCurrentStroke
            }])
        }
        magicCurrentStroke = []
        magicPage.inkCanvas.finishStroke()
        magicPauseTimer.restart()
    }
    function magicAsk() {
        if (magicStrokes.length < 1 || ocrStore.busy || aiReplyStore.busy) return
        if (!ocrStore.configured || !aiReplyStore.configured) {
            magicAnswer = ""
            return
        }
        var batch = magicStrokes.slice()
        // A pause defines one question. The original diary lets the paper
        // drink the question while the cloud work begins.
        magicStrokes = []
        magicRevealTimer.stop()
        magicAnswerHoldTimer.stop()
        magicAnswerFadeTimer.stop()
        magicReplyDraft = ""
        magicRevealText = ""
        magicRevealLength = 0
        magicAnswer = ""
        magicAnswerOpacity = 1.0
        magicReplyComplete = false
        magicPaperCleared = false
        root.pendingDirectOcrKind = "magic"
        ocrStore.clearCandidates()
        ocrStore.recognizeStrokeBlock(batch)
        magicQuestionFadeTimer.restart()
    }

    function clearMagicPage() {
        magicPauseTimer.stop()
        magicRevealTimer.stop()
        magicQuestionFadeTimer.stop()
        magicAnswerHoldTimer.stop()
        magicAnswerFadeTimer.stop()
        magicPaperClearTimer.stop()
        magicStrokes = []
        magicCurrentStroke = []
        magicStrokeRecords = []
        magicAnswer = ""
        magicReplyDraft = ""
        magicRevealText = ""
        magicRevealLength = 0
        magicAwaitingReply = false
        magicReplyComplete = false
        magicPaperCleared = false
        magicQuestionOpacity = 1.0
        magicAnswerOpacity = 1.0
        magicPage.replyInkCanvas.clear()
        magicInkBottomY = 0
        if (pendingDirectOcrKind === "magic") {
            pendingDirectOcrKind = ""
            pendingDirectOcrBookId = ""
            pendingDirectOcrPageIndex = -1
            pendingDirectOcrItemId = ""
        }
        magicPage.inkCanvas.clearLive()
    }

    function openMagicBook() {
        clearMagicPage()
        magicMenuOpen = false
        magicMenuPenTap = false
        screenName = "magic"
    }

    function recognizeReaderInkBlock(block) {
        if (!block || !block.blockId) {
            return
        }
        root.readerSelectedInkBlockId = String(block.blockId)
        root.beginDirectHandwritingOcr("block", String(block.blockId),
                                       block.strokes || [], root.pageIndex)
    }

    function beginPausedAiHandwriting() {
        if (!root.readerAiHandwritingMode || root.currentFreeNotePoints.length > 0
                || root.pendingDirectOcrKind !== "" || ocrStore.busy || aiReplyStore.busy) {
            return
        }
        root.flushPendingFreeInkStrokes()
        var blocks = readerStore.pageInkBlocks || []
        if (blocks.length < 1) {
            return
        }
        var block = blocks[blocks.length - 1] || ({})
        if (!block.blockId || !(block.strokes || []).length) {
            return
        }
        // Subsequent writing is intentionally a new sentence/block, rather
        // than becoming part of the one already sent to the cloud.
        root.readerForceNewFreeInkGroup = true
        root.readerSelectedInkBlockId = String(block.blockId)
        root.beginDirectHandwritingOcr("ai", String(block.blockId), block.strokes || [], root.pageIndex)
    }

    function askReaderInkBlockAi(block) {
        if (!block || !block.blockId) {
            return
        }
        root.readerSelectedInkBlockId = String(block.blockId)
        if (String(block.ocrText || "").trim() !== "") {
            root.beginAiHandwritingReply(root.currentBookId, root.pageIndex, String(block.blockId), block.ocrText)
            return
        }
        root.beginDirectHandwritingOcr("ai", String(block.blockId), block.strokes || [], root.pageIndex)
    }

    function beginAiHandwritingReply(bookId, pageIndex, blockId, question) {
        if (!aiReplyStore.configured) {
            root.showReaderOcrStatus("请先到“我的”配置 DeepSeek", true)
            return
        }
        root.readerAiPendingBookId = String(bookId || "")
        root.readerAiPendingPageIndex = Math.max(0, Math.floor(Number(pageIndex) || 0))
        root.readerAiPendingBlockId = String(blockId || "")
        root.readerAiReplyDraft = ""
        root.readerAiRevealBlockId = root.readerAiPendingBlockId
        root.readerAiRevealText = ""
        root.readerAiRevealLength = 0
        root.showReaderOcrStatus("AI 正在思考…", false)
        aiReplyStore.requestReply(String(question || ""))
    }

    function readerAiReplyDisplay(block) {
        var reply = String((block || {}).aiReply || "")
        if (String((block || {}).blockId || "") === root.readerAiRevealBlockId
                && root.readerAiRevealText !== "") {
            return root.readerAiRevealText.slice(0, root.readerAiRevealLength)
        }
        return reply
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
        } else if (root.pendingDirectOcrKind === "magic") {
            if (result !== "") {
                root.magicAnswer = ""
                root.magicAwaitingReply = true
                aiReplyStore.requestReply(result, root.magicPersonaChoice)
            } else {
                root.magicAnswer = ""
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
            } else if (root.pendingDirectOcrKind === "ai") {
                readerStore.setPageInkBlockOcrText(root.pendingDirectOcrBookId,
                                                   root.pendingDirectOcrPageIndex,
                                                   root.pendingDirectOcrItemId, result)
                root.beginAiHandwritingReply(root.pendingDirectOcrBookId,
                                             root.pendingDirectOcrPageIndex,
                                             root.pendingDirectOcrItemId, result)
            }
            if (root.pendingDirectOcrKind !== "ai") {
                root.showReaderOcrStatus("识别完成，文字已附在笔迹旁", true)
            }
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

    Connections {
        target: aiReplyStore
        function onReplySentenceReady(sentence) {
            if (root.magicAwaitingReply) {
                var remaining = root.magicAnswerMaxCharacters - root.magicReplyDraft.length
                if (remaining <= 0) return
                root.magicReplyDraft += String(sentence || "").slice(0, remaining)
                root.magicAnswer = root.magicReplyDraft
                return
            }
            if (root.readerAiPendingBlockId === "") {
                return
            }
            root.readerAiReplyDraft = (root.readerAiReplyDraft + String(sentence || "")).trim()
            root.readerAiRevealText = root.readerAiReplyDraft
            readerStore.setPageInkBlockAiReply(root.readerAiPendingBookId,
                                               root.readerAiPendingPageIndex,
                                               root.readerAiPendingBlockId,
                                               root.readerAiReplyDraft)
            readerAiRevealTimer.start()
            root.showReaderOcrStatus("AI 正在书写…", false)
        }
        function onReplyFinished(succeeded) {
            if (root.magicAwaitingReply) {
                root.magicAwaitingReply = false
                if (!succeeded && root.magicReplyDraft === "") root.magicAnswer = ""
                root.magicReplyComplete = succeeded && root.magicReplyDraft !== ""
                if (root.magicReplyComplete && root.magicPaperCleared) magicPaperClearTimer.restart()
                return
            }
            if (root.readerAiPendingBlockId === "") {
                return
            }
            root.showReaderOcrStatus(succeeded ? "AI 回复已写在笔记旁" : aiReplyStore.status, true)
            root.readerAiPendingBookId = ""
            root.readerAiPendingPageIndex = -1
            root.readerAiPendingBlockId = ""
        }
    }

    Timer {
        id: readerAiRevealTimer
        interval: 38
        repeat: true
        onTriggered: {
            if (root.readerAiRevealLength >= root.readerAiRevealText.length) {
                stop()
            } else {
                root.readerAiRevealLength += 1
            }
        }
    }
    Timer { id: magicPauseTimer; interval: 2600; repeat: false; onTriggered: root.magicAsk() }
    Timer {
        id: magicQuestionFadeTimer
        interval: 160
        repeat: true
        onTriggered: {
            root.magicQuestionOpacity = Math.max(0, root.magicQuestionOpacity - 0.1)
            if (root.magicQuestionOpacity > 0) return
            stop()
            root.magicStrokeRecords = []
            magicPage.inkCanvas.clearLive()
            root.magicInkBottomY = 0
            root.magicPaperCleared = true
            magicPaperClearTimer.restart()
        }
    }
    Timer {
        id: magicPaperClearTimer
        // Wait through the final Qt/e-paper composition after the question
        // layer is cleared.  The reply must never share a visible page with
        // the writer's question.
        interval: 720
        repeat: false
        onTriggered: {
            if (root.magicPaperCleared && root.magicReplyComplete
                    && root.magicReplyDraft !== "") magicRevealTimer.start()
        }
    }
    Timer {
        id: magicRevealTimer
        // Let the question fade settle first.  The native writer below then
        // draws its own skeleton paths at pen speed; QML Text never animates.
        interval: 120
        repeat: false
        onTriggered: {
            if (root.magicReplyComplete && root.magicReplyDraft !== "")
                magicPage.replyInkCanvas.begin(root.magicReplyDraft, root.magicFontPath,
                                    root.magicNotebookAnswerFontPixels, root.magicNotebookLinePitch)
        }
    }
    Timer {
        id: magicAnswerHoldTimer
        interval: 3600
        repeat: false
        onTriggered: magicAnswerFadeTimer.start()
    }
    Timer {
        id: magicAnswerFadeTimer
        interval: 1
        repeat: false
        onTriggered: magicPage.replyInkCanvas.fade()
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
        var local = softKeyboardPanel.handwritingPad.mapFromItem(root.contentItem,
                                                       Number(x) || 0,
                                                       Number(y) || 0)
        return ({
            "x": root.clamp(local.x, 3, Math.max(3, softKeyboardPanel.handwritingPad.width - 3)),
            "y": root.clamp(local.y, 3, Math.max(3, softKeyboardPanel.handwritingPad.height - 3))
        })
    }

    function keyboardHandwritingContains(x, y) {
        var local = softKeyboardPanel.handwritingPad.mapFromItem(root.contentItem,
                                                       Number(x) || 0,
                                                       Number(y) || 0)
        return local.x >= 0 && local.x <= softKeyboardPanel.handwritingPad.width
            && local.y >= 0 && local.y <= softKeyboardPanel.handwritingPad.height
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
        softKeyboardPanel.handwritingInk.beginStroke(point.x, point.y, "#111111", 5, 1, true)
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
        softKeyboardPanel.handwritingInk.appendPoint(point.x, point.y)
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
        softKeyboardPanel.handwritingInk.finishStroke()
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
        softKeyboardPanel.handwritingInk.finishStroke()
    }

    function keyboardClearHandwriting() {
        root.keyboardHandwritingStrokes = []
        root.keyboardHandwritingCurrentStroke = []
        root.keyboardHandwritingCandidates = []
        root.keyboardCandidatePage = 0
        root.keyboardHandwritingStatus = ""
        root.keyboardHandwritingDrawing = false
        if (softKeyboardPanel.handwritingInk) {
            softKeyboardPanel.handwritingInk.clearLive()
        }
    }

    function keyboardUndoHandwritingStroke() {
        if (root.keyboardHandwritingStrokes.length === 0) {
            root.keyboardHandwritingStatus = "没有可撤销的笔画"
            return
        }
        softKeyboardPanel.handwritingInk.clearLive()
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
        if (keyboardTarget === shelfPage.discoverSearchInputField) {
            discoverStore.search(shelfPage.discoverSearchInputField.text)
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
        readerPage.inkCanvas.clearLive()
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
        var lx = Math.round(Number(x) || 0) - readerPage.settingsPanel.x
        var ly = Math.round(Number(y) || 0) - readerPage.settingsPanel.y
        if (lx < 0 || ly < 0 || lx > readerPage.settingsPanel.width || ly > readerPage.settingsPanel.height) {
            return false
        }
        if (root.readerPointInRect(lx, ly, readerPage.settingsPanel.width - 68, 24, 60, 60)) {
            root.closeReaderSettings()
            return true
        }

        var fontStepperX = Math.round((readerPage.settingsPanel.width - 246) / 2)
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

        var fontChoices = ["系统", "微米黑", "正黑", "霞鹜文楷", "思源黑体", "思源宋体", "寒蝉正楷", "寒蝉活宋", "马善政", "刘建毛草", "智勇行", "龙藏体", "站酷快乐"]
        for (var f = 0; f < fontChoices.length; f++) {
            var fontX = 124 + f * (78 + 3)
            if (root.readerPointInRect(lx, ly, fontX, 552, 78, 56)) {
                root.readerFontChoice = fontChoices[f]
                root.applyReaderSettingChange(true)
                return true
            }
        }

        var weightValues = [Font.DemiBold, Font.Bold]
        for (var w = 0; w < weightValues.length; w++) {
            var weightX = 840 + w * (52 + 6)
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

        if (readerPage.settingsPanel.height > 720
                && root.readerPointInRect(lx, ly, 150, 690, readerPage.settingsPanel.width - 270, 50)) {
            root.setReaderProgressPercent((lx - 150) / Math.max(1, readerPage.settingsPanel.width - 270) * 100)
            return true
        }
        if (readerPage.settingsPanel.height > 780
                && root.readerPointInRect(lx, ly, readerPage.settingsPanel.width - 164, 746, 136, 58)) {
            networkStore.reload()
            return true
        }
        if (readerPage.settingsPanel.height > 812
                && root.readerPointInRect(lx, ly, 24, 790, 128, 58)) {
            root.exitReaderToShelf()
            return true
        }
        if (readerPage.settingsPanel.height > 812
                && root.readerPointInRect(lx, ly, 164, 790, 128, 58)) {
            root.forceReaderRefresh += 1
            return true
        }
        if (readerPage.settingsPanel.height > 812
                && root.readerPointInRect(lx, ly, 304, 790, 128, 58)
                && !progressSyncStore.running) {
            progressSyncStore.syncProgress(root.currentBookId, root.currentReaderProgressPercent(), root.currentReaderSummaryText(), root.currentReaderElapsedSeconds())
            return true
        }
        if (readerPage.settingsPanel.height > 812
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
            && (root.screenName === "reader" || root.screenName === "magic"
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
            if (root.screenName === "magic") {
                root.magicBegin(x, y)
                return
            }
            if (!root.beginKeyboardHandwritingStroke(x, y)) {
                root.beginStylusStroke(x, y, pressure)
            }
        }
        function onStylusMoved(x, y, pressure) {
            if (root.screenName === "magic") {
                root.magicAppend(x, y)
                return
            }
            if (!root.appendKeyboardHandwritingStroke(x, y)) {
                root.appendStylusStroke(x, y, pressure)
            }
        }
        function onStylusReleased(x, y, pressure) {
            if (root.screenName === "magic") {
                root.magicEnd(x, y)
                return
            }
            if (!root.endKeyboardHandwritingStroke(x, y)) {
                root.endStylusStroke(x, y, pressure)
            }
        }
        function onStylusTapped(x, y) {
            if (root.screenName === "magic" && root.magicMenuPenTap) {
                root.magicMenuPenTap = false
                root.magicMenuOpen = !root.magicMenuOpen
                return
            }
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

    ShelfPage {
        id: shelfPage
        appRoot: root
    }

    MagicNotebookPage {
        id: magicPage
        appRoot: root
        answerHoldTimer: magicAnswerHoldTimer
    }

    BookDetailPage {
        id: detailPage
        appRoot: root
    }

    ReaderPage {
        id: readerPage
        appRoot: root
        replyFontFamily: lxgwWenKaiFont.name
        replyFontReady: lxgwWenKaiFont.status === FontLoader.Ready
    }

    SoftKeyboardPanel {
        id: softKeyboardPanel
        appRoot: root
    }

    SleepCoverScreen {
        id: sleepCoverScreen
        anchors.fill: parent
        visible: root.sleepOverlayVisible
        z: 100
        coverSource: root.sleepCoverSource
        bookTitle: root.sleepBookTitle
        readerFontFamily: root.readerFontFamily
        inkColor: root.inkColor
        coverAspectRatio: root.coverAspectRatio
    }

    QrLoginScreen {
        id: qrLoginScreen
        anchors.fill: parent
        visible: root.showQrLogin
        z: 95
        inkColor: root.inkColor
        brandGreenDark: root.brandGreenDark
        loginConfirmUrl: accountStore.loginConfirmUrl
        loginRunning: accountStore.loginRunning
        loginStatusText: accountStore.loginStatusText
        onCancelRequested: root.closeQrLogin()
        onRetryRequested: root.openQrLogin()
    }

}

import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const fetchNotesTool = read('apps/weread-move/tools/fetch-notes.lua');
assert(fetchNotesTool.includes('"popular"'), 'notes helper must support a popular mode for community marks');
assert(fetchNotesTool.includes('client:gateway("/book/bestbookmarks"'), 'popular mode must fetch popular WeRead highlights');
assert(fetchNotesTool.includes('client:gateway("/book/readreviews"'), 'popular mode must fetch reader comments below popular highlights');
assert(fetchNotesTool.includes('mode == "range_reviews"'), 'notes helper must fetch one tapped underline review range on demand');
assert(fetchNotesTool.includes('run_range_reviews'), 'notes helper must keep single-range review fetching separate from page mark discovery');
assert(fetchNotesTool.includes('client:gateway("/book/underlines"'), 'chapter mode must fetch per-chapter underline ranges for in-text comments');
assert(fetchNotesTool.includes('mode == "chapter"'), 'notes helper must expose a chapter mode for current-page underline comments');
assert(fetchNotesTool.includes('Content.fetch_catalog'), 'chapter mode must map local chapter indexes to real WeRead chapterUid values');
assert(fetchNotesTool.includes('chapter_key') && fetchNotesTool.includes('== chapter_key'), 'chapter mode must prefer exact chapterUid matches over local chapter indexes');
assert(fetchNotesTool.includes('chapter_key:match("^index:(%d+)$")'), 'chapter mode must distinguish a local catalog index from a numeric chapterUid');
assert(fetchNotesTool.includes('range_text_fallback'), 'chapter mode must emit underline heat-map rows even when WeRead returns no markText');
assert(fetchNotesTool.includes('plain_offsets_for_range'), 'chapter mode must map WeRead XHTML ranges to plain-text offsets');
assert(fetchNotesTool.includes('local function utf8_slice') && fetchNotesTool.includes('utf8_slice(xhtml, start_i, end_i)'), 'WeRead character ranges must be sliced by UTF-8 characters instead of raw bytes');
assert(!fetchNotesTool.includes('xhtml:sub(start_i + 1, math.min(#xhtml, end_i))'), 'chapter mode must not interpret WeRead character offsets as Lua byte indexes');
assert(fetchNotesTool.includes('plainStart = plain_start') && fetchNotesTool.includes('plainEnd = plain_end'), 'chapter mode must emit helper-computed plain offsets for range-only comments');
assert(fetchNotesTool.includes('mark_text:find("<", 1, true)') && fetchNotesTool.includes('class='), 'chapter mode must suppress broken XHTML-fragment fallback text');
assert(fetchNotesTool.includes('valid_utf8(clean)') && fetchNotesTool.includes('utf8_prefix(clean, 80)'), 'chapter mode must not emit split UTF-8 fragments as underline anchors');
assert(fetchNotesTool.includes('anchorText = mark_text'), 'chapter mode must expose a dedicated local-text anchor for QML correction');
assert(fetchNotesTool.includes('local page_start = tonumber(arg and arg[4])'), 'chapter mode must accept a current-page plain-text start offset');
assert(fetchNotesTool.includes('local page_end = tonumber(arg and arg[5])'), 'chapter mode must accept a current-page plain-text end offset');
assert(fetchNotesTool.includes('overlaps_page_window'), 'chapter mode must filter emitted underlines to the current page window');
assert(fetchNotesTool.includes('pageStart = page_start') && fetchNotesTool.includes('pageEnd = page_end'), 'chapter mode must echo the page window so QML can map comments to the visible page');
assert(!fetchNotesTool.includes('range ~= "" and mark_text ~= "" and count < max_ranges'), 'chapter mode must not drop title/comment underlines just because /book/underlines omits text');
assert(fetchNotesTool.includes('kind = "popular_mark"'), 'popular mode must emit popular_mark rows');
assert(fetchNotesTool.includes('kind = "popular_review"'), 'popular mode must emit popular_review rows');
assert(fetchNotesTool.includes('RM_WEREAD_MARK_LIMIT'), 'popular mode must let the Qt reader request a larger bounded mark window for page-by-page comments');
assert(fetchNotesTool.includes('local max_marks = math.min(120'), 'popular mode must keep per-book prefetch bounded for e-ink reading while covering more pages than the top few highlights');
assert(fetchNotesTool.indexOf('kind = "popular_mark"') < fetchNotesTool.indexOf('client:gateway("/book/readreviews"'), 'popular marks must stream before slow review detail calls');
assert(fetchNotesTool.includes('RM_WEREAD_SKIP_REVIEWS'), 'popular comment helper must support a fast marks-only diagnostic mode');

const notesStoreHeader = read('apps/weread-qt/notes_store.h');
assert(notesStoreHeader.includes('Q_PROPERTY(QVariantList popularMarks'), 'NotesStore must expose popular community marks');
assert(notesStoreHeader.includes('Q_INVOKABLE void refreshPopularMarks'), 'NotesStore must refresh popular marks from QML');
assert(notesStoreHeader.includes('Q_INVOKABLE void bufferPopularMarks'), 'NotesStore must expose a non-blocking popular mark buffer entrypoint');
assert(notesStoreHeader.includes('Q_INVOKABLE void cancelPopularMarks'), 'NotesStore must let page turns cancel stale underline-comment loads');
assert(notesStoreHeader.includes('Q_INVOKABLE bool popularMarksBuffered'), 'NotesStore must let QML skip repeated popular mark fetches');
assert(notesStoreHeader.includes('Q_INVOKABLE void refreshPopularReviews'), 'NotesStore must expose on-demand review loading for a tapped underline');
assert(notesStoreHeader.includes('loadCachedPopularMarks') && notesStoreHeader.includes('persistPopularMarksCache'), 'NotesStore must persist page underline ranges across app restarts');
assert(notesStoreHeader.includes('loadCachedPopularReviews') && notesStoreHeader.includes('persistPopularReviewsCache'), 'NotesStore must persist tapped review detail across app restarts');

const notesStoreCpp = read('apps/weread-qt/notes_store.cpp');
assert(notesStoreCpp.includes('m_popularMarks'), 'NotesStore must retain popular mark rows');
assert(notesStoreCpp.includes('popular_mark') && notesStoreCpp.includes('popular_review'), 'NotesStore must parse popular marks and nested reviews');
assert(notesStoreCpp.includes('popularMarksBuffered') && notesStoreCpp.includes('bufferPopularMarks'), 'NotesStore must implement idempotent popular mark buffering');
assert(notesStoreCpp.includes('m_popularBookId'), 'NotesStore must track which book the popular mark cache belongs to');
assert(notesStoreCpp.includes('m_processTimeoutTimer'), 'NotesStore must time out stalled note/comment helper calls');
assert(notesStoreCpp.includes('笔记加载超时'), 'NotesStore timeout must surface a Chinese failure state instead of hiding comments forever');
assert(notesStoreCpp.includes('m_popularMarks[i] = mark'), 'popular review rows must attach to already visible popular marks');
assert(notesStoreCpp.includes('mark.insert(QStringLiteral("reviews"), QVariantList())'), 'popular mark rows must normalize Lua empty tables into a real review list');
const appendRowFunction = notesStoreCpp.slice(notesStoreCpp.indexOf('void NotesStore::appendRow'), notesStoreCpp.indexOf('void NotesStore::setState'));
assert(appendRowFunction.includes('const bool notifyChanged = kind != QStringLiteral("popular_mark")') && appendRowFunction.includes('kind != QStringLiteral("popular_review")'), 'streamed comment rows must be batched instead of invalidating the reader for every returned review');
assert(appendRowFunction.includes('if (notifyChanged)') && appendRowFunction.includes('emit changed();'), 'non-reader note rows must retain incremental update notifications');
const appendOutputFunction = notesStoreCpp.slice(notesStoreCpp.indexOf('void NotesStore::appendOutput'), notesStoreCpp.indexOf('void NotesStore::finishProcess'));
const doneStateStart = appendOutputFunction.indexOf('state == QStringLiteral("done")');
const doneStateEnd = appendOutputFunction.indexOf('state == QStringLiteral("error")', doneStateStart);
const doneStateBranch = appendOutputFunction.slice(doneStateStart, doneStateEnd);
assert(!doneStateBranch.includes('setState(m_running'), 'helper completion must wait for QProcess finish and notify the reader only once');
assert(notesStoreCpp.includes('m_cancelledForPopularRestart'), 'NotesStore must distinguish intentional page-turn cancellation from a real failure');
assert(notesStoreCpp.includes('m_process.kill()'), 'NotesStore must interrupt stale current-page comment loads when the reader moves on');
assert(notesStoreCpp.includes('pageStart') && notesStoreCpp.includes('pageEnd'), 'NotesStore must parse visible page offsets from the social prefetch key');
assert(notesStoreCpp.includes('args << pageStart << pageEnd'), 'NotesStore must pass visible page offsets to the Lua note helper');
assert(notesStoreCpp.includes('RM_WEREAD_SKIP_REVIEWS') && notesStoreCpp.includes('arguments.first() == QStringLiteral("chapter")'), 'current-page mark discovery must skip slow bulk review detail requests');
assert(notesStoreCpp.includes('QStringLiteral("range_reviews")'), 'NotesStore must invoke the single-range review helper mode');
assert(notesStoreCpp.includes('social-comments-cache.json'), 'social comment cache must live in the app data directory');
assert(notesStoreCpp.includes('24 * 60 * 60'), 'social comment cache must avoid repeated online requests for 24 hours');
assert(notesStoreCpp.includes('QStringLiteral("contexts")') && notesStoreCpp.includes('QStringLiteral("reviews")'), 'social cache must separate page mark contexts from range review details');
assert(notesStoreCpp.indexOf('loadCachedPopularMarks(trimmed, key)') < notesStoreCpp.indexOf('m_popularContextKey = key'), 'page buffering must check persistent cache before starting a network helper');
assert(notesStoreCpp.includes('loadCachedPopularReviews(trimmedBookId, trimmedChapterUid, trimmedRange)'), 'tapped comments must check persistent review cache before a network request');
assert(notesStoreCpp.includes('^chapterIndex:(\\\\d+)') && notesStoreCpp.includes('QStringLiteral("index:%1")'), 'NotesStore must preserve local-index intent instead of sending a bare numeric UID');

const qml = read('apps/weread-qt/Main.qml');
const socialAnchor = read('apps/weread-qt/SocialAnchor.js');
assert(qml.includes('showReaderSocialPopup'), 'reader must track the social comment popup');
assert(qml.includes('readerPopularMarksForRange'), 'reader must map popular marks onto visible text ranges');
assert(!qml.includes("href='social:"), 'inline comments must not rely on Qt rich-text links that can only draw solid underlines');
assert(!qml.includes('text-decoration:underline'), 'inline comments must not leave a solid HTML underline beneath the dashed overlay');
assert(!qml.includes('text-decoration:none'), 'popular marks must not suppress the anchor underline on Qt RichText');
assert(qml.includes("href='socialchapter'"), 'chapter comments must appear only as a chapter-end entrypoint');
assert(qml.includes('readerChapterSocialRows'), 'chapter comment entrypoint must aggregate current-chapter rows for the popup');
assert(qml.includes('openReaderChapterSocialPopup'), 'chapter comment entrypoint must open the same compact popup');
assert(qml.includes('readerPopularMarkSearchBounds'), 'inline mark matching must be bounded to the current chapter or current page context');
assert(qml.includes('import "SocialAnchor.js" as SocialAnchor'), 'reader must use the executable social-anchor resolver shared with regression tests');
assert(qml.includes('socialAnchorForPopularMark'), 'reader must resolve both underline endpoints through the same corrected anchor');
assert(socialAnchor.includes('normalizedMatch') && socialAnchor.includes('chapter-title'), 'social anchor resolver must tolerate whitespace drift and title-only ranges');
assert(socialAnchor.includes('return invalidResult(approximate)'), 'unreliable remote ranges must be suppressed instead of drawn at raw offsets');
assert(qml.includes('readerSocialDisplayText'), 'inline social popup must show local range text when the API only gives a range');
const richReaderTextFunction = qml.slice(qml.indexOf('function richReaderText'), qml.indexOf('function readerFootnoteByIndex'));
assert(!richReaderTextFunction.includes('readerPopularMarksForRange'), 'review-detail updates must not invalidate and re-layout the body RichText');
assert(qml.includes('readerSocialDashRectsForPage'), 'reader must derive dashed underline geometry from corrected text ranges');
assert(qml.includes('id: readerSocialGeometryRefreshTimer') && qml.includes('readerSocialGeometryToken'), 'reader must recompute dash geometry after the RichText layout settles');
assert(qml.includes('property var readerSocialDashRects: []') && qml.includes('property var readerSocialHitRects: []'), 'reader must cache social geometry instead of recalculating glyph positions from input bindings');
assert(qml.includes('rebuildReaderSocialGeometry'), 'reader must rebuild cached social geometry only after the RichText layout settles');
assert(qml.includes('reader-social-geometry dashes='), 'reader must log rendered dash counts separately from matched comment rows');
assert(qml.includes('readerDocumentPositionForTextOffset'), 'reader must map corrected body offsets into the rendered TextEdit document');
assert(qml.includes('readerBodyText.positionToRectangle(position)'), 'dashed underlines must use actual rendered glyph positions instead of estimated line widths');
assert(qml.includes('readerSocialHitRectsForPage'), 'reader must create hit rectangles for visible underline comments above page-turn areas');
assert(qml.includes('openReaderSocialPopupAtPoint'), 'reader must expose coordinate-based social comment activation for stylus taps');
assert(qml.includes('root.openReaderSocialPopupAtPoint(x, y)'), 'stylus taps must try social underline hit regions before ordinary reader gestures');
assert(qml.includes('openReaderSocialPopup'), 'reader must open a community popup from a social link');
assert(qml.includes('closeReaderSocialPopup'), 'reader must close the community popup');
assert(qml.includes('readerSocialPopupPanel'), 'reader must render a dedicated community comment popup');
const socialPopupSnippet = qml.slice(qml.indexOf('id: readerSocialPopupPanel'), qml.indexOf('id: readerStylusToolBar'));
assert(socialPopupSnippet.includes('height: Math.round(root.height * 0.80)'), 'community comments must use roughly 80 percent of the screen height');
assert(socialPopupSnippet.includes('font.pixelSize: 30'), 'community comment body must use a clearly readable e-ink font size');
assert(qml.includes('id: readerSocialTouchLayer'), 'reader must install a dedicated underline-comment touch layer');
assert(qml.includes('model: root.readerSocialHitRects'), 'underline-comment delegates must consume cached geometry without binding to glyph-by-glyph recalculation');
assert(!qml.match(/function openReaderSocialPopupAtPoint[\s\S]*?var rects = root\.readerSocialHitRectsForPage\(\)/), 'stylus hit testing must use cached geometry without recalculating TextEdit positions');
assert(qml.includes('onReleased: root.openReaderSocialPopup(socialUnderlineDelegate.socialIndex'), 'underline-comment hit rectangles must open after release while still blocking page-turn gestures');
assert(qml.includes('id: readerSocialPopupOutsideCloseArea') && qml.includes('onPressed: root.closeReaderSocialPopup()'), 'a stuck social popup must close immediately on an outside press');
assert(qml.includes('reader-social-open index='), 'reader must log successful social popup activation for device diagnostics');
assert(qml.includes('selfTestMode === "reader-social"') && qml.includes('reader-social-selftest=ok'), 'reader must expose a device self-test that exercises cached social geometry');
assert(qml.includes('selfTestMode === "reader-social-clicks"') && qml.includes('reader-social-clicks-selftest=ok'), 'reader must automate repeated underline comment opens and closes on the device');
assert(qml.includes('id: readerSocialClicksSelfTestTimer') && qml.includes('maxLagMs'), 'repeated-comment self-test must measure main-thread heartbeat stalls');
assert(qml.includes('maxLagMs > 900'), 'repeated-comment self-test must reject input stalls that are visible on e-ink');
assert(qml.includes('notesStore.refreshPopularReviews'), 'opening an underline popup must request only that underline review detail');
assert(qml.includes('refreshActiveReaderSocialMark'), 'open popup must update when asynchronous review rows arrive');
assert(qml.includes('index * 16') && qml.includes('Math.min(9'), 'reader must paint short black dash segments instead of a continuous underline');
assert(qml.includes('readerSocialPrefetchTimer'), 'reader must use a delayed timer to prefetch community comments');
assert(qml.includes('interval: 3000'), 'reader comment loading must wait 3 seconds on e-ink before fetching');
assert(qml.includes('scheduleReaderSocialPrefetch'), 'reader must schedule social prefetch after page changes');
assert(qml.includes('readerSocialPrefetchKey'), 'reader social prefetch must be keyed by visible page/chapter instead of only by book');
assert(qml.includes('readerSocialPageToken'), 'reader social loading must invalidate stale page requests after a page turn');
assert(qml.includes('root.readerSocialPageToken += 1'), 'page turns must bump the social request token to ignore old work');
assert(qml.includes('currentReaderSocialPrefetchKey'), 'reader must compute a current-page comment prefetch key');
assert(qml.includes('chapterUid:') && qml.includes('chapter.chapterUid'), 'reader must prefetch underline comments by real WeRead chapterUid when available');
assert(qml.includes('return "chapterIndex:" + (chapterIndex + 1)'), 'reader must label fallback chapter numbers as local indexes, not ambiguous numeric UIDs');
assert(!qml.includes('return "chapter:" + (chapterIndex + 1)'), 'reader must not emit the ambiguous legacy numeric chapter key');
assert(qml.includes('chapterRelativePageStart') && qml.includes('chapterRelativePageEnd'), 'reader social prefetch key must encode chapter-relative visible page offsets');
assert(!qml.includes('var bucket = Math.floor'), 'reader comment prefetch must fetch the visible chapter, not invent page buckets unsupported by WeRead');
assert(qml.includes('notesStore.bufferPopularMarksForContext(root.currentBookId'), 'reader must ask NotesStore for a larger context-aware comment cache');
assert(qml.includes('notesStore.bufferPopularMarksForContext(root.currentBookId'), 'reader must warm current-chapter underline comments through the non-blocking buffer API');

const socialClicksDeviceScript = read('scripts/test-weread-social-clicks-on-move.sh');
assert(socialClicksDeviceScript.includes('SELFTEST_MODE=reader-social-clicks'), 'device script must run the repeated social-comment self-test mode');
assert(socialClicksDeviceScript.includes("jq '.reviews = {}'"), 'device script must force real review-detail requests instead of only testing cache hits');
assert(socialClicksDeviceScript.includes('reader-social-clicks-selftest=ok'), 'device script must require the repeated-click success marker');
assert(socialClicksDeviceScript.includes('${CACHE_PATH}.test-backup'), 'device script must preserve and restore the user comment cache');
assert(!qml.includes('notesStore.bufferPopularMarksForContext(bookId'), 'opening a book must not immediately load comments before the page settles');
assert(!qml.includes('notesStore.bufferPopularMarksForContext(root.currentBookId, root.currentReaderSocialPrefetchKey())'), 'reader catalog must not expose manual underline refresh controls');
const enterReaderIndex = qml.indexOf('function enterReaderForBook');
const enterReaderSnippet = qml.slice(enterReaderIndex, enterReaderIndex + 1800);
assert(!enterReaderSnippet.includes('notesStore.refreshBookNotes(bookId)'), 'opening a reader must not let full-book note sync block current-page underline comments');
assert(qml.includes('id: readerSocialRefreshOnNotesChanged'), 'reader must listen for async comment rows and refresh visible rich text');
assert(qml.includes('id: readerSocialRefreshDebounceTimer'), 'reader must debounce async comment row refreshes so a comment batch repaints once');
const socialConnectionIndex = qml.indexOf('id: readerSocialRefreshOnNotesChanged');
const socialConnectionSnippet = qml.slice(socialConnectionIndex, qml.indexOf('Timer {', socialConnectionIndex));
assert(socialConnectionSnippet.includes('readerSocialRefreshDebounceTimer.restart()'), 'comment row changes must schedule one debounced repaint');
assert(!socialConnectionSnippet.includes('root.forceReaderRefresh += 1'), 'comment row changes must not repaint RichText once per streamed row');
const socialDebounceSnippet = qml.slice(qml.indexOf('id: readerSocialRefreshDebounceTimer'), qml.indexOf('function ensureReaderPagination'));
assert(socialDebounceSnippet.includes('root.forceReaderRefresh += 1'), 'debounced comment refresh must force RichText to re-evaluate visible underline links');
assert(socialDebounceSnippet.includes('readerPopularMarksForRange(root.currentReaderTextStart, root.currentReaderTextEnd)'), 'debounced comment refresh must log visible-page matches for debugging');
assert(socialAnchor.includes('plainStart') && socialAnchor.includes('pageStart'), 'reader must accept helper-provided plain text offsets as approximate underline hints');
assert(socialAnchor.includes('approximateOffset') && socialAnchor.includes('currentStart') && socialAnchor.includes('pageStart'), 'reader must retain page-window offsets only as approximate search hints');
assert(!qml.includes('if (!networkStore.connected) {\n                return\n            }'), 'popular comment prefetch must not be completely skipped by a stale network status flag');
assert(!qml.includes('notesStore.refreshPopularMarks(bookId)'), 'opening a book must not block on immediate community comment refresh');
assert(qml.includes('notesStore.popularMarks'), 'reader must consume NotesStore popular marks');
assert(qml.includes('划线评论'), 'reader UI must label the feature as inline underline comments instead of generic hot comments');
const titleBranchIndex = qml.indexOf("class='reader-title'");
const titleBranchSnippet = qml.slice(titleBranchIndex, titleBranchIndex + 700);
assert(titleBranchSnippet.includes('root.richReaderText(para, paraGlobalStart)'), 'reader chapter titles must also render inline underline comments');

const progressSyncStoreHeader = read('apps/weread-qt/progress_sync_store.h');
assert(progressSyncStoreHeader.includes('int elapsedSeconds'), 'ProgressSyncStore must accept elapsed reading seconds');

const progressSyncStoreCpp = read('apps/weread-qt/progress_sync_store.cpp');
assert(progressSyncStoreCpp.includes('QString::number(qMax(0, elapsedSeconds))'), 'ProgressSyncStore must pass elapsed seconds to the helper');

const syncProgressTool = read('apps/weread-move/tools/sync-progress.lua');
assert(syncProgressTool.includes('[elapsedSeconds]'), 'sync-progress helper usage must document elapsed seconds');
assert(syncProgressTool.includes('elapsed_seconds = elapsed_seconds'), 'sync-progress helper must put elapsed seconds into read payload');

console.log('reader social comment validation ok');

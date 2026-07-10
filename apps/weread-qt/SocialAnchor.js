.pragma library

function clamp(value, lower, upper) {
    return Math.max(lower, Math.min(upper, value))
}

function finiteInteger(value, fallback) {
    var parsed = Number(value)
    return isNaN(parsed) || !isFinite(parsed) ? fallback : Math.floor(parsed)
}

function compactLength(value) {
    return String(value || "").replace(/\s+/g, "").length
}

function cleanAnchorText(value) {
    var anchor = String(value || "").replace(/\s+/g, " ").trim()
    if (anchor.length < 4 || anchor.indexOf("�") >= 0 || /<[^>]*>|class\s*=/i.test(anchor)) {
        return ""
    }
    return anchor
}

function approximateOffset(mark, context) {
    var plainStart = finiteInteger((mark || {}).plainStart, -1)
    if (plainStart < 0) {
        return -1
    }
    var pageStart = finiteInteger((mark || {}).pageStart, -1)
    if (pageStart >= 0) {
        return finiteInteger(context.currentStart, 0) + plainStart - pageStart
    }
    return finiteInteger(context.chapterStart, 0) + plainStart
}

function normalizedMatch(body, anchor, start, end, approximate) {
    var safeBody = String(body || "")
    var safeStart = clamp(finiteInteger(start, 0), 0, safeBody.length)
    var safeEnd = clamp(finiteInteger(end, safeBody.length), safeStart, safeBody.length)
    var needle = String(anchor || "").replace(/\s+/g, "")
    if (needle.length < 4 || safeEnd <= safeStart) {
        return { "start": -1, "end": -1 }
    }

    var compact = ""
    var offsets = []
    for (var i = safeStart; i < safeEnd; i++) {
        var ch = safeBody.charAt(i)
        if (/\s/.test(ch)) {
            continue
        }
        compact += ch
        offsets.push(i)
    }

    var bestStart = -1
    var bestEnd = -1
    var bestDistance = Number.MAX_VALUE
    var searchFrom = 0
    while (searchFrom <= compact.length - needle.length) {
        var position = compact.indexOf(needle, searchFrom)
        if (position < 0 || position + needle.length > offsets.length) {
            break
        }
        var localStart = offsets[position]
        var localEnd = offsets[position + needle.length - 1] + 1
        var distance = approximate >= 0 ? Math.abs(localStart - approximate) : localStart - safeStart
        if (distance < bestDistance) {
            bestStart = localStart
            bestEnd = localEnd
            bestDistance = distance
        }
        searchFrom = position + 1
    }
    return { "start": bestStart, "end": bestEnd }
}

function result(match, source, approximate) {
    return {
        "start": finiteInteger(match.start, -1),
        "end": finiteInteger(match.end, -1),
        "source": source || "",
        "approximate": finiteInteger(approximate, -1)
    }
}

function invalidResult(approximate) {
    return result({ "start": -1, "end": -1 }, "", approximate)
}

function resolve(body, mark, context) {
    var safeBody = String(body || "")
    var safeContext = context || {}
    var currentStart = clamp(finiteInteger(safeContext.currentStart, 0), 0, safeBody.length)
    var currentEnd = clamp(finiteInteger(safeContext.currentEnd, safeBody.length), currentStart, safeBody.length)
    var chapterStart = clamp(finiteInteger(safeContext.chapterStart, currentStart), 0, safeBody.length)
    var chapterEnd = clamp(finiteInteger(safeContext.chapterEnd, safeBody.length), chapterStart, safeBody.length)
    var approximate = approximateOffset(mark, {
        "currentStart": currentStart,
        "chapterStart": chapterStart
    })
    var anchor = cleanAnchorText((mark || {}).anchorText || (mark || {}).text)

    if (anchor !== "") {
        var pageMatch = normalizedMatch(safeBody, anchor, currentStart, currentEnd, approximate)
        if (pageMatch.start >= 0) {
            return result(pageMatch, "text", approximate)
        }
        var chapterMatch = normalizedMatch(safeBody, anchor, chapterStart, chapterEnd, approximate)
        if (chapterMatch.start >= 0) {
            return result(chapterMatch, "text", approximate)
        }
        return invalidResult(approximate)
    }

    var title = cleanAnchorText(safeContext.chapterTitle || (mark || {}).chapter)
    var titleDistance = approximate >= 0 ? approximate - chapterStart : Number.MAX_VALUE
    var titleIsVisible = chapterStart >= currentStart && chapterStart < currentEnd
    var titleRangeLimit = Math.max(64, compactLength(title) * 4)
    if ((mark || {}).rangeOnly && title !== "" && titleIsVisible
            && titleDistance >= 0 && titleDistance <= titleRangeLimit) {
        var titleMatch = normalizedMatch(safeBody, title, chapterStart, currentEnd, chapterStart)
        if (titleMatch.start >= 0) {
            return result(titleMatch, "chapter-title", approximate)
        }
    }

    return invalidResult(approximate)
}

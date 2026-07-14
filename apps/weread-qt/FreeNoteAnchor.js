.pragma library

function number(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) ? parsed : fallback
}

function strokeBounds(points) {
    var left = Infinity
    var top = Infinity
    var right = -Infinity
    var bottom = -Infinity
    for (var index = 0; index < (points || []).length; index++) {
        var point = points[index] || ({})
        var x = number(point.x, 0)
        var y = number(point.y, 0)
        left = Math.min(left, x)
        top = Math.min(top, y)
        right = Math.max(right, x)
        bottom = Math.max(bottom, y)
    }
    if (!isFinite(left)) {
        return ({ "left": 0, "top": 0, "right": 0, "bottom": 0, "width": 0, "height": 0 })
    }
    return ({ "left": left, "top": top, "right": right, "bottom": bottom,
              "width": Math.max(1, right - left), "height": Math.max(1, bottom - top) })
}

function distanceToBox(bounds, box) {
    var centerX = (bounds.left + bounds.right) / 2
    var centerY = (bounds.top + bounds.bottom) / 2
    var dx = centerX < box.xStart ? box.xStart - centerX : (centerX > box.xEnd ? centerX - box.xEnd : 0)
    var dy = centerY < box.yStart ? box.yStart - centerY : (centerY > box.yEnd ? centerY - box.yEnd : 0)
    return dy * 3 + dx
}

function paragraphRange(body, position) {
    var source = String(body || "")
    var safe = Math.max(0, Math.min(source.length, Math.floor(number(position, 0))))
    var start = source.lastIndexOf("\n\n", Math.max(0, safe - 1))
    start = start < 0 ? 0 : start + 2
    var end = source.indexOf("\n\n", safe)
    end = end < 0 ? source.length : end
    return ({ "textStart": start, "textEnd": Math.max(start + 1, end) })
}

function compact(value, maximum) {
    return String(value || "").replace(/\s+/g, " ").trim().slice(0, maximum)
}

function anchor(points, boxes, body, pageIndex, pageWidth, pageHeight) {
    var bounds = strokeBounds(points)
    var best = null
    var bestDistance = Infinity
    for (var index = 0; index < (boxes || []).length; index++) {
        var box = boxes[index] || ({})
        var distance = distanceToBox(bounds, box)
        if (distance < bestDistance) {
            best = box
            bestDistance = distance
        }
    }
    var lineHeight = best ? Math.max(1, number(best.yEnd, 0) - number(best.yStart, 0)) : 1
    var closeEnough = best && bestDistance <= Math.max(72, lineHeight * 3.2)
    var fallback = {
        "pageIndex": Math.max(0, Math.floor(number(pageIndex, 0))),
        "x": bounds.left / Math.max(1, number(pageWidth, 1)),
        "y": bounds.top / Math.max(1, number(pageHeight, 1)),
        "width": bounds.width / Math.max(1, number(pageWidth, 1)),
        "height": bounds.height / Math.max(1, number(pageHeight, 1))
    }
    if (!closeEnough) {
        return ({ "anchor": { "kind": "page-free", "textStart": -1, "textEnd": -1, "confidence": 0 }, "fallback": fallback, "bounds": bounds })
    }
    var range = paragraphRange(body, best.textStart)
    var source = String(body || "")
    return ({
        "anchor": {
            "kind": "paragraph",
            "textStart": range.textStart,
            "textEnd": range.textEnd,
            "quote": compact(source.slice(range.textStart, range.textEnd), 96),
            "prefix": compact(source.slice(Math.max(0, range.textStart - 32), range.textStart), 32),
            "suffix": compact(source.slice(range.textEnd, range.textEnd + 32), 32),
            "confidence": Math.max(1, Math.round(100 - bestDistance / Math.max(1, lineHeight) * 12))
        },
        "fallback": fallback,
        "bounds": bounds
    })
}

function normalize(points, bounds) {
    var result = []
    for (var index = 0; index < (points || []).length; index++) {
        var point = points[index] || ({})
        result.push({
            "x": (number(point.x, bounds.left) - bounds.left) / Math.max(1, bounds.width),
            "y": (number(point.y, bounds.top) - bounds.top) / Math.max(1, bounds.height),
            "pressure": Math.max(0, number(point.pressure, 0))
        })
    }
    return result
}

function flatten(strokes) {
    var result = []
    for (var strokeIndex = 0; strokeIndex < (strokes || []).length; strokeIndex++) {
        var stroke = strokes[strokeIndex] || []
        for (var pointIndex = 0; pointIndex < stroke.length; pointIndex++) {
            result.push(stroke[pointIndex])
        }
    }
    return result
}

function normalizeStrokes(strokes, bounds) {
    var result = []
    for (var strokeIndex = 0; strokeIndex < (strokes || []).length; strokeIndex++) {
        result.push(normalize(strokes[strokeIndex], bounds))
    }
    return result
}

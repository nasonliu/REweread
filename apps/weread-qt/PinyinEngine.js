.pragma library
.import "PinyinLexicon.js" as Lexicon

// Project-specific entries supplement the Apache-2.0 Rime vocabulary. Keep
// these small and auditable; user text must never be written into this table.
var PROJECT_PHRASES = {
    "weidu": ["微信读书"],
    "weixindushu": ["微信读书"],
    "pingfandeshijie": ["平凡的世界"],
    "santi": ["三体"]
}

function normalized(value) {
    return String(value || "").toLowerCase().replace(/[^a-z']/g, "").replace(/'/g, "")
}

function lookup(key, limit) {
    var maximum = Math.max(1, Number(limit) || 8)
    var result = []
    var seen = ({})
    var local = PROJECT_PHRASES[key] || []
    var source = local.concat(Lexicon.candidates(key, maximum))
    for (var index = 0; index < source.length && result.length < maximum; index++) {
        var text = String(source[index] || "")
        if (text !== "" && !seen[text]) {
            seen[text] = true
            result.push(text)
        }
    }
    return result
}

function addCandidate(result, seen, text, consume) {
    if (!text || !consume || seen[text]) {
        return
    }
    seen[text] = true
    result.push({ "text": text, "consume": consume })
}

function longestMatchAt(buffer, offset) {
    var last = Math.min(buffer.length, offset + 24)
    for (var end = last; end > offset; end--) {
        var key = buffer.slice(offset, end)
        var words = lookup(key, 1)
        if (words.length > 0) {
            return ({ "key": key, "text": words[0] })
        }
    }
    return ({ "key": "", "text": "" })
}

function bestSentence(buffer) {
    var offset = 0
    var text = ""
    var pieces = 0
    while (offset < buffer.length && pieces < 12) {
        var match = longestMatchAt(buffer, offset)
        if (match.key === "") {
            return ({ "text": "", "consume": 0, "pieces": 0 })
        }
        text += match.text
        offset += match.key.length
        pieces += 1
    }
    return ({ "text": text, "consume": offset, "pieces": pieces })
}

function candidates(value, limit) {
    var buffer = normalized(value)
    var maximum = Math.max(1, Number(limit) || 8)
    var result = []
    var seen = ({})
    if (buffer === "") {
        return result
    }

    var sentence = bestSentence(buffer)
    if (sentence.pieces > 1 && sentence.consume === buffer.length) {
        addCandidate(result, seen, sentence.text, sentence.consume)
    }

    var exact = lookup(buffer, maximum)
    for (var exactIndex = 0; exactIndex < exact.length; exactIndex++) {
        addCandidate(result, seen, exact[exactIndex], buffer.length)
    }

    var last = Math.min(buffer.length, 24)
    for (var end = last; end > 0; end--) {
        var prefix = buffer.slice(0, end)
        var words = lookup(prefix, 3)
        for (var wordIndex = 0; wordIndex < words.length; wordIndex++) {
            addCandidate(result, seen, words[wordIndex], prefix.length)
        }
    }
    return result.slice(0, maximum)
}

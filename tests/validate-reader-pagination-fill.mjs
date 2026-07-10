function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const width = 954;
const height = 1696;
const margin = 64;
const topY = 96;
const bottomGestureHeight = 56;

const paragraphs = [
  '伊朗的历史并不是一条平直的道路。王朝、宗教、部落、帝国和革命不断交错，每一次政治秩序的重建都伴随着社会结构的重新排列。',
  '在漫长的近代转型中，城市、乡村和边疆地区对于国家权力的理解并不相同。中央政权试图建立统一制度，地方社会则以自己的方式保存传统。',
  '这种张力解释了许多看似突然的历史事件。革命并非凭空发生，它往往是长期财政压力、宗教动员、外部干预和知识分子传播共同作用的结果。',
  '对于普通读者来说，理解这一段历史最困难的地方并不是记住年代，而是把制度变化、思想变化和日常生活经验放在同一张地图上观察。',
  '因此，叙述必须给读者留下足够的连续性。每一页都应该尽量利用屏幕，让段落自然延展，而不是因为过分保守的分页估算留下大片空白。'
];

const bodyText = Array.from({ length: 80 }, (_, index) => paragraphs[index % paragraphs.length]).join('\n\n');

function paginate(settings) {
  const readerContentBottom = height - bottomGestureHeight;
  const readerLinePixels = () => Math.ceil(settings.fontSize * settings.lineHeight);
  const readerBottomSafety = () => Math.min(8, settings.paragraphSpacing);
  const readerBodyHeight = () => {
    const usable = Math.max(0, readerContentBottom - topY - readerBottomSafety());
    const linePx = Math.max(1, readerLinePixels());
    return Math.max(linePx * 2, Math.floor(usable / linePx) * linePx);
  };
  const estimatedCharsPerLine = () => {
    const textWidth = Math.max(120, width - margin * 2);
    const familySafety = settings.font === '霞鹜文楷' ? 0.98 : 0.96;
    return Math.max(6, Math.floor(textWidth / Math.max(1, settings.fontSize * familySafety)));
  };
  const estimatedFirstLineChars = (indent) => {
    const textWidth = Math.max(120, width - margin * 2 - Math.max(0, indent));
    const familySafety = settings.font === '霞鹜文楷' ? 0.98 : 0.96;
    return Math.max(4, Math.floor(textWidth / Math.max(1, settings.fontSize * familySafety)));
  };
  const estimatedParagraphLines = (value, firstLineIndent) => {
    const para = String(value || '').replace(/\s+/g, ' ').trim();
    if (para.length === 0) return 0;
    const firstChars = estimatedFirstLineChars(firstLineIndent);
    const restChars = estimatedCharsPerLine();
    if (para.length <= firstChars) return 1;
    return 1 + Math.ceil((para.length - firstChars) / restChars);
  };
  const paragraphGap = () => Math.min(12, Math.max(0, settings.paragraphSpacing));
  const sliceHeight = (value, firstLineIndent) => {
    return String(value || '').split(/\n+/).reduce((total, raw, index) => {
      const para = raw.replace(/\s+/g, ' ').trim();
      if (!para) return total;
      const indent = index === 0 ? Math.max(0, firstLineIndent) : settings.fontSize * 2;
      return total + estimatedParagraphLines(para, indent) * readerLinePixels() + paragraphGap();
    }, 0);
  };
  const partialParagraphEnd = (paragraphStart, paragraphEnd, remainingHeight) => {
    const para = bodyText.slice(paragraphStart, paragraphEnd).replace(/\s+/g, ' ').trim();
    const availableLines = Math.floor(Math.max(0, remainingHeight) / readerLinePixels());
    if (availableLines < 1) return paragraphStart;
    const firstLineChars = estimatedFirstLineChars(settings.fontSize * 2);
    const restLineChars = estimatedCharsPerLine();
    const charBudget = availableLines <= 1 ? firstLineChars : firstLineChars + (availableLines - 1) * restLineChars;
    return Math.min(paragraphEnd, paragraphStart + Math.max(1, Math.floor(charBudget)));
  };
  const pageEnd = (start) => {
    const maxHeight = readerBodyHeight();
    let totalHeight = 0;
    let cursor = start;
    let end = start;
    while (cursor < bodyText.length) {
      let paragraphEnd = bodyText.indexOf('\n', cursor);
      if (paragraphEnd < 0) paragraphEnd = bodyText.length;
      let nextStart = paragraphEnd;
      while (nextStart < bodyText.length && bodyText.charAt(nextStart) === '\n') nextStart += 1;
      const paragraph = bodyText.slice(cursor, paragraphEnd).replace(/\s+/g, ' ').trim();
      if (!paragraph) {
        cursor = nextStart;
        continue;
      }
      const paragraphHeight = sliceHeight(paragraph, settings.fontSize * 2);
      if (totalHeight + paragraphHeight <= maxHeight) {
        totalHeight += paragraphHeight;
        end = nextStart;
        cursor = nextStart;
        continue;
      }
      const partial = partialParagraphEnd(cursor, paragraphEnd, maxHeight - totalHeight);
      return Math.max(start + 1, partial > cursor ? partial : end);
    }
    return Math.max(start + 1, end > start ? end : bodyText.length);
  };
  const paintedHeight = (start, end) => {
    const page = bodyText.slice(start, end);
    return sliceHeight(page, start > 0 ? 0 : settings.fontSize * 2);
  };

  const ratios = [];
  let start = 0;
  let guard = 0;
  while (start < bodyText.length && guard < 500) {
    const end = pageEnd(start);
    if (end >= bodyText.length) break;
    ratios.push(paintedHeight(start, end) / readerBodyHeight());
    start = end;
    guard += 1;
  }
  return ratios;
}

const combinations = [];
for (const fontSize of [30, 34, 38]) {
  for (const lineHeight of [1.16, 1.26, 1.36]) {
    for (const paragraphSpacing of [0, 8, 12, 20]) {
      combinations.push({ fontSize, lineHeight, paragraphSpacing, font: '霞鹜文楷' });
    }
  }
}

for (const settings of combinations) {
  const ratios = paginate(settings).slice(1, -1);
  const low = Math.min(...ratios);
  assert(low >= 0.95, `pagination fill too low ${low.toFixed(3)} for ${JSON.stringify(settings)}`);
}

console.log('reader pagination fill combinations ok');

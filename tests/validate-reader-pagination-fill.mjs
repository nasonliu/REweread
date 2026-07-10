function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const width = 954;
const height = 1696;
const margin = 64;
const topY = 96;
const bottomGestureHeight = 56;
const footerHeight = 46;

const paragraphs = [
  '清晨的街道还没有完全醒来，窗外的光线慢慢越过屋檐。人们沿着熟悉的路线前行，又在细小的变化中重新认识这座城市。',
  '一本书的节奏来自句子，也来自段落之间恰当的停顿。连续的文字需要稳定地铺满页面，同时为读者留下清楚而自然的呼吸。',
  '当字号、行距和页边距发生变化时，阅读位置应当保持稳定。分页算法需要重新计算每一行，却不能让读者突然跳到完全不同的章节。',
  '在电子纸屏幕上，清晰比装饰更重要。文字必须保持足够的黑度，控件需要直接可靠，每一次翻页也应该快速而明确。',
  '因此，每一页都应尽量利用可读区域，让段落自然延展。只有章节结束或图文排版确实需要时，页面底部才可以保留更大的空白。'
];

const bodyText = Array.from({ length: 80 }, (_, index) => paragraphs[index % paragraphs.length]).join('\n\n');

function paginate(settings) {
  const readerLinePixels = () => Math.ceil(settings.fontSize * settings.lineHeight);
  const readerFooterGap = readerLinePixels();
  const readerContentBottom = height - bottomGestureHeight - footerHeight - readerFooterGap;
  const readerBottomSafety = () => Math.min(10, Math.max(6, settings.paragraphSpacing));
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

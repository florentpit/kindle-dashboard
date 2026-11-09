import AppKit

enum NewsLayout {
    static func gap(_ b: PageBlock) -> Double { b.fontSize * 0.65 }
    static func height(_ b: PageBlock, sources: SourceSnapshot) -> Double {
        let width = max(20, b.width - 2 * b.padding)
        func measure(_ text: String, size: Double, bold: Bool = false, lines: Int? = nil) -> Double {
            var font = NSFont(name: b.fontName, size: size) ?? .systemFont(ofSize: size)
            if bold { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
            let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = b.lineSpacing
            let rect = (text as NSString).boundingRect(with: NSSize(width: width, height: 100_000), options: [.usesLineFragmentOrigin,.usesFontLeading], attributes: [.font:font,.paragraphStyle:paragraph])
            let lineHeight = font.ascender - font.descender + font.leading + b.lineSpacing
            return ceil(min(rect.height, lines.map { Double($0) * lineHeight } ?? rect.height))
        }
        var heights: [Double] = []
        if !b.text.isEmpty { heights.append(measure(b.text, size: b.fontSize * 1.08, bold: true)) }
        for article in (sources.news[b.sourceURL] ?? []).dropFirst(b.newsOffset).prefix(b.articleCount) {
            var h = measure(article.title, size: b.fontSize, bold: true)
            if b.showSummary && !article.summary.isEmpty { h += 9 + measure(article.summary, size: b.fontSize * 0.84, lines: b.newsSummaryLines) }
            heights.append(h)
        }
        if b.showNewsSource == true { heights.append(max(20,b.fontSize * 0.65)) }
        return ceil(heights.reduce(0,+) + Double(max(0,heights.count-1)) * gap(b) + b.padding * 2 + 16)
    }
}

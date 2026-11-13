import SwiftUI
import AppKit
import CoreImage

struct PageScene: View {
    let page: KindlePage
    var date = Date()
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: page.background)
            ForEach(page.blocks.filter { !$0.hidden }) { block in
                BlockContent(block: block, page: page, date: date)
                    .frame(width: block.width, height: block.height, alignment: .topLeading)
                    .clipped()
                    .opacity(block.opacity)
                    .offset(x: block.x, y: block.y)
            }
        }
        .frame(width: page.width, height: page.height, alignment: .topLeading)
        .clipped()
        .environment(\.colorScheme, .light)
    }
}

struct BlockContent: View {
    let block: PageBlock
    let page: KindlePage
    var date = Date()
    private var textAlignment: TextAlignment { block.alignment == "center" ? .center : block.alignment == "right" ? .trailing : .leading }
    private var frameAlignment: Alignment { block.alignment == "center" ? .top : block.alignment == "right" ? .topTrailing : .topLeading }
    private var font: Font {
        var font = Font.custom(block.fontName, size: block.fontSize)
        if block.bold { font = font.weight(.bold) }
        if block.italic { font = font.italic() }
        return font
    }

    var body: some View {
        content
            .font(font)
            .foregroundStyle(Color(white: block.ink))
            .multilineTextAlignment(textAlignment)
            .lineSpacing(block.lineSpacing)
            .padding(block.padding)
            .frame(width: block.width, height: block.height, alignment: frameAlignment)
            .background(block.hasBackground ? Color(white: block.background) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: block.cornerRadius))
    }

    @ViewBuilder private var content: some View {
        switch block.kind {
        case .text:
            Text(block.text.replacingOccurrences(of: "{date}", with: formatted("d MMMM yyyy"))).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
        case .date: Text(formatted(block.dateFormat).uppercased()).tracking(3)
        case .clock: Text(formatted(block.clockFormat)).monospacedDigit().frame(maxWidth: .infinity, alignment: frameAlignment)
        case .divider: Rectangle().fill(Color(white: block.ink))
        case .shape: RoundedRectangle(cornerRadius: block.cornerRadius).strokeBorder(Color(white: block.ink), lineWidth: 2)
        case .image:
            if let id = block.imageID, let asset = page.assets.first(where: { $0.id == id }), let image = NSImage(data: asset.data) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: block.imageFill ? .fill : .fit)
                    .frame(width: max(1, block.width - block.padding * 2), height: max(1, block.height - block.padding * 2))
                    .clipped().saturation(0).contrast(block.imageContrast).brightness(block.imageBrightness)
            } else {
                ZStack { Color(white: 0.94); Image(systemName: "photo").font(.system(size: 54)).foregroundStyle(Color(white: 0.55)) }
            }
        case .weather:
            if block.weatherStyle == "detailed" { DetailedWeatherView(block:block,page:page,date:date) }
            else { weather }
        case .news: news
        }
    }

    @ViewBuilder private var weather: some View {
        let weather = page.sources.weather["\(block.city)|\(block.unit)"]
        if block.forecastOnly == true {
            HStack(spacing: 35) {
                if let weather {
                    ForEach(Array(weather.days.prefix(3).enumerated()), id: \.offset) { _, day in
                        HStack(spacing: 18) {
                            Image(systemName: Self.weatherIcon(day.code)).font(.system(size: block.fontSize * 1.45, weight: .light))
                            VStack(alignment: .leading, spacing: 12) {
                                Text(day.day.uppercased()).font(.custom("Inter", size: block.fontSize * 0.65))
                                Text(String(format: "%.0f° / %.0f°", day.high, day.low)).font(.custom(block.fontName, size: block.fontSize))
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else { Text("Chargez les prévisions météo.") }
            }
        } else {
        VStack(alignment: .leading, spacing: block.fontSize * 0.4) {
            Text(block.city).font(.custom(block.fontName, size: block.fontSize))
            HStack(alignment: .center, spacing: 28) {
                HStack(spacing: 18) {
                    Text(weather.map { String(format: "%.0f°", $0.temperature) } ?? "—°")
                        .font(.custom(block.fontName, size: block.fontSize * 2.9)).fixedSize()
                    Image(systemName: Self.weatherIcon(weather?.code ?? 3)).font(.system(size: block.fontSize * 1.65, weight: .light))
                }.fixedSize().layoutPriority(1)
                if block.showForecast, let weather {
                    Rectangle().fill(Color(white: 0.65)).frame(width: 1, height: block.fontSize * 2.7)
                    ForEach(Array(weather.days.prefix(3).enumerated()), id: \.offset) { _, day in
                        VStack(spacing: 10) {
                            Text(day.day.capitalized)
                            Image(systemName: Self.weatherIcon(day.code)).font(.system(size: block.fontSize * 0.9))
                            Text(String(format: "%.0f° / %.0f°", day.high, day.low))
                        }.font(.custom(block.fontName, size: block.fontSize * 0.64)).frame(maxWidth: .infinity)
                    }
                }
            }
        }
        }
    }

    private var news: some View {
        VStack(alignment: .leading, spacing: NewsLayout.gap(block)) {
            if !block.text.isEmpty {
                Text(block.text).font(.custom(block.fontName, size: block.fontSize * 1.08).weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if page.sources.sourceErrors?["news:" + block.sourceURL] != nil {
                Text("Source indisponible · dernière récupération : " + WeatherText.updateTime(page.sources.newsFetchedAt?[block.sourceURL], relativeTo: date, timezone: page.schedule.timezone))
                    .font(.custom("Inter", size: max(13, block.fontSize * 0.48))).foregroundStyle(Color(white: 0.4))
            }
            if let articles = page.sources.news[block.sourceURL], !articles.isEmpty {
                ForEach(Array(articles.dropFirst(block.newsOffset).prefix(block.articleCount).enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 9) {
                        Text(item.title).font(.custom(block.fontName, size: block.fontSize).weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        if block.showSummary && !item.summary.isEmpty {
                            Text(item.summary).font(.custom(block.fontName, size: block.fontSize * 0.84))
                                .lineLimit(block.newsSummaryLines).fixedSize(horizontal: false, vertical: true)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if block.showNewsSource == true {
                    Text(URL(string: block.sourceURL)?.host ?? block.sourceURL)
                        .font(.custom("Inter", size: max(13, block.fontSize * 0.48))).foregroundStyle(Color(white: 0.4))
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ajoutez une adresse de site ou de flux RSS dans Contenu, puis chargez les articles.")
                    Text(block.sourceURL).font(.custom("Inter", size: max(15, block.fontSize * 0.55)))
                }.font(.custom(block.fontName, size: block.fontSize * 0.8))
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatted(_ format: String) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.timeZone = TimeZone(identifier: page.schedule.timezone); f.dateFormat = format
        return f.string(from: date)
    }

    static func weatherIcon(_ code: Int) -> String {
        switch code {
        case 0: "sun.max"
        case 1, 2: "cloud.sun"
        case 45, 48: "cloud.fog"
        case 51...67, 80...82: "cloud.rain"
        case 71...77, 85, 86: "cloud.snow"
        case 95...99: "cloud.bolt.rain"
        default: "cloud"
        }
    }
}

@MainActor enum PageRenderer {
    static func png(_ page: KindlePage, date: Date = Date()) throws -> Data {
        let renderer = ImageRenderer(content: PageScene(page: page, date: date))
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: page.width, height: page.height)
        guard let cgImage = renderer.cgImage else { throw PageError.invalid("Le rendu de la page a échoué.") }
        let ci = CIImage(cgImage: cgImage).applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0])
        let context = CIContext()
        let space = CGColorSpaceCreateDeviceGray()
        guard let gray = context.createCGImage(ci, from: ci.extent, format: .L8, colorSpace: space) else {
            throw PageError.invalid("Conversion en niveaux de gris impossible.")
        }
        let bitmap = NSBitmapImageRep(cgImage: gray)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw PageError.invalid("Export PNG impossible.") }
        return data
    }
}

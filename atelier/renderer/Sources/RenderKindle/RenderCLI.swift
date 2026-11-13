import Foundation
import AppKit
import CoreText
import CryptoKit

@main struct RenderCLI {
    @MainActor static func main() async {
        do {
            _ = NSApplication.shared
            guard CommandLine.arguments.count >= 3 else { throw PageError.invalid("Usage : RenderKindle composition.kindlepage dossier-sortie [--cached]") }
            let input = URL(fileURLWithPath: CommandLine.arguments[1])
            let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
            var page = try KindlePage.decode(Data(contentsOf: input))
            let fonts = Bundle.module.resourceURL!.appendingPathComponent("Resources/Fonts")
            for url in (try? FileManager.default.contentsOfDirectory(at: fonts, includingPropertiesForKeys: nil)) ?? [] {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
            for font in page.fonts {
                if let provider = CGDataProvider(data: font.data as CFData), let cgFont = CGFont(provider) { CTFontManagerRegisterGraphicsFont(cgFont, nil) }
            }
            if !CommandLine.arguments.contains("--cached") { page.sources = try await SourceService.fetch(for: page) }
            let now = Date()
            let png = try PageRenderer.png(page, date: now)
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            try png.write(to: output.appendingPathComponent("dashboard.png"), options: .atomic)
            let sha = SHA256.hash(data: png).map { String(format: "%02x", $0) }.joined()
            try "\(sha)  dashboard.png\n".write(to: output.appendingPathComponent("dashboard.sha256"), atomically: true, encoding: .utf8)
            try ISO8601DateFormatter().string(from: now).write(to: output.appendingPathComponent("version.txt"), atomically: true, encoding: .utf8)
            try String(Int(now.timeIntervalSince1970)).write(to:output.appendingPathComponent("generated-at.txt"),atomically:true,encoding:.utf8)
            let schedule = page.schedule.nextDates(after: now, count: 400).map { "\(Int($0.timeIntervalSince1970))\n" }.joined()
            try schedule.write(to: output.appendingPathComponent("schedule.txt"), atomically: true, encoding: .utf8)
            print("Édition générée : \(Int(page.width)) × \(Int(page.height)), PNG gris, SHA-256 \(sha)")
        } catch {
            FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8)); exit(1)
        }
    }
}

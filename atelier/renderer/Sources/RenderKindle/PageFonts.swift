import Foundation
import CoreText
import SwiftUI

/// Use actual PostScript names in SwiftUI, on both the Mac and hosted renderer.
/// Missing bundled faces are errors rather than silently substituted system fonts.
enum PageFonts {
    static let bundled = ["Inter": "Inter-Regular", "Newsreader": "Newsreader16pt-Regular"]
    static func name(_ requested: String) -> String { bundled[requested] ?? requested }
    static func native(_ requested:String,size:Double) -> CTFont {
        CTFontCreateWithName(name(requested) as CFString,size,nil)
    }
    static func font(_ requested:String,size:Double) -> Font {
        Font(native(requested,size:size))
    }
    static func register(_ page: KindlePage, resources: URL) throws {
        for (file, expected) in bundled {
            let url = resources.appendingPathComponent("Resources/Fonts/" + file + ".ttf")
            guard let data = try? Data(contentsOf: url), let provider = CGDataProvider(data: data as CFData),
                  let font = CGFont(provider), font.postScriptName as String? == expected else {
                throw PageError.invalid("La police embarquée \(file) est absente ou invalide.")
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            let resolved = CTFontCreateWithName(expected as CFString, 40, nil)
            guard CTFontCopyPostScriptName(resolved) as String == expected else {
                throw PageError.invalid("La police \(file) n’a pas pu être chargée. Le rendu est arrêté pour éviter une substitution.")
            }
        }
        for embedded in page.fonts {
            guard let provider = CGDataProvider(data: embedded.data as CFData), let font = CGFont(provider) else {
                throw PageError.invalid("Une police importée n’est pas lisible.")
            }
            CTFontManagerRegisterGraphicsFont(font, nil)
        }
        for block in page.blocks where !block.hidden && [.weather, .news, .text, .date, .clock].contains(block.kind) {
            let requested = name(block.fontName)
            let resolved = CTFontCreateWithName(requested as CFString, block.fontSize, nil)
            let actual = CTFontCopyPostScriptName(resolved) as String
            let family = CTFontCopyFamilyName(resolved) as String
            guard actual.caseInsensitiveCompare(requested) == .orderedSame || family.caseInsensitiveCompare(requested) == .orderedSame else {
                throw PageError.invalid("La police \(block.fontName) n’est pas disponible. Importez-la dans la composition avant de publier.")
            }
        }
    }
}

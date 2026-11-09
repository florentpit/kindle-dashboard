// Generated from generator/generate.py ICONS; preserve its vector paths.
import SwiftUI

struct WeatherGlyphPart { let path: Path; let white: Bool; let stroke: Double? }
enum WeatherGlyphs {
    static func parts(_ name: String) -> [WeatherGlyphPart] {
        var parts: [WeatherGlyphPart] = []
        switch name {
        case "clear":
            do {
                var p = Path()
                p.addEllipse(in: CGRect(x: 7.8, y: 7.8, width: 8.4, height: 8.4))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 12, y: 2.5))
                p.addLine(to: CGPoint(x: 12, y: 4.7))
                p.move(to: CGPoint(x: 12, y: 19.3))
                p.addLine(to: CGPoint(x: 12, y: 21.5))
                p.move(to: CGPoint(x: 2.5, y: 12))
                p.addLine(to: CGPoint(x: 4.7, y: 12))
                p.move(to: CGPoint(x: 19.3, y: 12))
                p.addLine(to: CGPoint(x: 21.5, y: 12))
                p.move(to: CGPoint(x: 5.3, y: 5.3))
                p.addLine(to: CGPoint(x: 6.9, y: 6.9))
                p.move(to: CGPoint(x: 17.1, y: 17.1))
                p.addLine(to: CGPoint(x: 18.7, y: 18.7))
                p.move(to: CGPoint(x: 5.3, y: 18.7))
                p.addLine(to: CGPoint(x: 6.9, y: 17.1))
                p.move(to: CGPoint(x: 17.1, y: 6.9))
                p.addLine(to: CGPoint(x: 18.7, y: 5.3))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
        case "clear-n":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 19.5, y: 14.5))
                p.addCurve(to: CGPoint(x: 11.488897, y: 12.511103), control1: CGPoint(x: 16.667378, y: 15.372209), control2: CGPoint(x: 13.584666, y: 14.606872))
                p.addCurve(to: CGPoint(x: 9.5, y: 4.5), control1: CGPoint(x: 9.393128, y: 10.415334), control2: CGPoint(x: 8.627791, y: 7.332622))
                p.addCurve(to: CGPoint(x: 3.893871, y: 12.940978), control1: CGPoint(x: 5.860416, y: 5.620686), control2: CGPoint(x: 3.515322, y: 9.151623))
                p.addCurve(to: CGPoint(x: 11.059022, y: 20.106129), control1: CGPoint(x: 4.27242, y: 16.730333), control2: CGPoint(x: 7.269667, y: 19.72758))
                p.addCurve(to: CGPoint(x: 19.5, y: 14.5), control1: CGPoint(x: 14.848377, y: 20.484678), control2: CGPoint(x: 18.379314, y: 18.139584))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
        case "partly":
            do {
                var p = Path()
                p.addEllipse(in: CGRect(x: 2.416, y: 2.416, width: 6.048, height: 6.048))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 5.44, y: -1.4))
                p.addLine(to: CGPoint(x: 5.44, y: 0.184))
                p.move(to: CGPoint(x: 5.44, y: 10.696))
                p.addLine(to: CGPoint(x: 5.44, y: 12.28))
                p.move(to: CGPoint(x: -1.4, y: 5.44))
                p.addLine(to: CGPoint(x: 0.184, y: 5.44))
                p.move(to: CGPoint(x: 10.696, y: 5.44))
                p.addLine(to: CGPoint(x: 12.28, y: 5.44))
                p.move(to: CGPoint(x: 0.616, y: 0.616))
                p.addLine(to: CGPoint(x: 1.768, y: 1.768))
                p.move(to: CGPoint(x: 9.112, y: 9.112))
                p.addLine(to: CGPoint(x: 10.264, y: 10.264))
                p.move(to: CGPoint(x: 0.616, y: 10.264))
                p.addLine(to: CGPoint(x: 1.768, y: 9.112))
                p.move(to: CGPoint(x: 9.112, y: 1.768))
                p.addLine(to: CGPoint(x: 10.264, y: 0.616))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 9, y: 20))
                p.addLine(to: CGPoint(x: 18.5, y: 20))
                p.addCurve(to: CGPoint(x: 22.3, y: 16.6), control1: CGPoint(x: 20.488225, y: 20.110457), control2: CGPoint(x: 22.189543, y: 18.588225))
                p.addCurve(to: CGPoint(x: 18.9, y: 12.8), control1: CGPoint(x: 22.410457, y: 14.611775), control2: CGPoint(x: 20.888225, y: 12.910457))
                p.addCurve(to: CGPoint(x: 13.149904, y: 9.413574), control1: CGPoint(x: 17.993576, y: 10.480246), control2: CGPoint(x: 15.618195, y: 9.081304))
                p.addCurve(to: CGPoint(x: 8.5, y: 14.2), control1: CGPoint(x: 10.681613, y: 9.745844), control2: CGPoint(x: 8.760725, y: 11.723129))
                p.addCurve(to: CGPoint(x: 5.85, y: 17.35), control1: CGPoint(x: 6.898374, y: 14.338071), control2: CGPoint(x: 5.711929, y: 15.748374))
                p.addCurve(to: CGPoint(x: 9, y: 20), control1: CGPoint(x: 5.988071, y: 18.951626), control2: CGPoint(x: 7.398374, y: 20.138071))
                p.closeSubpath()
                parts.append(.init(path: p, white: true, stroke: nil))
            }
        case "partly-n":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 11.15, y: 7.15))
                p.addCurve(to: CGPoint(x: 5.542228, y: 5.757772), control1: CGPoint(x: 9.167165, y: 7.760547), control2: CGPoint(x: 7.009266, y: 7.22481))
                p.addCurve(to: CGPoint(x: 4.15, y: 0.15), control1: CGPoint(x: 4.07519, y: 4.290734), control2: CGPoint(x: 3.539453, y: 2.132835))
                p.addCurve(to: CGPoint(x: 0.22571, y: 6.058684), control1: CGPoint(x: 1.602291, y: 0.93448), control2: CGPoint(x: -0.039275, y: 3.406136))
                p.addCurve(to: CGPoint(x: 5.241316, y: 11.07429), control1: CGPoint(x: 0.490694, y: 8.711233), control2: CGPoint(x: 2.588767, y: 10.809306))
                p.addCurve(to: CGPoint(x: 11.15, y: 7.15), control1: CGPoint(x: 7.893864, y: 11.339275), control2: CGPoint(x: 10.36552, y: 9.697709))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 9, y: 20))
                p.addLine(to: CGPoint(x: 18.5, y: 20))
                p.addCurve(to: CGPoint(x: 22.3, y: 16.6), control1: CGPoint(x: 20.488225, y: 20.110457), control2: CGPoint(x: 22.189543, y: 18.588225))
                p.addCurve(to: CGPoint(x: 18.9, y: 12.8), control1: CGPoint(x: 22.410457, y: 14.611775), control2: CGPoint(x: 20.888225, y: 12.910457))
                p.addCurve(to: CGPoint(x: 13.149904, y: 9.413574), control1: CGPoint(x: 17.993576, y: 10.480246), control2: CGPoint(x: 15.618195, y: 9.081304))
                p.addCurve(to: CGPoint(x: 8.5, y: 14.2), control1: CGPoint(x: 10.681613, y: 9.745844), control2: CGPoint(x: 8.760725, y: 11.723129))
                p.addCurve(to: CGPoint(x: 5.85, y: 17.35), control1: CGPoint(x: 6.898374, y: 14.338071), control2: CGPoint(x: 5.711929, y: 15.748374))
                p.addCurve(to: CGPoint(x: 9, y: 20), control1: CGPoint(x: 5.988071, y: 18.951626), control2: CGPoint(x: 7.398374, y: 20.138071))
                p.closeSubpath()
                parts.append(.init(path: p, white: true, stroke: nil))
            }
        case "cloud":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 7, y: 19))
                p.addLine(to: CGPoint(x: 17.5, y: 19))
                p.addCurve(to: CGPoint(x: 21.7, y: 15.2), control1: CGPoint(x: 19.709139, y: 19.110457), control2: CGPoint(x: 21.589543, y: 17.409139))
                p.addCurve(to: CGPoint(x: 17.9, y: 11), control1: CGPoint(x: 21.810457, y: 12.990861), control2: CGPoint(x: 20.109139, y: 11.110457))
                p.addCurve(to: CGPoint(x: 11.459374, y: 7.155461), control1: CGPoint(x: 16.917443, y: 8.369098), control2: CGPoint(x: 14.241426, y: 6.771729))
                p.addCurve(to: CGPoint(x: 6.3, y: 12.6), control1: CGPoint(x: 8.677322, y: 7.539192), control2: CGPoint(x: 6.533652, y: 9.801345))
                p.addCurve(to: CGPoint(x: 3.45, y: 16.15), control1: CGPoint(x: 4.532689, y: 12.7933), control2: CGPoint(x: 3.2567, y: 14.382689))
                p.addCurve(to: CGPoint(x: 7, y: 19), control1: CGPoint(x: 3.6433, y: 17.917311), control2: CGPoint(x: 5.232689, y: 19.1933))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
        case "fog":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 7, y: 15.5))
                p.addLine(to: CGPoint(x: 17.5, y: 15.5))
                p.addCurve(to: CGPoint(x: 21.7, y: 11.7), control1: CGPoint(x: 19.709139, y: 15.610457), control2: CGPoint(x: 21.589543, y: 13.909139))
                p.addCurve(to: CGPoint(x: 17.9, y: 7.5), control1: CGPoint(x: 21.810457, y: 9.490861), control2: CGPoint(x: 20.109139, y: 7.610457))
                p.addCurve(to: CGPoint(x: 11.459374, y: 3.655461), control1: CGPoint(x: 16.917443, y: 4.869098), control2: CGPoint(x: 14.241426, y: 3.271729))
                p.addCurve(to: CGPoint(x: 6.3, y: 9.1), control1: CGPoint(x: 8.677322, y: 4.039192), control2: CGPoint(x: 6.533652, y: 6.301345))
                p.addCurve(to: CGPoint(x: 3.45, y: 12.65), control1: CGPoint(x: 4.532689, y: 9.2933), control2: CGPoint(x: 3.2567, y: 10.882689))
                p.addCurve(to: CGPoint(x: 7, y: 15.5), control1: CGPoint(x: 3.6433, y: 14.417311), control2: CGPoint(x: 5.232689, y: 15.6933))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 4, y: 18.5))
                p.addLine(to: CGPoint(x: 20, y: 18.5))
                p.move(to: CGPoint(x: 6, y: 21.5))
                p.addLine(to: CGPoint(x: 18, y: 21.5))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
        case "drizzle":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 7, y: 15.5))
                p.addLine(to: CGPoint(x: 17.5, y: 15.5))
                p.addCurve(to: CGPoint(x: 21.7, y: 11.7), control1: CGPoint(x: 19.709139, y: 15.610457), control2: CGPoint(x: 21.589543, y: 13.909139))
                p.addCurve(to: CGPoint(x: 17.9, y: 7.5), control1: CGPoint(x: 21.810457, y: 9.490861), control2: CGPoint(x: 20.109139, y: 7.610457))
                p.addCurve(to: CGPoint(x: 11.459374, y: 3.655461), control1: CGPoint(x: 16.917443, y: 4.869098), control2: CGPoint(x: 14.241426, y: 3.271729))
                p.addCurve(to: CGPoint(x: 6.3, y: 9.1), control1: CGPoint(x: 8.677322, y: 4.039192), control2: CGPoint(x: 6.533652, y: 6.301345))
                p.addCurve(to: CGPoint(x: 3.45, y: 12.65), control1: CGPoint(x: 4.532689, y: 9.2933), control2: CGPoint(x: 3.2567, y: 10.882689))
                p.addCurve(to: CGPoint(x: 7, y: 15.5), control1: CGPoint(x: 3.6433, y: 14.417311), control2: CGPoint(x: 5.232689, y: 15.6933))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 8.5, y: 18.5))
                p.addLine(to: CGPoint(x: 8.5, y: 19))
                p.move(to: CGPoint(x: 12, y: 19.5))
                p.addLine(to: CGPoint(x: 12, y: 20))
                p.move(to: CGPoint(x: 15.5, y: 18.5))
                p.addLine(to: CGPoint(x: 15.5, y: 19))
                p.move(to: CGPoint(x: 10, y: 21.5))
                p.addLine(to: CGPoint(x: 10, y: 22))
                p.move(to: CGPoint(x: 14, y: 21.5))
                p.addLine(to: CGPoint(x: 14, y: 22))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
        case "rain":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 7, y: 15.5))
                p.addLine(to: CGPoint(x: 17.5, y: 15.5))
                p.addCurve(to: CGPoint(x: 21.7, y: 11.7), control1: CGPoint(x: 19.709139, y: 15.610457), control2: CGPoint(x: 21.589543, y: 13.909139))
                p.addCurve(to: CGPoint(x: 17.9, y: 7.5), control1: CGPoint(x: 21.810457, y: 9.490861), control2: CGPoint(x: 20.109139, y: 7.610457))
                p.addCurve(to: CGPoint(x: 11.459374, y: 3.655461), control1: CGPoint(x: 16.917443, y: 4.869098), control2: CGPoint(x: 14.241426, y: 3.271729))
                p.addCurve(to: CGPoint(x: 6.3, y: 9.1), control1: CGPoint(x: 8.677322, y: 4.039192), control2: CGPoint(x: 6.533652, y: 6.301345))
                p.addCurve(to: CGPoint(x: 3.45, y: 12.65), control1: CGPoint(x: 4.532689, y: 9.2933), control2: CGPoint(x: 3.2567, y: 10.882689))
                p.addCurve(to: CGPoint(x: 7, y: 15.5), control1: CGPoint(x: 3.6433, y: 14.417311), control2: CGPoint(x: 5.232689, y: 15.6933))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 8.5, y: 18))
                p.addLine(to: CGPoint(x: 7.5, y: 21.5))
                p.move(to: CGPoint(x: 12.5, y: 18))
                p.addLine(to: CGPoint(x: 11.5, y: 21.5))
                p.move(to: CGPoint(x: 16.5, y: 18))
                p.addLine(to: CGPoint(x: 15.5, y: 21.5))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
        case "snow":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 7, y: 15.5))
                p.addLine(to: CGPoint(x: 17.5, y: 15.5))
                p.addCurve(to: CGPoint(x: 21.7, y: 11.7), control1: CGPoint(x: 19.709139, y: 15.610457), control2: CGPoint(x: 21.589543, y: 13.909139))
                p.addCurve(to: CGPoint(x: 17.9, y: 7.5), control1: CGPoint(x: 21.810457, y: 9.490861), control2: CGPoint(x: 20.109139, y: 7.610457))
                p.addCurve(to: CGPoint(x: 11.459374, y: 3.655461), control1: CGPoint(x: 16.917443, y: 4.869098), control2: CGPoint(x: 14.241426, y: 3.271729))
                p.addCurve(to: CGPoint(x: 6.3, y: 9.1), control1: CGPoint(x: 8.677322, y: 4.039192), control2: CGPoint(x: 6.533652, y: 6.301345))
                p.addCurve(to: CGPoint(x: 3.45, y: 12.65), control1: CGPoint(x: 4.532689, y: 9.2933), control2: CGPoint(x: 3.2567, y: 10.882689))
                p.addCurve(to: CGPoint(x: 7, y: 15.5), control1: CGPoint(x: 3.6433, y: 14.417311), control2: CGPoint(x: 5.232689, y: 15.6933))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 8, y: 19.5))
                p.addLine(to: CGPoint(x: 8.01, y: 19.5))
                p.move(to: CGPoint(x: 12, y: 18.5))
                p.addLine(to: CGPoint(x: 12.01, y: 18.5))
                p.move(to: CGPoint(x: 16, y: 19.5))
                p.addLine(to: CGPoint(x: 16.01, y: 19.5))
                p.move(to: CGPoint(x: 10, y: 22))
                p.addLine(to: CGPoint(x: 10.01, y: 22))
                p.move(to: CGPoint(x: 14, y: 22))
                p.addLine(to: CGPoint(x: 14.01, y: 22))
                parts.append(.init(path: p, white: false, stroke: 2.6))
            }
        case "storm":
            do {
                var p = Path()
                p.move(to: CGPoint(x: 7, y: 15.5))
                p.addLine(to: CGPoint(x: 17.5, y: 15.5))
                p.addCurve(to: CGPoint(x: 21.7, y: 11.7), control1: CGPoint(x: 19.709139, y: 15.610457), control2: CGPoint(x: 21.589543, y: 13.909139))
                p.addCurve(to: CGPoint(x: 17.9, y: 7.5), control1: CGPoint(x: 21.810457, y: 9.490861), control2: CGPoint(x: 20.109139, y: 7.610457))
                p.addCurve(to: CGPoint(x: 11.459374, y: 3.655461), control1: CGPoint(x: 16.917443, y: 4.869098), control2: CGPoint(x: 14.241426, y: 3.271729))
                p.addCurve(to: CGPoint(x: 6.3, y: 9.1), control1: CGPoint(x: 8.677322, y: 4.039192), control2: CGPoint(x: 6.533652, y: 6.301345))
                p.addCurve(to: CGPoint(x: 3.45, y: 12.65), control1: CGPoint(x: 4.532689, y: 9.2933), control2: CGPoint(x: 3.2567, y: 10.882689))
                p.addCurve(to: CGPoint(x: 7, y: 15.5), control1: CGPoint(x: 3.6433, y: 14.417311), control2: CGPoint(x: 5.232689, y: 15.6933))
                p.closeSubpath()
                parts.append(.init(path: p, white: false, stroke: nil))
            }
            do {
                var p = Path()
                p.move(to: CGPoint(x: 12.5, y: 16.5))
                p.addLine(to: CGPoint(x: 10, y: 20))
                p.addLine(to: CGPoint(x: 13, y: 20))
                p.addLine(to: CGPoint(x: 11, y: 23.5))
                parts.append(.init(path: p, white: false, stroke: nil))
            }
        default: return Self.parts("cloud")
        }
        return parts
    }
}

struct WeatherGlyph: View {
    let code: Int
    var isDay = true
    var stroke: Double = 1.8
    var body: some View {
        Canvas { context, size in
            let factor = min(size.width, size.height) / 24
            let transform = CGAffineTransform(scaleX: factor, y: factor)
            for part in WeatherGlyphs.parts(WeatherText.glyph(code, isDay: isDay)) {
                let path = part.path.applying(transform)
                if part.white { context.fill(path, with: .color(.white)) }
                context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: (part.stroke ?? stroke) * factor, lineCap: .round, lineJoin: .round))
            }
        }.accessibilityLabel(WeatherText.condition(code))
    }
}

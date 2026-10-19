import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: 1)
    }
}

/// The same tokens as css/site.css.
enum Palette {
    static let soot = Color(hex: 0x0d0b0a)
    static let soot2 = Color(hex: 0x171310)
    static let soot3 = Color(hex: 0x221c17)
    static let bone = Color(hex: 0xe8dcc6)
    static let boneDim = Color(hex: 0xa99d8a)
    static let rule = Color(hex: 0xe8dcc6).opacity(0.16)
    static let manila = Color(hex: 0xd8c49b)
    static let manilaDeep = Color(hex: 0xc6ae80)
    static let tagInk = Color(hex: 0x2a1f17)
    static let tagInkDim = Color(hex: 0x5d4a39)
    static let whiteHot = Color(hex: 0xfff1c8)

    static let straw = Color(hex: 0xe3b862)
    static let bronze = Color(hex: 0xb0682e)
    static let purple = Color(hex: 0x7a4596)
    static let blue = Color(hex: 0x3a5bab)
    static let paleBlue = Color(hex: 0x86a2c9)

    static func chamber(_ phaseID: String) -> Color {
        switch phaseID {
        case "soak": return purple
        case "cool": return blue
        default: return straw
        }
    }

    static func stampInk(_ phaseID: String) -> Color {
        switch phaseID {
        case "soak": return Color(hex: 0x4b2560)
        case "cool": return Color(hex: 0x1f356e)
        default: return Color(hex: 0x7a2c12)
        }
    }
}

/// Steel's temper colours, hot (0) to cool (1). `fill` for glows; `ink` is safe for text on soot.
enum Temper {
    private struct Stop {
        let p: Double
        let fill: (Double, Double, Double)
        let ink: (Double, Double, Double)
    }

    private static let stops: [Stop] = [
        Stop(p: 0.0, fill: (227, 184, 98), ink: (240, 211, 138)),   // straw
        Stop(p: 0.3, fill: (176, 104, 46), ink: (230, 167, 109)),   // bronze
        Stop(p: 0.55, fill: (122, 69, 150), ink: (195, 154, 224)),  // purple
        Stop(p: 0.8, fill: (58, 91, 171), ink: (152, 176, 239)),    // deep blue
        Stop(p: 1.0, fill: (134, 162, 201), ink: (185, 205, 230)),  // pale blue
    ]

    static func fill(_ p: Double) -> Color { color(p, ink: false) }
    static func ink(_ p: Double) -> Color { color(p, ink: true) }

    private static func color(_ raw: Double, ink: Bool) -> Color {
        let p = min(1, max(0, raw.isFinite ? raw : 0))
        for i in 1..<stops.count where p <= stops[i].p {
            let a = stops[i - 1], b = stops[i]
            let t = (p - a.p) / (b.p - a.p)
            let ca = ink ? a.ink : a.fill, cb = ink ? b.ink : b.fill
            return Color(.sRGB,
                         red: (ca.0 + (cb.0 - ca.0) * t) / 255,
                         green: (ca.1 + (cb.1 - ca.1) * t) / 255,
                         blue: (ca.2 + (cb.2 - ca.2) * t) / 255,
                         opacity: 1)
        }
        let last = ink ? stops[stops.count - 1].ink : stops[stops.count - 1].fill
        return Color(.sRGB, red: last.0 / 255, green: last.1 / 255, blue: last.2 / 255, opacity: 1)
    }
}

/// One condensed industrial face, one old serif for the narrator. Both bundled in Fonts/.
enum AFont {
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("BigShouldersDisplay-Black", size: size, relativeTo: style)
    }
    static func label(_ size: CGFloat, relativeTo style: Font.TextStyle = .footnote) -> Font {
        .custom("BigShouldersDisplay-Bold", size: size, relativeTo: style)
    }
    static func narrator(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("IM_FELL_English_Roman", size: size, relativeTo: style)
    }
    static func narratorItalic(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("IM_FELL_English_Italic", size: size, relativeTo: style)
    }
}

/// Small uppercase label, like the manual's specimen tags.
struct Eyebrow: View {
    let text: String
    var color: Color = Palette.straw
    var size: CGFloat = 13

    init(_ text: String, color: Color = Palette.straw, size: CGFloat = 13) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text.uppercased())
            .font(AFont.label(size))
            .tracking(size * 0.16)
            .foregroundStyle(color)
    }
}

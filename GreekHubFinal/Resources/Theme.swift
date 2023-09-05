import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let ghGold       = Color(hex: "#C9A84C")
    static let ghBackground = Color(hex: "#0A0A0A")
    static let ghSurface    = Color(hex: "#141414")
    static let ghSurface2   = Color(hex: "#1E1E1E")
    static let ghBorder     = Color(hex: "#2A2A2A")
    static let ghText       = Color(hex: "#F0F0F0")
    static let ghTextMuted  = Color(hex: "#888888")
    static let ghGreen      = Color(hex: "#4CC99A")
    static let ghBlue       = Color(hex: "#4C6BC9")
    static let ghPink       = Color(hex: "#C94C8A")
    static let ghRed        = Color(hex: "#C94C4C")
    static let ghPurple     = Color(hex: "#8A4CC9")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }

    static func fromHex(_ hex: String) -> Color { Color(hex: hex) }
}

// MARK: - Typography

extension Font {
    static let ghLargeTitle  = Font.system(size: 28, weight: .bold, design: .default)
    static let ghTitle       = Font.system(size: 22, weight: .bold)
    static let ghTitle2      = Font.system(size: 18, weight: .semibold)
    static let ghHeadline    = Font.system(size: 16, weight: .semibold)
    static let ghBody        = Font.system(size: 15, weight: .regular)
    static let ghCallout     = Font.system(size: 14, weight: .regular)
    static let ghCaption     = Font.system(size: 12, weight: .regular)
    static let ghCaptionBold = Font.system(size: 12, weight: .semibold)
}

// MARK: - Shared View Modifiers

struct GHCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.ghSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.ghBorder, lineWidth: 0.5)
            )
    }
}

struct GHPillStyle: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content
            .font(.ghCaptionBold)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

extension View {
    func ghCard() -> some View { modifier(GHCardStyle()) }
    func ghPill(color: Color) -> some View { modifier(GHPillStyle(color: color)) }
}

// MARK: - Avatar

struct AvatarView: View {
    let initials: String
    let colorHex: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex).opacity(0.25))
            Circle()
                .stroke(Color(hex: colorHex).opacity(0.6), lineWidth: 1.5)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundColor(Color(hex: colorHex))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Relative time

extension Date {
    var relativeString: String {
        let diff = Date().timeIntervalSince(self)
        if diff < 60       { return "just now" }
        if diff < 3600     { return "\(Int(diff/60))m" }
        if diff < 86400    { return "\(Int(diff/3600))h" }
        return "\(Int(diff/86400))d"
    }
}

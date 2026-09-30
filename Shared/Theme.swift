import SwiftUI
import UIKit

// "종이 수첩과 잉크" 디자인 토큰 (DESIGN §5)

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }

    /// 라이트/다크에 따라 바뀌는 색
    static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(Color(hex: hex))
        })
    }
}

enum Ink {
    static let paper = Color.dynamic(light: "F4EFE6", dark: "161514")
    static let card = Color.dynamic(light: "FBF8F2", dark: "211F1D")
    static let ink = Color.dynamic(light: "1C1B1A", dark: "EDE6D8")
    static let faint = ink.opacity(0.5)
    static let empty = Color.dynamic(light: "E3DCCF", dark: "34312D")
    static let line = ink.opacity(0.12)
}

enum ThemeTint: String, CaseIterable, Identifiable {
    case tomato, teal, cobalt, mustard, plum, moss

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .tomato: "E4572E"
        case .teal: "1B998B"
        case .cobalt: "2E5EAA"
        case .mustard: "E3A72F"
        case .plum: "8E3B75"
        case .moss: "5B7F3A"
        }
    }

    var color: Color { Color(hex: hex) }

    var title: String {
        switch self {
        case .tomato: String(localized: "토마토")
        case .teal: String(localized: "청록")
        case .cobalt: String(localized: "코발트")
        case .mustard: String(localized: "겨자")
        case .plum: String(localized: "자두")
        case .moss: String(localized: "이끼")
        }
    }
}

/// 습관 색 팔레트 — 테마 색 + 먹색
enum HabitPalette {
    static let hexes: [String] = ThemeTint.allCases.map(\.hex) + ["3A3632", "C26D4A"]
}

enum Metrics {
    static let radius: CGFloat = 14
    static let border: CGFloat = 1.2
    static let shadowOffset: CGFloat = 3
    static let gutter: CGFloat = 16
}

extension Font {
    /// 큰 숫자
    static func number(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    /// 작은 대문자 라벨
    static let label: Font = .system(.caption2, design: .monospaced).weight(.semibold)
}

struct InkCard: ViewModifier {
    var padding: CGFloat = 16
    var fill: Color = Ink.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: Metrics.radius)
                        .fill(Ink.ink)
                        .offset(x: Metrics.shadowOffset, y: Metrics.shadowOffset)
                    RoundedRectangle(cornerRadius: Metrics.radius)
                        .fill(fill)
                    RoundedRectangle(cornerRadius: Metrics.radius)
                        .strokeBorder(Ink.ink, lineWidth: Metrics.border)
                }
            }
    }
}

extension View {
    func inkCard(padding: CGFloat = 16, fill: Color = Ink.card) -> some View {
        modifier(InkCard(padding: padding, fill: fill))
    }

    /// 소문자 없이 자간을 넓힌 라벨
    func labelStyle() -> some View {
        font(.label).tracking(1.2).textCase(.uppercase).foregroundStyle(Ink.faint)
    }
}

/// 섹션 제목: 라벨 + 오른쪽 보조 요소
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    init(_ title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title).labelStyle()
            Spacer()
            trailing
        }
    }
}

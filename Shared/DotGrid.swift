import SwiftUI

/// 앱 전체의 공통 시각 언어인 점 (DESIGN §5)
enum DotState: Equatable {
    case empty
    case filled
    case accent
    case today
    /// 잔디 농도 0...4
    case level(Int)
}

struct Dot: View {
    var state: DotState
    var tint: Color
    var size: CGFloat

    var body: some View {
        switch state {
        case .empty:
            Circle().fill(Ink.empty).frame(width: size, height: size)
        case .filled:
            Circle().fill(Ink.ink).frame(width: size, height: size)
        case .accent:
            Circle().fill(tint).frame(width: size, height: size)
        case .today:
            Circle()
                .strokeBorder(tint, lineWidth: max(1, size * 0.22))
                .frame(width: size, height: size)
        case .level(let l):
            Circle()
                .fill(l <= 0 ? Ink.empty : tint.opacity(Self.opacity(for: l)))
                .frame(width: size, height: size)
        }
    }

    static func opacity(for level: Int) -> Double {
        switch level {
        case 1: 0.3
        case 2: 0.55
        case 3: 0.8
        default: 1
        }
    }
}

/// 개수가 많은 점 그리드는 Canvas로 그려 성능을 확보한다 (NFR-3)
struct DotCanvas: View {
    let count: Int
    let columns: Int
    var spacingRatio: CGFloat = 0.35
    var tint: Color
    let state: (Int) -> DotState

    var body: some View {
        GeometryReader { geo in
            let cols = CGFloat(columns)
            let cell = geo.size.width / cols
            let dot = cell / (1 + spacingRatio)
            Canvas { ctx, _ in
                for i in 0..<count {
                    let r = CGFloat(i / columns), c = CGFloat(i % columns)
                    let rect = CGRect(
                        x: c * cell + (cell - dot) / 2,
                        y: r * cell + (cell - dot) / 2,
                        width: dot, height: dot
                    )
                    draw(state(i), in: rect, ctx: &ctx)
                }
            }
        }
        .aspectRatio(CGFloat(columns) / CGFloat(max(1, rows)), contentMode: .fit)
    }

    private var rows: Int { (count + columns - 1) / columns }

    private func draw(_ s: DotState, in rect: CGRect, ctx: inout GraphicsContext) {
        let path = Path(ellipseIn: rect)
        switch s {
        case .empty: ctx.fill(path, with: .color(Ink.empty))
        case .filled: ctx.fill(path, with: .color(Ink.ink))
        case .accent: ctx.fill(path, with: .color(tint))
        case .today:
            let w = max(1, rect.width * 0.22)
            ctx.stroke(Path(ellipseIn: rect.insetBy(dx: w / 2, dy: w / 2)), with: .color(tint), lineWidth: w)
        case .level(let l):
            ctx.fill(path, with: .color(l <= 0 ? Ink.empty : tint.opacity(Dot.opacity(for: l))))
        }
    }
}

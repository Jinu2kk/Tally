import SwiftUI
import UIKit

/// 잠금화면 배경화면 = 배경 + 달력 (FR-7.13, 7.15, IC-18)
struct CalendarWallpaperView: View {
    let size: CGSize
    let style: CalendarStyle
    let photo: UIImage?
    let snapshot: CalendarSnapshot

    var body: some View {
        ZStack(alignment: .top) {
            CalendarBackgroundView(style: style, photo: photo)
                .frame(width: size.width, height: size.height)
                .clipped()
            // 위쪽 약 35%는 잠금화면 시계·위젯 자리
            let top = size.height * (snapshot.weeks.count == 1 ? 0.62 : 0.345)
            MonthCalendarGrid(snapshot: snapshot, style: style,
                              width: .init(value: size.width * 0.94 * style.wallpaperScale),
                              maxHeight: (size.height - top - size.height * 0.05) * style.wallpaperScale)
                .padding(.top, top)
                .frame(width: size.width)
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .clipped()
        .environment(\.colorScheme, .light)
    }
}

enum CalendarWallpaperError: Error, CustomLocalizedStringResourceConvertible {
    case noAccess, renderFailed
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noAccess: "Tally에 캘린더 권한이 없어요. 앱을 열어 캘린더를 연결해 주세요."
        case .renderFailed: "배경화면을 만들지 못했어요."
        }
    }
}

enum CalendarWallpaper {
    /// 앱이 화면에 떠 있을 때 기기 화면 크기를 기억해 둔다 (단축어는 백그라운드라 화면 정보를 못 얻을 수 있음)
    static let screenKey = "lastScreen" // [w, h, scale]

    @MainActor
    static func rememberScreen(_ screen: UIScreen?) {
        guard let s = screen else { return }
        AppSettings.store.set([Double(s.bounds.width), Double(s.bounds.height), Double(s.scale)], forKey: screenKey)
    }

    static var screen: (size: CGSize, scale: CGFloat) {
        if let a = AppSettings.store.array(forKey: screenKey) as? [Double], a.count == 3 {
            return (CGSize(width: a[0], height: a[1]), a[2])
        }
        return (Wallpaper.defaultSize, 3)
    }

    /// 지금 일정과 설정으로 배경화면을 만든다. weekly가 nil이면 설정값
    @MainActor
    static func render(weekly: Bool? = nil, now: Date = .now, size: CGSize? = nil, scale: CGFloat? = nil,
                       style overrideStyle: CalendarStyle? = nil) throws -> UIImage {
        let store = CalendarStore.shared
        store.reload()
        guard store.hasAccess else { throw CalendarWallpaperError.noAccess }
        var style = overrideStyle ?? .current
        if let weekly { style.wallpaperWeekly = weekly }
        let cal = AppSettings.calendar
        let snapshot0 = CalendarSnapshot.make(month: now, events: [], holidays: [], today: now, calendar: cal, weekly: style.wallpaperWeekly)
        guard let interval = snapshot0.interval else { throw CalendarWallpaperError.renderFailed }
        let events = store.events(in: interval)
        let holidays = CalendarMath.holidays(events, holidayCalendarIDs: store.holidayCalendarIDs, calendar: cal)
        var snapshot = CalendarSnapshot.make(month: now, events: events, holidays: holidays, today: now, calendar: cal, weekly: style.wallpaperWeekly)
        snapshot.lanes = style.wallpaperWeekly ? 7 : 4

        let screen = screen
        let view = CalendarWallpaperView(size: size ?? screen.size, style: style,
                                         photo: style.background == .photo ? CalendarBackgroundStore.load() : nil,
                                         snapshot: snapshot)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale ?? screen.scale
        guard let image = renderer.uiImage else { throw CalendarWallpaperError.renderFailed }
        return image
    }
}

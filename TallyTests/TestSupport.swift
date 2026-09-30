import Foundation

/// 테스트용 고정 달력/날짜
enum TS {
    static func calendar(tz: String = "Asia/Seoul", mondayFirst: Bool = false) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: tz)!
        c.firstWeekday = mondayFirst ? 2 : 1
        return c
    }

    static func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12, cal: Calendar = calendar()) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    static func days(_ list: [(Int, Int, Int)], cal: Calendar = calendar()) -> Set<Date> {
        Set(list.map { cal.startOfDay(for: date($0.0, $0.1, $0.2, cal: cal)) })
    }
}

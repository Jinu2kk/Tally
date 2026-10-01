import SwiftUI
import UIKit

/// 탭 「달력」 (FR-7). 기본 캘린더 일정을 월간 달력으로
struct CalendarTabView: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.openURL) private var openURL

    // 표시 설정 — 바뀌면 화면이 다시 그려지도록 각각 구독
    @AppStorage(SettingsKey.weekStartsOnMonday, store: AppSettings.store) private var mondayFirst = false
    @AppStorage(SettingsKey.tint, store: AppSettings.store) private var tintRaw = ThemeTint.tomato.rawValue
    @AppStorage(SettingsKey.emphasizeHoliday, store: AppSettings.store) private var emHoliday = true
    @AppStorage(SettingsKey.emphasizeSaturday, store: AppSettings.store) private var emSat = false
    @AppStorage(SettingsKey.emphasizeSunday, store: AppSettings.store) private var emSun = true
    @AppStorage(SettingsKey.hideAdjacentDays, store: AppSettings.store) private var hideAdjacent = false
    @AppStorage(SettingsKey.todayColor, store: AppSettings.store) private var todayHex = ""
    @AppStorage(SettingsKey.calendarBackground, store: AppSettings.store) private var bgKind = CalendarBackgroundKind.none.rawValue
    @AppStorage(SettingsKey.backgroundColor, store: AppSettings.store) private var bgHex = "1E3A3A"
    @AppStorage(SettingsKey.backgroundPattern, store: AppSettings.store) private var bgPattern = 0
    @AppStorage(SettingsKey.backgroundOpacity, store: AppSettings.store) private var bgOpacity = 0.7
    @AppStorage(SettingsKey.backgroundBlur, store: AppSettings.store) private var bgBlur = 0.0
    @AppStorage(SettingsKey.statsPeriod, store: AppSettings.store) private var periodRaw = CalendarPeriod.month.rawValue

    @State private var month = Date.now
    @State private var photo: UIImage?
    @State private var selectedDay: Date?
    @State private var editor: EditorTarget?
    @State private var sheet: Sheet?
    @State private var dragX: CGFloat = 0

    enum Sheet: String, Identifiable { case design, calendars, wallpaper, agenda, settings; var id: String { rawValue } }

    private var calendar: Calendar { AppSettings.calendar(mondayFirst: mondayFirst) }

    private var style: CalendarStyle {
        CalendarStyle(emphasizeHoliday: emHoliday, emphasizeSaturday: emSat, emphasizeSunday: emSun,
                      hideAdjacentDays: hideAdjacent, todayHex: todayHex,
                      tintHex: (ThemeTint(rawValue: tintRaw) ?? .tomato).hex,
                      background: CalendarBackgroundKind(rawValue: bgKind) ?? .none,
                      backgroundHex: bgHex, pattern: bgPattern, opacity: bgOpacity, blur: bgBlur)
    }

    var body: some View {
        let style = style
        ZStack {
            CalendarBackgroundView(style: style, photo: photo)
                .ignoresSafeArea()
            if store.hasAccess {
                content(style)
            } else {
                permissionCard
            }
        }
        .sheet(item: $sheet, onDismiss: reloadPhoto) { s in
            switch s {
            case .design: CalendarDesignSheet()
            case .calendars: CalendarPickerSheet()
            case .wallpaper: CalendarWallpaperSheet()
            case .agenda: AgendaSheet(onEdit: openEditorAfterDismiss)
            case .settings: SettingsView()
            }
        }
        .sheet(item: Binding(get: { selectedDay.map(IdentifiedDate.init) }, set: { selectedDay = $0?.date })) {
            DayEventsSheet(day: $0.date, onEdit: openEditorAfterDismiss)
        }
        .sheet(item: $editor) { t in
            EventEditor(store: store.eventStore, event: t.eventID.flatMap(store.event(id:)), start: t.start) {
                editor = nil
                store.reload()
            }
            .ignoresSafeArea()
        }
        .onAppear {
            reloadPhoto()
            store.reload()
            CalendarWallpaper.rememberScreen((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen)
        }
        .onChange(of: bgKind) { reloadPhoto() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in store.reload() }
    }

    // MARK: 본문

    private func content(_ style: CalendarStyle) -> some View {
        let fg: Color = style.onImage ? .white : Ink.ink
        return GeometryReader { geo in
            let width = geo.size.width - 16
            let interval = CalendarMath.gridInterval(for: month, calendar: calendar)
            let _ = store.revision
            let events = interval.map { store.events(in: $0) } ?? []
            let holidays = CalendarMath.holidays(events, holidayCalendarIDs: store.holidayCalendarIDs, calendar: calendar)
            let snapshot = CalendarSnapshot.make(month: month, events: events, holidays: holidays, calendar: calendar)

            // 위 버튼줄(약 62)과 아래 통계줄(약 70)을 뺀 높이에 맞춘다
            let gridHeight = geo.size.height - 62 - 70 - 16
            VStack(spacing: 0) {
                topBar(fg: fg)
                Spacer(minLength: 8)
                ZStack(alignment: .topTrailing) {
                    MonthCalendarGrid(snapshot: snapshot, style: style, width: .init(value: width), maxHeight: gridHeight) { day in
                        selectedDay = calendar.startOfDay(for: day)
                    }
                    monthControls(fg: fg).padding(.top, 14)
                }
                .offset(x: dragX)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { v in if abs(v.translation.width) > abs(v.translation.height) { dragX = v.translation.width / 3 } }
                        .onEnded { v in
                            if v.translation.width < -80 { shift(1) } else if v.translation.width > 80 { shift(-1) }
                            withAnimation(.spring(response: 0.3)) { dragX = 0 }
                        }
                )
                .padding(.horizontal, 8)
                Spacer(minLength: 8)
                statsBar(fg: fg)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button { editor = EditorTarget(start: selectedOrToday) } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color(hex: style.tintHex)))
                    .overlay(Circle().strokeBorder(Ink.ink, lineWidth: style.onImage ? 0 : Metrics.border))
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            }
            .accessibilityLabel("일정 추가")
            .padding(.trailing, 18)
            .padding(.bottom, 8)
        }
    }

    private var selectedOrToday: Date {
        calendar.isDate(month, equalTo: .now, toGranularity: .month) ? .now : (calendar.dateInterval(of: .month, for: month)?.start ?? .now)
    }

    private func topBar(fg: Color) -> some View {
        HStack {
            Button { sheet = .agenda } label: {
                Image(systemName: "list.bullet.below.rectangle").font(.title3.weight(.semibold)).foregroundStyle(fg)
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(fg.opacity(0.25), lineWidth: 1))
            }
            .accessibilityLabel("다가오는 일정")
            Spacer()
            HStack(spacing: 20) {
                iconButton("paintpalette", label: "디자인", fg: fg) { sheet = .design }
                iconButton("checklist", label: "캘린더 선택", fg: fg) { sheet = .calendars }
                iconButton("square.and.arrow.up", label: "배경화면 만들기", fg: fg) { sheet = .wallpaper }
                iconButton("gearshape", label: "설정", fg: fg) { sheet = .settings }
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(fg.opacity(0.25), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func iconButton(_ icon: String, label: String, fg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).font(.title3.weight(.semibold)).foregroundStyle(fg) }
            .accessibilityLabel(label)
    }

    private func monthControls(fg: Color) -> some View {
        HStack(spacing: 14) {
            if !calendar.isDate(month, equalTo: .now, toGranularity: .month) {
                Button { withAnimation(.snappy) { month = .now } } label: {
                    Text("Today").font(.subheadline.weight(.bold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(fg.opacity(0.15)))
                }
                .accessibilityLabel("오늘로")
            }
            Button { shift(-1) } label: { Image(systemName: "chevron.left").padding(6) }
                .accessibilityLabel("이전 달")
            Button { shift(1) } label: { Image(systemName: "chevron.right").padding(6) }
                .accessibilityLabel("다음 달")
        }
        .font(.title3.weight(.semibold))
        .foregroundStyle(fg)
        .padding(.trailing, 8)
    }

    private func shift(_ n: Int) {
        withAnimation(.snappy) { month = calendar.date(byAdding: .month, value: n, to: month) ?? month }
    }

    // MARK: 통계 (FR-7.8)

    private func statsBar(fg: Color) -> some View {
        let period = CalendarPeriod(rawValue: periodRaw) ?? .month
        let base = period == .month ? month : Date.now
        let interval = CalendarMath.interval(of: period, containing: base, calendar: calendar)
        let stats = interval.map { CalendarMath.periodStats(store.events(in: $0), in: $0, calendar: calendar) }
        return HStack(spacing: 12) {
            Picker("기간", selection: $periodRaw) {
                ForEach(CalendarPeriod.allCases) { Text($0.title).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
            Spacer(minLength: 0)
            if let stats {
                HStack(spacing: 14) {
                    statText(stats.eventCount, unit: "개", label: "일정", fg: fg)
                    statText(stats.busyDays, unit: "일", label: "바쁜 날", fg: fg)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(fg.opacity(0.2), lineWidth: 1))
        .padding(.trailing, 70) // + 버튼 자리
    }

    private func statText(_ n: Int, unit: String, label: String, fg: Color) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(n)\(unit)").font(.system(.headline, design: .rounded).weight(.heavy)).foregroundStyle(fg)
            Text(label).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(fg.opacity(0.6))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: 권한 (FR-7.1)

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<7) { i in Dot(state: i == 3 ? .accent : .empty, tint: .accentColor, size: 12) }
            }
            Text("기본 캘린더를 연결하세요").font(.title3.weight(.bold)).foregroundStyle(Ink.ink)
            Text("iPhone 캘린더(구글·iCloud 계정 포함)의 일정을 달력과 배경화면에 보여 줘요. 일정은 Tally에 따로 저장하지 않아요.")
                .font(.subheadline).foregroundStyle(Ink.faint)
            Button {
                if store.status == .notDetermined {
                    Task { await store.requestAccess() }
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text(store.status == .notDetermined ? "캘린더 연결" : "설정에서 권한 켜기")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
        }
        .inkCard(padding: 20)
        .padding(16)
    }

    // MARK: 기타

    private func openEditorAfterDismiss(_ t: EditorTarget) {
        selectedDay = nil
        sheet = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { editor = t }
    }

    private func reloadPhoto() {
        photo = bgKind == CalendarBackgroundKind.photo.rawValue ? CalendarBackgroundStore.load() : nil
    }
}

struct IdentifiedDate: Identifiable {
    let date: Date
    var id: Date { date }
}

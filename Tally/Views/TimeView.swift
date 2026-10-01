import SwiftUI
import SwiftData
import UIKit
import WidgetKit

/// 탭 「시간」 — 올해 진행률, 라이프 캘린더, D-Day, 배경화면 (FR-2)
struct TimeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DDay.date) private var ddays: [DDay]
    @AppStorage(SettingsKey.birthDate, store: AppSettings.store) private var birthRaw: Double = 0
    @AppStorage(SettingsKey.lifeExpectancy, store: AppSettings.store) private var expectancy = AppSettings.defaultLifeExpectancy
    @AppStorage(SettingsKey.weekStartsOnMonday, store: AppSettings.store) private var mondayFirst = false
    @AppStorage(SettingsKey.tint, store: AppSettings.store) private var tintRaw = ThemeTint.tomato.rawValue

    @State private var now = Date.now
    @State private var showBirth = false
    @State private var showNewDDay = false

    private var calendar: Calendar { AppSettings.calendar(mondayFirst: mondayFirst) }
    private var birth: Date? { birthRaw == 0 ? nil : Date(timeIntervalSinceReferenceDate: birthRaw) }
    private var tint: Color { (ThemeTint(rawValue: tintRaw) ?? .tomato).color }

    var body: some View {
        PaperScreen(String(localized: "시간"), subtitle: String(localized: "남은 날을 세는 곳")) {
            EmptyView()
        } content: {
            yearCard
            lifeCard
            ddaySection
            WallpaperCard()
        }
        .sheet(isPresented: $showBirth) { BirthSettingsView() }
        .sheet(isPresented: $showNewDDay) { DDayEditorView() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
    }

    // MARK: 올해 (FR-2.1)

    private var yearCard: some View {
        let y = YearProgress(now: now, calendar: calendar)
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(String(localized: "\(String(y.year))년")) {
                Text("\(y.dayOfYear)일째").font(.label).foregroundStyle(Ink.faint)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(y.percent)").font(.number(52))
                Text("%").font(.number(22)).foregroundStyle(Ink.faint)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(y.daysLeft)").font(.number(26)).foregroundStyle(tint)
                    Text("일 남음").labelStyle()
                }
            }
            .foregroundStyle(Ink.ink)
            DotCanvas(count: y.daysInYear, columns: 21, tint: tint) { i in
                i < y.dayOfYear - 1 ? .filled : (i == y.dayOfYear - 1 ? .today : .empty)
            }
            .accessibilityLabel("올해 \(y.daysInYear)일 중 \(y.dayOfYear)일째")
        }
        .inkCard(padding: 18)
    }

    // MARK: 인생 (FR-2.2)

    @ViewBuilder private var lifeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(String(localized: "Memento mori")) {
                Button { showBirth = true } label: {
                    Image(systemName: "slider.horizontal.3").font(.footnote.weight(.bold))
                }
                .foregroundStyle(Ink.ink)
                .accessibilityLabel("생년월일 설정")
            }
            if let birth {
                let l = LifeProgress(birth: birth, expectancy: expectancy, now: now, calendar: calendar)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(l.livedWeeks.formatted()).font(.number(34))
                        Text("주 살았고").labelStyle()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(l.weeksLeft.formatted()).font(.number(34)).foregroundStyle(tint)
                        Text("주 남았어요").labelStyle()
                    }
                }
                .foregroundStyle(Ink.ink)
                DotCanvas(count: l.totalWeeks, columns: 52, spacingRatio: 0.5, tint: tint) { i in
                    i < l.livedWeeks ? .filled : (i == l.livedWeeks ? .today : .empty)
                }
                .accessibilityLabel("\(expectancy)년 중 \(l.percent)퍼센트")
                Text("한 줄 = 1년 · 점 하나 = 1주 · 기대 수명 \(expectancy)세")
                    .font(.caption2).foregroundStyle(Ink.faint)
            } else {
                Text("생년월일을 입력하면 평생을 주 단위 점으로 보여 드려요.")
                    .font(.subheadline).foregroundStyle(Ink.faint)
                Button { showBirth = true } label: {
                    Text("생년월일 입력")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(tint))
                        .foregroundStyle(.white)
                }
            }
        }
        .inkCard(padding: 18)
    }

    // MARK: D-Day (FR-2.3)

    private var ddaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(String(localized: "D-Day")) {
                Button { showNewDDay = true } label: { Image(systemName: "plus").font(.footnote.weight(.bold)) }
                    .foregroundStyle(Ink.ink)
                    .accessibilityLabel("D-Day 추가")
            }
            if ddays.isEmpty {
                Text("기다리는 날을 추가해 보세요").font(.subheadline).foregroundStyle(Ink.faint)
                    .inkCard(padding: 14)
            }
            ForEach(ddays) { d in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(d.title).font(.headline).foregroundStyle(Ink.ink)
                        Text(d.date.formatted(.dateTime.locale(.app).year().month().day().weekday()))
                            .font(.label).foregroundStyle(Ink.faint)
                    }
                    Spacer()
                    let past = DDayMath.daysUntil(d.date, now: now, calendar: calendar) < 0
                    Text(DDayMath.label(d.date, now: now, calendar: calendar))
                        .font(.number(24))
                        .foregroundStyle(past ? Ink.faint : tint)
                }
                .inkCard(padding: 14)
                .contextMenu {
                    Button(role: .destructive) {
                        context.delete(d)
                        try? context.save()
                    } label: { Label("삭제", systemImage: "trash") }
                }
            }
        }
    }
}

// MARK: - 배경화면 카드 (FR-2.5)

private struct WallpaperCard: View {
    @AppStorage(SettingsKey.wallpaperKind, store: AppSettings.store) private var kindRaw = WallpaperKind.year.rawValue
    @AppStorage(SettingsKey.tint, store: AppSettings.store) private var tintRaw = ThemeTint.tomato.rawValue
    @AppStorage(SettingsKey.birthDate, store: AppSettings.store) private var birthRaw: Double = 0
    @State private var dark = false
    @State private var image: UIImage?
    @State private var fileURL: URL?

    private var kind: WallpaperKind { WallpaperKind(rawValue: kindRaw) ?? .year }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(String(localized: "배경화면"))
            HStack(alignment: .top, spacing: 16) {
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        Rectangle().fill(Ink.empty)
                    }
                }
                .frame(width: 96, height: 208)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Ink.ink, lineWidth: Metrics.border))

                VStack(alignment: .leading, spacing: 12) {
                    Picker("종류", selection: $kindRaw) {
                        ForEach(WallpaperKind.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("어두운 배경", isOn: $dark).font(.subheadline)
                    if image != nil, let fileURL {
                        Button { ShareSheet.present([fileURL]) } label: {
                            Label("저장 · 공유", systemImage: "square.and.arrow.down")
                                .font(.subheadline.weight(.bold))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(Ink.ink))
                                .foregroundStyle(Ink.paper)
                        }
                    }
                    Text("단축어 앱의 ‘Tally 배경화면 만들기’로 매일 자동으로 바꿀 수 있어요.")
                        .font(.caption2).foregroundStyle(Ink.faint)
                }
            }
        }
        .inkCard(padding: 18)
        .task(id: "\(kindRaw)-\(dark)-\(tintRaw)-\(birthRaw)") { render() }
    }

    @MainActor private func render() {
        let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen
        image = Wallpaper.render(kind: kind, size: screen?.bounds.size ?? Wallpaper.defaultSize,
                                 scale: screen?.scale ?? 3, dark: dark)
        fileURL = image?.temporaryPNG(named: "Tally 배경화면")
    }
}

// MARK: - 생년월일 / 기대 수명

struct BirthSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.birthDate, store: AppSettings.store) private var birthRaw: Double = 0
    @AppStorage(SettingsKey.lifeExpectancy, store: AppSettings.store) private var expectancy = AppSettings.defaultLifeExpectancy
    @State private var birth = Calendar.current.date(from: DateComponents(year: 1995, month: 1, day: 1)) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("생년월일", selection: $birth, in: ...Date.now, displayedComponents: .date)
                    .environment(\.locale, .app)
                Stepper(value: $expectancy, in: AppSettings.lifeExpectancyRange) {
                    HStack {
                        Text("기대 수명")
                        Spacer()
                        Text("\(expectancy)세").monospacedDigit().foregroundStyle(Ink.faint)
                    }
                }
                if birthRaw != 0 {
                    Button("생년월일 지우기", role: .destructive) { birthRaw = 0; dismiss() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle("라이프 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        birthRaw = Calendar.current.startOfDay(for: birth).timeIntervalSinceReferenceDate
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
            }
            .onAppear { if birthRaw != 0 { birth = Date(timeIntervalSinceReferenceDate: birthRaw) } }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - D-Day 추가

struct DDayEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                TextField("이름 (예: 여행)", text: $title)
                DatePicker("날짜", selection: $date, displayedComponents: .date)
                    .environment(\.locale, .app)
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle("새 D-Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        context.insert(DDay(title: title.trimmingCharacters(in: .whitespaces),
                                            date: Calendar.current.startOfDay(for: date)))
                        try? context.save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

import SwiftUI
import SwiftData
import UIKit
import UserNotifications
import WidgetKit

/// 설정 (FR-6)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Habit> { $0.isArchived }, sort: \Habit.name) private var archived: [Habit]

    @AppStorage(SettingsKey.appearance, store: AppSettings.store) private var appearance = AppearanceMode.system.rawValue
    @AppStorage(SettingsKey.tint, store: AppSettings.store) private var tintRaw = ThemeTint.tomato.rawValue
    @AppStorage(SettingsKey.weekStartsOnMonday, store: AppSettings.store) private var mondayFirst = false
    @AppStorage(SettingsKey.birthDate, store: AppSettings.store) private var birthRaw: Double = 0
    @AppStorage(SettingsKey.lifeExpectancy, store: AppSettings.store) private var expectancy = AppSettings.defaultLifeExpectancy

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showBirth = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("화면") {
                    Picker("모드", selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("테마 색")
                        HStack {
                            ForEach(ThemeTint.allCases) { t in
                                Button { tintRaw = t.rawValue } label: {
                                    Circle().fill(t.color)
                                        .frame(width: 30, height: 30)
                                        .overlay(Circle().strokeBorder(Ink.ink, lineWidth: tintRaw == t.rawValue ? 2.5 : 0).padding(-4))
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel(t.title)
                                .accessibilityAddTraits(tintRaw == t.rawValue ? .isSelected : [])
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    HStack {
                        Text("주 시작")
                        Spacer(minLength: 24)
                        Picker("주 시작 요일", selection: $mondayFirst) {
                            Text("일요일").tag(false)
                            Text("월요일").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 180)
                    }
                }

                Section("라이프 캘린더") {
                    Button { showBirth = true } label: {
                        HStack {
                            Text("생년월일 · 기대 수명").foregroundStyle(Ink.ink)
                            Spacer()
                            Text(birthSummary).foregroundStyle(Ink.faint)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("알림 권한")
                        Spacer()
                        Text(statusText).foregroundStyle(Ink.faint)
                    }
                    if notificationStatus == .denied {
                        Button("설정 앱에서 켜기") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                } header: { Text("알림") } footer: { Text("습관 편집에서 ‘매일 알림’을 켜면 권한을 요청해요.") }

                if !archived.isEmpty {
                    Section("보관한 습관") {
                        ForEach(archived) { h in
                            HStack {
                                Text("\(h.icon) \(h.name)")
                                Spacer()
                                Button("꺼내기") {
                                    h.isArchived = false
                                    try? context.save()
                                    Reminders.sync(h)
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("모든 데이터 초기화", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Tally \(appVersion) · 데이터는 이 기기에만 저장돼요.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } }
            }
            .sheet(isPresented: $showBirth) { BirthSettingsView() }
            .confirmationDialog("습관, 기록, 할 일, D-Day를 모두 지울까요? 되돌릴 수 없어요.",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("모두 삭제", role: .destructive, action: resetAll)
                Button("취소", role: .cancel) {}
            }
            .task { notificationStatus = await Reminders.authorizationStatus() }
            .onChange(of: tintRaw) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: mondayFirst) { WidgetCenter.shared.reloadAllTimelines() }
        }
        .preferredColorScheme(scheme)
    }

    /// 시트는 부모의 preferredColorScheme을 바로 따라가지 않아 직접 지정
    private var scheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearance) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private var birthSummary: String {
        guard birthRaw != 0 else { return String(localized: "미입력") }
        let d = Date(timeIntervalSinceReferenceDate: birthRaw)
        return d.formatted(.dateTime.locale(.app).year().month().day()) + " · \(expectancy)세"
    }

    private var statusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: String(localized: "허용됨")
        case .denied: String(localized: "꺼짐")
        default: String(localized: "요청 전")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// FR-6.4: 확인 대화상자를 거친 뒤에만 호출
    private func resetAll() {
        // 일괄 삭제는 화면의 @Query에 바로 반영되지 않아 하나씩 지운다
        (try? context.fetch(FetchDescriptor<Habit>()))?.forEach(context.delete)   // 기록은 cascade
        (try? context.fetch(FetchDescriptor<TaskItem>()))?.forEach(context.delete)
        (try? context.fetch(FetchDescriptor<DDay>()))?.forEach(context.delete)
        try? context.save()
        Reminders.cancelAll()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

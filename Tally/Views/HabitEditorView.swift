import SwiftUI
import SwiftData
import WidgetKit

/// 습관 생성/수정/보관/삭제 (FR-1.1, FR-1.6)
struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let habit: Habit?
    let nextOrder: Int

    @State private var name = ""
    @State private var icon = "✏️"
    @State private var colorHex = HabitPalette.hexes[0]
    @State private var hasTarget = false
    @State private var targetMinutes = 20
    @State private var hasReminder = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now
    @State private var confirmDelete = false
    @State private var reminderDenied = false

    static let presetIcons = ["💧", "🏃", "📚", "🧘", "✍️", "🥗", "😴", "💊", "🎸", "🧹", "🌱", "📵", "🚶", "🏋️", "🙏", "☕️"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        TextField("", text: $icon)
                            .font(.system(size: 30))
                            .multilineTextAlignment(.center)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color(hex: colorHex).opacity(0.18)))
                            .onChange(of: icon) { _, v in
                                // 마지막으로 입력한 글자 하나만 쓴다
                                if let last = v.last { if String(last) != icon { icon = String(last) } }
                            }
                            .accessibilityLabel("아이콘")
                        TextField("예: 물 2L 마시기", text: $name)
                            .font(.title3.weight(.semibold))
                    }
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(Self.presetIcons, id: \.self) { e in
                                Button { icon = e } label: {
                                    Text(e).font(.title2)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(icon == e ? Ink.empty : .clear))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                } header: { Text("이름과 아이콘") }

                Section {
                    HStack {
                        ForEach(HabitPalette.hexes, id: \.self) { hex in
                            Button { colorHex = hex } label: {
                                Circle().fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(Ink.ink, lineWidth: colorHex == hex ? 2.5 : 0).padding(-4))
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(hex)
                        }
                    }
                    .padding(.vertical, 6)
                } header: { Text("색") }

                Section {
                    Toggle("목표 시간", isOn: $hasTarget.animation())
                    if hasTarget {
                        Stepper(value: $targetMinutes, in: 5...600, step: 5) {
                            Text("\(targetMinutes)분").monospacedDigit()
                        }
                    }
                    Toggle("매일 알림", isOn: $hasReminder.animation())
                    if hasReminder {
                        DatePicker("시각", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if reminderDenied {
                        Text("알림 권한이 꺼져 있어요. 설정 앱에서 Tally 알림을 켜 주세요.")
                            .font(.footnote).foregroundStyle(.red)
                    }
                } header: { Text("옵션") }

                if let habit {
                    Section {
                        Button(habit.isArchived ? "보관 해제" : "보관하기") { toggleArchive(habit) }
                        Button("삭제", role: .destructive) { confirmDelete = true }
                    } footer: {
                        Text("보관하면 목록과 위젯에서 숨겨지고 기록은 남아요.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle(habit == nil ? "새 습관" : "습관 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { Task { await save() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("이 습관과 모든 기록을 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) { delete() }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let h = habit else { return }
        name = h.name
        icon = h.icon
        colorHex = h.colorHex
        if let m = h.targetMinutes { hasTarget = true; targetMinutes = m }
        if let hh = h.reminderHour, let mm = h.reminderMinute {
            hasReminder = true
            reminderTime = Calendar.current.date(bySettingHour: hh, minute: mm, second: 0, of: .now) ?? reminderTime
        }
    }

    @MainActor
    private func save() async {
        if hasReminder, !(await Reminders.requestAuthorization()) {
            reminderDenied = true
            return
        }
        let h = habit ?? Habit(name: "", icon: icon, colorHex: colorHex, sortOrder: nextOrder)
        h.name = name.trimmingCharacters(in: .whitespaces)
        h.icon = icon.isEmpty ? "✏️" : icon
        h.colorHex = colorHex
        h.targetMinutes = hasTarget ? targetMinutes : nil
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        h.reminderHour = hasReminder ? comps.hour : nil
        h.reminderMinute = hasReminder ? comps.minute : nil
        if habit == nil { context.insert(h) }
        try? context.save()
        Reminders.sync(h)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    private func toggleArchive(_ h: Habit) {
        h.isArchived.toggle()
        try? context.save()
        Reminders.sync(h)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    private func delete() {
        guard let h = habit else { return }
        Reminders.cancel(h)
        context.delete(h)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

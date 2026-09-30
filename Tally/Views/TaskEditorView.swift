import SwiftUI
import SwiftData

/// 할 일 추가/수정 (FR-3.2)
struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let task: TaskItem?
    @State var quadrant: Quadrant

    @State private var title = ""
    @State private var note = ""
    @State private var hasDue = false
    @State private var due = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now

    init(task: TaskItem?, quadrant: Quadrant) {
        self.task = task
        _quadrant = State(initialValue: quadrant)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("할 일", text: $title)
                        .font(.title3.weight(.semibold))
                    TextField("메모", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Quadrant.allCases) { q in
                            Button { quadrant = q } label: {
                                HStack(spacing: 6) {
                                    QuadrantMark(quadrant: q, size: 10)
                                    Text(q.title).font(.subheadline.weight(.semibold))
                                    Spacer(minLength: 0)
                                }
                                .padding(10)
                                .foregroundStyle(quadrant == q ? Ink.paper : Ink.ink)
                                .background(RoundedRectangle(cornerRadius: 10).fill(quadrant == q ? Ink.ink : Ink.empty.opacity(0.5)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("사분면") } footer: { Text(quadrant.subtitle) }

                Section {
                    Toggle("마감일", isOn: $hasDue.animation())
                    if hasDue {
                        DatePicker("날짜", selection: $due, displayedComponents: .date)
                            .environment(\.locale, .app)
                    }
                }
                if let task {
                    Section {
                        Button("삭제", role: .destructive) {
                            context.delete(task)
                            try? context.save()
                            dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Ink.paper)
            .navigationTitle(task == nil ? "새 할 일" : "할 일 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let task else { return }
                title = task.title
                note = task.note
                if let d = task.dueDate { hasDue = true; due = d }
            }
        }
    }

    private func save() {
        let t = task ?? TaskItem(title: "", quadrant: quadrant)
        if task == nil {
            let maxOrder = (try? context.fetch(FetchDescriptor<TaskItem>()))?.map(\.sortOrder).max() ?? -1
            t.sortOrder = maxOrder + 1
            context.insert(t)
        }
        t.title = title.trimmingCharacters(in: .whitespaces)
        t.note = note
        t.quadrant = quadrant
        t.dueDate = hasDue ? Calendar.current.startOfDay(for: due) : nil
        try? context.save()
        dismiss()
    }
}

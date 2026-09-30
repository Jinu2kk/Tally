import SwiftUI
import SwiftData

/// 탭 「우선순위」 — 아이젠하워 매트릭스 (FR-3)
struct MatrixView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\TaskItem.sortOrder), SortDescriptor(\TaskItem.createdAt)])
    private var tasks: [TaskItem]
    @AppStorage(SettingsKey.hideDoneTasks, store: AppSettings.store) private var hideDone = false
    @AppStorage(SettingsKey.matrixListMode, store: AppSettings.store) private var listMode = false

    @State private var newIn: Quadrant?
    @State private var editing: TaskItem?

    var body: some View {
        let open = tasks.filter { !$0.isDone }.count
        PaperScreen(String(localized: "우선순위"), subtitle: String(localized: "남은 할 일 \(open)개")) {
            Button { withAnimation { hideDone.toggle() } } label: {
                Image(systemName: hideDone ? "eye.slash" : "eye")
            }
            .accessibilityLabel(hideDone ? "완료 항목 보이기" : "완료 항목 숨기기")
            Button { withAnimation(.snappy) { listMode.toggle() } } label: {
                Image(systemName: listMode ? "square.grid.2x2" : "list.bullet")
            }
            .accessibilityLabel(listMode ? "매트릭스 보기" : "목록 보기")
        } content: {
            if listMode {
                VStack(spacing: 18) {
                    ForEach(Quadrant.allCases) { q in
                        ListSection(quadrant: q, tasks: items(in: q), onAdd: { newIn = q },
                                    onEdit: { editing = $0 }, onMove: move, onDelete: delete)
                    }
                }
            } else {
                axisLabels
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(Quadrant.allCases) { q in
                        QuadrantCard(quadrant: q, tasks: items(in: q), onAdd: { newIn = q },
                                     onEdit: { editing = $0 }, onMove: move, onDelete: delete)
                    }
                }
                Text("할 일을 길게 눌러 다른 칸으로 끌어 옮길 수 있어요")
                    .font(.caption2)
                    .foregroundStyle(Ink.faint)
                    .frame(maxWidth: .infinity)
            }
        }
        .sheet(item: $newIn) { TaskEditorView(task: nil, quadrant: $0) }
        .sheet(item: $editing) { TaskEditorView(task: $0, quadrant: $0.quadrant) }
    }

    private var axisLabels: some View {
        HStack(spacing: 14) {
            Text("긴급함").labelStyle().frame(maxWidth: .infinity)
            Text("급하지 않음").labelStyle().frame(maxWidth: .infinity)
        }
        .padding(.bottom, -8)
    }

    private func items(in q: Quadrant) -> [TaskItem] {
        tasks
            .filter { $0.quadrant == q && !(hideDone && $0.isDone) }
            .sorted { ($0.isDone ? 1 : 0, $0.sortOrder) < ($1.isDone ? 1 : 0, $1.sortOrder) }
    }

    /// 드래그 앤 드롭 또는 메뉴로 사분면 이동 (IC-9)
    private func move(_ id: String, to q: Quadrant) -> Bool {
        guard let task = tasks.first(where: { $0.id.uuidString == id }) else { return false }
        guard task.quadrant != q else { return false }
        withAnimation(.snappy) {
            task.quadrant = q
            task.sortOrder = (tasks.filter { $0.quadrant == q }.map(\.sortOrder).max() ?? -1) + 1
        }
        try? context.save()
        return true
    }

    private func delete(_ task: TaskItem) {
        withAnimation { context.delete(task) }
        try? context.save()
    }
}

// MARK: - 사분면 표식

struct QuadrantMark: View {
    let quadrant: Quadrant
    var size: CGFloat = 12

    var body: some View {
        switch quadrant {
        case .doFirst: Dot(state: .accent, tint: .accentColor, size: size)
        case .schedule: Dot(state: .filled, tint: .accentColor, size: size)
        case .delegate: Dot(state: .today, tint: .accentColor, size: size)
        case .eliminate: Circle().strokeBorder(Ink.faint, style: StrokeStyle(lineWidth: 1.2, dash: [2, 2]))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - 매트릭스 카드

private struct QuadrantCard: View {
    let quadrant: Quadrant
    let tasks: [TaskItem]
    let onAdd: () -> Void
    let onEdit: (TaskItem) -> Void
    let onMove: (String, Quadrant) -> Bool
    let onDelete: (TaskItem) -> Void

    @State private var targeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                QuadrantMark(quadrant: quadrant)
                Text(quadrant.code).font(.label).foregroundStyle(Ink.faint)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus").font(.footnote.weight(.bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Ink.ink)
                .accessibilityLabel("\(quadrant.title)에 추가")
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(quadrant.title).font(.headline).foregroundStyle(Ink.ink)
                Text(quadrant.subtitle).font(.caption2).foregroundStyle(Ink.faint).lineLimit(1)
            }
            Rectangle().fill(Ink.line).frame(height: 1)
            if tasks.isEmpty {
                Text("비어 있음").font(.caption).foregroundStyle(Ink.faint)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tasks) { task in
                        TaskLine(task: task, compact: true, onEdit: { onEdit(task) }, onMove: onMove, onDelete: { onDelete(task) })
                            .draggable(task.id.uuidString) {
                                Text(task.title).font(.subheadline.weight(.semibold))
                                    .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Ink.card))
                            }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 200, alignment: .top)
        .inkCard(padding: 12, fill: targeted ? Color.accentColor.opacity(0.15) : Ink.card)
        .scaleEffect(targeted ? 1.02 : 1)
        .animation(.snappy, value: targeted)
        .dropDestination(for: String.self) { ids, _ in
            ids.map { onMove($0, quadrant) }.contains(true)
        } isTargeted: { targeted = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quadrant-\(quadrant.code)")
    }
}

// MARK: - 목록 보기

private struct ListSection: View {
    let quadrant: Quadrant
    let tasks: [TaskItem]
    let onAdd: () -> Void
    let onEdit: (TaskItem) -> Void
    let onMove: (String, Quadrant) -> Bool
    let onDelete: (TaskItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                QuadrantMark(quadrant: quadrant)
                Text(quadrant.title).font(.headline).foregroundStyle(Ink.ink)
                Text(quadrant.subtitle).font(.caption2).foregroundStyle(Ink.faint)
                Spacer()
                Button(action: onAdd) { Image(systemName: "plus") }
                    .foregroundStyle(Ink.ink)
                    .accessibilityLabel("\(quadrant.title)에 추가")
            }
            if tasks.isEmpty {
                Text("비어 있음").font(.caption).foregroundStyle(Ink.faint)
            }
            ForEach(tasks) { task in
                TaskLine(task: task, compact: false, onEdit: { onEdit(task) }, onMove: onMove, onDelete: { onDelete(task) })
                    .inkCard(padding: 12)
                    .swipeToDelete { onDelete(task) }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("task-row")
            }
        }
    }
}

// MARK: - 할 일 한 줄

private struct TaskLine: View {
    let task: TaskItem
    let compact: Bool
    let onEdit: () -> Void
    let onMove: (String, Quadrant) -> Bool
    let onDelete: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { task.isDone.toggle() }
                try? context.save()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4).strokeBorder(Ink.ink, lineWidth: 1.3)
                    if task.isDone {
                        RoundedRectangle(cornerRadius: 4).fill(Color.accentColor)
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .black)).foregroundStyle(.white)
                    }
                }
                .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                .padding(.top, 1)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: task.isDone) { _, new in new }
            .accessibilityLabel(task.isDone ? "완료 취소" : "완료")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(compact ? .footnote.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(task.isDone ? Ink.faint : Ink.ink)
                    .strikethrough(task.isDone)
                    .lineLimit(compact ? 2 : 3)
                if let due = task.dueDate {
                    Text(DDayMath.label(due, now: .now, calendar: .current) + " · " + due.formatted(.dateTime.locale(.app).month().day()))
                        .font(.label)
                        .foregroundStyle(due < Calendar.current.startOfDay(for: .now) && !task.isDone ? Color.accentColor : Ink.faint)
                }
                if !compact, !task.note.isEmpty {
                    Text(task.note).font(.caption).foregroundStyle(Ink.faint).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button { onEdit() } label: { Label("편집", systemImage: "pencil") }
            Menu {
                ForEach(Quadrant.allCases.filter { $0 != task.quadrant }) { q in
                    Button(q.title) { _ = onMove(task.id.uuidString, q) }
                }
            } label: { Label("옮기기", systemImage: "arrow.right.square") }
            Button(role: .destructive, action: onDelete) { Label("삭제", systemImage: "trash") }
        }
    }
}

// MARK: - 왼쪽으로 밀어 삭제 (ScrollView 안에서 쓰는 가벼운 스와이프)

private struct SwipeToDelete: ViewModifier {
    let onDelete: () -> Void
    @State private var dx: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(alignment: .trailing) {
                Image(systemName: "trash.fill")
                    .foregroundStyle(Color.accentColor)
                    .padding(.trailing, 16)
                    .opacity(Double(min(1, -dx / 80)))
            }
            .offset(x: dx)
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { v in
                        guard abs(v.translation.width) > abs(v.translation.height), v.translation.width < 0 else { return }
                        dx = max(v.translation.width, -120)
                    }
                    .onEnded { _ in
                        if dx < -90 { onDelete() }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dx = 0 }
                    }
            )
    }
}

private extension View {
    func swipeToDelete(_ action: @escaping () -> Void) -> some View { modifier(SwipeToDelete(onDelete: action)) }
}

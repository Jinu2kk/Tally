import SwiftUI

struct RootTabView: View {
    /// 디버그·스크린샷용: 실행 인자 `-tab habits|matrix|time|stats`
    @State private var tab: Tab = Tab(rawValue: UserDefaults.standard.string(forKey: "tab") ?? "") ?? .calendar

    /// 탭 순서: 달력 · 습관 · 할 일 · 시간 · 기록 (DC-7)
    enum Tab: String, Hashable { case calendar, habits, matrix, time, stats }

    var body: some View {
        TabView(selection: $tab) {
            CalendarTabView()
                .tabItem { Label("달력", systemImage: "calendar") }
                .tag(Tab.calendar)
            TodayView()
                .tabItem { Label("습관", systemImage: "circle.dotted.circle") }
                .tag(Tab.habits)
            MatrixView()
                .tabItem { Label("할 일", systemImage: "square.grid.2x2") }
                .tag(Tab.matrix)
            TimeView()
                .tabItem { Label("시간", systemImage: "hourglass") }
                .tag(Tab.time)
            StatsView()
                .tabItem { Label("기록", systemImage: "chart.dots.scatter") }
                .tag(Tab.stats)
        }
    }
}

/// 모든 탭 공통 화면 틀: 종이 배경 + 큰 제목 + 설정 버튼
struct PaperScreen<Content: View, Actions: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var actions: Actions
    @ViewBuilder var content: Content
    @State private var showSettings = false

    init(_ title: String, subtitle: String? = nil,
         @ViewBuilder actions: () -> Actions = { EmptyView() },
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.actions = actions()
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let subtitle { Text(subtitle).labelStyle() }
                        Text(title)
                            .font(.number(34))
                            .foregroundStyle(Ink.ink)
                    }
                    content
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 32)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Ink.paper.ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    actions
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("설정")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }
}

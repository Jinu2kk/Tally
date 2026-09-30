import SwiftUI

struct RootTabView: View {
    /// 디버그·스크린샷용: 실행 인자 `-tab time|matrix|stats`
    @State private var tab: Tab = Tab(rawValue: UserDefaults.standard.string(forKey: "tab") ?? "") ?? .today

    enum Tab: String, Hashable { case today, time, matrix, stats }

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("오늘", systemImage: "circle.dotted.circle") }
                .tag(Tab.today)
            TimeView()
                .tabItem { Label("시간", systemImage: "hourglass") }
                .tag(Tab.time)
            MatrixView()
                .tabItem { Label("우선순위", systemImage: "square.grid.2x2") }
                .tag(Tab.matrix)
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

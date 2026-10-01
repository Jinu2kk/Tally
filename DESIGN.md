# DESIGN — Tally

> 요구사항: [REQUIREMENTS.md](REQUIREMENTS.md) · 구현 계획: [IMPLEMENT.md](IMPLEMENT.md)

## 1. 결정 체크리스트

### 제품 결정 (DC)
- [x] **DC-1 앱 이름 = Tally.** "하나씩 세어 기록하다"라는 뜻이 기능과 맞음. 검증: 홈 화면 표시 이름 확인 (MT-0.1)
- [x] **DC-2 디자인 = "종이 수첩과 잉크".** 숫자와 점 중심의 차분한 인상. 검증: MT-7.x 다크/라이트 점검
- [x] **DC-3 번들 ID 접두어 = `com.jinu2kk`.** 검증: 빌드 설정 확인 (Phase 0 exit)
- [x] **DC-4 iCloud 동기화와 인앱 결제 제외.** 모든 기능 무료. 모델은 CloudKit 호환으로 설계 (§4)
- [x] **DC-5 저장소 = `github.com/Jinu2kk/Tally`.** 기능(Phase) 단위로 커밋하고 바로 push. 인증은 `gh auth login` + `gh auth setup-git`(README "GitHub 인증"). 인증 전에는 로컬 커밋만 쌓고 인증 후 한꺼번에 push

### 구현 결정 (IC)
- [x] **IC-1 프로젝트 형식:** 손으로 작성한 `.xcodeproj` + Xcode 16의 폴더 동기화 그룹(`PBXFileSystemSynchronizedRootGroup`). 파일을 추가해도 pbxproj를 고칠 필요가 없음. XcodeGen 등 외부 도구 불필요. 검증: `xcodebuild -list`
- [x] **IC-2 공유 코드:** `Shared/` 폴더를 앱, 위젯, 테스트 세 타깃에 함께 포함. 별도 프레임워크는 만들지 않음 (타깃 수와 설정 최소화)
- [x] **IC-3 저장소:** App Group 컨테이너의 `Tally.store`. `containerURL`이 nil이면 기본 위치로 대체 (NFR-5). 검증: T-0.2
- [x] **IC-4 설정 저장:** App Group `UserDefaults(suiteName:)`. 위젯이 생년월일, 테마를 읽어야 하므로. 앱에서는 `@AppStorage(store:)`로 사용
- [x] **IC-5 streak 규칙:** 오늘 완료 안 했어도 어제까지 연속이면 streak 유지(오늘은 아직 기회가 있으므로). 어제도 안 했으면 0. 검증: T-1.x
- [x] **IC-6 날짜 키:** `HabitLog.day`는 `Calendar.current.startOfDay`로 정규화해 저장. 같은 날짜 중복 기록은 토글 로직에서 막음 (unique 제약 대신, CloudKit 호환)
- [x] **IC-7 위젯 인터랙션:** `ToggleHabitIntent(habitID:)`를 `Shared/`에 두고 위젯 `Button(intent:)`에서 호출. 인텐트는 공유 ModelContainer에서 직접 토글
- [x] **IC-8 배경화면:** `ImageRenderer`로 `WallpaperView`를 렌더링. 앱은 `ShareLink`, 단축어는 `MakeWallpaperIntent`가 `IntentFile`(PNG) 반환
- [x] **IC-9 드래그 앤 드롭:** `TaskItem.id`의 UUID 문자열을 `String`(Transferable)로 전달하고 `dropDestination(for: String.self)`에서 조회
- [x] **IC-10 테스트:** `TallyTests` 단위 테스트 타깃(호스트 앱 없음)에 `Shared/`를 포함해 순수 계산 함수를 검증. XCTest 사용
- [x] **IC-12 UI 자동 검증:** `TallyUITests`(XCUITest) 타깃 추가. 실행 인자 `-uiTesting YES`면 메모리 저장소를 써서 테스트끼리 데이터가 섞이지 않음. 수동 체크리스트 중 자동화 가능한 항목(MT-1.x, MT-3.x 등)을 대신 검증. 디버그 전용 `-seedDemo YES|<습관 수>`로 시연·성능 데이터 생성
- [x] **IC-11 앱 아이콘:** Swift 스크립트(`scripts/make_icon.swift`)로 1024px PNG 생성. 단일 크기 아이콘 사용

## 2. 아키텍처

```
┌──────────── Tally (app) ────────────┐   ┌──── TallyWidget (extension) ────┐
│ TallyApp → RootTabView               │   │ TallyWidgetBundle               │
│  ├ TodayView      (FR-1)             │   │  ├ YearProgressWidget  (FR-5.1)│
│  ├ TimeView       (FR-2)             │   │  ├ HabitsWidget        (FR-5.2)│
│  ├ MatrixView     (FR-3)             │   │  ├ ContributionWidget  (FR-5.3)│
│  ├ StatsView      (FR-4)             │   │  └ MementoWidget       (FR-5.4)│
│  └ SettingsView   (FR-6, 시트)       │   └────────────────────────────────┘
└──────────────┬──────────────────────┘                  │
               └────────────┬─────────────────────────────┘
                     Shared/ (두 타깃 + 테스트에 포함)
  Models · Persistence · Settings · Theme · Calculations · DotGrid · Intents · Reminders
                            │
            App Group: group.com.jinu2kk.tally
            ├ Library/Application Support/Tally.store  (SwiftData)
            └ UserDefaults suite                        (설정)
```

## 3. 모듈 계약

| 파일 | 책임 | 공개 API(요약) |
|---|---|---|
| `Shared/Models.swift` | SwiftData 모델 4종 | `Habit`, `HabitLog`, `TaskItem`, `DDay`, `Quadrant` |
| `Shared/Persistence.swift` | 공유 컨테이너 | `SharedStore.container`, `SharedStore.appGroupID` |
| `Shared/AppSettings.swift` | 설정 키와 기본값 | `SettingsKey`, `AppSettings.defaults`, `AppSettings.birthDate` 등 |
| `Shared/Calculations.swift` | 순수 계산 함수 | `Streaks.current/longest`, `YearProgress`, `LifeProgress`, `Contribution.grid`, `DDayMath.label`, `MonthStats.rate` |
| `Shared/Theme.swift` | 디자인 토큰 | `Ink`, `ThemeTint`, `Metrics`, `.inkCard()` modifier |
| `Shared/DotGrid.swift` | 공통 점 컴포넌트 | `Dot(state:)`, `DotGrid(count:columns:state:)` |
| `Shared/HabitActions.swift` | 토글 로직(앱·위젯 공용) | `HabitActions.toggle(_:on:in:)`, `isDone(_:on:)` |
| `Shared/Intents.swift` | App Intents | `ToggleHabitIntent`, `MakeWallpaperIntent`, `HabitEntity`, `TallyShortcuts` |
| `Shared/Wallpaper.swift` | 배경화면 뷰·렌더링 | `WallpaperKind`, `WallpaperView`, `Wallpaper.render(kind:size:)` |
| `Tally/Reminders.swift` | 로컬 알림 | `Reminders.schedule(for:)`, `cancel(for:)`, `cancelAll()` |

계산 함수는 모두 `Calendar`와 `now`를 인자로 받아 테스트에서 고정할 수 있게 한다.

## 4. 데이터 모델 (스키마 v1, CloudKit 호환)

```swift
@Model final class Habit {
  var id: UUID = UUID()
  var name: String = ""
  var icon: String = "✏️"            // 이모지 1개
  var colorHex: String = "E4572E"
  var targetMinutes: Int? = nil
  var reminderHour: Int? = nil        // 둘 다 nil이면 알림 없음
  var reminderMinute: Int? = nil
  var sortOrder: Int = 0
  var isArchived: Bool = false
  var createdAt: Date = Date()
  @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit) var logs: [HabitLog]? = []
}
@Model final class HabitLog { var day: Date = Date(); var habit: Habit? }
@Model final class TaskItem { var id: UUID; var title: String; var note: String; var quadrantRaw: Int; var isDone: Bool; var dueDate: Date?; var createdAt: Date; var sortOrder: Int }
@Model final class DDay     { var id: UUID; var title: String; var date: Date; var createdAt: Date }
```

## 5. 디자인 시스템 (DC-2)

| 토큰 | 라이트 | 다크 |
|---|---|---|
| `Ink.paper` 배경 | `#F4EFE6` | `#161514` |
| `Ink.card` 카드 | `#FBF8F2` | `#211F1D` |
| `Ink.ink` 글자·테두리 | `#1C1B1A` | `#EDE6D8` |
| `Ink.faint` 보조 | ink 45% | ink 45% |
| `Ink.empty` 빈 점 | ink 12% | ink 16% |

- 테마 색(`ThemeTint`): 토마토 `#E4572E`(기본), 청록 `#1B998B`, 코발트 `#2E5EAA`, 겨자 `#E3A72F`, 자두 `#8E3B75`, 이끼 `#5B7F3A`
- 카드: 모서리 14, 1pt 잉크 테두리, 오른쪽 아래로 3pt 어긋난 단색 그림자(스티커 느낌)
- 글꼴: 큰 숫자 `.system(size:, weight: .heavy, design: .rounded)`, 라벨 `.system(.caption, design: .monospaced).weight(.semibold)` + 대문자·자간
- 점 상태: `.filled`(잉크), `.accent`(테마 색), `.today`(테마 색 링), `.empty`(연한 원), 잔디 농도 `.level(0...4)`
- 완료 애니메이션: `.spring(response: 0.35, dampingFraction: 0.6)` + `sensoryFeedback(.success)`

## 6. 운영 정책
- 위젯 갱신: 모델 변경 후 `WidgetCenter.shared.reloadAllTimelines()`. 타임라인은 다음 자정에 `.after` 정책
- 알림 식별자: `habit-<uuid>`. 권한은 첫 리마인더 설정 시 요청
- 데이터 초기화: 확인 대화상자 → 모든 모델 삭제 → `Reminders.cancelAll()` → 위젯 갱신
- 비밀 값: 코드에 토큰이나 개인 정보 없음. `.gitignore`에 `xcuserdata`, `DerivedData`, `build/`

## 7. 결정 ↔ 검증 연결
| 결정 | 검증 |
|---|---|
| IC-3 | T-0.2 컨테이너 생성, MT-5.2 위젯과 앱 데이터 일치 |
| IC-5 | T-1.1 ~ T-1.5 |
| IC-6 | T-1.6 같은 날 두 번 토글 시 기록 0개 |
| IC-7 | MT-5.2 위젯에서 체크 → 앱 반영 |
| IC-8 | MT-2.5, MT-2.6 |
| IC-9 | MT-3.3 |

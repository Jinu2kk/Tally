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
- [x] **IC-13 일정 편집 = 시스템 편집기(`EKEventEditViewController`).** 반복·알림·위치·초대까지 기본 캘린더와 같은 기능을 바로 지원하고, 삭제 시 "이번 일정만 / 이후 모두" 처리도 시스템이 맡음. 읽기 화면(월간 달력, 날짜별 목록)만 Tally 디자인으로 만든다. 검증: MT-8.4
- [x] **IC-14 일정 데이터 경계:** EventKit 객체(`EKEvent`)를 화면에 직접 넘기지 않고 값 타입 `DayEvent`로 변환. 날짜 칸 배치·정렬·최대 4개 계산은 `CalendarMath`(순수 함수)에서 처리해 테스트한다. 검증: T-9.x
- [x] **IC-11 앱 아이콘:** Swift 스크립트(`scripts/make_icon.swift`)로 1024px PNG 생성. 단일 크기 아이콘 사용

### 달력 결정 (2026-10-01 추가)
- [x] **DC-6 일정 저장소 = iPhone 기본 캘린더(EventKit).** 사용자가 이미 쓰는 일정(구글 캘린더 등 계정 포함)을 다시 입력할 필요가 없음. Tally는 일정을 따로 저장하지 않는다 (NFR-6)
- [x] **DC-7 달력 화면 배치 = 참고 이미지 6장 기준 (2026-10-01).** 달력을 첫 탭으로. 탭 순서: 달력 · 습관 · 할 일 · 시간 · 기록. 상단 왼쪽 일정 목록, 오른쪽 묶음 버튼(디자인 · 캘린더 선택 · 내보내기). 날짜 칸은 테두리 없이 주마다 가는 구분선, 일정은 막대/색 줄. 배경 사진 위에서도 읽히도록 글자에 그림자. 생김새는 Tally 토큰(잉크·종이, 둥근 숫자, 모노 라벨)을 쓴다. 검증: MT-8.x 스크린샷
- [x] **IC-15 주 단위 막대 배치:** 각 주(7칸)마다 그 주와 겹치는 일정을 레인(줄)에 배정. 여러 날·종일 일정 먼저(길이 긴 순), 이후 시간 일정. 레인 0~3만 그리고, 들어가지 못한 일정은 날짜별 `+n`. 순수 함수 `CalendarMath.weekLayout`. 검증: T-9.7~9.9
- [x] **IC-16 공휴일 판정:** 캘린더 제목에 '휴일'·'공휴일'·'holiday'(대소문자 무시)가 포함되면 공휴일 캘린더. 그 캘린더의 일정이 있는 날을 공휴일로 본다. 검증: T-9.10
- [x] **IC-18 앱 화면과 배경화면은 같은 뷰로 그린다.** `MonthCalendarGrid`(일정·설정 값만 받는 순수 SwiftUI 뷰)를 앱 화면과 `CalendarWallpaper.render`가 함께 쓴다. 배경화면은 `ImageRenderer`로 기기 화면 크기(포인트 × 배율)에 그린다. 위쪽 약 35%는 잠금화면 시계·위젯 자리로 비운다. 검증: T-11.x, MT-8.12, MT-8.14
- [x] **IC-19 단축어 동작 `MakeCalendarWallpaperIntent`:** `openAppWhenRun = false`. 매개변수: 형태(월간/주간, 기본=설정값). 출력: `IntentFile`(PNG). EventKit 권한이 없으면 `CalendarWallpaperError.noAccess`로 실패. 앱 프로세스가 백그라운드로 실행되어 처리. 검증: MT-8.14
- [x] **IC-17 배경 저장:** 선택한 사진은 App Group 컨테이너의 `calendar-background.jpg`(긴 변 2400px로 줄여 JPEG)로 저장. 설정 값(종류, 불투명도, 블러, 강조, 오늘 색, 미리보기 숨김, 배경화면 크기·월간/주간)은 App Group UserDefaults. 셔플 패턴은 코드로 그린다(외부 이미지 없음)

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

## 6-1. 달력 모듈 계약
| 파일 | 책임 | 공개 API(요약) |
|---|---|---|
| `Shared/CalendarMath.swift` | 순수 계산 | `DayEvent`, `CalendarMath.monthGrid`, `events(on:from:)`, `cellLayout(_:limit:)`, `periodStats` |
| `Tally/CalendarStore.swift` | EventKit 래퍼 (`@Observable`) | `authorization`, `requestAccess()`, `calendars`, `events(in:)`, `editor(for:)`, 변경 알림 구독 |
| `Tally/Views/CalendarView.swift` 외 | 화면 | DC-7 확정 후 작성 |

권한 키: `NSCalendarsFullAccessUsageDescription`(iOS 17 전체 접근). 쓰기 전용 접근은 읽기가 안 되므로 쓰지 않는다.

## 7. 결정 ↔ 검증 연결
| 결정 | 검증 |
|---|---|
| IC-3 | T-0.2 컨테이너 생성, MT-5.2 위젯과 앱 데이터 일치 |
| IC-5 | T-1.1 ~ T-1.5 |
| IC-6 | T-1.6 같은 날 두 번 토글 시 기록 0개 |
| IC-7 | MT-5.2 위젯에서 체크 → 앱 반영 |
| IC-8 | MT-2.5, MT-2.6 |
| IC-9 | MT-3.3 |
| DC-6, IC-13 | MT-8.1 ~ 8.5 |
| IC-14 | T-9.1 ~ T-9.6 |

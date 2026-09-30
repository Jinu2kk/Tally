# 개발 프롬프트 — 습관·시간 관리 앱 "Tally"

> 이 문서는 앱 개발을 시작하기 전에 AI 개발 에이전트(또는 개발자)에게 전달할 작업 지시서입니다.
> 레퍼런스 앱의 **기능**은 똑같이 구현하되, **디자인과 브랜딩은 독자적으로** 만드는 것이 목표입니다.

---

## 1. 역할과 목표

당신은 SwiftUI와 SwiftData에 능숙한 iOS 시니어 개발자입니다.
App Store의 **「데일리(Daily)」 앱(Pacifiq, id6737768320)**과 **기능은 같지만 디자인이 다른** iOS 앱을 처음부터 만드세요.

- 저장소: `https://github.com/Jinu2kk/calendar`
- 앱 이름(가칭): **Tally**
- 결과물: Xcode에서 바로 열어 시뮬레이터로 실행할 수 있는 프로젝트 + README

### 지켜야 할 것
- 레퍼런스 앱의 이름, 아이콘, 문구, 스크린샷, 색상 조합, 레이아웃을 **복제하지 않는다.** 기능 요구사항만 참고한다.
- 외부 라이브러리 없이 Apple 기본 프레임워크만 사용한다.

---

## 2. 기술 스택과 제약

| 항목 | 내용 |
|---|---|
| 최소 OS | iOS 17.0 (iPhone 우선, iPad에서도 레이아웃이 깨지지 않을 것) |
| UI | SwiftUI |
| 저장 | SwiftData, App Group 공유 컨테이너(앱과 위젯이 같이 사용) |
| 위젯 | WidgetKit 확장 (iOS 17 인터랙티브 위젯) |
| 단축어 | App Intents |
| 알림 | UserNotifications (로컬 알림) |
| 언어 | 한국어 기본, 문자열은 `String(localized:)`로 작성해 이후 다국어 확장 가능하게 |
| 번들 ID | `com.jinu2kk.tally` / 위젯 `com.jinu2kk.tally.widget` / App Group `group.com.jinu2kk.tally` |

- Xcode 16 이상의 폴더 동기화 그룹(`PBXFileSystemSynchronizedRootGroup`)을 쓰는 `.xcodeproj`로 구성한다.
- 모델과 공통 로직은 `Shared/` 폴더에 두고 앱 타깃과 위젯 타깃에 함께 포함한다.
- App Group 컨테이너를 쓸 수 없을 때(서명 없는 빌드 등)는 기본 저장소로 대체해 앱이 멈추지 않게 한다.

---

## 3. 기능 요구사항 (레퍼런스 앱과 동일한 범위)

### 3.1 습관 트래커 — 탭 「오늘」
- 습관 생성/수정/삭제/보관: 이름, **이모지 또는 SF Symbol 아이콘**, 색상, 목표 시간(분, 선택), 리마인더 시각(선택)
- 오늘 날짜 기준 목록. **탭하거나 스와이프하면 완료/취소**
- 습관마다 **현재 연속 기록(streak)**과 최장 기록 표시
- 상단에 주간 날짜 스트립: 지난 날짜를 골라 그날 기록도 수정 가능
- 드래그로 순서 변경
- 리마인더: 지정한 시각에 매일 로컬 알림, 수정·삭제 시 알림도 갱신

### 3.2 라이프 캘린더 & 올해 진행률 — 탭 「시간」
- **올해 진행률**: 1년을 365(366)개 점 그리드로 표시. 지난 날, 오늘, 남은 날을 구분하고 진행률(%)과 남은 일수 표시
- **라이프 캘린더(Memento Mori)**: 생년월일과 기대 수명(기본 80세)을 입력하면 평생을 주 단위 점 그리드로 표시
- **D-Day**: 여러 개 등록 가능, 남은 일수 표시
- **색상 테마** 선택(최소 5가지)
- **배경화면 만들기**: 그리드를 기기 화면 비율 이미지로 렌더링(`ImageRenderer`)해 사진에 저장하거나 공유
- **단축어 연동**: "오늘 배경화면 만들기" App Intent가 이미지 파일을 반환 → 단축어 자동화로 매일 배경화면 교체 가능

### 3.3 아이젠하워 매트릭스 — 탭 「우선순위」
- 할 일을 긴급도 × 중요도 4분면에 배치: **지금 하기 / 일정 잡기 / 위임하기 / 버리기**
- 할 일 추가(제목, 메모, 마감일 선택), 완료 체크, 삭제
- **드래그 앤 드롭으로 사분면 이동** (`Transferable` + `dropDestination`)
- **매트릭스 보기 ↔ 목록 보기** 전환, 완료한 항목 숨기기

### 3.4 통계 — 탭 「기록」
- 습관별 **GitHub 스타일 잔디 그래프**(최근 1년, 스크롤 가능)
- 전체 습관을 합친 잔디 그래프(하루에 완료한 비율로 농도 표현)
- 현재 연속 기록, 최장 연속 기록, 전체 완료 횟수
- **월별 달성률**: 월 달력 형태 + 완료율(%)

### 3.5 위젯 (소/중/대 + 잠금화면)
1. **올해 진행률** — 점 그리드 + %
2. **오늘의 습관** — 목록 + 체크 버튼 (App Intent로 위젯 안에서 바로 완료)
3. **잔디 그래프** — 습관 하나 또는 전체 선택 (`AppIntentConfiguration`)
4. **Memento Mori** — 살아온 주 / 남은 주
- 앱에서 데이터가 바뀌면 `WidgetCenter.shared.reloadAllTimelines()`를 호출하고, 자정에 타임라인을 갱신한다.

### 3.6 설정
- 다크/라이트/시스템 모드, 테마 색상, 주 시작 요일(일/월)
- 생년월일, 기대 수명
- 알림 권한 상태 안내
- 데이터 초기화(확인 대화상자 필수)

### 이번 범위에서 제외 (README에 "추후 작업"으로 적기)
- iCloud 동기화 (유료 개발자 계정과 CloudKit 설정이 필요. 다만 모델은 CloudKit 호환 규칙을 따른다: 모든 속성은 기본값이나 옵셔널, unique 제약 없음)
- 인앱 결제(Pro 플랜) — 모든 기능 무료
- Mac, visionOS 전용 UI

---

## 4. 디자인 방향 — 레퍼런스와 확실히 다르게

레퍼런스는 "귀엽고 미니멀한" 스타일입니다. Tally는 **"종이 수첩과 잉크"** 콘셉트로 갑니다.

- **색**: 크림색 종이 배경(`#F4EFE6`), 먹색 잉크(`#1C1B1A`), 포인트는 **한 가지 색**만 사용(기본 토마토 `#E4572E`). 다크 모드는 먹색 배경에 크림색 잉크.
- **타이포**: 큰 숫자는 `.system(design: .rounded)` 굵은 체, 라벨은 `.monospaced` 작은 대문자. 숫자 중심의 대시보드 느낌.
- **형태**: 카드 그림자 대신 **1pt 잉크 테두리**와 살짝 어긋난 오프셋 그림자(스티커 느낌). 모서리 반경 14.
- **점(dot)**: 앱의 공통 시각 언어. 진행률, 잔디, 라이프 캘린더를 모두 같은 점 컴포넌트로 그린다(칸이 채워진 점 / 테두리만 있는 점 / 오늘은 포인트 색 링).
- **탭바**: 기본 TabView를 쓰되 아이콘은 SF Symbols 중 선이 얇은 것으로 통일.
- **애니메이션**: 완료 시 점이 잉크 번지듯 채워지는 스프링 애니메이션 + `sensoryFeedback(.success)`.
- **앱 아이콘**: 크림 배경 위 먹색 점 4개 중 하나만 토마토색 (1024×1024, 코드로 생성해도 됨).
- 디자인 토큰(색, 간격, 반경, 폰트)은 `Shared/Theme.swift` 한 곳에 모은다.

---

## 5. 데이터 모델 (SwiftData)

```swift
@Model Habit     { id, name, icon, colorHex, targetMinutes?, reminderTime?, sortOrder, isArchived, createdAt, logs: [HabitLog] }
@Model HabitLog  { day: Date(해당 날짜 00:00), minutes?, habit: Habit? }
@Model TaskItem  { id, title, note, quadrant: Int(0...3), isDone, dueDate?, createdAt, sortOrder }
@Model DDay      { id, title, date, colorHex, createdAt }
```
- 설정 값은 App Group `UserDefaults`에 저장(위젯에서도 읽어야 하므로).
- streak 계산, 잔디 데이터 계산, 연/생애 진행률 계산은 **UI와 분리된 순수 함수**(`Shared/Calculations.swift`)로 만든다.

---

## 6. 프로젝트 구조

```
Tally.xcodeproj
Tally/            앱 진입점, 탭, 화면별 View, Assets
  Views/Today/  Views/Time/  Views/Matrix/  Views/Stats/  Views/Settings/
Shared/           Models, Theme, Calculations, Persistence(ModelContainer), AppIntents, DotGrid 컴포넌트
TallyWidget/      WidgetBundle, 위젯 4종
Config/           Info.plist(위젯), .entitlements
TallyTests/       Calculations 단위 테스트
README.md  .gitignore
```

---

## 7. 작업 순서와 완료 기준

1. **뼈대**: 프로젝트, 타깃 2개, App Group, 테마, 모델 → 빈 탭 화면이 실행된다
2. **습관**: CRUD, 완료 토글, streak, 알림
3. **우선순위**: 매트릭스, 드래그 앤 드롭, 목록 전환
4. **시간**: 올해 진행률, 라이프 캘린더, D-Day, 배경화면 저장, 단축어 Intent
5. **기록**: 잔디 그래프, 월별 달성률
6. **위젯**: 4종 + 인터랙티브 체크
7. **마무리**: 설정, 다크 모드 점검, 테스트, README

각 단계를 마칠 때마다:
- `xcodebuild -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 16' build`가 **경고 없이 성공**
- `Calculations` 단위 테스트 통과 (streak: 오늘 미완료·어제 완료면 streak 유지, 윤년, 주 시작 요일)
- 시뮬레이터에서 해당 기능을 직접 조작해 확인하고 스크린샷을 남긴다
- 의미 단위로 git 커밋

---

## 8. 결정이 필요한 사항 (개발 전 확인)

- [ ] 앱 이름: **Tally**로 할지, 다른 이름으로 할지
- [ ] 디자인 콘셉트: "종이 수첩과 잉크"로 진행해도 되는지
- [ ] 번들 ID 접두어 `com.jinu2kk` 사용 여부
- [ ] iCloud 동기화와 인앱 결제는 이번 범위에서 빼도 되는지
- [ ] 저장소 `Jinu2kk/calendar` 접근 방법: 현재 공개 주소로는 404가 나옵니다(비공개이거나 아직 없는 저장소로 보임). 푸시는 직접 하실지, 인증을 설정해 주실지

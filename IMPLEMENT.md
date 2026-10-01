# IMPLEMENT — Tally

> 설계: [DESIGN.md](DESIGN.md) · 수동 테스트: [MANUAL_TEST_CHECKLIST.md](MANUAL_TEST_CHECKLIST.md)

## 공통 명령
```bash
# 빌드
xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' -derivedDataPath build build
# 단위 테스트
xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' -derivedDataPath build test
```
**모든 Phase 공통 종료 조건:** 빌드 성공, Swift 경고 0, 그때까지의 테스트 통과, git 커밋 + `git push origin main`.

---

## Phase 0 — 뼈대 ✅
**진입:** 문서 4종 작성 완료
- [x] `.xcodeproj` (타깃: Tally, TallyWidget, TallyTests / 스킴: Tally) — IC-1, IC-2
- [x] Entitlements(App Group), 위젯 Info.plist, `.gitignore`
- [x] `Shared/`: Models, Persistence, AppSettings, Theme, DotGrid
- [x] `RootTabView` 탭 4개 + 설정 시트 자리
- [x] 위젯 번들 빈 껍데기 1개
- [x] 앱 아이콘 생성 스크립트 — IC-11

**기본 테스트:** T-0.1 모델 인메모리 컨테이너 생성 / T-0.2 `SharedStore` 컨테이너 생성
**종료:** 시뮬레이터에서 탭 4개가 보이고 배경이 종이색

## Phase 1 — 습관 (FR-1) ✅
- [x] `Calculations.Streaks`, `HabitActions`
- [x] `TodayView`: 주간 스트립, 습관 행, 탭/스와이프 토글, 순서 변경, 빈 상태
- [x] `HabitEditorView`: 이름, 이모지, 색, 목표 시간, 리마인더, 삭제/보관
- [x] `Reminders`

**기본 테스트:** T-1.1 연속 3일 → 3 / T-1.2 오늘 미완료·어제까지 2일 → 2 / T-1.3 어제·오늘 미완료 → 0 / T-1.4 최장 기록 / T-1.5 월 경계·윤년 / T-1.6 같은 날 두 번 토글 → 기록 0개
- [x] UI 테스트 `HabitFlowUITests` (MT-1.1~1.3 자동화) — IC-12

**종료:** MT-1.x 통과

## Phase 2 — 우선순위 (FR-3) ✅
- [x] `MatrixView` 2×2, `QuadrantCard`, 드래그 앤 드롭 — IC-9
- [x] 목록 보기, 완료 숨기기, `TaskEditorView`

**기본 테스트:** T-2.1 `Quadrant` rawValue 왕복, 이름/설명
- [x] UI 테스트 `MatrixFlowUITests` (추가 → 완료 → 숨기기 → 드래그 이동 → 목록 보기 스와이프 삭제)

**종료:** MT-3.x 통과

## Phase 3 — 시간 (FR-2) ✅
- [x] `YearProgress`, `LifeProgress`, `DDayMath`
- [x] `TimeView`: 올해 진행률 카드, 라이프 캘린더 카드, D-Day 목록
- [x] `WallpaperView` + ShareLink — IC-8
- [x] `MakeWallpaperIntent`, `TallyShortcuts`

**기본 테스트:** T-3.1 1월 1일 → 1일째 / T-3.2 윤년 366 / T-3.3 12월 31일 남은 0일 / T-3.4 생애 주 수 = 기대수명×52 / T-3.5 D-Day 라벨 D-3, D-Day, D+2
- [x] UI 테스트 `TimeFlowUITests` (생년월일 → D-Day → 배경화면 공유 시트). `SHOT_DIR` 환경 변수로 스크린샷 저장

**종료:** MT-2.x 통과 (MT-2.6 단축어 실행은 Phase 8 수동 확인)

## Phase 4 — 기록 (FR-4) ✅
- [x] `Contribution.grid`(53주 × 7일, 주 시작 요일 반영), `MonthStats`
- [x] `StatsView`: 요약 숫자, 전체 잔디, 습관별 잔디, 월 달력

**기본 테스트:** T-4.1 그리드 마지막 칸이 오늘이 포함된 주 / T-4.2 주 시작 월요일일 때 첫 행이 월요일 / T-4.3 농도 단계 경계값 / T-4.4 월 달성률(생성일 이전 날짜 제외)
**종료:** MT-4.x 통과

## Phase 5 — 위젯 (FR-5) ✅
- [x] 공용 타임라인 프로바이더(자정 갱신)
- [x] 위젯 4종, `ToggleHabitIntent` 버튼 — IC-7
- [x] 잔디 위젯 `AppIntentConfiguration` + `HabitEntity` 쿼리
- [x] 앱의 모델 변경 지점에서 `reloadAllTimelines()`

- [x] 앱 복귀 시 새 ModelContext로 교체 (위젯이 바꾼 기록을 앱이 읽도록)
- [x] 위젯 화면을 `Shared/WidgetViews.swift`로 분리, 디버그 전용 `-widgetGallery YES` 미리보기

**기본 테스트:** 위젯 타깃 빌드 / T-5.1 `HabitEntity` 쿼리가 보관된 습관 제외 / T-5.2 `ToggleHabitIntent.perform()`이 공유 저장소에 기록

> 참고: 앱 안 미리보기의 `Button(intent:)`는 인텐트를 실행하지 않아 UI 자동화 대상에서 제외. 위젯 체크(MT-5.2)는 홈 화면에서 수동 확인
**종료:** MT-5.x 통과

## Phase 6 — 설정 (FR-6) ✅
- [x] `SettingsView`: 화면 모드, 테마, 주 시작 요일, 생년월일, 기대수명, 알림 상태, 데이터 초기화(확인 필수)

- [x] 보관한 습관 꺼내기 (FR-1.1 보관의 복원 경로)
- [x] UI 테스트 `SettingsFlowUITests` (월요일 시작, 다크 모드, 초기화 취소/확인)

**기본 테스트:** T-6.1 설정 기본값 / 전체 빌드
**종료:** MT-6.x 통과

## Phase 7 — 테스트 강화 (Hardening) ✅
- [x] 경계값 테스트 보강: 시간대(서울/뉴욕), 기대수명 1·120, 생년월일이 미래, 습관 0개
- [x] 다크 모드 전 화면 스크린샷 점검 (NFR-4)
- [x] 성능: 습관 50개 × 365일 시드 데이터로 탭 전환 확인 (NFR-3). 디버그 전용 시드 기능 `-seedDemo` 실행 인자
- [x] Swift 경고 0 재확인

**결과 (2026-10-01)**
- `EdgeCaseTests` 6건 추가: 뉴욕 서머타임 경계 streak·연중 일수, 기대수명 0/1/120, 미래 생년월일, 습관 0개, 잘못된 hex
- 클린 빌드 Swift 경고 0. 남는 1줄은 UI 테스트 타깃의 `appintentsmetadataprocessor` 안내(코드 경고 아님)
- 성능: `-seedDemo 50`(습관 50개, 기록 약 11,700건) 후 기록 탭이 실행 3초 안에 표시. 시드 생성 자체는 약 28초(디버그 전용)
- 다크 모드: 오늘·시간·우선순위·기록 탭 스크린샷 확인, 글자 대비 문제 없음

## Phase 8 — 통합 테스트 (Integration) ✅
- [x] 클린 빌드 + 전체 테스트
- [x] 시뮬레이터에 설치 → MANUAL_TEST_CHECKLIST 전체 수행, 결과 기록
- [x] 앱 ↔ 위젯 데이터 일치, 단축어 동작 확인
- [x] README 작성(실행 방법, 구조, GitHub 인증 안내), 최종 커밋

**결과 (2026-10-01)**
- 클린 빌드 후 전체 테스트: 단위 32개 + UI 6개 통과
- App Group 컨테이너에 `Tally.store` 생성 확인 → 앱과 위젯이 같은 저장소 사용 (IC-3)
- UI 테스트 추가: `HabitLifecycleUITests`(어제 체크, 보관/꺼내기, 삭제), `StatsFlowUITests`(습관 선택, 연속 일치, 월 이동)
- 수동 체크리스트: 통과 28 / 실패 0 / 미수행 9. 미수행은 홈 화면 위젯, 실시간 알림, 단축어 앱처럼 기기 조작이 필요한 항목

## Phase 9 — 달력 기반: EventKit 연동 (FR-7.1, 7.4, 7.5, 7.6, 7.9) ✅
**진입:** DC-6 확정 (DC-7은 미확정이어도 진행 가능)
- [x] 권한 문구(Info.plist), `CalendarStore` (권한, 캘린더 목록, 기간 조회, 변경 알림)
- [x] `CalendarMath`: 6주 월 그리드, 날짜별 일정(여러 날 일정 포함), 정렬, 최대 4개 + 초과 수, 기간 통계
- [x] 디버그 시드: 시뮬레이터 기본 캘린더에 예시 일정 생성 (`-seedEvents YES`)

- [x] 주 단위 막대 배치 `weekLayout`(IC-15), 공휴일 판정(IC-16)

**기본 테스트:** T-9.1 월 그리드 42칸·주 시작 반영 / T-9.2 여러 날 일정이 각 날짜에 표시 / T-9.3 종일 먼저·시작 시각 순 / T-9.4 최대 4개 + 초과 수 / T-9.5 자정에 끝나는 일정은 다음 날에 표시 안 함 / T-9.6 이번 달·올해 통계 / T-9.7~9.9 주 막대·레인·초과 / T-9.10 공휴일
**종료:** 테스트 통과, 커밋·push

## Phase 10 — 달력 화면 (FR-7.2, 7.3, 7.6, 7.7, 7.8, 7.14)
**진입:** DC-7 확정 ✅
- [ ] 탭 순서 변경(달력 첫 탭), `CalendarTabView`: 월 제목, 이전/다음/Today, 요일, 6주 그리드, 막대·색 줄, 오늘 강조, `+n`
- [ ] 날짜 탭 → 그날 일정 시트, 일정 탭 → 시스템 편집기, `+` → 새 일정
- [ ] 캘린더 선택 시트(계정별, 캘린더 추가), 다가오는 일정 목록, 통계 이번 달/올해
- [ ] 강조(공휴일·토·일)

**기본 테스트:** T-9.7~9.10 / UI: 권한 허용 상태에서 시드 일정 표시, 날짜 탭 목록, 다음 달 → Today
**종료:** MT-8.1~8.9, 8.13 스크린샷·UI 테스트

## Phase 11 — 달력 디자인·배경화면 (FR-7.11 ~ 7.13)
- [ ] 디자인 시트: 배경(없음·단색·사진·셔플), 불투명도, 블러, 오늘 색, 미리보기 숨기기, 재설정
- [ ] 배경화면 내보내기 시트: 잠금화면 미리보기, 월간/주간, 크기 조절, 공유
- [ ] **[핵심]** `MakeCalendarWallpaperIntent` (백그라운드 실행, 앱 화면과 같은 뷰로 렌더) + README 자동화 설정 안내 (FR-7.15, IC-18, IC-19)
**기본 테스트:** 배경화면 렌더링 크기, 설정 기본값 / UI: 디자인 시트 조작
**종료:** MT-8.10~8.12

---

## 상태 (Handoff)
| 항목 | 내용 |
|---|---|
| 완료 | 문서 4종, Phase 0~8. 달력 요구사항(FR-7)·설계(DC-6, IC-13, IC-14) 추가 |
| 다음 | Phase 9 → 10 → 11 |
| 막힌 점 | 없음 (참고 이미지 수신, DC-7 확정) |
| 최신 커밋 | `git log -1` |

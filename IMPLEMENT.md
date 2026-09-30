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

## Phase 0 — 뼈대
**진입:** 문서 4종 작성 완료
- [ ] `.xcodeproj` (타깃: Tally, TallyWidget, TallyTests / 스킴: Tally) — IC-1, IC-2
- [ ] Entitlements(App Group), 위젯 Info.plist, `.gitignore`
- [ ] `Shared/`: Models, Persistence, AppSettings, Theme, DotGrid
- [ ] `RootTabView` 탭 4개 + 설정 시트 자리
- [ ] 위젯 번들 빈 껍데기 1개
- [ ] 앱 아이콘 생성 스크립트 — IC-11

**기본 테스트:** T-0.1 모델 인메모리 컨테이너 생성 / T-0.2 `SharedStore` 컨테이너 생성
**종료:** 시뮬레이터에서 탭 4개가 보이고 배경이 종이색

## Phase 1 — 습관 (FR-1)
- [ ] `Calculations.Streaks`, `HabitActions`
- [ ] `TodayView`: 주간 스트립, 습관 행, 탭/스와이프 토글, 순서 변경, 빈 상태
- [ ] `HabitEditorView`: 이름, 이모지, 색, 목표 시간, 리마인더, 삭제/보관
- [ ] `Reminders`

**기본 테스트:** T-1.1 연속 3일 → 3 / T-1.2 오늘 미완료·어제까지 2일 → 2 / T-1.3 어제·오늘 미완료 → 0 / T-1.4 최장 기록 / T-1.5 월 경계·윤년 / T-1.6 같은 날 두 번 토글 → 기록 0개
**종료:** MT-1.x 통과

## Phase 2 — 우선순위 (FR-3)
- [ ] `MatrixView` 2×2, `QuadrantCard`, 드래그 앤 드롭 — IC-9
- [ ] 목록 보기, 완료 숨기기, `TaskEditorView`

**기본 테스트:** T-2.1 `Quadrant` rawValue 왕복, 이름/설명
**종료:** MT-3.x 통과

## Phase 3 — 시간 (FR-2)
- [ ] `YearProgress`, `LifeProgress`, `DDayMath`
- [ ] `TimeView`: 올해 진행률 카드, 라이프 캘린더 카드, D-Day 목록
- [ ] `WallpaperView` + ShareLink — IC-8
- [ ] `MakeWallpaperIntent`, `TallyShortcuts`

**기본 테스트:** T-3.1 1월 1일 → 1일째 / T-3.2 윤년 366 / T-3.3 12월 31일 남은 0일 / T-3.4 생애 주 수 = 기대수명×52 / T-3.5 D-Day 라벨 D-3, D-Day, D+2
**종료:** MT-2.x 통과

## Phase 4 — 기록 (FR-4)
- [ ] `Contribution.grid`(53주 × 7일, 주 시작 요일 반영), `MonthStats`
- [ ] `StatsView`: 요약 숫자, 전체 잔디, 습관별 잔디, 월 달력

**기본 테스트:** T-4.1 그리드 마지막 칸이 오늘이 포함된 주 / T-4.2 주 시작 월요일일 때 첫 행이 월요일 / T-4.3 농도 단계 경계값 / T-4.4 월 달성률(생성일 이전 날짜 제외)
**종료:** MT-4.x 통과

## Phase 5 — 위젯 (FR-5)
- [ ] 공용 타임라인 프로바이더(자정 갱신)
- [ ] 위젯 4종, `ToggleHabitIntent` 버튼 — IC-7
- [ ] 잔디 위젯 `AppIntentConfiguration` + `HabitEntity` 쿼리
- [ ] 앱의 모델 변경 지점에서 `reloadAllTimelines()`

**기본 테스트:** 위젯 타깃 빌드 / T-5.1 `HabitEntity` 쿼리가 보관된 습관 제외
**종료:** MT-5.x 통과

## Phase 6 — 설정 (FR-6)
- [ ] `SettingsView`: 화면 모드, 테마, 주 시작 요일, 생년월일, 기대수명, 알림 상태, 데이터 초기화(확인 필수)

**기본 테스트:** T-6.1 설정 기본값 / 전체 빌드
**종료:** MT-6.x 통과

## Phase 7 — 테스트 강화 (Hardening)
- [ ] 경계값 테스트 보강: 시간대(서울/뉴욕), 기대수명 1·120, 생년월일이 미래, 습관 0개
- [ ] 다크 모드 전 화면 스크린샷 점검 (NFR-4)
- [ ] 성능: 습관 50개 × 365일 시드 데이터로 탭 전환 확인 (NFR-3). 디버그 전용 시드 기능 `-seedDemo` 실행 인자
- [ ] Swift 경고 0 재확인

## Phase 8 — 통합 테스트 (Integration)
- [ ] 클린 빌드 + 전체 테스트
- [ ] 시뮬레이터에 설치 → MANUAL_TEST_CHECKLIST 전체 수행, 결과 기록
- [ ] 앱 ↔ 위젯 데이터 일치, 단축어 동작 확인
- [ ] README 작성(실행 방법, 구조, GitHub 인증 안내), 최종 커밋

---

## 상태 (Handoff)
| 항목 | 내용 |
|---|---|
| 완료 | 문서 4종 |
| 다음 | Phase 0 |
| 막힌 점 | GitHub 인증 대기 중 (DC-5). 인증 전 커밋은 로컬에 보관 |
| 최신 커밋 | (없음) |

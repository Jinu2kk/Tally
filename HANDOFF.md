# 인수인계 — Phase 11 달력 디자인·배경화면 개선 (2026-10-01)

마지막 커밋은 `30475d3`(Phase 11 달력 배경화면)이고, 아래 작업은 **모두 커밋 전**이다.
빌드는 시뮬레이터와 실기기 모두 성공했고, 실기기(iPhone 18 Pro)에 설치까지 마쳤다. 사용자 확인은 아직 받지 못했다.

## 이번에 바뀐 것

### 1. 세로 위치 설정 (새 설정값)
- `Shared/AppSettings.swift`: `SettingsKey.wallpaperOffset`를 추가했다. 값은 달력 윗변 위치를 화면 높이에 대한 비율로 저장하고, `-1`이면 자동이다.
- `Shared/CalendarStyle.swift`
  - `CalendarStyle.wallpaperOffset`, `offsetRange = 0.08...0.75`, `wallpaperTop(weeks:)`를 추가했다. 자동일 때 기본값은 월간 0.345, 주간 0.62다.
  - `CalendarStyle.current`에서 이 값을 읽고, `resetStored()`의 삭제 키 목록에도 넣었다.

### 2. 블러를 CoreImage로 처리
- `CalendarBackgroundStore.blurred(_:radius:)`를 만들었다. 이미지를 최대 1200px로 줄인 뒤 가우시안 블러를 입히고, 결과는 캐시에 1개만 둔다.
  - 블러 반경은 393pt 화면 기준으로 픽셀 값으로 바꿔 쓴다.
  - 바꾼 이유: SwiftUI `.blur`를 쓰면 사진 가장자리가 투명하거나 검게 나오고, ImageRenderer로 만든 결과도 화면과 달랐다.
- `CalendarBackgroundView(style:photo:)`는 이제 사진을 인자로 받는다.
  - 패턴 배경은 `.blur`를 그대로 쓰고, 번진 가장자리가 화면 밖으로 나가도록 `scaleEffect`로 조금 키운다.

### 3. 배경화면 렌더 (`Tally/Calendar/CalendarWallpaper.swift`)
- `CalendarWallpaperView`는 달력 윗변을 `style.wallpaperTop(...)` 위치에 둔다.
- `CalendarWallpaper.snapshot(style:now:)` 헬퍼를 만들어 미리보기와 렌더가 같은 데이터를 쓰게 했다.

### 4. 디자인 시트 (`Tally/Calendar/CalendarDesignSheet.swift`, 거의 새로 작성)
- 이 파일에 있는 공용 컴포넌트:
  - `EmphasisChips`: 공휴일·토·일 강조 칩
  - `VerticalSlider`: 세로 슬라이더. 위쪽이 작은 값이고, 접근성 조절 동작도 지원한다.
  - `LockScreenPreview`: 실제 `CalendarWallpaperView`를 축소해서 보여 준다. 날짜, 시계, 위젯 줄(원형 4개와 사각형 1개), 손전등·카메라 버튼 자리를 실제 잠금화면 비율로 겹쳐 그린다.
  - `WallpaperLayoutEditor`: 미리보기를 정중앙에 두고 오른쪽에 세로 슬라이더와 '자동' 버튼을 붙인다. 아래에는 크기 슬라이더(60~100%)와 월간/주간 전환이 있다.
    - 슬라이더 손잡이 높이는 미리보기 속 달력 윗변과 맞춰 두었다.
    - 디자인 시트와 공유 시트가 이 컴포넌트를 같이 쓴다.
- `CalendarDesignSheet` 화면 구성(위에서부터):
  1. 레이아웃 편집기
  2. 강조 칩
  3. 배경 타일: 종이 / 단색 / 사진 / 셔플
     - 단색 타일은 누르면 선택되고, 타일 안의 ColorPicker로 색을 바꾼다.
     - 사진을 이미 골랐다면 타일을 눌러 선택하고, X 버튼으로 지운다.
  4. 불투명도·블러 슬라이더 (종이 배경일 때는 비활성)
  5. 오늘 컬러, 이전/다음 달 숨기기
  6. 기본값으로 재설정
- '잠금 화면 미리보기' 라벨은 `labelStyle()`(고정폭 글꼴에 자간이 넓음) 대신 `.caption.weight(.semibold)`를 쓴다.

### 5. 배경화면 공유 시트 (`CalendarWallpaperSheet.swift`)
- 기존의 렌더 이미지 미리보기를 빼고 `WallpaperLayoutEditor`로 바꿨다. 그래서 디자인 시트와 같은 값을 보여 준다.
- 공유용 PNG는 `.task(id:)`에서 0.25초 디바운스한 뒤 한 번 렌더한다. 이 id에는 offset도 들어 있다.

### 6. 달력 탭 (`CalendarTabView.swift`)
- `wallpaperScale`과 `wallpaperOffset`을 구독한다.
- 그리드 너비와 최대 높이에 크기 비율을 곱하고, 그리드를 가운데에 둔다.
- 세로 위치를 직접 정했다면 `CalendarWallpaper.screen.size.height * offset - geo.frame(in: .global).minY - 62(버튼 줄)` 위치에 그리드를 둔다.
  - 이 값은 최소 8, 최대 사용 가능 높이의 60%로 제한한다.
  - '자동'이면 기존 배치를 그대로 쓴다.

### 기타
- `.gitignore`에 `build-device/`를 추가했다.

## 빌드와 설치

시뮬레이터:
```bash
xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' -derivedDataPath build build
```

실기기 빌드. 프로젝트에 DEVELOPMENT_TEAM이 없어서 명령줄로 넘긴다. pbxproj는 수정하지 말 것.
```bash
xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'id=00008160-00190D1A10834036' -derivedDataPath build-device -allowProvisioningUpdates DEVELOPMENT_TEAM=67H369ND97 build
```

실기기 설치:
```bash
xcrun devicectl device install app --device 00008160-00190D1A10834036 build-device/Build/Products/Debug-iphoneos/Tally.app
```

실기기 실행:
```bash
xcrun devicectl device process launch --terminate-existing --device 00008160-00190D1A10834036 com.jinu2kk.tally
```

## 주의 사항
- 디스크 공간이 부족해서 빌드가 실패한 적이 있다(ENOSPC). 정리할 때는 `build/`, `build-device/`, `~/Library/Developer/Xcode/DerivedData/Tally-*` 같은 Tally 빌드 결과물만 지운다.
- Claude 시뮬레이터 도구는 계속 "Xcode not selected" 오류를 낸다. 하지만 `xcode-select -p`로 보면 이미 정상 경로다. 지금은 실기기에서 확인하고 있다.
- 기존 `$TMPDIR/run.sh` 같은 도우미 스크립트는 사라졌다.

## 남은 일
1. 사용자 실기기 확인 결과 받기:
   - 미리보기의 위젯·시계 자리가 실제 잠금화면과 맞는지
   - 세로 슬라이더 손잡이와 달력 윗변이 일치하는지
   - 달력 탭의 위치와 크기가 자연스러운지
   - 공유 시트와 디자인 시트 값이 같이 움직이는지
2. 달력 탭에서 세로 위치 때문에 달력이 너무 낮아 보이면 탭에는 크기만 반영하는 안을 제안했다. 사용자 판단을 기다리는 중이다.
3. 확인되면 커밋한다. 메시지 예: `feat: 달력 배경화면 세로 위치·크기 조절, 잠금화면 미리보기, CoreImage 블러`. 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`를 붙인다.
4. 필요하면 `REQUIREMENTS.md`, `DESIGN.md`, `MANUAL_TEST_CHECKLIST.md`의 FR-7.11~7.13 항목에 세로 위치 설정과 달력 탭 반영 내용을 추가한다.

# 날씨창고 (NalssiChanggo) — CLAUDE.md

## 프로젝트 개요

Apple WeatherKit · Google Weather API · 한국 기상청 API 세 소스를 앙상블·집계하여 최종 날씨 값을 제공하는 iOS 날씨 앱.

- **플랫폼**: iOS 17+, iPhone 전용, Portrait 고정, 라이트 모드 고정
- **UI**: SwiftUI + `@Observable`
- **빌드**: Tuist / 번들 ID `com.andev.nalssichanggo`

---

## 아키텍처

**Clean Architecture + MVVM**

```
View → ViewModel(@Observable) → UseCase → Repository Protocol → Repository Impl → DataSource
```

| 모듈 | 역할 | 주요 의존 |
|------|------|----------|
| `App` | 진입점, DI 조립, 화면 | 모든 모듈 |
| `Core` | 공유 유틸, 에러 타입, 네트워크 기반 | 없음 |
| `WeatherDomain` | Entity, Repository·UseCase Protocol | 없음 |
| `WeatherData` | Repository 구현, DTO 매핑, DataSource | Core, Location, WeatherDomain, WeatherEnsemble |
| `WeatherEnsemble` | 3개 API 앙상블 집계 | WeatherDomain |
| `Location` | CoreLocation 래핑 | Core |
| `DesignSystem` | 디자인 토큰, 아이콘, 폰트 | 없음 |
| `Widget` | 홈 화면 위젯 | WeatherDomain, DesignSystem |

**의존 방향은 위 표의 순서로만 흐른다. 역방향 금지.**

---

## Tuist

```bash
tuist generate          # 파일·의존성 추가 후 반드시 실행
tuist clean && tuist generate  # 캐시 문제 발생 시
```

- 새 소스 파일 추가 → `tuist generate` 없이는 Xcode가 인식 못 함
- `Derived/` 폴더는 자동 생성이므로 직접 수정 금지
- Team ID는 `Project.swift` 상단 `devTeam` 상수로 관리

---

## 외부 의존성

`Tuist/Package.swift` 관리. 추가 시 `Package.swift` 수정 → `tuist install` → `tuist generate`.

| 패키지 | 용도 | 사용 모듈 |
|--------|------|----------|
| Alamofire | HTTP 네트워크 | WeatherData |

---

## DesignSystem

### 구조

```
Projects/DesignSystem/
├── Sources/
│   ├── Foundation/
│   │   ├── Color+Token.swift   # Color.ink, Color.gold 등 20개 토큰
│   │   ├── Typography.swift    # NCFont.* 토큰
│   │   ├── Spacing.swift       # NCSpacing.*, NCRadius.*
│   │   └── FontRegistrar.swift # 폰트 프로세스 등록
│   └── Icons/
│       ├── WeatherIcon.swift   # WeatherIcon enum + WeatherIconView
│       └── OutfitIcon.swift    # OutfitIcon enum + OutfitIconView
└── Resources/
    ├── Fonts/                  # Pretendard, IBMPlexMono, Caveat TTF/OTF
    └── Icons.xcassets/         # Weather/ · Outfit/ SVG (template 렌더링)
```

### 사용 규칙

- 색상은 반드시 `Color.ink`, `Color.gold` 등 **토큰**을 사용한다. 16진수 직접 사용 금지.
- 폰트는 반드시 `NCFont.heroTemp`, `NCFont.monoEyebrow` 등 **토큰**을 사용한다. `.custom("Pretendard-Bold", size: ...)` 직접 사용 금지.
- 간격·반경은 `NCSpacing.*`, `NCRadius.*`를 우선 사용한다.
- 아이콘은 `WeatherIconView(.sun, size:)` / `OutfitIconView(.umbrella, size:)`로 사용한다.

### 폰트 등록

폰트는 DesignSystem 프레임워크 번들에 포함되어 있으며, **앱 시작 시 한 번** 등록해야 한다.

```swift
// NalssiChanggoApp.init()
FontRegistrar.register()
```

Info.plist `UIAppFonts` 등록 방식은 사용하지 않는다.

---

## Capability

Entitlements는 `Project.swift` `.entitlements(.dictionary([...]))` 블록에서 인라인 관리. 별도 `.entitlements` 파일 생성 금지.

| Capability | 타겟 | 비고 |
|------------|------|------|
| WeatherKit | App, Widget | Apple Developer 포털 활성화 필요 |
| Push Notification | App | 배포 시 `aps-environment` → `"production"` |
| App Groups | App, Widget | `group.com.andev.nalssichanggo` |
| Location | App Info.plist | WhenInUse + AlwaysAndWhenInUse |
| Background Modes | App Info.plist | `remote-notification`, `fetch` |

---

## Widget

- 타겟: `NalssiChanggoWidget` / 소스: `Projects/Widget/Sources/`
- App과 데이터 공유: App Groups → `UserDefaults(suiteName:)` 또는 파일
- 네트워크 호출은 App 타겟 담당, Widget은 캐시된 데이터만 읽는다

---

## API 키 관리

`Projects/App/Sources/Secrets.swift` (gitignore 등록, 직접 생성 필요)

```swift
enum Secrets {
    static let googleWeatherAPIKey = "YOUR_KEY"
    static let kmaServiceKey       = "YOUR_KEY"  // 기상청 서비스키
}
```

- WeatherKit은 별도 키 없음 (Apple Developer 계정 인증)
- 기상청 API는 1일 트래픽 제한 → 개발 중 Mock 데이터 우선 활용
- CI 환경: 환경변수 또는 시크릿 주입 방식 사용

---

## 날씨 API

| 소스 | 방식 | 좌표 |
|------|------|------|
| Apple WeatherKit | 네이티브 프레임워크 | 위경도 |
| Google Weather API | REST | 위경도 |
| 기상청 단기예보 API | REST | Lambert 격자(nx/ny) — 위경도 변환 유틸 `Core`에 위치 |

---

## 앙상블 전략

`WeatherEnsemble` 모듈에서 집계. 전략은 항목별로 다를 수 있으며 미확정.

- `EnsembleStrategy` 프로토콜로 추상화, 구체 전략은 DI로 교체 가능하게 설계
- 수치 항목(기온·강수량)과 상태 항목(맑음·흐림)은 전략을 분리

---

## 코딩 컨벤션

- 변수·함수명 영어, 주석 한국어 허용
- ViewModel에 `@Observable` 사용 (`ObservableObject` 사용 금지)
- 네트워크 호출 기본 패턴: **Combine**
- Repository 구현체 네이밍: `XxxRepositoryImpl`
- DTO 네이밍: `XxxDTO` / Domain Entity: `Xxx` (접미사 없음)

---

## 테스트

- 단위 테스트: `Projects/App/Tests/` (`NalssiChanggoTests` 타겟)
- `WeatherEnsemble` 집계 로직은 순수 Swift이므로 단위 테스트 필수
- 네트워크 레이어: Repository Protocol을 Mock 주입하여 테스트

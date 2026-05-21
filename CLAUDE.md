# 날씨창고 (NalssiChanggo) — CLAUDE.md

## 프로젝트 개요

Apple Weather API, Google Weather API, 한국 기상청 API 세 가지 데이터 소스를 호출한 뒤 앱 내부에서 앙상블·집계하여 최종 날씨 값을 사용자에게 제공하는 iOS 날씨 앱.

- **플랫폼**: iOS 17+
- **UI 프레임워크**: SwiftUI
- **빌드 시스템**: Tuist
- **번들 ID**: `com.andev.nalssichanggo`

---

## 아키텍처

**Clean Architecture + MVVM**

```
View (SwiftUI)
  └─ ViewModel (@Observable / ObservableObject)
       └─ UseCase (Domain)
            └─ Repository Protocol (Domain)
                 └─ Repository Impl (Data)
                      └─ DataSource (Network / Local)
```

- `WeatherDomain`: Entity, Repository Protocol, UseCase Protocol 정의. 외부 프레임워크 의존 없음.
- `WeatherData`: Repository 구현체, DataSource, DTO→Entity 매핑. Alamofire 사용.
- `WeatherEnsemble`: 세 API 결과를 받아 앙상블 집계 로직 수행. `WeatherDomain`에만 의존.
- `Location`: CoreLocation 래핑. `Core`에 의존.
- `DesignSystem`: 공통 UI 컴포넌트, 색상, 폰트. 비즈니스 로직 없음.
- `Core`: 공유 유틸리티(네트워크 기반, 에러 타입, 익스텐션 등). 다른 도메인 모듈에 의존하지 않음.
- `App`: 진입점, DI 조립, 루트 뷰. 모든 모듈에 의존.

### 의존 방향 (역방향 금지)

```
App → WeatherData, WeatherEnsemble, Location, DesignSystem, Core
WeatherData → Core, Location, WeatherDomain, WeatherEnsemble
WeatherEnsemble → WeatherDomain
Location → Core
DesignSystem → (없음)
Core → (없음)
```

---

## 모듈 구조 (Tuist)

```
Projects/
├── App/
│   ├── Sources/
│   ├── Resources/
│   └── Tests/
├── Core/Sources/
├── DesignSystem/Sources/
├── Location/Sources/
├── WeatherDomain/Sources/
├── WeatherData/Sources/
└── WeatherEnsemble/Sources/
```

### Tuist 명령어

```bash
# 프로젝트 재생성 (의존성·파일 추가 후 반드시 실행)
tuist generate

# 캐시 정리 후 재생성
tuist clean && tuist generate
```

새 소스 파일을 추가하거나 `Project.swift`를 변경한 뒤에는 항상 `tuist generate`를 실행해야 Xcode가 인식한다.

---

## 외부 의존성

`Tuist/Package.swift`에서 관리.

| 패키지 | 용도 |
|--------|------|
| Alamofire | HTTP 네트워크 레이어 (`WeatherData` 모듈에서만 사용) |

의존성 추가 시 `Package.swift` 수정 → `tuist install` → `tuist generate` 순서로 진행.

---

## API 키 및 민감 정보 관리

민감 정보는 **`Secrets.swift`** 파일로 관리하며 `.gitignore`에 등록되어 있다.

```
Projects/App/Sources/Secrets.swift   ← gitignore됨, 직접 생성 필요
```

`Secrets.swift` 템플릿:

```swift
enum Secrets {
    static let appleWeatherAPIKey = "YOUR_KEY"
    static let googleWeatherAPIKey = "YOUR_KEY"
    static let kmaServiceKey = "YOUR_KEY"       // 기상청 API 서비스키
}
```

- `Secrets.swift`를 커밋하지 않는다.
- CI 환경에서는 환경변수 또는 별도 시크릿 주입 방식을 사용한다.

---

## 날씨 API 정보

| 소스 | 비고 |
|------|------|
| Apple WeatherKit (WeatherKit framework) | iOS 16+ 네이티브, 위도/경도 기반 |
| Google Weather API | REST, 위도/경도 기반 |
| 한국 기상청 단기예보 API | REST, 격자(nx/ny) 좌표 기반, 위경도→격자 변환 필요 |

기상청 API는 위경도를 Lambert 격자 좌표로 변환하는 유틸리티가 `Core` 모듈에 위치해야 한다.

---

## 앙상블(집계) 전략

세 API 결과를 `WeatherEnsemble` 모듈에서 집계한다. 전략은 항목별로 다를 수 있으며 아직 확정되지 않았다.

- 집계 전략은 `EnsembleStrategy` 프로토콜로 추상화하고, 구체 전략은 주입(DI) 방식으로 교체 가능하게 설계한다.
- 기온·강수 등 수치 항목과 날씨 상태(맑음/흐림 등) 항목은 전략이 다를 수 있다.

---

## 코딩 컨벤션

- Swift 공식 API 가이드라인을 따른다.
- 변수·함수명은 영어, 주석은 한국어도 허용.
- `@Observable`(iOS 17+)을 ViewModel에 기본으로 사용한다. `ObservableObject`는 사용하지 않는다.
- Combine을 네트워크 호출의 기본 패턴으로 사용한다.
- Repository 구현체는 `XxxRepositoryImpl` 네이밍을 따른다.
- DTO는 `XxxDTO`, Domain Entity는 `Xxx`(접미사 없음) 네이밍을 따른다.

---

## 테스트

- 단위 테스트는 `Projects/App/Tests/` 아래에 작성한다 (현재는 `NalssiChanggoTests` 타겟).
- `WeatherEnsemble` 집계 로직은 외부 의존 없이 순수 Swift이므로 반드시 단위 테스트를 작성한다.
- 네트워크 레이어는 `Repository Protocol`을 Mock으로 주입하여 테스트한다.

---

## 주의사항

- `Project.swift`에서 `DEVELOPMENT_TEAM`을 본인 Team ID로 교체해야 빌드된다.
- 기상청 API는 1일 트래픽 제한이 있으므로 개발 중에는 Mock 데이터를 우선 활용한다.
- WeatherKit은 App ID에 WeatherKit capability가 활성화되어 있어야 한다.
- `Derived/` 폴더는 Tuist가 자동 생성하므로 직접 수정하지 않는다.

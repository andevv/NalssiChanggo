# 날씨창고 (NalssiChanggo) — CLAUDE.md

## 프로젝트 개요

Apple WeatherKit · OpenWeatherMap API · 한국 기상청 API 세 소스를 앙상블·집계하여 최종 날씨 값을 제공하는 iOS 날씨 앱.

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

현재 외부 패키지 없음. 네트워크 레이어는 `URLSession` 직접 사용.

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
    static let openWeatherMapAPIKey = "YOUR_KEY"   // openweathermap.org 발급
    static let kmaServiceKey        = "YOUR_KEY"   // 기상청 서비스키 (URL 인코딩된 값 그대로)
    static let airKoreaAPIKey       = "YOUR_KEY"
}
```

- WeatherKit은 별도 키 없음 (Apple Developer 계정 인증)
- 기상청·에어코리아 키는 data.go.kr 활용 신청 후 발급
- OpenWeatherMap 키는 openweathermap.org 회원가입 후 발급 (Free plan)
- CI 환경: 환경변수 또는 시크릿 주입 방식 사용

---

## 날씨 API

| 소스 | 방식 | 좌표 | 구현 상태 |
|------|------|------|----------|
| Apple WeatherKit | 네이티브 프레임워크 | 위경도 | ✅ 완료 |
| 기상청 단기예보 API | REST | Lambert 격자(nx/ny) | ✅ 완료 |
| OpenWeatherMap API | REST | 위경도 | ✅ 완료 |

### 기상청 API 엔드포인트

베이스 URL: `https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0`

| 오퍼레이션 | 용도 | 발표 주기 | 구현 |
|-----------|------|----------|------|
| `getUltraSrtNcst` | 초단기실황 (현재 기온·풍속·습도·강수형태) | 매시 :40 | ✅ |
| `getVilageFcst` | 단기예보 (시간별·일별 24h+) | 3시간마다 | ✅ |
| `getUltraSrtFcst` | 초단기예보 (SKY 포함) | 매 30분 | 보류 — 운영 전환 후 추가 예정 |

- 일일 호출 한도: `getUltraSrtNcst` + `getVilageFcst` 공유 (VilageFcstInfoService_2.0 서비스 기준)
- Lambert 격자 변환: `Core/LambertConverter.swift` — `LambertConverter.convert(latitude:longitude:) → GridPoint`
- **SKY 보완**: `getUltraSrtNcst`는 SKY(하늘 상태) 카테고리를 제공하지 않아 강수 없을 때 `state = .unknown`이 됨. `KMAWeatherDataSource`에서 두 API 결과를 합산할 때 `current.state == .unknown`이면 `getVilageFcst` 첫 슬롯의 state로 덮어씀

### OpenWeatherMap API 엔드포인트

베이스 URL: `https://api.openweathermap.org/data/2.5`

| 엔드포인트 | 용도 | 구현 |
|-----------|------|------|
| `GET /weather` | 현재 날씨 (기온·체감·습도·풍속·상태·일출몰) | ✅ |
| `GET /forecast` | 5일 3시간 예보 → 시간별·일별 집계 (cnt=40) | ✅ |

- Free plan: 분당 60회, 월 100만 회
- 풍속 단위: m/s (수신) → km/h 변환 후 저장
- 날씨 상태: condition code (int) → `WeatherState` 매핑 (`OpenWeatherMapDataSource`)
- 시간별 예보: 3시간 간격 슬롯 (KMA·Apple은 1시간 간격 — 앙상블 시 매칭 없는 슬롯은 Apple 단독 사용)

---

## 앙상블 전략

`WeatherEnsemble` 모듈에서 집계. `WeatherEnsembler`가 `WeatherSummary`를 소스별로 받아 병합.

### 현재 구현 (WeatherKit × KMA × OWM)

| 항목 | 전략 | 가중치 |
|------|------|--------|
| 기온·습도·풍속 | `WeightedAverageStrategy` (가중 평균) | KMA 0.4 : Apple 0.3 : OWM 0.3 |
| 강수확률 | `WeightedAverageStrategy` (가중 평균) | KMA 0.4 : Apple 0.3 : OWM 0.3 |
| 날씨 상태 | `MajorityVoteStrategy` (가중 다수결) | KMA 0.4 : Apple 0.3 : OWM 0.3, `.unknown` 투표 제외 |
| feelsLike | Apple → KMA → OWM 순 우선 | 소스 배열 삽입 순서 기준 (Apple 장애 시 KMA 대체) |
| isDaytime | Apple → KMA → OWM 순 우선 | OWM은 일출/일몰 Unix timestamp 제공 |

- 소스 장애 시 정상 소스만 가중치 정규화하여 집계 (nil-safe)
- `ensemble(apple:kma:owm:)` — `owm` 기본값 nil, 기존 2소스 호출도 그대로 동작
- 수치 항목(`NumericEnsembleStrategy`)과 상태 항목(`StateEnsembleStrategy`) 전략 분리
- 앙상블 결과에 `SourceBreakdown`을 함께 생성하여 `WeatherSummary.sourceBreakdown`에 포함 — 소스별 기온·상태·편차, 소스 간 일치도(표준편차 기반 0–1), 평균 절대편차 보관

---

## 메인 화면 컴포넌트

`Projects/App/Sources/Main/` 하위 구조:

```
View/
  MainView.swift          # ScrollView 루트, WeatherContentView 조합
Components/
  WeatherHeroCard.swift   # 현재 기온·날씨 상태·앙상블 소스 표시 — 탭 시 SourceBreakdownView sheet
  SourceBreakdownView.swift # 소스별 날씨 비교 sheet (영수증 스타일)
  AirRainRow.swift        # 대기질 카드 + 강수 카드 (가로 2분할)
  OutfitCard.swift        # 옷차림 추천
  HourlyTimelineCard.swift # 시간별 예보 (가로 스크롤)
Model/
  WeatherDisplayData.swift # WeatherSummary → View용 표시 데이터 매핑 (SourceBreakdownDisplayData 포함)
  OutfitRecommender.swift  # 체감 온도·강수 확률 기반 옷차림 추천
```

### WeatherDisplayData 주요 로직

**강수 카드 레이블** (`rainCondition`)
- 기준: `precipitationChance >= 0.4` (40%) 이상이 처음 등장하는 시각
- 현재 시각 자체가 40% 이상이면 `"지금"`, 이후 시각이면 `"N시부터"`
- 0–39%만 있으면 `"강수 없음"`
- `peakHour`는 옷차림 추천의 `maxRainChance`용으로만 유지

**시간별 예보 기온**
- `isNow`(첫 번째 슬롯)는 `summary.current.temperature`(실시간 관측 앙상블) 사용
- 이후 슬롯은 `hourlyForecasts[n].temperature`(예보값) 사용
- 메인 기온 카드와 "지금" 셀 기온이 항상 일치하도록 보장

**시간별 예보 아이콘**
- `WeatherState` → `mapWeatherIcon(state:isDaytime:)` 매핑
- `isDaytime`은 해당 시각의 hour가 6–19시 범위인지로 판별 (sunrise/sunset 미사용)
- 아이콘(WeatherState)과 강수확률(precipitationChance)은 독립 데이터 — 불일치 가능

**강수 확률 색상 임계값 (HourlyTimelineCard)**
- `pct < 10`: `"—"` 표시 (inkFaint)
- `10 ≤ pct < 40`: 물방울 + % 연한 rain 색
- `pct >= 40`: 물방울 + % 진한 rain 색

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

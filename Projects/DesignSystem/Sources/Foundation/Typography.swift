import SwiftUI

// 앱 시작 시 FontRegistrar.register() 를 호출해야 폰트가 활성화됩니다.

// MARK: - NCFontSet

/// 디바이스별 명시적 고정 크기 폰트 컬렉션.
/// WeatherContentView 가 iPhone → `.phone` / iPad → `.pad` 를 Environment에 주입한다.
/// 컴포넌트 뷰는 `@Environment(\.ncFonts) var fonts` 로 읽는다.
public struct NCFontSet {

    // Pretendard — Display
    public let heroTemp: Font
    public let heroDeg: Font
    public let subTemp: Font
    public let locationTitle: Font
    /// 소스 비교 일치도 수치 등 대형 표시 (36 / 44pt)
    public let displayXL: Font
    /// 소스별 기온 등 중대형 표시 (28 / 35pt)
    public let displayLG: Font

    // Pretendard — UI
    public let cardValue: Font
    public let conditionBody: Font
    public let cardTitle: Font
    public let labelLarge: Font
    public let chip: Font
    public let labelSmall: Font
    public let labelTiny: Font

    // IBM Plex Mono
    public let monoEmphasis: Font
    public let monoBody: Font
    public let monoEyebrow: Font
    public let monoSmall: Font
    public let monoTiny: Font

    // Caveat
    public let accent: Font
}

extension NCFontSet {

    /// iPhone 세트 — 기존 대비 소폭 확대, 모두 fixedSize (Dynamic Type 미반응)
    public static let phone = NCFontSet(
        heroTemp:      .pretendardFixed(96,   .bold),
        heroDeg:       .pretendardFixed(60,   .medium),
        subTemp:       .pretendardFixed(30,   .bold),
        locationTitle: .pretendardFixed(34,   .bold),
        displayXL:     .pretendardFixed(36,   .bold),
        displayLG:     .pretendardFixed(28,   .bold),
        cardValue:     .pretendardFixed(27,   .bold),
        conditionBody: .pretendardFixed(18,   .medium),
        cardTitle:     .pretendardFixed(19,   .semibold),
        labelLarge:    .pretendardFixed(15,   .semibold),
        chip:          .pretendardFixed(13,   .medium),
        labelSmall:    .pretendardFixed(12,   .regular),
        labelTiny:     .pretendardFixed(10,   .regular),
        monoEmphasis:  .ibmPlexMonoFixed(13,  .medium),
        monoBody:      .ibmPlexMonoFixed(12,  .regular),
        monoEyebrow:   .ibmPlexMonoFixed(11,  .regular),
        monoSmall:     .ibmPlexMonoFixed(11,  .regular),
        monoTiny:      .ibmPlexMonoFixed(10,  .medium),
        accent:        .caveatFixed(15,       .medium)
    )

    /// iPad 세트 — phone 대비 약 1.25×, fixedSize
    public static let pad = NCFontSet(
        heroTemp:      .pretendardFixed(120,  .bold),
        heroDeg:       .pretendardFixed(75,   .medium),
        subTemp:       .pretendardFixed(38,   .bold),
        locationTitle: .pretendardFixed(42,   .bold),
        displayXL:     .pretendardFixed(44,   .bold),
        displayLG:     .pretendardFixed(35,   .bold),
        cardValue:     .pretendardFixed(30,   .bold),
        conditionBody: .pretendardFixed(22,   .medium),
        cardTitle:     .pretendardFixed(24,   .semibold),
        labelLarge:    .pretendardFixed(16,   .semibold),
        chip:          .pretendardFixed(16,   .medium),
        labelSmall:    .pretendardFixed(15,   .regular),
        labelTiny:     .pretendardFixed(12,   .regular),
        monoEmphasis:  .ibmPlexMonoFixed(16,  .medium),
        monoBody:      .ibmPlexMonoFixed(15,  .regular),
        monoEyebrow:   .ibmPlexMonoFixed(14,  .regular),
        monoSmall:     .ibmPlexMonoFixed(14,  .regular),
        monoTiny:      .ibmPlexMonoFixed(12,  .medium),
        accent:        .caveatFixed(19,       .medium)
    )
}

// MARK: - Environment Key

private struct NCFontSetKey: EnvironmentKey {
    static let defaultValue: NCFontSet = .phone
}

public extension EnvironmentValues {
    var ncFonts: NCFontSet {
        get { self[NCFontSetKey.self] }
        set { self[NCFontSetKey.self] = newValue }
    }
}

// MARK: - NCFont (위젯 및 레거시 호환용 static 토큰)

// 앱 컴포넌트 뷰는 @Environment(\.ncFonts) 를 사용한다.
// 위젯 Extension 은 WidgetKit 프로세스에서 실행되므로 이 static 토큰을 직접 참조한다.
public enum NCFont {

    // MARK: - 기온 표시 (Pretendard)
    public static let heroTemp: Font      = NCFontSet.phone.heroTemp
    public static let heroDeg: Font       = NCFontSet.phone.heroDeg
    public static let subTemp: Font       = NCFontSet.phone.subTemp

    // MARK: - UI 텍스트 (Pretendard)
    public static let locationTitle: Font = NCFontSet.phone.locationTitle
    public static let cardValue: Font     = NCFontSet.phone.cardValue
    public static let conditionBody: Font = NCFontSet.phone.conditionBody
    public static let cardTitle: Font     = NCFontSet.phone.cardTitle
    public static let labelLarge: Font    = NCFontSet.phone.labelLarge
    public static let chip: Font          = NCFontSet.phone.chip
    public static let labelSmall: Font    = NCFontSet.phone.labelSmall
    public static let labelTiny: Font     = NCFontSet.phone.labelTiny

    // MARK: - 수치 / 모노 (IBM Plex Mono)
    public static let monoEmphasis: Font  = NCFontSet.phone.monoEmphasis
    public static let monoBody: Font      = NCFontSet.phone.monoBody
    public static let monoEyebrow: Font   = NCFontSet.phone.monoEyebrow
    public static let monoSmall: Font     = NCFontSet.phone.monoSmall
    public static let monoTiny: Font      = NCFontSet.phone.monoTiny

    // MARK: - 위젯 전용 (systemSmall 기온 표시용 — 별도 크기 유지)
    public static let widgetTemp: Font = .pretendardFixed(48, .bold)
    public static let widgetDeg: Font  = .pretendardFixed(28, .medium)

    // MARK: - 손글씨 액센트 (Caveat)
    public static let accent: Font     = NCFontSet.phone.accent
}

// MARK: - Font Helpers (DesignSystem internal)

extension Font {

    static func pretendardFixed(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        let name: String
        switch weight {
        case .bold:     name = "Pretendard-Bold"
        case .semibold: name = "Pretendard-SemiBold"
        case .medium:   name = "Pretendard-Medium"
        default:        name = "Pretendard-Regular"
        }
        return .custom(name, fixedSize: size)
    }

    static func ibmPlexMonoFixed(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        let name = weight == .medium ? "IBMPlexMono-Medium" : "IBMPlexMono-Regular"
        return .custom(name, fixedSize: size)
    }

    static func caveatFixed(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        let name = weight == .medium ? "Caveat-Medium" : "Caveat-Regular"
        return .custom(name, fixedSize: size)
    }
}

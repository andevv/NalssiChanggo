import SwiftUI

// 앱 시작 시 FontRegistrar.register() 를 호출해야 폰트가 활성화됩니다.

public enum NCFont {

    // MARK: - 기온 표시 (Pretendard)

    /// 메인 기온 — 92pt Bold
    public static let heroTemp: Font      = .pretendard(size: 92, weight: .bold)
    /// 도(°) 기호 — 56pt Medium
    public static let heroDeg: Font       = .pretendard(size: 56, weight: .medium)
    /// 서브 기온 — 28pt Bold
    public static let subTemp: Font       = .pretendard(size: 28, weight: .bold)

    // MARK: - UI 텍스트 (Pretendard)

    /// 지역명 — 32pt Bold
    public static let locationTitle: Font = .pretendard(size: 32, weight: .bold)
    /// 카드 큰 값 (좋음, 오후 비 등) — 26pt Bold
    public static let cardValue: Font     = .pretendard(size: 26, weight: .bold)
    /// 날씨 상태 본문 — 17pt Medium
    public static let conditionBody: Font = .pretendard(size: 17, weight: .medium)
    /// 섹션/카드 타이틀 — 18pt SemiBold
    public static let cardTitle: Font     = .pretendard(size: 18, weight: .semibold)
    /// 보조 레이블 — 14pt SemiBold
    public static let labelLarge: Font    = .pretendard(size: 14, weight: .semibold)
    /// 칩 텍스트 — 12pt Medium
    public static let chip: Font          = .pretendard(size: 12, weight: .medium)
    /// 카드 소형 레이블 — 11pt Regular
    public static let labelSmall: Font    = .pretendard(size: 11, weight: .regular)
    /// 미세 레이블 — 9pt Regular
    public static let labelTiny: Font     = .pretendard(size: 9,  weight: .regular)

    // MARK: - 수치 / 모노 (IBM Plex Mono)

    /// 어그리먼트 퍼센트 — 12pt Medium
    public static let monoEmphasis: Font  = .ibmPlexMono(size: 12, weight: .medium)
    /// 수치 본문 — 11pt Regular
    public static let monoBody: Font      = .ibmPlexMono(size: 11, weight: .regular)
    /// 섹션 아이브로우 — 10.5pt Regular (+ tracking 1.4 별도 적용)
    public static let monoEyebrow: Font   = .ibmPlexMono(size: 10.5, weight: .regular)
    /// 소형 수치 — 10pt Regular
    public static let monoSmall: Font     = .ibmPlexMono(size: 10, weight: .regular)
    /// 극소형 — 9pt Medium
    public static let monoTiny: Font      = .ibmPlexMono(size: 9, weight: .medium)

    // MARK: - 손글씨 액센트 (Caveat)

    /// 손글씨 액센트 — 14pt Medium
    public static let accent: Font        = .caveat(size: 14, weight: .medium)
}

// MARK: - Font Helpers

private extension Font {

    static func pretendard(size: CGFloat, weight: Font.Weight) -> Font {
        let name: String
        switch weight {
        case .bold:     name = "Pretendard-Bold"
        case .semibold: name = "Pretendard-SemiBold"
        case .medium:   name = "Pretendard-Medium"
        default:        name = "Pretendard-Regular"
        }
        return .custom(name, size: size, relativeTo: .body)
    }

    static func ibmPlexMono(size: CGFloat, weight: Font.Weight) -> Font {
        let name = weight == .medium ? "IBMPlexMono-Medium" : "IBMPlexMono-Regular"
        return .custom(name, size: size, relativeTo: .body)
    }

    static func caveat(size: CGFloat, weight: Font.Weight) -> Font {
        let name = weight == .medium ? "Caveat-Medium" : "Caveat-Regular"
        return .custom(name, size: size, relativeTo: .body)
    }
}

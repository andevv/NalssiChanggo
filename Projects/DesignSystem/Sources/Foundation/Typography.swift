import SwiftUI

// 앱 시작 시 FontRegistrar.register() 를 호출해야 폰트가 활성화됩니다.

public enum NCFont {

    // MARK: - Temperature / Numeric (IBM Plex Mono)

    /// 메인 기온 표시 — 32pt Medium
    public static let tempHero: Font    = .ibmPlexMono(size: 32, weight: .medium)
    /// 서브 기온 — 28pt Medium
    public static let tempLarge: Font   = .ibmPlexMono(size: 28, weight: .medium)
    /// 수치 레이블 — 14pt Regular
    public static let numeric: Font     = .ibmPlexMono(size: 14, weight: .regular)
    /// 소형 수치 — 11pt Regular
    public static let numericSmall: Font = .ibmPlexMono(size: 11, weight: .regular)
    /// 극소형 수치 — 10pt Regular
    public static let numericTiny: Font = .ibmPlexMono(size: 10, weight: .regular)

    // MARK: - UI / Korean (Pretendard)

    /// 섹션 타이틀 — 14pt SemiBold
    public static let labelLarge: Font  = .pretendard(size: 14, weight: .semibold)
    /// 카드 레이블 — 11pt Medium
    public static let labelMedium: Font = .pretendard(size: 11, weight: .medium)
    /// 보조 레이블 — 10pt Regular
    public static let labelSmall: Font  = .pretendard(size: 10, weight: .regular)
    /// 미세 레이블 — 9pt Regular
    public static let labelTiny: Font   = .pretendard(size: 9,  weight: .regular)

    // MARK: - Accent / Handwriting (Caveat)

    /// 손글씨 액센트 — 14pt Medium
    public static let accent: Font      = .caveat(size: 14, weight: .medium)
}

// MARK: - Font Helpers

private extension Font {

    static func pretendard(size: CGFloat, weight: Font.Weight) -> Font {
        let name: String
        switch weight {
        case .semibold: name = "Pretendard-SemiBold"
        case .medium:   name = "Pretendard-Medium"
        case .bold:     name = "Pretendard-Bold"
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

import CoreFoundation

public enum NCSpacing {
    /// 기본 패딩 단위 (7pt)
    public static let base: CGFloat    = 7
    /// 소형 간격 (14pt = base × 2)
    public static let small: CGFloat   = 14
    /// 중형 간격 (24pt)
    public static let medium: CGFloat  = 24
    /// 대형 간격 (28pt)
    public static let large: CGFloat   = 28
    /// 화면 가장자리 여백 (24pt)
    public static let screenH: CGFloat = 24
    /// 섹션 상단 여백 (32pt)
    public static let sectionTop: CGFloat = 32
}

public enum NCRadius {
    /// 카드 모서리 (18pt)
    public static let card: CGFloat    = 18
    /// 카드 내부 요소 (12pt)
    public static let inner: CGFloat   = 12
    /// 태그/배지 (100pt — pill)
    public static let pill: CGFloat    = 100
    /// 소형 요소 (8pt)
    public static let small: CGFloat   = 8
    /// 미세 요소 (6pt)
    public static let xsmall: CGFloat  = 6
}

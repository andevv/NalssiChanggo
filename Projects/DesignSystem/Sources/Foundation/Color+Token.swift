import SwiftUI

public extension Color {

    // MARK: - Background

    /// 앱 전체 배경 (warm gray) #efeae0
    static let appBg          = Color(hex: 0xEFEAE0)
    /// 카드 배경 (off-white) #faf6ec
    static let paper          = Color(hex: 0xFAF6EC)
    /// 카드 내부 보조 배경 #f3eddf
    static let paperGrain     = Color(hex: 0xF3EDDF)
    /// 카드 테두리 #e6dfcd
    static let paperEdge      = Color(hex: 0xE6DFCD)
    /// 구분선 #d8cfb7
    static let hairline       = Color(hex: 0xD8CFB7)

    // MARK: - Text (Ink)

    /// 본문 텍스트 #1c1a16
    static let ink            = Color(hex: 0x1C1A16)
    /// 보조 텍스트 #3a3631
    static let ink2           = Color(hex: 0x3A3631)
    /// 3차 텍스트 #6b6357
    static let ink3           = Color(hex: 0x6B6357)
    /// 4차 텍스트 #9a9080
    static let ink4           = Color(hex: 0x9A9080)
    /// 비활성/placeholder #cdc3ad
    static let inkFaint       = Color(hex: 0xCDC3AD)

    // MARK: - Gold (맑음/따뜻함)

    /// 메인 골드 #d99514
    static let gold           = Color(hex: 0xD99514)
    /// 진한 골드 #a06d0c
    static let goldDeep       = Color(hex: 0xA06D0C)
    /// 골드 테두리 #ecc764
    static let goldEdge       = Color(hex: 0xECC764)
    /// 골드 배경 틴트 #fff1ce
    static let goldSoft       = Color(hex: 0xFFF1CE)

    // MARK: - Rain (비/추위)

    /// 비 강조색 #3a6fb0
    static let rain           = Color(hex: 0x3A6FB0)
    /// 비 배경 틴트 #d9e6f4
    static let rainSoft       = Color(hex: 0xD9E6F4)

    // MARK: - Warn (경고)

    /// 경고색 #c2532a
    static let warn           = Color(hex: 0xC2532A)
    /// 경고 배경 틴트 #fbe2d3
    static let warnSoft       = Color(hex: 0xFBE2D3)

    // MARK: - Air Quality

    /// 좋음 #4d8c5a
    static let airGood        = Color(hex: 0x4D8C5A)
    /// 좋음 배경 틴트 #dcefdf
    static let airGoodSoft    = Color(hex: 0xDCEFDF)
}

// MARK: - Hex Initializer

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red:     Double((hex >> 16) & 0xFF) / 255,
            green:   Double((hex >> 8)  & 0xFF) / 255,
            blue:    Double( hex        & 0xFF) / 255,
            opacity: opacity
        )
    }
}

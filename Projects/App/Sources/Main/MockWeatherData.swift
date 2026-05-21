import Foundation

struct MockWeather {
    let receiptNo     = "NO. 20260520·0941"
    let location      = "서울 · 강남구"
    let dateLabel     = "5/20 화"

    // TOTAL
    let temperature   = 19
    let condition     = "구름 조금"
    let feelsLike     = 17
    let agreementPct  = 92
    let icon          = "wx-cloud-sun"    // WeatherIcon.cloudSun

    // 미세먼지
    let pmGrade       = "좋음"
    let pmGradeIndex  = 0                 // AirDial grade
    let pmValue       = 12
    let pmDelta       = -4

    // 강수
    let rainCondition = "오후 비"
    let hourlyRain: [(hour: String, pct: Int)] = [
        ("12", 10), ("13", 15), ("14", 25), ("15", 40),
        ("16", 60), ("17", 55), ("18", 35), ("19", 20)
    ]
    let rainPeakLabel = "15시 60%"

    // OUTFIT
    let outfitIcon    = "of-light-outer"   // OutfitIcon.lightOuter
    let outfitLabel   = "긴팔 + 얇은 가디건"
    let outfitSub     = "14° → 22° → 16° · ☂ 우산 챙기기"
    let outfitChips: [(label: String, highlight: Bool)] = [
        ("긴팔", false), ("가디건", false), ("면바지", false),
        ("운동화", false), ("☂ 우산", true)
    ]
}

import Foundation
import SwiftUI
import DesignSystem
import WeatherDomain

struct WeatherDisplayData {

    // MARK: Header
    let receiptNo: String
    let location: String
    let dateLabel: String

    // MARK: Hero
    let temperature: Int
    let condition: String
    let feelsLike: Int
    let weatherIcon: WeatherIcon

    // MARK: Rain
    let rainCondition: String
    let hourlyRain: [(hour: String, pct: Int)]
    let rainPeakLabel: String

    // MARK: Air Quality
    let hasAirData: Bool
    let airGrade: String
    let airGradeIndex: Int    // 0=좋음 1=보통 2=나쁨 3=매우나쁨 4=위험 (AirDial 입력)
    let airPM25: Int          // PM2.5 μg/m³
    let airPM10: Int          // PM10 μg/m³

    // MARK: Outfit
    let outfitIcon: OutfitIcon
    let outfitLabel: String
    let outfitSub: String
    let outfitChips: [(label: String, highlight: Bool)]

    // MARK: Computed

    var airGradeColor: Color {
        switch airGradeIndex {
        case 0:  return .airGood
        case 1:  return Color(hex: 0xC9A52E)
        case 2:  return Color(hex: 0xCF6F2A)
        case 3:  return Color(hex: 0xA93A26)
        default: return Color(hex: 0x742323)
        }
    }
}

// MARK: - Mapping from WeatherSummary

extension WeatherDisplayData {

    static func from(summary: WeatherSummary, locationName: String) -> WeatherDisplayData {
        let current = summary.current
        let now = Date()

        // Header
        let receiptFormatter = DateFormatter()
        receiptFormatter.dateFormat = "yyyyMMdd·HHmm"
        let receiptNo = "NO. \(receiptFormatter.string(from: current.date))"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M/d E"
        let dateLabel = dateFormatter.string(from: current.date)

        // 다음 8시간 시간당 강수 확률
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "H"
        let upcomingHours = summary.hourlyForecasts
            .filter { $0.date >= now }
            .prefix(8)

        let hourlyRain = upcomingHours.map { f in
            (hour: hourFormatter.string(from: f.date), pct: Int(f.precipitationChance * 100))
        }

        let peakHour = upcomingHours.max(by: { $0.precipitationChance < $1.precipitationChance })
        let rainCondition: String
        let rainPeakLabel: String
        if let peak = peakHour, peak.precipitationChance >= 0.3 {
            let h = hourFormatter.string(from: peak.date)
            rainCondition = "\(h)시 전후 비"
            rainPeakLabel = "\(h)시 \(Int(peak.precipitationChance * 100))%"
        } else {
            rainCondition = "강수 없음"
            rainPeakLabel = "강수 없음"
        }

        // Outfit
        let today = summary.dailyForecasts.first
        let maxRainChance = peakHour?.precipitationChance ?? 0
        let outfit = OutfitRecommender.recommend(
            feelsLike: current.feelsLike,
            minTemp: today?.lowTemperature,
            maxTemp: today?.highTemperature,
            maxRainChance: maxRainChance
        )

        // Air Quality
        let air = summary.airQuality

        return WeatherDisplayData(
            receiptNo: receiptNo,
            location: locationName.isEmpty ? "위치 확인 중…" : locationName,
            dateLabel: dateLabel,
            temperature: Int(current.temperature.rounded()),
            condition: current.state.koreanLabel,
            feelsLike: Int(current.feelsLike.rounded()),
            weatherIcon: mapWeatherIcon(state: current.state, isDaytime: current.isDaytime),
            rainCondition: rainCondition,
            hourlyRain: Array(hourlyRain),
            rainPeakLabel: rainPeakLabel,
            hasAirData: air != nil,
            airGrade: air?.grade ?? "--",
            airGradeIndex: air?.gradeIndex ?? 0,
            airPM25: air?.pm25Value ?? 0,
            airPM10: air?.pm10Value ?? 0,
            outfitIcon: outfit.icon,
            outfitLabel: outfit.label,
            outfitSub: outfit.sub,
            outfitChips: outfit.chips
        )
    }

    private static func mapWeatherIcon(state: WeatherState, isDaytime: Bool) -> WeatherIcon {
        switch state {
        case .clear, .mostlyClear, .hot:
            return isDaytime ? .sun : .moon
        case .partlyCloudy:
            return isDaytime ? .cloudSun : .moonCloud
        case .mostlyCloudy, .cloudy:
            return .cloud
        case .drizzle, .rain, .sleet:
            return .cloudRain
        case .heavyRain, .thunderstorm:
            return .cloudHeavyRain
        case .snow, .heavySnow, .blizzard, .frigid:
            return .cloudSnow
        case .fog, .haze:
            return .fog
        case .windy:
            return .wind
        case .unknown:
            return isDaytime ? .cloudSun : .moonCloud
        }
    }
}

// MARK: - Preview helper

extension WeatherDisplayData {
    static var preview: WeatherDisplayData {
        WeatherDisplayData(
            receiptNo: "NO. 20260524·0941",
            location: "서울 · 강남구",
            dateLabel: "5/24 일",
            temperature: 19,
            condition: "구름 조금",
            feelsLike: 17,
            weatherIcon: .cloudSun,
            rainCondition: "오후 비",
            hourlyRain: [
                ("12", 10), ("13", 15), ("14", 25), ("15", 40),
                ("16", 60), ("17", 55), ("18", 35), ("19", 20)
            ],
            rainPeakLabel: "16시 60%",
            hasAirData: true,
            airGrade: "좋음",
            airGradeIndex: 0,
            airPM25: 8,
            airPM10: 22,
            outfitIcon: .lightOuter,
            outfitLabel: "긴팔 + 얇은 가디건",
            outfitSub: "14° → 22° · ☂ 우산 챙기기",
            outfitChips: [
                ("긴팔", false), ("가디건", false), ("면바지", false),
                ("운동화", false), ("☂ 우산", true)
            ]
        )
    }
}

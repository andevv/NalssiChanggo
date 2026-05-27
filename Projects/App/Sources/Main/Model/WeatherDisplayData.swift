import Foundation
import SwiftUI
import DesignSystem
import WeatherDomain
import Core

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

    // MARK: Hourly Timeline
    let todayLow: Int?
    let todayHigh: Int?
    let hourlyTimeline: [HourlyItem]

    struct HourlyItem: Identifiable {
        let id: Int
        let hourLabel: String
        let temperature: Int
        let precipitationPct: Int
        let icon: WeatherIcon
        let isNow: Bool
        let dayLabel: String?   // 날짜 변경 시점의 첫 항목에만 설정 (e.g. "5/28 목")
    }

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
        let receiptNo = "NO. \(receiptFormatter.string(from: now))"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M/d E"
        let dateLabel = dateFormatter.string(from: now)

        // 다음 8시간 시간당 강수 확률
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "H"
        let startOfHour = Calendar.current.dateInterval(of: .hour, for: now)?.start ?? now
        let upcomingHours = summary.hourlyForecasts
            .filter { $0.date >= startOfHour }
            .prefix(8)

        let hourlyRain = upcomingHours.map { f in
            (hour: hourFormatter.string(from: f.date), pct: Int(f.precipitationChance * 100))
        }

        let peakHour = upcomingHours.max(by: { $0.precipitationChance < $1.precipitationChance })

        // 강수 시작 시각: 40% 이상이 처음 등장하는 시간 (피크가 아닌 시작 기준)
        let rainThreshold = 0.4
        let firstRain = upcomingHours.first { $0.precipitationChance >= rainThreshold }
        let isNowRaining = (upcomingHours.first?.precipitationChance ?? 0) >= rainThreshold
        let rainCondition: String
        let rainPeakLabel: String
        if let rain = firstRain {
            let h = hourFormatter.string(from: rain.date)
            rainCondition = isNowRaining ? "지금" : "\(h)시부터"
            rainPeakLabel = "\(h)시 \(Int(rain.precipitationChance * 100))%"
        } else {
            rainCondition = "강수 없음"
            rainPeakLabel = "강수 없음"
        }

        // 시간별 예보 (최대 24시간)
        let dayLabelFormatter = DateFormatter()
        dayLabelFormatter.locale = Locale(identifier: "ko_KR")
        dayLabelFormatter.dateFormat = "M/d E"

        let forecastSlots = Array(
            summary.hourlyForecasts
                .filter { $0.date >= startOfHour }
                .prefix(24)
        )
        let hourlyTimeline: [HourlyItem] = forecastSlots.enumerated().map { idx, forecast in
            let hour = Calendar.current.component(.hour, from: forecast.date)
            let isDaytime = (6...19).contains(hour)
            let prevDate = idx > 0 ? forecastSlots[idx - 1].date : nil
            let dayLabel: String? = prevDate.flatMap { prev in
                Calendar.current.isDate(forecast.date, inSameDayAs: prev)
                    ? nil
                    : dayLabelFormatter.string(from: forecast.date)
            }
            return HourlyItem(
                id: idx,
                hourLabel: "\(hourFormatter.string(from: forecast.date))시",
                temperature: Int(forecast.temperature.rounded()),
                precipitationPct: Int(forecast.precipitationChance * 100),
                icon: mapWeatherIcon(state: forecast.state, isDaytime: isDaytime),
                isNow: idx == 0,
                dayLabel: dayLabel
            )
        }

        // 오늘 최저·최고 기온
        let today = summary.dailyForecasts.first
        let todayLow  = today.map { Int($0.lowTemperature.rounded()) }
        let todayHigh = today.map { Int($0.highTemperature.rounded()) }

        // Outfit
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
            outfitChips: outfit.chips,
            todayLow: todayLow,
            todayHigh: todayHigh,
            hourlyTimeline: hourlyTimeline
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
            outfitLabel: "가디건",
            outfitSub: "14° → 22° · ☂ 우산 챙기기",
            outfitChips: [
                ("긴팔", false), ("가디건", false), ("☂ 우산", true)
            ],
            todayLow: 14,
            todayHigh: 22,
            hourlyTimeline: {
                let icons: [WeatherIcon] = [
                    .cloudRain, .cloudRain, .cloud, .cloudSun,
                    .sun, .sun, .cloudSun, .cloud,
                    .cloudRain, .cloudRain, .cloud, .cloudSun
                ]
                let temps   = [19, 20, 21, 22, 22, 21, 20, 19, 18, 17, 16, 16]
                let pcts    = [60, 55, 40, 20,  5,  0,  0,  5, 30, 45, 50, 40]
                let labels  = ["지금", "14시", "15시", "16시", "17시", "18시", "19시", "20시", "21시", "22시", "23시", "0시"]
                let dayLabels: [String?] = Array(repeating: nil, count: 11) + ["5/28 목"]
                return (0..<12).map { i in
                    HourlyItem(id: i, hourLabel: labels[i], temperature: temps[i],
                               precipitationPct: pcts[i], icon: icons[i],
                               isNow: i == 0, dayLabel: dayLabels[i])
                }
            }()
        )
    }
}

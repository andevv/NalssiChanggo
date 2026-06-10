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

    // MARK: Daily Forecast (7일)
    let dailyForecast: [DailyForecastItem]

    // MARK: Source Breakdown
    let sourceBreakdown: SourceBreakdownDisplayData?

    struct SourceBreakdownDisplayData {
        struct SourceCard: Identifiable {
            let id: String              // "apple", "kma", "owm"
            let initial: String         // "A", "K", "O"
            let name: String            // "Apple", "KMA 기상청", "OWM"
            let temperature: Int
            let conditionLabel: String
            let weatherIcon: WeatherIcon
            let weightBadge: String     // "× 1.0", "× 1.3"
            let deviationLabel: String  // "+0.7°", "-0.3°", "±0°"
            let deviationPositive: Bool
            let rawDeviation: Double
        }

        let ensembleTemp: Int
        let ensembleCondition: String
        let ensembleIcon: WeatherIcon
        let agreementPct: Int           // 0–100
        let agreementLabel: String      // "세 소스 일치" / "소스 의견 갈림"
        let avgAbsDeviationLabel: String // "Σ 0.8°"
        let tempRangeMin: Double
        let tempRangeMax: Double
        let sources: [SourceCard]
        let commentText: String
        let updatedLabel: String        // "09:41 KST"
    }

    struct DailyForecastItem: Identifiable {
        let id: Int
        let dayLabel: String        // "오늘", "월", "화", …
        let dateLabel: String       // "5/27" 형식
        let isToday: Bool
        let isSunday: Bool
        let lowTemp: Int
        let highTemp: Int
        let precipitationPct: Int   // 0–100
        let icon: WeatherIcon
    }

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
                temperature: idx == 0 ? Int(current.temperature.rounded()) : Int(forecast.temperature.rounded()),
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

        // 7일 예보
        let koDayFormatter = DateFormatter()
        koDayFormatter.locale = Locale(identifier: "ko_KR")
        koDayFormatter.dateFormat = "E"

        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "M/d"

        // 현재 시각 슬롯의 강수 확률 (hourlyForecasts 첫 번째 = "지금" 슬롯)
        let nowPrecipPct = Int((upcomingHours.first?.precipitationChance ?? 0) * 100)

        let dailyForecast: [DailyForecastItem] = summary.dailyForecasts.prefix(7).enumerated().map { idx, daily in
            let isToday = Calendar.current.isDate(daily.date, inSameDayAs: now)
            let dayLabel = isToday ? "오늘" : koDayFormatter.string(from: daily.date)
            let weekday = Calendar.current.component(.weekday, from: daily.date)

            // 오늘 행: 날씨 상태·강수 확률을 앙상블 현재 관측값으로 덮어씀 (영웅 카드와 동일한 소스)
            let icon = isToday
                ? mapWeatherIcon(state: current.state, isDaytime: current.isDaytime)
                : mapWeatherIcon(state: daily.state, isDaytime: true)
            let precipPct = isToday ? nowPrecipPct : Int(daily.precipitationChance * 100)

            // 현재 기온이 예보 최고를 초과하는 경우 실제 관측값을 오늘 최고로 반영
            let highTemp = isToday
                ? Int(max(daily.highTemperature, current.temperature).rounded())
                : Int(daily.highTemperature.rounded())

            return DailyForecastItem(
                id: idx,
                dayLabel: dayLabel,
                dateLabel: shortDateFormatter.string(from: daily.date),
                isToday: isToday,
                isSunday: weekday == 1,
                lowTemp: Int(daily.lowTemperature.rounded()),
                highTemp: highTemp,
                precipitationPct: precipPct,
                icon: icon
            )
        }

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

        // Source Breakdown
        let sourceBreakdown = summary.sourceBreakdown.map {
            makeSourceBreakdown($0, ensembleState: current.state, isDaytime: current.isDaytime)
        }

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
            hourlyTimeline: hourlyTimeline,
            dailyForecast: dailyForecast,
            sourceBreakdown: sourceBreakdown
        )
    }

    private static func makeSourceBreakdown(
        _ breakdown: SourceBreakdown,
        ensembleState: WeatherState,
        isDaytime: Bool
    ) -> SourceBreakdownDisplayData {
        let minWeight = min(
            breakdown.apple?.rawWeight ?? .greatestFiniteMagnitude,
            breakdown.kma?.rawWeight   ?? .greatestFiniteMagnitude,
            breakdown.owm?.rawWeight   ?? .greatestFiniteMagnitude
        )

        func weightBadge(_ w: Double) -> String {
            let ratio = minWeight > 0 ? w / minWeight : 1
            return String(format: "× %.1f", ratio)
        }

        func deviationLabel(_ dev: Double) -> String {
            if abs(dev) < 0.05 { return "±0°" }
            return dev > 0 ? String(format: "+%.1f°", dev) : String(format: "%.1f°", dev)
        }

        func card(id: String, initial: String, name: String, snap: SourceBreakdown.SourceSnapshot?) -> SourceBreakdownDisplayData.SourceCard? {
            guard let s = snap else { return nil }
            return SourceBreakdownDisplayData.SourceCard(
                id: id,
                initial: initial,
                name: name,
                temperature: Int(s.temperature.rounded()),
                conditionLabel: s.state.koreanLabel,
                weatherIcon: mapWeatherIcon(state: s.state, isDaytime: isDaytime),
                weightBadge: weightBadge(s.rawWeight),
                deviationLabel: deviationLabel(s.deviation),
                deviationPositive: s.deviation >= 0,
                rawDeviation: s.deviation
            )
        }

        let cards = [
            card(id: "apple", initial: "A", name: "Apple",     snap: breakdown.apple),
            card(id: "kma",   initial: "K", name: "KMA 기상청", snap: breakdown.kma),
            card(id: "owm",   initial: "O", name: "OWM",       snap: breakdown.owm),
        ].compactMap { $0 }

        // 온도 범위 (바 스케일링용)
        let allTemps = cards.map { Double($0.temperature) } + [breakdown.ensembleTemperature]
        let rangeMin = (allTemps.min() ?? breakdown.ensembleTemperature) - 1
        let rangeMax = (allTemps.max() ?? breakdown.ensembleTemperature) + 1

        let agreementPct = Int((breakdown.agreement * 100).rounded())
        let agreementLabel: String
        switch agreementPct {
        case 90...: agreementLabel = "세 소스 일치"
        case 70...: agreementLabel = "대체로 일치"
        case 50...: agreementLabel = "소스 의견 갈림"
        default:    agreementLabel = "소스 불일치"
        }

        let commentText: String
        switch agreementPct {
        case 90...: commentText = "세 군데 모두 비슷한 값이에요. 앙상블을 믿어도 좋겠어요 👌"
        case 70...: commentText = "소스 간 차이가 크지 않아요. KMA 가중치를 높여 보정했어요."
        case 50...: commentText = "소스 간 의견이 갈려요. 실제 날씨와 함께 참고해 주세요."
        default:    commentText = "소스 간 차이가 커요. 직접 날씨를 확인해 보시는 게 좋겠어요 ☁️"
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let updatedLabel = "\(timeFormatter.string(from: Date())) KST"

        let avgDevLabel = String(format: "Σ %.1f°", breakdown.avgAbsDeviation)

        return SourceBreakdownDisplayData(
            ensembleTemp: Int(breakdown.ensembleTemperature.rounded()),
            ensembleCondition: ensembleState.koreanLabel,
            ensembleIcon: mapWeatherIcon(state: ensembleState, isDaytime: isDaytime),
            agreementPct: agreementPct,
            agreementLabel: agreementLabel,
            avgAbsDeviationLabel: avgDevLabel,
            tempRangeMin: rangeMin,
            tempRangeMax: rangeMax,
            sources: cards,
            commentText: commentText,
            updatedLabel: updatedLabel
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
            }(),
            dailyForecast: [
                DailyForecastItem(id: 0, dayLabel: "오늘", dateLabel: "5/27", isToday: true,  isSunday: false, lowTemp: 14, highTemp: 22, precipitationPct: 60, icon: .cloudRain),
                DailyForecastItem(id: 1, dayLabel: "수",   dateLabel: "5/28", isToday: false, isSunday: false, lowTemp: 13, highTemp: 20, precipitationPct: 40, icon: .cloud),
                DailyForecastItem(id: 2, dayLabel: "목",   dateLabel: "5/29", isToday: false, isSunday: false, lowTemp: 12, highTemp: 21, precipitationPct: 20, icon: .cloudSun),
                DailyForecastItem(id: 3, dayLabel: "금",   dateLabel: "5/30", isToday: false, isSunday: false, lowTemp: 14, highTemp: 24, precipitationPct:  5, icon: .sun),
                DailyForecastItem(id: 4, dayLabel: "토",   dateLabel: "5/31", isToday: false, isSunday: false, lowTemp: 15, highTemp: 25, precipitationPct:  0, icon: .sun),
                DailyForecastItem(id: 5, dayLabel: "일",   dateLabel: "6/01", isToday: false, isSunday: true,  lowTemp: 13, highTemp: 23, precipitationPct: 35, icon: .cloud),
                DailyForecastItem(id: 6, dayLabel: "월",   dateLabel: "6/02", isToday: false, isSunday: false, lowTemp: 11, highTemp: 19, precipitationPct: 80, icon: .cloudHeavyRain),
            ],
            sourceBreakdown: SourceBreakdownDisplayData(
                ensembleTemp: 19,
                ensembleCondition: "구름 조금",
                ensembleIcon: .cloudSun,
                agreementPct: 92,
                agreementLabel: "세 소스 일치",
                avgAbsDeviationLabel: "Σ 0.6°",
                tempRangeMin: 17.0,
                tempRangeMax: 21.0,
                sources: [
                    SourceBreakdownDisplayData.SourceCard(
                        id: "apple", initial: "A", name: "Apple",
                        temperature: 18, conditionLabel: "대체로 맑음", weatherIcon: .cloudSun,
                        weightBadge: "× 1.0", deviationLabel: "-0.8°",
                        deviationPositive: false, rawDeviation: -0.8
                    ),
                    SourceBreakdownDisplayData.SourceCard(
                        id: "kma", initial: "K", name: "KMA 기상청",
                        temperature: 20, conditionLabel: "구름 조금", weatherIcon: .cloudSun,
                        weightBadge: "× 1.3", deviationLabel: "+0.7°",
                        deviationPositive: true, rawDeviation: 0.7
                    ),
                    SourceBreakdownDisplayData.SourceCard(
                        id: "owm", initial: "O", name: "OWM",
                        temperature: 19, conditionLabel: "맑음", weatherIcon: .sun,
                        weightBadge: "× 1.0", deviationLabel: "-0.3°",
                        deviationPositive: false, rawDeviation: -0.3
                    ),
                ],
                commentText: "세 군데 모두 비슷한 값이에요. 앙상블을 믿어도 좋겠어요 👌",
                updatedLabel: "09:41 KST"
            )
        )
    }
}

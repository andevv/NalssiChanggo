import WidgetKit
import WeatherDomain
import DesignSystem

/// 날씨 갱신 후 App Groups SharedUserDefaults에 위젯 스냅샷을 기록하고
/// WidgetKit에 타임라인 재로드를 요청한다.
///
/// Widget 타겟은 API를 직접 호출하지 않으며, 이 파일이 기록한 캐시만 읽는다.
enum WidgetDataWriter {

    static func write(summary: WeatherSummary, locationName: String) {
        let current = summary.current
        let daily = summary.dailyForecasts.first
        let icon = mapIcon(state: current.state, isDaytime: current.isDaytime)

        let snapshot = WidgetWeatherSnapshot(
            temperature: Int(current.temperature.rounded()),
            feelsLike: Int(current.feelsLike.rounded()),
            conditionLabel: current.state.koreanLabel,
            weatherIconRaw: icon.rawValue,
            precipitationChance: Int(((daily?.precipitationChance) ?? 0) * 100),
            todayLow: daily.map { Int($0.lowTemperature.rounded()) },
            todayHigh: daily.map { Int($0.highTemperature.rounded()) },
            locationName: locationName,
            updatedAt: Date()
        )

        guard
            let data = try? JSONEncoder().encode(snapshot),
            let defaults = UserDefaults(suiteName: WidgetWeatherSnapshot.appGroupID)
        else { return }

        defaults.set(data, forKey: WidgetWeatherSnapshot.sharedDefaultsKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "NalssiChanggoWidget")
    }

    private static func mapIcon(state: WeatherState, isDaytime: Bool) -> WeatherIcon {
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

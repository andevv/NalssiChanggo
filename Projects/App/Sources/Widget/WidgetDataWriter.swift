import WidgetKit
import WeatherDomain
import DesignSystem

/// 날씨 갱신 후 App Groups SharedUserDefaults에 위젯 스냅샷을 기록하고
/// WidgetKit에 타임라인 재로드를 요청한다.
/// Widget은 자체적으로 앙상블 fetch를 수행하며, 앱 실행 시에는 이 기록으로 즉시 갱신한다.
enum WidgetDataWriter {

    static func write(summary: WeatherSummary, locationName: String) {
        let current = summary.current
        let daily = summary.dailyForecasts.first
        let icon = mapIcon(state: current.state, isDaytime: current.isDaytime)

        let now = Date()
        let hourly: [HourlyWidgetSnapshot] = summary.hourlyForecasts
            .filter { $0.date > now }
            .prefix(11)
            .map { forecast in
                let isDaytime = {
                    let hour = Calendar.current.component(.hour, from: forecast.date)
                    return (6..<20).contains(hour)
                }()
                return HourlyWidgetSnapshot(
                    date: forecast.date,
                    temperature: Int(forecast.temperature.rounded()),
                    weatherIconRaw: mapIcon(state: forecast.state, isDaytime: isDaytime).rawValue,
                    precipitationChance: Int((forecast.precipitationChance * 100).rounded())
                )
            }

        let snapshot = WidgetWeatherSnapshot(
            temperature: Int(current.temperature.rounded()),
            feelsLike: Int(current.feelsLike.rounded()),
            conditionLabel: current.state.koreanLabel,
            weatherIconRaw: icon.rawValue,
            precipitationChance: Int(((daily?.precipitationChance) ?? 0) * 100),
            todayLow: daily.map { Int($0.lowTemperature.rounded()) },
            todayHigh: daily.map { Int($0.highTemperature.rounded()) },
            locationName: locationName,
            updatedAt: now,
            hourlyForecasts: hourly
        )

        guard
            let data = try? JSONEncoder().encode(snapshot),
            let defaults = UserDefaults(suiteName: WidgetWeatherSnapshot.appGroupID)
        else { return }

        defaults.set(data, forKey: WidgetWeatherSnapshot.sharedDefaultsKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "NalssiChanggoWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "LockScreenWeatherWidget")
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

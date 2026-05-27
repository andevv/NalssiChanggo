import Foundation
import WeatherDomain

/// Apple WeatherKit · KMA · OpenWeatherMap 3소스 앙상블 집계
/// - 기온·습도·풍속: 가중 평균 (사용 가능한 소스만 정규화)
/// - 강수확률: 가중 평균
/// - 날씨 상태: 가중 다수결, `.unknown` 투표 제외
/// - feelsLike: Apple → KMA → OWM 순 우선 (소스 배열 삽입 순서 기준)
/// - isDaytime: Apple → KMA → OWM 순 우선 (일출/일몰 기준)
/// - airQuality: 외부 주입 (AirKorea)
/// - 소스 장애: 정상 소스만 가중치 정규화하여 집계
public struct WeatherEnsembler {

    public let appleWeight: Double
    public let kmaWeight: Double
    public let owmWeight: Double

    private let tempStrategy: NumericEnsembleStrategy
    private let precipStrategy: NumericEnsembleStrategy
    private let stateStrategy: StateEnsembleStrategy

    public init(
        appleWeight: Double = 0.3,
        kmaWeight: Double = 0.4,
        owmWeight: Double = 0.3,
        tempStrategy: NumericEnsembleStrategy = WeightedAverageStrategy(),
        precipStrategy: NumericEnsembleStrategy = WeightedAverageStrategy(),
        stateStrategy: StateEnsembleStrategy = MajorityVoteStrategy()
    ) {
        self.appleWeight  = appleWeight
        self.kmaWeight    = kmaWeight
        self.owmWeight    = owmWeight
        self.tempStrategy = tempStrategy
        self.precipStrategy = precipStrategy
        self.stateStrategy  = stateStrategy
    }

    /// nil 소스는 제외하고 집계. 전부 nil이면 nil 반환.
    public func ensemble(
        apple: WeatherSummary?,
        kma: WeatherSummary?,
        owm: WeatherSummary? = nil
    ) -> WeatherSummary? {
        var sources: [(WeatherSummary, Double)] = []
        if let a = apple { sources.append((a, appleWeight)) }
        if let k = kma   { sources.append((k, kmaWeight)) }
        if let o = owm   { sources.append((o, owmWeight)) }

        switch sources.count {
        case 0: return nil
        case 1: return sources[0].0
        default: return mergeSources(sources)
        }
    }

    // MARK: - 내부 병합

    private func mergeSources(_ sources: [(WeatherSummary, Double)]) -> WeatherSummary {
        // Apple → OWM → KMA 순으로 feelsLike / isDaytime 기준 소스 선택
        let preferred = sources[0].0.current

        return WeatherSummary(
            current: mergeCurrentWeather(
                sources: sources.map { ($0.0.current, $0.1) },
                preferred: preferred
            ),
            hourlyForecasts: mergeHourly(sources: sources),
            dailyForecasts:  mergeDaily(sources: sources),
            airQuality: sources.compactMap { $0.0.airQuality }.first
        )
    }

    private func mergeCurrentWeather(
        sources: [(CurrentWeather, Double)],
        preferred: CurrentWeather
    ) -> CurrentWeather {
        CurrentWeather(
            temperature: tempStrategy.combine(sources.map { ($0.0.temperature, $0.1) }),
            feelsLike:   preferred.feelsLike,
            state:       stateStrategy.combine(sources.map { ($0.0.state, $0.1) }),
            isDaytime:   preferred.isDaytime,
            humidity:    tempStrategy.combine(sources.map { ($0.0.humidity, $0.1) }),
            windSpeed:   tempStrategy.combine(sources.map { ($0.0.windSpeed, $0.1) }),
            date:        preferred.date
        )
    }

    // 첫 번째 소스(Apple)의 시간 슬롯 기준으로 나머지 소스를 hour 단위 조인
    private func mergeHourly(sources: [(WeatherSummary, Double)]) -> [HourlyForecast] {
        guard let (primary, primaryWeight) = sources.first else { return [] }

        let otherByHour: [([Date: HourlyForecast], Double)] = sources.dropFirst().map { summary, weight in
            let dict = Dictionary(
                summary.hourlyForecasts.map { (truncToHour($0.date), $0) },
                uniquingKeysWith: { first, _ in first }
            )
            return (dict, weight)
        }

        return primary.hourlyForecasts.map { item in
            let key = truncToHour(item.date)
            var temps:   [(Double, Double)] = [(item.temperature, primaryWeight)]
            var precips: [(Double, Double)] = [(item.precipitationChance, primaryWeight)]
            var states:  [(WeatherState, Double)] = [(item.state, primaryWeight)]

            for (byHour, weight) in otherByHour {
                if let match = byHour[key] {
                    temps.append((match.temperature, weight))
                    precips.append((match.precipitationChance, weight))
                    states.append((match.state, weight))
                }
            }
            return HourlyForecast(
                date: item.date,
                temperature: tempStrategy.combine(temps),
                precipitationChance: precipStrategy.combine(precips),
                state: stateStrategy.combine(states)
            )
        }
    }

    // 첫 번째 소스(Apple)의 날짜 슬롯 기준으로 나머지 소스를 day 단위 조인
    private func mergeDaily(sources: [(WeatherSummary, Double)]) -> [DailyForecast] {
        guard let (primary, primaryWeight) = sources.first else { return [] }

        let otherByDay: [([Date: DailyForecast], Double)] = sources.dropFirst().map { summary, weight in
            let dict = Dictionary(
                summary.dailyForecasts.map { (truncToDay($0.date), $0) },
                uniquingKeysWith: { first, _ in first }
            )
            return (dict, weight)
        }

        return primary.dailyForecasts.map { item in
            let key = truncToDay(item.date)
            var lows:    [(Double, Double)] = [(item.lowTemperature, primaryWeight)]
            var highs:   [(Double, Double)] = [(item.highTemperature, primaryWeight)]
            var precips: [(Double, Double)] = [(item.precipitationChance, primaryWeight)]
            var states:  [(WeatherState, Double)] = [(item.state, primaryWeight)]

            for (byDay, weight) in otherByDay {
                if let match = byDay[key] {
                    lows.append((match.lowTemperature, weight))
                    highs.append((match.highTemperature, weight))
                    precips.append((match.precipitationChance, weight))
                    states.append((match.state, weight))
                }
            }
            return DailyForecast(
                date: item.date,
                lowTemperature: tempStrategy.combine(lows),
                highTemperature: tempStrategy.combine(highs),
                precipitationChance: precipStrategy.combine(precips),
                state: stateStrategy.combine(states)
            )
        }
    }

    // MARK: - 날짜 보조

    private static let kst = TimeZone(identifier: "Asia/Seoul")!

    private func truncToHour(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Self.kst
        return cal.dateInterval(of: .hour, for: date)!.start
    }

    private func truncToDay(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Self.kst
        return cal.startOfDay(for: date)
    }
}

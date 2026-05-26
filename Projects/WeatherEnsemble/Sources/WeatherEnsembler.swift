import Foundation
import WeatherDomain

/// Apple WeatherKit + 기상청 KMA 앙상블 집계
/// - 기온: 가중 평균 (KMA 0.6 : Apple 0.4)
/// - 강수확률: 가중 평균 (KMA 0.6 : Apple 0.4)
/// - 날씨 상태: 가중 다수결 (KMA 0.6 : Apple 0.4) — 동점 시 KMA 우선
/// - isDaytime: Apple WeatherKit (일출/일몰 기준으로 정확)
/// - feelsLike: Apple WeatherKit (KMA 미제공)
/// - airQuality: 외부에서 주입 (AirKorea)
/// - 소스 장애: 정상 소스 단독 사용
public struct WeatherEnsembler {

    public let appleWeight: Double
    public let kmaWeight: Double

    private let tempStrategy: NumericEnsembleStrategy
    private let precipStrategy: NumericEnsembleStrategy
    private let stateStrategy: StateEnsembleStrategy

    public init(
        appleWeight: Double = 0.4,
        kmaWeight: Double = 0.6,
        tempStrategy: NumericEnsembleStrategy = WeightedAverageStrategy(),
        precipStrategy: NumericEnsembleStrategy = WeightedAverageStrategy(),
        stateStrategy: StateEnsembleStrategy = MajorityVoteStrategy()
    ) {
        self.appleWeight    = appleWeight
        self.kmaWeight      = kmaWeight
        self.tempStrategy   = tempStrategy
        self.precipStrategy = precipStrategy
        self.stateStrategy  = stateStrategy
    }

    /// 양쪽 소스 중 nil인 쪽은 제외하고 집계. 둘 다 nil이면 nil 반환.
    public func ensemble(apple: WeatherSummary?, kma: WeatherSummary?) -> WeatherSummary? {
        switch (apple, kma) {
        case (let a?, let k?): return merge(apple: a, kma: k)
        case (let a?, nil):    return a
        case (nil, let k?):    return k
        case (nil, nil):       return nil
        }
    }

    // MARK: - 내부 병합

    private func merge(apple: WeatherSummary, kma: WeatherSummary) -> WeatherSummary {
        WeatherSummary(
            current: mergeCurrentWeather(apple: apple.current, kma: kma.current),
            hourlyForecasts: mergeHourly(apple: apple.hourlyForecasts, kma: kma.hourlyForecasts),
            dailyForecasts: mergeDaily(apple: apple.dailyForecasts, kma: kma.dailyForecasts),
            airQuality: apple.airQuality ?? kma.airQuality
        )
    }

    private func mergeCurrentWeather(apple: CurrentWeather, kma: CurrentWeather) -> CurrentWeather {
        let temperature = tempStrategy.combine([
            (apple.temperature, appleWeight),
            (kma.temperature,   kmaWeight)
        ])
        let humidity = tempStrategy.combine([
            (apple.humidity, appleWeight),
            (kma.humidity,   kmaWeight)
        ])
        let windSpeed = tempStrategy.combine([
            (apple.windSpeed, appleWeight),
            (kma.windSpeed,   kmaWeight)
        ])
        let state = stateStrategy.combine([
            (apple.state, appleWeight),
            (kma.state,   kmaWeight)
        ])
        return CurrentWeather(
            temperature: temperature,
            feelsLike: apple.feelsLike,   // KMA 미제공 → Apple
            state: state,
            isDaytime: apple.isDaytime,   // WeatherKit 일출/일몰 기준
            humidity: humidity,
            windSpeed: windSpeed,
            date: apple.date
        )
    }

    private func mergeHourly(apple: [HourlyForecast], kma: [HourlyForecast]) -> [HourlyForecast] {
        let kmaByHour = Dictionary(
            kma.map { (truncToHour($0.date), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return apple.map { appleItem in
            guard let kmaItem = kmaByHour[truncToHour(appleItem.date)] else {
                return appleItem
            }
            return HourlyForecast(
                date: appleItem.date,
                temperature: tempStrategy.combine([
                    (appleItem.temperature, appleWeight),
                    (kmaItem.temperature,   kmaWeight)
                ]),
                precipitationChance: precipStrategy.combine([
                    (appleItem.precipitationChance, appleWeight),
                    (kmaItem.precipitationChance,   kmaWeight)
                ]),
                state: stateStrategy.combine([
                    (appleItem.state, appleWeight),
                    (kmaItem.state,   kmaWeight)
                ])
            )
        }
    }

    private func mergeDaily(apple: [DailyForecast], kma: [DailyForecast]) -> [DailyForecast] {
        let kmaByDay = Dictionary(
            kma.map { (truncToDay($0.date), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return apple.map { appleItem in
            guard let kmaItem = kmaByDay[truncToDay(appleItem.date)] else {
                return appleItem
            }
            return DailyForecast(
                date: appleItem.date,
                lowTemperature: tempStrategy.combine([
                    (appleItem.lowTemperature, appleWeight),
                    (kmaItem.lowTemperature,   kmaWeight)
                ]),
                highTemperature: tempStrategy.combine([
                    (appleItem.highTemperature, appleWeight),
                    (kmaItem.highTemperature,   kmaWeight)
                ]),
                precipitationChance: precipStrategy.combine([
                    (appleItem.precipitationChance, appleWeight),
                    (kmaItem.precipitationChance,   kmaWeight)
                ]),
                state: stateStrategy.combine([
                    (appleItem.state, appleWeight),
                    (kmaItem.state,   kmaWeight)
                ])
            )
        }
    }

    // MARK: - 날짜 보조

    private static let kst: TimeZone = TimeZone(identifier: "Asia/Seoul")!

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

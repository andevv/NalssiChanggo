import Foundation

// MARK: - 시간별 스냅샷

/// 위젯 타임라인의 각 시간별 Entry에 사용되는 경량 예보 스냅샷.
public struct HourlyWidgetSnapshot: Codable, Sendable {
    public let date: Date
    public let temperature: Int
    public let weatherIconRaw: String    // WeatherIcon.rawValue
    public let precipitationChance: Int  // 0–100

    public init(
        date: Date,
        temperature: Int,
        weatherIconRaw: String,
        precipitationChance: Int
    ) {
        self.date                = date
        self.temperature         = temperature
        self.weatherIconRaw      = weatherIconRaw
        self.precipitationChance = precipitationChance
    }
}

// MARK: - 현재 날씨 스냅샷

/// App → Widget 데이터 공유용 Codable 스냅샷.
/// App Groups UserDefaults에 JSON으로 직렬화하여 저장한다.
public struct WidgetWeatherSnapshot: Codable, Sendable {

    public let temperature: Int
    public let feelsLike: Int
    public let conditionLabel: String
    public let weatherIconRaw: String    // WeatherIcon.rawValue
    public let precipitationChance: Int  // 0–100 (오늘 일일 강수확률)
    public let todayLow: Int?
    public let todayHigh: Int?
    public let locationName: String
    public let updatedAt: Date
    /// 현재 이후 최대 11개 — 위젯 Multi-Entry 타임라인 구성용
    public let hourlyForecasts: [HourlyWidgetSnapshot]

    public static let sharedDefaultsKey  = "widgetWeatherSnapshot"
    public static let appGroupID         = "group.com.andev.nalssichanggo"
    public static let staleThreshold: TimeInterval = 6 * 3600

    public var isStale: Bool {
        Date().timeIntervalSince(updatedAt) > WidgetWeatherSnapshot.staleThreshold
    }

    public init(
        temperature: Int,
        feelsLike: Int,
        conditionLabel: String,
        weatherIconRaw: String,
        precipitationChance: Int,
        todayLow: Int?,
        todayHigh: Int?,
        locationName: String,
        updatedAt: Date,
        hourlyForecasts: [HourlyWidgetSnapshot] = []
    ) {
        self.temperature         = temperature
        self.feelsLike           = feelsLike
        self.conditionLabel      = conditionLabel
        self.weatherIconRaw      = weatherIconRaw
        self.precipitationChance = precipitationChance
        self.todayLow            = todayLow
        self.todayHigh           = todayHigh
        self.locationName        = locationName
        self.updatedAt           = updatedAt
        self.hourlyForecasts     = hourlyForecasts
    }

    public static func load() -> WidgetWeatherSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data     = defaults.data(forKey: sharedDefaultsKey)
        else { return nil }
        return try? JSONDecoder().decode(WidgetWeatherSnapshot.self, from: data)
    }
}

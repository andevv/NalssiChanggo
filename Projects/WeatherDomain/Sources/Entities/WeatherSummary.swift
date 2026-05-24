public struct WeatherSummary: Sendable {
    public let current: CurrentWeather
    public let hourlyForecasts: [HourlyForecast]
    public let dailyForecasts: [DailyForecast]
    /// 위치에 따라 WeatherKit 미지원 지역에서 nil
    public let airQuality: AirQualityData?

    public init(
        current: CurrentWeather,
        hourlyForecasts: [HourlyForecast],
        dailyForecasts: [DailyForecast],
        airQuality: AirQualityData? = nil
    ) {
        self.current = current
        self.hourlyForecasts = hourlyForecasts
        self.dailyForecasts = dailyForecasts
        self.airQuality = airQuality
    }
}

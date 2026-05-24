public struct WeatherSummary: Sendable {
    public let current: CurrentWeather
    public let hourlyForecasts: [HourlyForecast]
    public let dailyForecasts: [DailyForecast]

    public init(
        current: CurrentWeather,
        hourlyForecasts: [HourlyForecast],
        dailyForecasts: [DailyForecast]
    ) {
        self.current = current
        self.hourlyForecasts = hourlyForecasts
        self.dailyForecasts = dailyForecasts
    }
}

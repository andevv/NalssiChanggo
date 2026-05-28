public struct WeatherSummary: Sendable {
    public let current: CurrentWeather
    public let hourlyForecasts: [HourlyForecast]
    public let dailyForecasts: [DailyForecast]
    /// 위치에 따라 WeatherKit 미지원 지역에서 nil
    public let airQuality: AirQualityData?
    /// 앙상블 소스별 원시 데이터 — 단일 소스 직접 반환 시에도 포함
    public let sourceBreakdown: SourceBreakdown?

    public init(
        current: CurrentWeather,
        hourlyForecasts: [HourlyForecast],
        dailyForecasts: [DailyForecast],
        airQuality: AirQualityData? = nil,
        sourceBreakdown: SourceBreakdown? = nil
    ) {
        self.current          = current
        self.hourlyForecasts  = hourlyForecasts
        self.dailyForecasts   = dailyForecasts
        self.airQuality       = airQuality
        self.sourceBreakdown  = sourceBreakdown
    }
}

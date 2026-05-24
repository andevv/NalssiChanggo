import Foundation

public struct HourlyForecast: Sendable {
    public let date: Date
    public let temperature: Double        // Celsius
    public let precipitationChance: Double // 0.0–1.0
    public let state: WeatherState

    public init(
        date: Date,
        temperature: Double,
        precipitationChance: Double,
        state: WeatherState
    ) {
        self.date = date
        self.temperature = temperature
        self.precipitationChance = precipitationChance
        self.state = state
    }
}

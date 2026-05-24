import Foundation

public struct DailyForecast: Sendable {
    public let date: Date
    public let lowTemperature: Double     // Celsius
    public let highTemperature: Double    // Celsius
    public let precipitationChance: Double // 0.0–1.0
    public let state: WeatherState

    public init(
        date: Date,
        lowTemperature: Double,
        highTemperature: Double,
        precipitationChance: Double,
        state: WeatherState
    ) {
        self.date = date
        self.lowTemperature = lowTemperature
        self.highTemperature = highTemperature
        self.precipitationChance = precipitationChance
        self.state = state
    }
}

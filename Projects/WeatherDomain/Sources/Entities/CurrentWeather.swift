import Foundation

public struct CurrentWeather: Sendable {
    public let temperature: Double        // Celsius
    public let feelsLike: Double          // Celsius
    public let state: WeatherState
    public let isDaytime: Bool
    public let humidity: Double           // 0.0–1.0
    public let windSpeed: Double          // km/h
    public let date: Date

    public init(
        temperature: Double,
        feelsLike: Double,
        state: WeatherState,
        isDaytime: Bool,
        humidity: Double,
        windSpeed: Double,
        date: Date
    ) {
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.state = state
        self.isDaytime = isDaytime
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.date = date
    }
}

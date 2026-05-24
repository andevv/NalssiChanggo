import WeatherDomain

public final class WeatherRepositoryImpl: WeatherRepositoryProtocol {

    private let dataSource = AppleWeatherDataSource()

    public init() {}

    public func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherSummary {
        try await dataSource.fetchWeather(latitude: latitude, longitude: longitude)
    }
}

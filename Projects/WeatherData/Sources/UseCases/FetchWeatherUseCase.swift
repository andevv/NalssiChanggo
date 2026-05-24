import WeatherDomain

public final class FetchWeatherUseCase: FetchWeatherUseCaseProtocol {

    private let repository: WeatherRepositoryProtocol

    public init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(latitude: Double, longitude: Double) async throws -> WeatherSummary {
        try await repository.fetchWeather(latitude: latitude, longitude: longitude)
    }
}

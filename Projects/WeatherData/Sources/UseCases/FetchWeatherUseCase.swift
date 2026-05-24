import Combine
import WeatherDomain

public final class FetchWeatherUseCase: FetchWeatherUseCaseProtocol {

    private let repository: WeatherRepositoryProtocol

    public init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        latitude: Double,
        longitude: Double,
        locationName: String
    ) -> AnyPublisher<WeatherSummary, Error> {
        repository.fetchWeather(latitude: latitude, longitude: longitude, locationName: locationName)
    }
}

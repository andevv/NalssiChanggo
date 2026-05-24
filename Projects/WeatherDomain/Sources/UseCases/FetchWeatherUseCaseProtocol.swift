import Combine

public protocol FetchWeatherUseCaseProtocol {
    func execute(latitude: Double, longitude: Double, locationName: String) -> AnyPublisher<WeatherSummary, Error>
}

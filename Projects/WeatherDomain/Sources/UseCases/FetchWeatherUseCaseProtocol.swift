import Combine

public protocol FetchWeatherUseCaseProtocol {
    func execute(latitude: Double, longitude: Double) -> AnyPublisher<WeatherSummary, Error>
}

import Combine

public protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherSummary, Error>
}

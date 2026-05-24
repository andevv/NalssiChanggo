import Combine

public protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: Double, longitude: Double, locationName: String) -> AnyPublisher<WeatherSummary, Error>
}

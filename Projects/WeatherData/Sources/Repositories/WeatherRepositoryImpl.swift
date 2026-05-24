import Combine
import WeatherDomain

public final class WeatherRepositoryImpl: WeatherRepositoryProtocol {

    private let dataSource = AppleWeatherDataSource()

    public init() {}

    public func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherSummary, Error> {
        dataSource.fetchWeather(latitude: latitude, longitude: longitude)
    }
}

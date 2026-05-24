import Combine
import WeatherDomain

public final class WeatherRepositoryImpl: WeatherRepositoryProtocol {

    private let appleDataSource = AppleWeatherDataSource()
    private let airKoreaDataSource: AirKoreaDataSource

    public init(airKoreaAPIKey: String) {
        airKoreaDataSource = AirKoreaDataSource(apiKey: airKoreaAPIKey)
    }

    public func fetchWeather(
        latitude: Double,
        longitude: Double,
        locationName: String
    ) -> AnyPublisher<WeatherSummary, Error> {
        let sidoName = AirKoreaDataSource.sidoName(from: locationName)

        let weatherPublisher = appleDataSource.fetchWeather(latitude: latitude, longitude: longitude)

        // 대기질 실패해도 날씨 데이터는 반환
        let airPublisher: AnyPublisher<AirQualityData?, Error> = airKoreaDataSource
            .fetchAirQuality(sidoName: sidoName)
            .map { Optional($0) }
            .replaceError(with: nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        return weatherPublisher
            .combineLatest(airPublisher) { summary, airQuality in
                WeatherSummary(
                    current: summary.current,
                    hourlyForecasts: summary.hourlyForecasts,
                    dailyForecasts: summary.dailyForecasts,
                    airQuality: airQuality
                )
            }
            .eraseToAnyPublisher()
    }
}

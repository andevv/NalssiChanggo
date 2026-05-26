import Foundation
import Combine
import WeatherDomain
import WeatherEnsemble
import Core

public final class WeatherRepositoryImpl: WeatherRepositoryProtocol {

    private let appleDataSource = AppleWeatherDataSource()
    private let airKoreaDataSource: AirKoreaDataSource
    private let kmaDataSource: KMAWeatherDataSource
    private let ensembler = WeatherEnsembler()

    public init(airKoreaAPIKey: String, kmaAPIKey: String) {
        airKoreaDataSource = AirKoreaDataSource(apiKey: airKoreaAPIKey)
        kmaDataSource = KMAWeatherDataSource(apiKey: kmaAPIKey)
    }

    public func fetchWeather(
        latitude: Double,
        longitude: Double,
        locationName: String
    ) -> AnyPublisher<WeatherSummary, Error> {
        let sidoName = AirKoreaDataSource.sidoName(from: locationName)

        // 소스 실패 시 nil로 처리해 앙상블에서 제외
        let applePublisher: AnyPublisher<WeatherSummary?, Error> = appleDataSource
            .fetchWeather(latitude: latitude, longitude: longitude)
            .map(Optional.init)
            .handleEvents(receiveCompletion: {
                if case .failure(let e) = $0 {
                    NCLogger.error("Apple WeatherKit 실패: \(e.localizedDescription)", category: .weather)
                }
            })
            .replaceError(with: nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let kmaPublisher: AnyPublisher<WeatherSummary?, Error> = kmaDataSource
            .fetchWeather(latitude: latitude, longitude: longitude)
            .map(Optional.init)
            .handleEvents(receiveCompletion: {
                if case .failure(let e) = $0 {
                    NCLogger.error("KMA 실패: \(e.localizedDescription)", category: .weather)
                }
            })
            .replaceError(with: nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let airPublisher: AnyPublisher<AirQualityData?, Error> = airKoreaDataSource
            .fetchAirQuality(sidoName: sidoName)
            .map(Optional.init)
            .replaceError(with: nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        return applePublisher
            .combineLatest(kmaPublisher, airPublisher)
            .tryMap { [ensembler] apple, kma, airQuality in
                guard var summary = ensembler.ensemble(apple: apple, kma: kma) else {
                    NCLogger.error("Apple·KMA 모두 실패 — 날씨 데이터 없음", category: .weather)
                    throw URLError(.cannotLoadFromNetwork)
                }
                NCLogger.info(
                    "앙상블 완료 — 기온: \(String(format: "%.1f", summary.current.temperature))°C " +
                    "상태: \(summary.current.state.koreanLabel) " +
                    "시간별: \(summary.hourlyForecasts.count)개 일별: \(summary.dailyForecasts.count)개",
                    category: .weather
                )
                // 대기질 주입
                summary = WeatherSummary(
                    current: summary.current,
                    hourlyForecasts: summary.hourlyForecasts,
                    dailyForecasts: summary.dailyForecasts,
                    airQuality: airQuality
                )
                return summary
            }
            .eraseToAnyPublisher()
    }
}

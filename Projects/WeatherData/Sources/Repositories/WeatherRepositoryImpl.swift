import Foundation
import Combine
import WeatherDomain
import WeatherEnsemble
import Core

public final class WeatherRepositoryImpl: WeatherRepositoryProtocol {

    private let appleDataSource = AppleWeatherDataSource()
    /// nil이면 대기질 API를 호출하지 않는다 (위젯 등 대기질 불필요 컨텍스트)
    private let airKoreaDataSource: AirKoreaDataSource?
    private let kmaDataSource: KMAWeatherDataSource
    private let owmDataSource: OpenWeatherMapDataSource
    private let ensembler = WeatherEnsembler()

    public init(airKoreaAPIKey: String?, kmaAPIKey: String, owmAPIKey: String) {
        airKoreaDataSource = airKoreaAPIKey.map { AirKoreaDataSource(apiKey: $0) }
        kmaDataSource      = KMAWeatherDataSource(apiKey: kmaAPIKey)
        owmDataSource      = OpenWeatherMapDataSource(apiKey: owmAPIKey)
    }

    public func fetchWeather(
        latitude: Double,
        longitude: Double,
        locationName: String
    ) -> AnyPublisher<WeatherSummary, Error> {
        let sidoName = AirKoreaDataSource.sidoName(from: locationName)

        let applePublisher: AnyPublisher<WeatherSummary?, Error> = appleDataSource
            .fetchWeather(latitude: latitude, longitude: longitude)
            .map(Optional.init)
            .handleEvents(receiveCompletion: {
                if case .failure(let e) = $0 {
                    NCLogger.warning("Apple WeatherKit 소스 실패 (앙상블 제외): \(e.localizedDescription)", category: .weather)
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
                    NCLogger.warning("KMA 소스 실패 (앙상블 제외): \(e.localizedDescription)", category: .weather)
                }
            })
            .replaceError(with: nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let owmPublisher: AnyPublisher<WeatherSummary?, Error> = owmDataSource
            .fetchWeather(latitude: latitude, longitude: longitude)
            .map(Optional.init)
            .handleEvents(receiveCompletion: {
                if case .failure(let e) = $0 {
                    NCLogger.warning("OWM 소스 실패 (앙상블 제외): \(e.localizedDescription)", category: .weather)
                }
            })
            .replaceError(with: nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let airPublisher: AnyPublisher<AirQualityData?, Error> = {
            guard let ds = airKoreaDataSource else {
                return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            return ds.fetchAirQuality(sidoName: sidoName)
                .map(Optional.init)
                .replaceError(with: nil)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }()

        return applePublisher
            .combineLatest(kmaPublisher, owmPublisher, airPublisher)
            .tryMap { [ensembler] apple, kma, owm, airQuality in
                guard var summary = ensembler.ensemble(apple: apple, kma: kma, owm: owm) else {
                    NCLogger.error("Apple·KMA·OWM 모두 실패 — 날씨 데이터 없음", category: .weather)
                    throw URLError(.cannotLoadFromNetwork)
                }
                NCLogger.info(
                    "앙상블 완료 — 기온: \(String(format: "%.1f", summary.current.temperature))°C " +
                    "상태: \(summary.current.state.koreanLabel) " +
                    "시간별: \(summary.hourlyForecasts.count)개 일별: \(summary.dailyForecasts.count)개",
                    category: .weather
                )
                summary = WeatherSummary(
                    current: summary.current,
                    hourlyForecasts: summary.hourlyForecasts,
                    dailyForecasts: summary.dailyForecasts,
                    airQuality: airQuality,
                    sourceBreakdown: summary.sourceBreakdown
                )
                return summary
            }
            .eraseToAnyPublisher()
    }
}

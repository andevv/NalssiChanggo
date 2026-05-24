import WeatherKit
import CoreLocation
import Combine
import WeatherDomain

final class AppleWeatherDataSource {

    private let service = WeatherService.shared

    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherSummary, Error> {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return Future { [service] promise in
            Task {
                do {
                    let (current, hourly, daily) = try await service.weather(
                        for: location,
                        including: .current, .hourly, .daily
                    )
                    let summary = WeatherSummary(
                        current: Self.mapCurrent(current),
                        hourlyForecasts: hourly.forecast.prefix(24).map(Self.mapHourly),
                        dailyForecasts: daily.forecast.prefix(7).map(Self.mapDaily)
                    )
                    promise(.success(summary))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Mappers

    private static func mapCurrent(_ wk: WeatherKit.CurrentWeather) -> WeatherDomain.CurrentWeather {
        WeatherDomain.CurrentWeather(
            temperature: wk.temperature.converted(to: .celsius).value,
            feelsLike: wk.apparentTemperature.converted(to: .celsius).value,
            state: mapCondition(wk.condition, isDaytime: wk.isDaylight),
            isDaytime: wk.isDaylight,
            humidity: wk.humidity,
            windSpeed: wk.wind.speed.converted(to: .kilometersPerHour).value,
            date: wk.date
        )
    }

    private static func mapHourly(_ wk: HourWeather) -> WeatherDomain.HourlyForecast {
        WeatherDomain.HourlyForecast(
            date: wk.date,
            temperature: wk.temperature.converted(to: .celsius).value,
            precipitationChance: wk.precipitationChance,
            state: mapCondition(wk.condition, isDaytime: true)
        )
    }

    private static func mapDaily(_ wk: DayWeather) -> WeatherDomain.DailyForecast {
        WeatherDomain.DailyForecast(
            date: wk.date,
            lowTemperature: wk.lowTemperature.converted(to: .celsius).value,
            highTemperature: wk.highTemperature.converted(to: .celsius).value,
            precipitationChance: wk.precipitationChance,
            state: mapCondition(wk.condition, isDaytime: true)
        )
    }

    private static func mapCondition(
        _ condition: WeatherKit.WeatherCondition,
        isDaytime: Bool
    ) -> WeatherDomain.WeatherState {
        switch condition {
        case .clear, .mostlyClear:                          return .clear
        case .partlyCloudy, .sunFlurries, .sunShowers:      return .partlyCloudy
        case .mostlyCloudy:                                 return .mostlyCloudy
        case .cloudy:                                       return .cloudy
        case .drizzle, .freezingDrizzle:                    return .drizzle
        case .rain, .scatteredThunderstorms:                return .rain
        case .heavyRain:                                    return .heavyRain
        case .isolatedThunderstorms, .thunderstorms, .strongStorms: return .thunderstorm
        case .snow, .flurries, .blowingSnow:                return .snow
        case .heavySnow:                                    return .heavySnow
        case .sleet, .freezingRain, .hail:                  return .sleet
        case .foggy:                                        return .fog
        case .haze, .smoky, .blowingDust:                   return .haze
        case .breezy, .windy:                               return .windy
        case .hot:                                          return .hot
        case .frigid:                                       return .frigid
        case .blizzard:                                     return .blizzard
        case .hurricane, .tropicalStorm:                    return .thunderstorm
        default:                                            return .unknown
        }
    }
}

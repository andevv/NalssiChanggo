import Foundation
import Combine
import WeatherDomain
import Core

final class OpenWeatherMapDataSource {

    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherSummary, Error> {
        let current  = fetchCurrentWeather(latitude: latitude, longitude: longitude)
        let forecast = fetchForecast(latitude: latitude, longitude: longitude)

        return current
            .combineLatest(forecast)
            .map { current, forecastResult in
                WeatherSummary(
                    current: current,
                    hourlyForecasts: forecastResult.hourly,
                    dailyForecasts: forecastResult.daily,
                    airQuality: nil
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - 현재 날씨

    private func fetchCurrentWeather(latitude: Double, longitude: Double) -> AnyPublisher<CurrentWeather, Error> {
        guard let url = buildURL(path: "weather", latitude: latitude, longitude: longitude) else {
            NCLogger.error("OWM 현재날씨 URL 생성 실패", category: .weather)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        NCLogger.request(url: url, category: .weather)

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                NCLogger.response(statusCode: code, body: data, category: .weather)
                guard code == 200 else { throw URLError(.badServerResponse) }
                return data
            }
            .decode(type: OWMCurrentWeatherDTO.self, decoder: JSONDecoder())
            .tryMap { dto -> CurrentWeather in
                guard let condition = dto.weather.first else {
                    throw URLError(.cannotParseResponse)
                }
                let isDaytime = Self.isDaytime(
                    dt: dto.dt,
                    sunrise: dto.sys?.sunrise,
                    sunset: dto.sys?.sunset
                )
                NCLogger.info(
                    "OWM 현재날씨: \(dto.main.temp)°C 상태=\(condition.id) 낮=\(isDaytime)",
                    category: .weather
                )
                return CurrentWeather(
                    temperature: dto.main.temp,
                    feelsLike: dto.main.feelsLike,
                    state: Self.mapCondition(condition.id),
                    isDaytime: isDaytime,
                    humidity: dto.main.humidity / 100.0,
                    windSpeed: dto.wind.speed * 3.6,   // m/s → km/h
                    date: Date(timeIntervalSince1970: dto.dt)
                )
            }
            .handleEvents(receiveCompletion: {
                if case .failure(let e) = $0 {
                    NCLogger.error("OWM 현재날씨 실패: \(e.localizedDescription)", category: .weather)
                }
            })
            .eraseToAnyPublisher()
    }

    // MARK: - 5일 3시간 예보

    private func fetchForecast(
        latitude: Double,
        longitude: Double
    ) -> AnyPublisher<(hourly: [HourlyForecast], daily: [DailyForecast]), Error> {
        guard let url = buildURL(
            path: "forecast",
            latitude: latitude,
            longitude: longitude,
            extra: ["cnt": "40"]
        ) else {
            NCLogger.error("OWM 예보 URL 생성 실패", category: .weather)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        NCLogger.request(url: url, category: .weather)

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                NCLogger.response(statusCode: code, body: data, category: .weather)
                guard code == 200 else { throw URLError(.badServerResponse) }
                return data
            }
            .decode(type: OWMForecastDTO.self, decoder: JSONDecoder())
            .map { dto in Self.mapToForecasts(items: dto.list) }
            .handleEvents(receiveCompletion: {
                if case .failure(let e) = $0 {
                    NCLogger.error("OWM 예보 실패: \(e.localizedDescription)", category: .weather)
                }
            })
            .eraseToAnyPublisher()
    }

    // MARK: - URL 빌더

    private func buildURL(
        path: String,
        latitude: Double,
        longitude: Double,
        extra: [String: String] = [:]
    ) -> URL? {
        var components = URLComponents(string: "\(baseURL)/\(path)")
        var items = [
            URLQueryItem(name: "lat",   value: "\(latitude)"),
            URLQueryItem(name: "lon",   value: "\(longitude)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
        ]
        for (key, value) in extra {
            items.append(URLQueryItem(name: key, value: value))
        }
        components?.queryItems = items
        return components?.url
    }

    // MARK: - 예보 매핑

    private static func mapToForecasts(
        items: [OWMForecastItem]
    ) -> (hourly: [HourlyForecast], daily: [DailyForecast]) {
        let kst = TimeZone(identifier: "Asia/Seoul")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst

        let now = Date()
        let dayFmt = DateFormatter()
        dayFmt.timeZone = kst
        dayFmt.dateFormat = "yyyyMMdd"

        var hourlyForecasts: [HourlyForecast] = []
        var dailyAgg: [String: OWMDailyAgg] = [:]

        for item in items {
            let date = Date(timeIntervalSince1970: item.dt)
            let dayKey = dayFmt.string(from: date)
            let condition = item.weather.first.map { mapCondition($0.id) } ?? .unknown
            let pop = item.pop ?? 0.0

            // 일별 집계
            var agg = dailyAgg[dayKey] ?? OWMDailyAgg()
            agg.tmx = max(agg.tmx, item.main.tempMax)
            agg.tmn = min(agg.tmn, item.main.tempMin)
            agg.maxPop = max(agg.maxPop, pop)
            if condition != .unknown { agg.states.append(condition) }
            dailyAgg[dayKey] = agg

            // 시간별 (현재 ~ 24시간)
            guard date >= now && date <= now.addingTimeInterval(24 * 3600) else { continue }
            hourlyForecasts.append(HourlyForecast(
                date: date,
                temperature: item.main.temp,
                precipitationChance: pop,
                state: condition
            ))
        }

        let dailyForecasts: [DailyForecast] = dailyAgg.keys.sorted().compactMap { dayKey in
            guard let date = dayFmt.date(from: dayKey) else { return nil }
            let agg = dailyAgg[dayKey]!
            guard agg.tmx > -OWMDailyAgg.sentinel else { return nil }
            return DailyForecast(
                date: date,
                lowTemperature: agg.tmn < OWMDailyAgg.sentinel ? agg.tmn : 0.0,
                highTemperature: agg.tmx,
                precipitationChance: agg.maxPop,
                state: agg.states.mostFrequent() ?? .unknown
            )
        }

        NCLogger.info(
            "OWM 시간별 \(hourlyForecasts.count)개 / 일별 \(dailyForecasts.count)개 파싱",
            category: .weather
        )
        return (hourly: hourlyForecasts, daily: dailyForecasts)
    }

    // MARK: - 날씨 상태 변환 (OWM condition code)

    private static func mapCondition(_ id: Int) -> WeatherState {
        switch id {
        case 200...232:             return .thunderstorm
        case 300...321:             return .drizzle
        case 500...501:             return .rain
        case 502...504:             return .heavyRain
        case 511:                   return .sleet
        case 520...521, 531:        return .rain
        case 522:                   return .heavyRain
        case 600...601:             return .snow
        case 602:                   return .heavySnow
        case 611...616:             return .sleet
        case 620...621:             return .snow
        case 622:                   return .heavySnow
        case 701, 741:              return .fog
        case 711, 721, 731,
             751, 761, 762:         return .haze
        case 771, 781:              return .windy
        case 800:                   return .clear
        case 801:                   return .mostlyClear
        case 802:                   return .partlyCloudy
        case 803:                   return .mostlyCloudy
        case 804:                   return .cloudy
        default:                    return .unknown
        }
    }

    // MARK: - 일출/일몰 기반 isDaytime

    private static func isDaytime(dt: TimeInterval, sunrise: TimeInterval?, sunset: TimeInterval?) -> Bool {
        if let rise = sunrise, let set = sunset {
            return dt >= rise && dt < set
        }
        let hour = Calendar.current.component(.hour, from: Date(timeIntervalSince1970: dt))
        return hour >= 6 && hour < 20
    }
}

// MARK: - 일별 집계용 내부 구조체

private struct OWMDailyAgg {
    static let sentinel: Double = 999.0
    var tmx: Double = -sentinel
    var tmn: Double = sentinel
    var maxPop: Double = 0.0
    var states: [WeatherState] = []
}

private extension Array where Element: Hashable {
    func mostFrequent() -> Element? {
        var counts: [Element: Int] = [:]
        for e in self { counts[e, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

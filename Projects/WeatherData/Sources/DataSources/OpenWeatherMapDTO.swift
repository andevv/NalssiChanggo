import Foundation

// MARK: - 현재 날씨 (GET /data/2.5/weather)

struct OWMCurrentWeatherDTO: Decodable {
    let dt: TimeInterval
    let main: OWMMain
    let wind: OWMWind
    let weather: [OWMWeatherCondition]
    let sys: OWMSys?
}

struct OWMMain: Decodable {
    let temp: Double
    let feelsLike: Double
    let humidity: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
    }
}

struct OWMSys: Decodable {
    let sunrise: TimeInterval?
    let sunset: TimeInterval?
}

// MARK: - 5일 3시간 예보 (GET /data/2.5/forecast)

struct OWMForecastDTO: Decodable {
    let list: [OWMForecastItem]
}

struct OWMForecastItem: Decodable {
    let dt: TimeInterval
    let main: OWMForecastMain
    let wind: OWMWind
    let weather: [OWMWeatherCondition]
    /// 강수확률 0.0–1.0
    let pop: Double?
}

struct OWMForecastMain: Decodable {
    let temp: Double
    let tempMin: Double
    let tempMax: Double
    let humidity: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case humidity
    }
}

// MARK: - 공통 타입

struct OWMWind: Decodable {
    /// m/s (units=metric)
    let speed: Double
}

struct OWMWeatherCondition: Decodable {
    let id: Int
    let main: String
}

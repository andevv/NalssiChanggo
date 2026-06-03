import Foundation
import Combine
import WeatherDomain
import Core

final class KMAWeatherDataSource {

    private let apiKey: String
    private let baseURL = "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0"

    init(apiKey: String) {
        self.apiKey = apiKey.removingPercentEncoding ?? apiKey
    }

    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherSummary, Error> {
        let grid = LambertConverter.convert(latitude: latitude, longitude: longitude)
        NCLogger.info("격자 변환: (\(latitude), \(longitude)) → nx=\(grid.nx), ny=\(grid.ny)", category: .weather)

        return fetchCurrentWeather(nx: grid.nx, ny: grid.ny)
            .combineLatest(fetchForecast(nx: grid.nx, ny: grid.ny))
            .map { current, forecast in
                // 초단기실황은 SKY 카테고리를 제공하지 않아 강수 없을 때 state가 .unknown이 됨.
                // 단기예보의 현재 시각 슬롯 state로 보완한다.
                let resolvedState: WeatherState
                if current.state == .unknown, let nearest = forecast.hourly.first {
                    resolvedState = nearest.state
                } else {
                    resolvedState = current.state
                }
                let patchedCurrent = CurrentWeather(
                    temperature: current.temperature,
                    feelsLike:   current.feelsLike,
                    state:       resolvedState,
                    isDaytime:   current.isDaytime,
                    humidity:    current.humidity,
                    windSpeed:   current.windSpeed,
                    date:        current.date
                )
                return WeatherSummary(
                    current: patchedCurrent,
                    hourlyForecasts: forecast.hourly,
                    dailyForecasts: forecast.daily,
                    airQuality: nil
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - 초단기실황 (getUltraSrtNcst)

    private func fetchCurrentWeather(nx: Int, ny: Int) -> AnyPublisher<CurrentWeather, Error> {
        guard let url = buildNowcastURL(nx: nx, ny: ny) else {
            NCLogger.error("초단기실황 URL 생성 실패 nx=\(nx) ny=\(ny)", category: .weather)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        NCLogger.request(url: url, category: .weather)

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                NCLogger.response(statusCode: statusCode, body: data, category: .weather)
                if statusCode == 429 {
                    NCLogger.warning("KMA API 호출 한도 초과 (429) — 앙상블에서 제외", category: .weather)
                    throw URLError(.badServerResponse)
                }
                guard statusCode == 200 else {
                    NCLogger.warning("KMA 초단기실황 HTTP \(statusCode)", category: .weather)
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: KMAResponse<KMANowcastItem>.self, decoder: JSONDecoder())
            .tryMap { response -> CurrentWeather in
                let header = response.response.header
                guard header.resultCode == "00" else {
                    NCLogger.warning("초단기실황 오류 \(header.resultCode): \(header.resultMsg)", category: .weather)
                    throw URLError(.cannotParseResponse)
                }
                let items = response.response.body.items.item
                NCLogger.info("초단기실황 \(items.count)개 수신", category: .weather)
                return try Self.mapToCurrentWeather(items: items)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - 단기예보 (getVilageFcst)

    private func fetchForecast(nx: Int, ny: Int) -> AnyPublisher<(hourly: [HourlyForecast], daily: [DailyForecast]), Error> {
        guard let url = buildForecastURL(nx: nx, ny: ny) else {
            NCLogger.error("단기예보 URL 생성 실패 nx=\(nx) ny=\(ny)", category: .weather)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        NCLogger.request(url: url, category: .weather)

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                NCLogger.response(statusCode: statusCode, body: data, category: .weather)
                if statusCode == 429 {
                    NCLogger.warning("KMA API 호출 한도 초과 (429) — 앙상블에서 제외", category: .weather)
                    throw URLError(.badServerResponse)
                }
                guard statusCode == 200 else {
                    NCLogger.warning("KMA 단기예보 HTTP \(statusCode)", category: .weather)
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: KMAResponse<KMAForecastItem>.self, decoder: JSONDecoder())
            .tryMap { response -> (hourly: [HourlyForecast], daily: [DailyForecast]) in
                let header = response.response.header
                guard header.resultCode == "00" else {
                    NCLogger.warning("단기예보 오류 \(header.resultCode): \(header.resultMsg)", category: .weather)
                    throw URLError(.cannotParseResponse)
                }
                let items = response.response.body.items.item
                NCLogger.info("단기예보 \(items.count)개 수신", category: .weather)
                return try Self.mapToForecasts(items: items)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - URL 빌더

    private func buildNowcastURL(nx: Int, ny: Int) -> URL? {
        let (date, time) = latestNowcastBase()
        NCLogger.debug("초단기실황 기준시각: \(date) \(time)", category: .weather)
        var components = URLComponents(string: "\(baseURL)/getUltraSrtNcst")
        components?.percentEncodedQueryItems = [
            URLQueryItem(name: "serviceKey", value: encode(apiKey)),
            URLQueryItem(name: "pageNo",     value: "1"),
            URLQueryItem(name: "numOfRows",  value: "10"),
            URLQueryItem(name: "dataType",   value: "JSON"),
            URLQueryItem(name: "base_date",  value: date),
            URLQueryItem(name: "base_time",  value: time),
            URLQueryItem(name: "nx",         value: "\(nx)"),
            URLQueryItem(name: "ny",         value: "\(ny)"),
        ]
        return components?.url
    }

    private func buildForecastURL(nx: Int, ny: Int) -> URL? {
        let (date, time) = latestVilageFcstBase()
        NCLogger.debug("단기예보 기준시각: \(date) \(time)", category: .weather)
        var components = URLComponents(string: "\(baseURL)/getVilageFcst")
        components?.percentEncodedQueryItems = [
            URLQueryItem(name: "serviceKey", value: encode(apiKey)),
            URLQueryItem(name: "pageNo",     value: "1"),
            URLQueryItem(name: "numOfRows",  value: "1000"),
            URLQueryItem(name: "dataType",   value: "JSON"),
            URLQueryItem(name: "base_date",  value: date),
            URLQueryItem(name: "base_time",  value: time),
            URLQueryItem(name: "nx",         value: "\(nx)"),
            URLQueryItem(name: "ny",         value: "\(ny)"),
        ]
        return components?.url
    }

    private func encode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?#")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    // MARK: - 기준 시각 계산

    /// 초단기실황: 매 시간 40분 발표, 30분 여유 적용
    private func latestNowcastBase() -> (date: String, time: String) {
        let kst = TimeZone(identifier: "Asia/Seoul")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst
        let safeDate = Date().addingTimeInterval(-30 * 60)
        let hour = cal.component(.hour, from: safeDate)
        let fmt = DateFormatter()
        fmt.timeZone = kst
        fmt.dateFormat = "yyyyMMdd"
        return (date: fmt.string(from: safeDate), time: String(format: "%02d00", hour))
    }

    /// 단기예보 발표 시각: 02·05·08·11·14·17·20·23시, 10분 이후 사용 가능
    private func latestVilageFcstBase() -> (date: String, time: String) {
        let kst = TimeZone(identifier: "Asia/Seoul")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst
        let now = Date()
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let totalMin = hour * 60 + minute

        let baseTimes = [2, 5, 8, 11, 14, 17, 20, 23]
        var selectedHour = 23
        var dayOffset = -1
        for bt in baseTimes.reversed() where totalMin >= bt * 60 + 10 {
            selectedHour = bt
            dayOffset = 0
            break
        }

        let fmt = DateFormatter()
        fmt.timeZone = kst
        fmt.dateFormat = "yyyyMMdd"
        let baseDate = cal.date(byAdding: .day, value: dayOffset, to: now)!
        return (date: fmt.string(from: baseDate), time: String(format: "%02d00", selectedHour))
    }

    // MARK: - 데이터 매핑

    private static func mapToCurrentWeather(items: [KMANowcastItem]) throws -> CurrentWeather {
        var values: [String: String] = [:]
        for item in items { values[item.category] = item.obsrValue }

        guard let tempStr = values["T1H"], let temp = Double(tempStr) else {
            throw URLError(.cannotParseResponse)
        }
        let pty = Int(values["PTY"] ?? "0") ?? 0
        let wsdMs = Double(values["WSD"] ?? "0") ?? 0.0
        let reh = Double(values["REH"] ?? "0") ?? 0.0

        NCLogger.info("초단기실황 매핑: T1H=\(temp)°C PTY=\(pty) WSD=\(wsdMs)m/s REH=\(reh)%", category: .weather)

        return CurrentWeather(
            temperature: temp,
            feelsLike: temp,
            state: weatherState(sky: nil, pty: pty),
            isDaytime: isDaytime(),
            humidity: reh / 100.0,
            windSpeed: wsdMs * 3.6,  // m/s → km/h
            date: Date()
        )
    }

    private static func mapToForecasts(
        items: [KMAForecastItem]
    ) throws -> (hourly: [HourlyForecast], daily: [DailyForecast]) {
        // (fcstDate+fcstTime) 별 카테고리 맵
        var slotMap: [String: [String: String]] = [:]
        for item in items {
            let key = item.fcstDate + item.fcstTime
            slotMap[key, default: [:]][item.category] = item.fcstValue
        }

        let kst = TimeZone(identifier: "Asia/Seoul")!
        let slotFmt = DateFormatter()
        slotFmt.timeZone = kst
        slotFmt.dateFormat = "yyyyMMddHHmm"

        let now = Date()
        var hourlyForecasts: [HourlyForecast] = []
        var dailyAgg: [String: DailyAgg] = [:]

        for key in slotMap.keys.sorted() {
            guard let date = slotFmt.date(from: key) else { continue }
            let cats = slotMap[key]!
            let dayKey = String(key.prefix(8))

            // 일별 집계
            var agg = dailyAgg[dayKey] ?? DailyAgg()
            if let v = cats["TMX"], let d = Double(v) { agg.tmx = d }
            if let v = cats["TMN"], let d = Double(v) { agg.tmn = d }
            if let v = cats["POP"], let d = Double(v) { agg.maxPop = max(agg.maxPop, d) }
            if agg.sky == nil, let v = cats["SKY"], let i = Int(v) { agg.sky = i }
            if agg.pty == nil, let v = cats["PTY"], let i = Int(v), i != 0 { agg.pty = i }
            dailyAgg[dayKey] = agg

            // 시간별 예보 (현재 ~ 24시간)
            guard date >= now && date <= now.addingTimeInterval(24 * 3600) else { continue }
            let sky = Int(cats["SKY"] ?? "1") ?? 1
            let pty = Int(cats["PTY"] ?? "0") ?? 0
            let pop = Double(cats["POP"] ?? "0") ?? 0.0
            let tmp = Double(cats["TMP"] ?? "0") ?? 0.0

            hourlyForecasts.append(HourlyForecast(
                date: date,
                temperature: tmp,
                precipitationChance: pop / 100.0,
                state: weatherState(sky: sky, pty: pty)
            ))
        }

        let dayFmt = DateFormatter()
        dayFmt.timeZone = kst
        dayFmt.dateFormat = "yyyyMMdd"

        let dailyForecasts: [DailyForecast] = dailyAgg.keys.sorted().compactMap { dayKey in
            guard let date = dayFmt.date(from: dayKey) else { return nil }
            let agg = dailyAgg[dayKey]!
            // TMX/TMN 둘 다 있어야 유효한 일별 데이터로 간주
            guard let tmn = agg.tmn, let tmx = agg.tmx else { return nil }
            return DailyForecast(
                date: date,
                lowTemperature: tmn,
                highTemperature: tmx,
                precipitationChance: agg.maxPop / 100.0,
                state: weatherState(sky: agg.sky, pty: agg.pty ?? 0)
            )
        }

        NCLogger.info("시간별 \(hourlyForecasts.count)개 / 일별 \(dailyForecasts.count)개 파싱 완료", category: .weather)
        return (hourly: hourlyForecasts, daily: dailyForecasts)
    }

    // MARK: - 날씨 상태 변환

    private static func weatherState(sky: Int?, pty: Int) -> WeatherState {
        switch pty {
        case 1: return .rain
        case 2: return .sleet
        case 3: return .snow
        case 4: return .rain      // 소나기
        case 5: return .drizzle   // 빗방울
        case 6: return .sleet     // 진눈깨비
        case 7: return .snow      // 눈날림
        default: break
        }
        switch sky {
        case 1: return .clear
        case 3: return .partlyCloudy
        case 4: return .cloudy
        default: return .unknown
        }
    }

    private static func isDaytime() -> Bool {
        let kst = TimeZone(identifier: "Asia/Seoul")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst
        let hour = cal.component(.hour, from: Date())
        return hour >= 6 && hour < 20
    }
}

// MARK: - 일별 집계용 내부 구조체

private struct DailyAgg {
    var tmx: Double? = nil
    var tmn: Double? = nil
    var maxPop: Double = 0.0
    var sky: Int? = nil
    var pty: Int? = nil
}

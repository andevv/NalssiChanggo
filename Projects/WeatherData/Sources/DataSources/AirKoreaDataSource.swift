import Foundation
import Combine
import WeatherDomain
import Core

final class AirKoreaDataSource {

    private let apiKey: String
    private let baseURL = "https://apis.data.go.kr/B552584/ArpltnInforInqireSvc"

    init(apiKey: String) {
        // Secrets.swift 값이 URL 인코딩된 채로 저장될 경우 이중 인코딩 방지
        self.apiKey = apiKey.removingPercentEncoding ?? apiKey
    }

    func fetchAirQuality(sidoName: String) -> AnyPublisher<AirQualityData, Error> {
        guard !sidoName.isEmpty, let url = buildURL(sidoName: sidoName) else {
            NCLogger.error("유효하지 않은 시도명 또는 URL 생성 실패: '\(sidoName)'", category: .air)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        NCLogger.request(url: url, category: .air)

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { [weak self] data, response -> Data in
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                NCLogger.response(statusCode: statusCode, body: data, category: .air)
                guard statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: AirKoreaResponse.self, decoder: JSONDecoder())
            .tryMap { response -> AirQualityData in
                let code = response.response.header.resultCode
                let msg  = response.response.header.resultMsg
                NCLogger.info("resultCode=\(code) msg=\(msg) items=\(response.response.body.items.count)개", category: .air)
                guard code == "00" else {
                    NCLogger.error("API 오류 코드: \(code) — \(msg)", category: .air)
                    throw URLError(.cannotParseResponse)
                }
                let result = try Self.mapToAirQuality(items: response.response.body.items)
                NCLogger.info("대기질 파싱 성공 — \(result.grade) (gradeIndex=\(result.gradeIndex), PM2.5=\(result.pm25Value)μg/m³, PM10=\(result.pm10Value)μg/m³)", category: .air)
                return result
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    NCLogger.error("fetchAirQuality 실패: \(error.localizedDescription)", category: .air)
                }
            })
            .eraseToAnyPublisher()
    }

    // MARK: - URL

    private func buildURL(sidoName: String) -> URL? {
        var components = URLComponents(string: "\(baseURL)/getCtprvnRltmMesureDnsty")
        // URLComponents는 + 를 인코딩하지 않으므로 percentEncodedQueryItems 사용
        components?.percentEncodedQueryItems = [
            URLQueryItem(name: "serviceKey", value: encode(apiKey)),
            URLQueryItem(name: "returnType", value: "json"),
            URLQueryItem(name: "numOfRows", value: "100"),
            URLQueryItem(name: "pageNo", value: "1"),
            URLQueryItem(name: "sidoName", value: encode(sidoName)),
            URLQueryItem(name: "ver", value: "1.3"),
        ]
        return components?.url
    }

    /// URLComponents가 인코딩하지 않는 + = ? # & 를 수동 percent-encode
    private func encode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?#")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    // MARK: - Mapping

    private static func mapToAirQuality(items: [AirKoreaItem]) throws -> AirQualityData {
        let valid = items.filter {
            guard let v = $0.pm25Value, let g = $0.pm25Grade else { return false }
            return v != "-" && g != "-" && !v.isEmpty && !g.isEmpty
        }
        NCLogger.debug("유효 측정소 \(valid.count)개 / 전체 \(items.count)개", category: .air)
        guard !valid.isEmpty else {
            NCLogger.warning("유효한 PM2.5 측정값 없음", category: .air)
            throw URLError(.cannotParseResponse)
        }

        let pm25Values = valid.compactMap { Int($0.pm25Value ?? "") }
        let pm25Grades = valid.compactMap { Int($0.pm25Grade ?? "") }

        let pm10ValidItems = items.filter {
            guard let v = $0.pm10Value, let g = $0.pm10Grade else { return false }
            return v != "-" && g != "-" && !v.isEmpty && !g.isEmpty
        }
        let pm10Values = pm10ValidItems.compactMap { Int($0.pm10Value ?? "") }
        let pm10Grades = pm10ValidItems.compactMap { Int($0.pm10Grade ?? "") }

        let avgPM25  = pm25Values.isEmpty ? 0 : pm25Values.reduce(0, +) / pm25Values.count
        let avgPM10  = pm10Values.isEmpty ? 0 : pm10Values.reduce(0, +) / pm10Values.count
        let avgPM25G = pm25Grades.isEmpty ? 1 : Int((Double(pm25Grades.reduce(0, +)) / Double(pm25Grades.count)).rounded())
        let avgPM10G = pm10Grades.isEmpty ? 1 : Int((Double(pm10Grades.reduce(0, +)) / Double(pm10Grades.count)).rounded())

        // PM2.5와 PM10 중 더 나쁜 등급을 전체 대기질 등급으로 사용
        let worstGrade = max(avgPM25G, avgPM10G)
        let apiGrade   = min(max(worstGrade, 1), 4)
        let gradeIndex = apiGrade - 1

        let gradeNames = ["좋음", "보통", "나쁨", "매우나쁨"]
        let grade = gradeNames[gradeIndex]

        NCLogger.debug("PM2.5 avg=\(avgPM25)μg/m³ grade=\(avgPM25G) | PM10 avg=\(avgPM10)μg/m³ grade=\(avgPM10G)", category: .air)

        return AirQualityData(
            gradeIndex: gradeIndex,
            grade: grade,
            pm25Value: avgPM25,
            pm10Value: avgPM10
        )
    }
}

// MARK: - 시도명 변환

extension AirKoreaDataSource {

    /// CLGeocoder administrativeArea → 에어코리아 시도명 변환
    static func sidoName(from locationName: String) -> String {
        let city = locationName
            .components(separatedBy: " · ")
            .first ?? locationName

        NCLogger.debug("시도명 변환: '\(locationName)' → city='\(city)'", category: .air)

        let mapping: [(key: String, sido: String)] = [
            ("서울", "서울"), ("Seoul", "서울"),
            ("부산", "부산"), ("Busan", "부산"),
            ("대구", "대구"), ("Daegu", "대구"),
            ("인천", "인천"), ("Incheon", "인천"),
            ("광주", "광주"), ("Gwangju", "광주"),
            ("대전", "대전"), ("Daejeon", "대전"),
            ("울산", "울산"), ("Ulsan", "울산"),
            ("세종", "세종"), ("Sejong", "세종"),
            ("경기", "경기"), ("Gyeonggi", "경기"),
            ("강원", "강원"), ("Gangwon", "강원"),
            ("충청북", "충북"), ("충북", "충북"), ("North Chungcheong", "충북"),
            ("충청남", "충남"), ("충남", "충남"), ("South Chungcheong", "충남"),
            ("전라북", "전북"), ("전북", "전북"), ("North Jeolla", "전북"),
            ("전라남", "전남"), ("전남", "전남"), ("South Jeolla", "전남"),
            ("경상북", "경북"), ("경북", "경북"), ("North Gyeongsang", "경북"),
            ("경상남", "경남"), ("경남", "경남"), ("South Gyeongsang", "경남"),
            ("제주", "제주"), ("Jeju", "제주"),
        ]

        for (key, sido) in mapping where city.contains(key) {
            NCLogger.debug("시도명 매핑 결과: '\(city)' → '\(sido)'", category: .air)
            return sido
        }
        NCLogger.warning("시도명 매핑 실패, 원본 사용: '\(city)'", category: .air)
        return city
    }
}

import Foundation

// MARK: - 공통 응답 래퍼

struct KMAResponse<T: Decodable>: Decodable {
    let response: KMAResponseBody<T>
}

struct KMAResponseBody<T: Decodable>: Decodable {
    let header: KMAHeader
    let body: KMABodyContent<T>
}

struct KMAHeader: Decodable {
    let resultCode: String
    let resultMsg: String
}

struct KMABodyContent<T: Decodable>: Decodable {
    let dataType: String?
    let items: KMAItems<T>
    let pageNo: Int
    let numOfRows: Int
    let totalCount: Int
}

struct KMAItems<T: Decodable>: Decodable {
    let item: [T]
}

// MARK: - 단기예보 아이템 (getVilageFcst)

struct KMAForecastItem: Decodable {
    let baseDate: String
    let baseTime: String
    let category: String
    let fcstDate: String
    let fcstTime: String
    let fcstValue: String
    let nx: Int
    let ny: Int
}

// MARK: - 초단기실황 아이템 (getUltraSrtNcst)

struct KMANowcastItem: Decodable {
    let baseDate: String
    let baseTime: String
    let category: String
    let nx: Int
    let ny: Int
    let obsrValue: String
}

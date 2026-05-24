// 에어코리아 getCtprvnRltmMesureDnsty (ver=1.3) 응답 DTO

struct AirKoreaResponse: Decodable {
    let response: AirKoreaBody
}

struct AirKoreaBody: Decodable {
    let header: AirKoreaHeader
    let body: AirKoreaPageBody
}

struct AirKoreaHeader: Decodable {
    let resultCode: String
    let resultMsg: String
}

struct AirKoreaPageBody: Decodable {
    let totalCount: Int
    let items: [AirKoreaItem]
}

struct AirKoreaItem: Decodable {
    let stationName: String
    let pm25Value: String?
    let pm25Grade: String?
    let pm10Value: String?
    let pm10Grade: String?
    let khaiValue: String?
    let khaiGrade: String?
    let dataTime: String?
}

import Foundation

/// 기상청 Lambert Conformal Conic 격자 좌표 변환 (위경도 → nx/ny)
public enum LambertConverter {

    public struct GridPoint {
        public let nx: Int
        public let ny: Int
    }

    // 기상청 공식 상수
    private static let re: Double = 6371.00877 / 5.0  // Re / grid(5km)
    private static let slat1: Double = 30.0 * .pi / 180.0
    private static let slat2: Double = 60.0 * .pi / 180.0
    private static let olon: Double  = 126.0 * .pi / 180.0
    private static let olat: Double  = 38.0  * .pi / 180.0
    private static let xo: Double    = 43.0
    private static let yo: Double    = 136.0

    private static let sn: Double = {
        log(cos(slat1) / cos(slat2)) /
        log(tan(.pi * 0.25 + slat2 * 0.5) / tan(.pi * 0.25 + slat1 * 0.5))
    }()

    private static let sf: Double = {
        pow(tan(.pi * 0.25 + slat1 * 0.5), sn) * cos(slat1) / sn
    }()

    private static let ro: Double = {
        re * sf / pow(tan(.pi * 0.25 + olat * 0.5), sn)
    }()

    public static func convert(latitude: Double, longitude: Double) -> GridPoint {
        let ra = re * sf / pow(tan(.pi * 0.25 + latitude * .pi / 180.0 * 0.5), sn)
        var theta = longitude * .pi / 180.0 - olon
        if theta > .pi  { theta -= 2.0 * .pi }
        if theta < -.pi { theta += 2.0 * .pi }
        theta *= sn

        let x = ra * sin(theta) + xo + 0.5
        let y = ro - ra * cos(theta) + yo + 0.5
        return GridPoint(nx: Int(x), ny: Int(y))
    }
}

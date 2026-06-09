import Foundation

/// App → Widget 위치 공유용 Codable 스냅샷.
/// App이 위치를 획득할 때마다 App Groups UserDefaults에 저장하고,
/// Widget은 이 값을 읽어 API 호출의 좌표로 사용한다.
public struct LocationSnapshot: Codable, Sendable {

    public let latitude: Double
    public let longitude: Double
    public let locationName: String

    public static let sharedDefaultsKey = "lastLocationSnapshot"
    public static let appGroupID        = WidgetWeatherSnapshot.appGroupID

    public init(latitude: Double, longitude: Double, locationName: String) {
        self.latitude     = latitude
        self.longitude    = longitude
        self.locationName = locationName
    }

    public static func load() -> LocationSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data     = defaults.data(forKey: sharedDefaultsKey)
        else { return nil }
        return try? JSONDecoder().decode(LocationSnapshot.self, from: data)
    }

    public func save() {
        guard
            let data     = try? JSONEncoder().encode(self),
            let defaults = UserDefaults(suiteName: Self.appGroupID)
        else { return }
        defaults.set(data, forKey: Self.sharedDefaultsKey)
    }
}

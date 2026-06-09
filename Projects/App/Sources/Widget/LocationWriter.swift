import WeatherDomain

/// 앱이 위치를 획득할 때마다 App Groups에 좌표를 기록한다.
/// Widget은 이 값을 읽어 API 호출 좌표로 사용한다.
enum LocationWriter {

    static func write(latitude: Double, longitude: Double, locationName: String) {
        LocationSnapshot(
            latitude: latitude,
            longitude: longitude,
            locationName: locationName
        ).save()
    }
}

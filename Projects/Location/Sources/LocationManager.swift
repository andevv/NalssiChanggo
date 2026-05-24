import CoreLocation
import Observation

@Observable
public final class LocationManager: NSObject {

    public private(set) var coordinate: CLLocationCoordinate2D?
    public private(set) var locationName: String = ""
    public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// 위치가 갱신될 때마다 증가 — View의 task(id:) 트리거용
    public private(set) var locationVersion: Int = 0
    public private(set) var locationError: Error?

    private let clManager = CLLocationManager()
    // 중복 요청 방지 — requestLocation() 진행 중이면 재호출 무시
    private var isRequestingLocation = false

    public override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // authorizationStatus는 delegate 설정 전 읽어야 locationManagerDidChangeAuthorization 초기 호출과 겹치지 않음
        authorizationStatus = clManager.authorizationStatus
    }

    public func requestLocation() {
        guard !isRequestingLocation else { return }
        switch clManager.authorizationStatus {
        case .notDetermined:
            clManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isRequestingLocation = true
            clManager.requestLocation()
        default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        isRequestingLocation = false
        coordinate = location.coordinate
        locationVersion += 1
        reverseGeocode(location)
    }

    public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        isRequestingLocation = false
        locationError = error
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        authorizationStatus = newStatus
        // 초기 delegate 설정 시 호출되는 경우는 무시 — requestLocation()은 View에서 명시적으로 호출
        // 권한이 새로 부여된 경우에만 자동 요청 (isRequestingLocation 가드가 중복 방지)
        if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            requestLocation()
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                let city     = placemark.administrativeArea ?? ""
                let district = placemark.subLocality ?? placemark.locality ?? ""
                if !city.isEmpty && !district.isEmpty {
                    self.locationName = "\(city) · \(district)"
                } else if !city.isEmpty {
                    self.locationName = city
                }
            }
        }
    }
}

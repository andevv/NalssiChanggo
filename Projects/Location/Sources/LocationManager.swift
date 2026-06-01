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
    /// 위치 취득 실패 (권한 거부 포함) — View의 .onChange 트리거용
    public private(set) var locationFailed: Bool = false

    private let clManager = CLLocationManager()
    // 중복 요청 방지 — requestLocation() 진행 중이면 재호출 무시
    private var isRequestingLocation = false

    public override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = clManager.authorizationStatus
        // delegate 초기 발화가 notDetermined일 때는 requestLocation()이 호출되지 않으므로
        // init에서 직접 호출: notDetermined → 권한 다이얼로그, authorized → guard로 무시됨
        requestLocation()
    }

    public func requestLocation() {
        guard !isRequestingLocation else { return }
        locationFailed = false
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
        // isRequestingLocation이 false면 이미 처리한 요청 — 캐시된 위치 등 중복 콜백 무시
        guard isRequestingLocation else { return }
        isRequestingLocation = false
        coordinate = location.coordinate
        // locationVersion은 reverseGeocode 완료 후 한 번만 증가
        reverseGeocode(location)
    }

    public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        isRequestingLocation = false
        locationError = error
        locationFailed = true
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        authorizationStatus = newStatus
        switch newStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한 허가 시 위치 요청 시작 (init 호출과 중복되더라도 guard로 무시됨)
            requestLocation()
        case .denied, .restricted:
            // 권한 거부 — 에러뷰 전환을 위해 실패 플래그 설정
            locationFailed = true
        default:
            break
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    let city     = placemark.administrativeArea ?? ""
                    let district = placemark.subLocality ?? placemark.locality ?? ""
                    if !city.isEmpty && !district.isEmpty {
                        self.locationName = "\(city) · \(district)"
                    } else if !city.isEmpty {
                        self.locationName = city
                    }
                }
                // 지오코딩 성공·실패 무관하게 한 번만 증가 → loadWeather 트리거
                self.locationVersion += 1
            }
        }
    }
}

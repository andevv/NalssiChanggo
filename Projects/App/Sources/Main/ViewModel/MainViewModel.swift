import Foundation
import Observation
import Combine
import WeatherKit
import WeatherDomain
import WeatherData
import Location

@Observable
final class MainViewModel {

    // MARK: View state
    var displayData: WeatherDisplayData?
    var isLoading = false
    var errorMessage: String?
    private(set) var isCoolingDown: Bool = {
        guard let last = UserDefaults.standard.object(forKey: "lastRefreshedAt") as? Date else { return false }
        return Date().timeIntervalSince(last) < 600
    }()

    private static let refreshCooldownInterval: TimeInterval = 600
    private static let lastRefreshedAtKey = "lastRefreshedAt"

    // MARK: Attribution (WeatherKit 라이선스 요구)
    var attributionMarkURL: URL?
    var attributionLegalURL: URL?

    // MARK: Dependencies
    let locationManager: LocationManager

    private let useCase: FetchWeatherUseCaseProtocol
    private var weatherTask: AnyCancellable?

    init(useCase: FetchWeatherUseCaseProtocol, locationManager: LocationManager) {
        self.useCase = useCase
        self.locationManager = locationManager
        resumeCooldownIfNeeded()
    }

    // MARK: Actions

    private func resumeCooldownIfNeeded() {
        guard let last = UserDefaults.standard.object(forKey: MainViewModel.lastRefreshedAtKey) as? Date else { return }
        let remaining = MainViewModel.refreshCooldownInterval - Date().timeIntervalSince(last)
        guard remaining > 0 else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(remaining))
            self?.isCoolingDown = false
        }
    }

    // 위치 갱신 등 자동 트리거 — 쿨다운 무시
    func loadWeather() {
        fetchWeather()
    }

    // 수동 새로고침 버튼 — 쿨다운 적용
    func refreshWeather() {
        guard !isCoolingDown else { return }
        isCoolingDown = true
        UserDefaults.standard.set(Date(), forKey: MainViewModel.lastRefreshedAtKey)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(MainViewModel.refreshCooldownInterval))
            self?.isCoolingDown = false
        }
        fetchWeather()
    }

    /// 위치 fetch 오류 시 에러 메시지 표시 — MainView의 .onChange(locationFailed)에서 호출
    /// 권한 거부(.denied / .restricted)는 MainView에서 authorizationStatus로 직접 처리하므로 여기서 제외
    func handleLocationFailure() {
        guard locationManager.authorizationStatus != .denied,
              locationManager.authorizationStatus != .restricted else { return }
        isLoading = false
        errorMessage = "위치 정보를 가져올 수 없습니다.\n잠시 후 다시 시도해 주세요."
    }

    func retry() {
        errorMessage = nil
        locationManager.requestLocation()
        if locationManager.coordinate != nil {
            fetchWeather()
        }
    }

    private func fetchWeather() {
        guard let coord = locationManager.coordinate else { return }
        isLoading = true
        errorMessage = nil

        // WeatherKit attribution 마크 URL (라이선스 요건 — async/await만 지원하는 WeatherKit API)
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let attr = try? await WeatherService.shared.attribution {
                attributionMarkURL = attr.combinedMarkLightURL
                attributionLegalURL = attr.legalPageURL
            }
        }

        weatherTask = useCase.execute(latitude: coord.latitude, longitude: coord.longitude, locationName: locationManager.locationName)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    isLoading = false
                    if case .failure = completion {
                        errorMessage = "날씨 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요."
                    }
                },
                receiveValue: { [weak self] summary in
                    guard let self else { return }
                    displayData = WeatherDisplayData.from(
                        summary: summary,
                        locationName: locationManager.locationName
                    )
                }
            )
    }
}

// MARK: - Preview factory

extension MainViewModel {
    enum PreviewState { case data, loading, error }

    static func makePreview(state: PreviewState = .data) -> MainViewModel {
        let vm = MainViewModel(
            useCase: NoOpWeatherUseCase(),
            locationManager: LocationManager()
        )
        switch state {
        case .data:    vm.displayData = .preview
        case .loading: break
        case .error:   vm.errorMessage = "날씨 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요."
        }
        return vm
    }
}

// Preview 전용 No-op 구현
private struct NoOpWeatherUseCase: FetchWeatherUseCaseProtocol {
    func execute(latitude: Double, longitude: Double, locationName: String) -> AnyPublisher<WeatherSummary, Error> {
        Empty().eraseToAnyPublisher()
    }
}

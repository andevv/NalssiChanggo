import Observation
import WeatherDomain
import WeatherData
import Location

@Observable
final class MainViewModel {

    // MARK: View state
    var displayData: WeatherDisplayData?
    var isLoading = false
    var errorMessage: String?

    // MARK: Dependencies
    let locationManager: LocationManager

    private let useCase: FetchWeatherUseCaseProtocol

    init(useCase: FetchWeatherUseCaseProtocol, locationManager: LocationManager) {
        self.useCase = useCase
        self.locationManager = locationManager
    }

    // MARK: Actions

    @MainActor
    func loadWeather() async {
        guard let coord = locationManager.coordinate else { return }
        isLoading = true
        errorMessage = nil
        do {
            let summary = try await useCase.execute(
                latitude: coord.latitude,
                longitude: coord.longitude
            )
            displayData = WeatherDisplayData.from(
                summary: summary,
                locationName: locationManager.locationName
            )
        } catch {
            errorMessage = "날씨 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요."
        }
        isLoading = false
    }

    @MainActor
    func retry() async {
        locationManager.requestLocation()
        await loadWeather()
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
    func execute(latitude: Double, longitude: Double) async throws -> WeatherSummary {
        throw CancellationError()
    }
}

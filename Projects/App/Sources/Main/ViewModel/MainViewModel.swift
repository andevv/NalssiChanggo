import Foundation
import Observation
import Combine
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
    private var weatherTask: AnyCancellable?

    init(useCase: FetchWeatherUseCaseProtocol, locationManager: LocationManager) {
        self.useCase = useCase
        self.locationManager = locationManager
    }

    // MARK: Actions

    func loadWeather() {
        guard let coord = locationManager.coordinate else { return }
        isLoading = true
        errorMessage = nil

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

    func retry() {
        locationManager.requestLocation()
        loadWeather()
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

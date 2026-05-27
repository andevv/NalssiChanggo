import SwiftUI
import DesignSystem
import Location
import WeatherData

@main
struct NalssiChanggoApp: App {

    private let viewModel: MainViewModel

    init() {
        FontRegistrar.register()

        let locationManager = LocationManager()
        let repository = WeatherRepositoryImpl(
            airKoreaAPIKey: Secrets.airKoreaAPIKey,
            kmaAPIKey: Secrets.kmaServiceKey,
            owmAPIKey: Secrets.openWeatherMapAPIKey
        )
        let useCase = FetchWeatherUseCase(repository: repository)
        viewModel = MainViewModel(useCase: useCase, locationManager: locationManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

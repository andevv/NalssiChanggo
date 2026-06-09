import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import DesignSystem
import Location
import WeatherData

@main
struct NalssiChanggoApp: App {

    private let viewModel: MainViewModel

    init() {
        FirebaseApp.configure()
        FontRegistrar.register()

        let locationManager = LocationManager()
        let repository = WeatherRepositoryImpl(
            airKoreaAPIKey: Secrets.airKoreaAPIKey,   // 앱은 대기질 표시 — non-nil
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

import SwiftUI
import DesignSystem

@main
struct NalssiChanggoApp: App {
    init() {
        FontRegistrar.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

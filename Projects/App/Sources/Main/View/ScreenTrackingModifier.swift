import SwiftUI
import FirebaseAnalytics

extension View {
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTrackingModifier(screenName: name))
    }
}

private struct ScreenTrackingModifier: ViewModifier {
    let screenName: String

    func body(content: Content) -> some View {
        content.onAppear {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName,
            ])
        }
    }
}

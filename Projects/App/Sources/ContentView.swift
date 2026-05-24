import SwiftUI

struct ContentView: View {
    let viewModel: MainViewModel

    var body: some View {
        MainView(viewModel: viewModel)
    }
}

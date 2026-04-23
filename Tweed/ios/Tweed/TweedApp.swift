import SwiftUI

@main
struct TweedApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLinked {
                MainTabView()
                    .environmentObject(appState)
            } else {
                LinkBankView()
                    .environmentObject(appState)
            }
        }
    }
}

// Central state object shared across the app
@MainActor
class AppState: ObservableObject {
    @Published var isLinked: Bool = false

    init() {
        isLinked = KeychainService.shared.hasAccessToken()
    }

    func markLinked() {
        isLinked = true
    }
}

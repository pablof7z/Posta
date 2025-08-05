import SwiftUI
import NDKSwift

@main
struct PostaApp: App {
    @State private var ndkManager = NDKManager.shared
    
    // Default relays for Posta
    private let defaultRelays = [
        RelayConstants.primal,
        RelayConstants.damus,
        RelayConstants.nostrBand,
        RelayConstants.nosLol
    ]
    private let userRelaysKey = "posta_user_added_relays"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(ndkManager)
                .preferredColorScheme(ndkManager.currentTheme.colorScheme)
                .onAppear {
                    setupNDK()
                }
        }
    }
    
    private func setupNDK() {
        // NDKManager.shared already initializes NDK synchronously in its init
        // No additional setup needed here
    }
}
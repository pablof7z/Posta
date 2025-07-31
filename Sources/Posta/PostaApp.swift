import SwiftUI
import NDKSwift

@main
struct PostaApp: App {
    @State private var ndkManager = NDKManager.shared
    @StateObject private var themeManager = ThemeManager()
    
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
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
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
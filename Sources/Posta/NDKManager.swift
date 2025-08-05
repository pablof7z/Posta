import Foundation
import NDKSwift
import Observation
import SwiftUI

@MainActor
@Observable 
class NDKManager: ObservableObject {
    // MARK: - Authentication
    private(set) var authManager: NDKAuthManager?
    
    // MARK: - Published Properties
    private(set) var ndk: NDK
    private(set) var isConnected = false
    private(set) var relayStatus: [String: Bool] = [:]
    private(set) var currentUserMetadata: NDKUserMetadata?
    private(set) var isInitialized = false
    
    // MARK: - Public Properties  
    var cache: NDKSQLiteCache?
    var zapManager: NDKZapManager?
    var error: Error?
    
    // MARK: - Configuration
    let defaultRelays = [
        RelayConstants.primal,
        RelayConstants.damus,
        RelayConstants.nostrBand,
        RelayConstants.nosLol
    ]
    
    let userRelaysKey = "posta_user_added_relays"
    
    var clientTagConfig: NDKClientTagConfig? {
        NDKClientTagConfig(
            name: "Posta",
            autoTag: true
        )
    }
    
    // MARK: - Private Properties
    private var profileObservationTask: Task<Void, Never>?
    private var relayMonitorTask: Task<Void, Never>?
    
    // MARK: - Theme Management
    enum Theme: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }
    
    private(set) var currentTheme: Theme = .system {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
    }
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        authManager?.isAuthenticated ?? false
    }
    
    var currentUser: NDKUser? {
        guard let pubkey = authManager?.activePubkey else { return nil }
        return NDKUser(pubkey: pubkey)
    }
    
    // MARK: - Initialization
    init() {
        print("NDKManager - Initializing...")
        
        // Load theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = Theme(rawValue: savedTheme) {
            self.currentTheme = theme
        }
        
        // Initialize NDK synchronously with empty relays
        ndk = NDK(relayUrls: [])
        
        Task {
            await setupNDK()
        }
    }
    
    deinit {
        // Tasks will be cancelled automatically when the instance is deallocated
    }
    
    // MARK: - Setup
    func setupNDK() async {
        print("NDKManager - Setting up NDK...")
        
        // Initialize SQLite cache for better performance and offline access
        do {
            cache = try await NDKSQLiteCache()
            // Re-initialize NDK with cache and relays
            let allRelays = getAllRelays()
            ndk = NDK(relayUrls: allRelays, cache: cache)
            print("NDK initialized with SQLite cache")
        } catch {
            print("Failed to initialize SQLite cache: \(error). Continuing without cache.")
            // Re-initialize with just relays
            let allRelays = getAllRelays()
            ndk = NDK(relayUrls: allRelays)
        }
        
        // Configure client tags if provided
        if let config = clientTagConfig {
            ndk.clientTagConfig = config
            print("NDKManager - Configured NIP-89 client tags")
        }
        
        // Initialize zap manager
        zapManager = NDKZapManager(ndk: ndk)
        print("NDKManager - Zap manager initialized")
        
        // Initialize auth manager
        authManager = NDKAuthManager(ndk: ndk)
        await authManager?.initialize()
        
        // If authenticated after restore, initialize user data
        if authManager?.isAuthenticated == true {
            if let signer = authManager?.activeSigner {
                Task {
                    let pubkey = try await signer.pubkey
                    await initializeUserData(for: pubkey)
                }
            }
        }
        
        Task {
            await connectToRelays()
        }
        
        // Mark as initialized
        isInitialized = true
        print("NDKManager - Initialization complete")
    }
    
    // MARK: - Relay Management
    func connectToRelays() async {
        print("NDKManager - Connecting to relays...")
        await ndk.connect()
        isConnected = true
        print("NDKManager - Connected to relays")
        
        // Monitor relay status
        relayMonitorTask?.cancel()
        relayMonitorTask = Task {
            await monitorRelayStatus()
        }
    }
    
    private func monitorRelayStatus() async {
        
        for await change in await ndk.relayChanges {
            switch change {
            case .relayConnected(let relay):
                relayStatus[relay.url] = true
            case .relayDisconnected(let relay):
                relayStatus[relay.url] = false
            case .relayAdded(let relay):
                relayStatus[relay.url] = false
            case .relayRemoved(let url):
                relayStatus.removeValue(forKey: url)
            }
        }
    }
    
    func getAllRelays() -> [String] {
        let userRelays = UserDefaults.standard.stringArray(forKey: userRelaysKey) ?? []
        return Array(Set(defaultRelays + userRelays))
    }
    
    var userAddedRelays: [String] {
        UserDefaults.standard.stringArray(forKey: userRelaysKey) ?? []
    }
    
    func addUserRelay(_ relayURL: String) async {
        
        var userRelays = userAddedRelays
        if !userRelays.contains(relayURL) && !defaultRelays.contains(relayURL) {
            userRelays.append(relayURL)
            UserDefaults.standard.set(userRelays, forKey: userRelaysKey)
            
            // Add to NDK and connect
            let relay = await ndk.addRelay(relayURL)
            await ndk.connect()
            if relay != nil {
                print("Added and connected to relay: \(relayURL)")
            }
        }
    }
    
    func removeUserRelay(_ relayURL: String) async {
        
        var userRelays = userAddedRelays
        userRelays.removeAll { $0 == relayURL }
        UserDefaults.standard.set(userRelays, forKey: userRelaysKey)
        
        // Don't remove if it's a default relay
        if !defaultRelays.contains(relayURL) {
            await ndk.removeRelay(relayURL)
            print("Removed relay: \(relayURL)")
        }
    }
    
    // MARK: - User Data
    func initializeUserData(for pubkey: String) async {
        // Observe current user's profile
        profileObservationTask?.cancel()
        profileObservationTask = Task {
            
            for await profile in await ndk.profileManager.subscribe(for: pubkey) {
                self.currentUserMetadata = profile
            }
        }
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() async {
        // Remove all user-added relays
        let userRelays = userAddedRelays
        for relay in userRelays {
            await removeUserRelay(relay)
        }
        
        print("NDKManager - Reset to default relays")
    }
    
    // MARK: - Error Handling
    func setError(_ error: Error?) {
        self.error = error
    }
}

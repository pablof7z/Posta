import Foundation
import NDKSwift
import NDKSwiftUI
import SwiftUI
import Combine

// MARK: - Simple Profile Data Source
@MainActor
class SimpleProfileDataSource: ObservableObject {
    @Published var metadata: NDKUserMetadata?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let ndk: NDK
    private let pubkey: String
    
    init(ndk: NDK, pubkey: String) {
        self.ndk = ndk
        self.pubkey = pubkey
    }
    
    func loadProfile() {
        // Placeholder implementation
        isLoading = true
        // Would load metadata here in real implementation
        isLoading = false
    }
}

// MARK: - Type Aliases for Compatibility
typealias UserProfileDataSource = SimpleProfileDataSource
typealias MultipleProfilesDataSource = SimpleProfileDataSource
typealias FollowListDataSource = SimpleProfileDataSource

// MARK: - Notes Data Source

/// Data source for text notes - wraps NDKEventDataSource with EOSE monitoring
typealias NotesDataSource = NDKEventDataSource

// MARK: - Session Notes Data Source

/// Data source for notes from followed users with session management
@MainActor
public class SessionNotesDataSource: ObservableObject {
    @Published public var notes: [NDKEvent] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    @Published public var hasEOSE = false
    @Published public var sessionData: NDKSessionData?
    
    private var eventDataSource: NDKEventDataSource?
    private var dataSource: NDKSubscription<NDKEvent>?
    private var eoseTask: Task<Void, Never>?
    private var signerMonitorTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    public let ndk: NDK
    
    public init(ndk: NDK) {
        self.ndk = ndk
        
        // Start monitoring for signer availability
        signerMonitorTask = Task {
            await monitorSignerAndSetup()
        }
    }
    
    deinit {
        eoseTask?.cancel()
        signerMonitorTask?.cancel()
    }
    
    private func monitorSignerAndSetup() async {
        // If signer is already available, set up immediately
        if ndk.signer != nil {
            await setupSession()
            return
        }
        
        // Wait for signer availability
        while ndk.signer == nil {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        }
        
        await setupSession()
    }
    
    private func setupSession() async {
        do {
            isLoading = true
            
            guard let signer = ndk.signer else {
                isLoading = false
                return
            }
            
            // Start session with proper configuration
            let config = NDKSessionConfiguration(
                dataRequirements: [.followList, .muteList, .webOfTrust(depth: 2)],
                preloadStrategy: .progressive
            )
            
            let sessionData = try await ndk.startSession(signer: signer, config: config)
            self.sessionData = sessionData
            
            // Create filter based on session data
            var authors = Array(sessionData.followList) + [sessionData.pubkey]
            
            // Bootstrap with popular accounts if user has no follows
            if sessionData.followList.isEmpty {
                let popularAccounts = [
                    "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2", // jack
                    "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d", // fiatjaf
                    "04c915daefee38317fa734444acee390a8269fe5810b2241e5e6dd343dfbecc9", // ODELL
                    "6e468422dfb74a5738702a8823b9b28168abab8655faacb6853cd0ee15deee93", // Gigi
                    "e88a691e98d9987c964521dff60025f60700378a4879180dcbbb4a5027850411" // nvk
                ]
                authors.append(contentsOf: popularAccounts)
            }
            
            let since = Timestamp(Date().timeIntervalSince1970 - 86400) // 24 hours ago
            let filter = NDKFilter(
                authors: authors,
                kinds: [1], // text notes
                since: since,
                limit: 200
            )
            
            // Use NDKEventDataSource for event handling
            eventDataSource = NDKEventDataSource(ndk: ndk, filter: filter)
            
            // Bind properties from NDKEventDataSource
            eventDataSource?.$events
                .receive(on: DispatchQueue.main)
                .assign(to: &$notes)
            
            eventDataSource?.$isLoading
                .receive(on: DispatchQueue.main)
                .assign(to: &$isLoading)
            
            eventDataSource?.$error
                .receive(on: DispatchQueue.main)
                .assign(to: &$error)
            
            // Keep raw data source for EOSE monitoring
            dataSource = ndk.subscribe(
                filter: filter,
                maxAge: 0,
                cachePolicy: .cacheWithNetwork
            )
            
            // Monitor EOSE separately
            await monitorEOSE()
            
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    private func monitorEOSE() async {
        guard let dataSource = dataSource else { return }
        
        eoseTask = Task {
            for await update in dataSource.relayUpdates {
                if case .eose = update {
                    hasEOSE = true
                }
            }
        }
    }
    
    /// Refresh the feed by clearing and re-fetching
    public func refresh() async {
        guard let sessionData = sessionData else { return }
        
        notes.removeAll()
        hasEOSE = false
        
        let since = Timestamp(Date().timeIntervalSince1970 - 86400) // 24 hours ago
        let filter = NDKFilter(
            authors: Array(sessionData.followList) + [sessionData.pubkey],
            kinds: [1], // text notes
            since: since,
            limit: 200
        )
        
        // Recreate data sources with network-only policy for refresh
        eventDataSource = NDKEventDataSource(ndk: ndk, filter: filter)
        
        // Re-bind properties
        eventDataSource?.$events
            .receive(on: DispatchQueue.main)
            .assign(to: &$notes)
        
        eventDataSource?.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        eventDataSource?.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$error)
        
        dataSource = ndk.subscribe(
            filter: filter,
            maxAge: 0,
            cachePolicy: .networkOnly
        )
        
        await monitorEOSE()
    }
}
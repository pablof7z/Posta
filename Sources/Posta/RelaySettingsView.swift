import SwiftUI
import NDKSwift

// Helper function to ensure WebSocket scheme
private func ensureWebSocketScheme(_ urlString: String) -> String {
    let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if trimmed.hasPrefix("wss://") || trimmed.hasPrefix("ws://") {
        return trimmed
    }
    
    // Default to secure WebSocket
    return "wss://" + trimmed
}

struct RelaySettingsView: View {
    @Environment(NDKManager.self) private var ndkManager
    @State private var relays: [NDKRelay] = []
    @State private var showingAddRelay = false
    @State private var newRelayUrl = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        List {
            Section(header: Text("Connected Relays")) {
                ForEach(relays, id: \.url) { relay in
                    RelayRow(relay: relay, onRemove: {
                        removeRelay(relay)
                    })
                }
            }
            
            Section {
                Button(action: { showingAddRelay = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Add Relay")
                    }
                }
            } footer: {
                Text("Relays are servers that store and distribute Nostr events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadRelays()
        }
        .sheet(isPresented: $showingAddRelay) {
            NavigationView {
                AddRelaySheet(
                    relayUrl: $newRelayUrl,
                    onAdd: { url in
                        Task {
                            await addRelay(url)
                            showingAddRelay = false
                            newRelayUrl = ""
                        }
                    },
                    onCancel: {
                        showingAddRelay = false
                        newRelayUrl = ""
                    }
                )
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .navigationTitle("Relays")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func loadRelays() async {
        let ndk = ndkManager.ndk
        relays = await ndk.relays.sorted { $0.url < $1.url }
    }
    
    private func addRelay(_ urlString: String) async {
        let ndk = ndkManager.ndk
        isLoading = true
        defer { isLoading = false }
        
        // Clean up URL and ensure WebSocket scheme
        let cleanUrl = ensureWebSocketScheme(urlString)
        
        // Simple URL validation
        guard URL(string: cleanUrl) != nil else {
            errorMessage = "Invalid relay URL"
            showingError = true
            return
        }
        
        // Check if already exists
        if relays.contains(where: { $0.url == cleanUrl }) {
            errorMessage = "Relay already added"
            showingError = true
            return
        }
        
        // Add relay
        let relay = await ndk.addRelay(cleanUrl)
        await ndk.connect()
        if relay != nil {
            await loadRelays()
        } else {
            errorMessage = "Failed to connect to relay"
            showingError = true
        }
    }
    
    private func removeRelay(_ relay: NDKRelay) {
        let ndk = ndkManager.ndk
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            await ndk.removeRelay(relay.url)
            await loadRelays()
        }
    }
}

// MARK: - Relay Row View
private struct RelayRow: View {
    let relay: NDKRelay
    let onRemove: () -> Void
    
    @State private var isConnected = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatRelayUrl(relay.url))
                    .font(.body)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
        .task {
            isConnected = await relay.isConnected
        }
    }
    
    private func formatRelayUrl(_ url: String) -> String {
        var formatted = url
        // Remove WebSocket scheme prefix for display
        if formatted.hasPrefix("wss://") {
            formatted = String(formatted.dropFirst(6)) // "wss://" is 6 characters
        } else if formatted.hasPrefix("ws://") {
            formatted = String(formatted.dropFirst(5)) // "ws://" is 5 characters
        }
        // Remove trailing slash
        if formatted.hasSuffix("/") {
            formatted = String(formatted.dropLast())
        }
        return formatted
    }
}

// MARK: - Add Relay Sheet
private struct AddRelaySheet: View {
    @Binding var relayUrl: String
    let onAdd: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    // Common relay suggestions
    private let suggestedRelays = [
        "relay.damus.io",
        "nos.lol",
        "relay.primal.net",
        "relay.nostr.band",
        "relay.nostr.wine",
        "relay.nostrgraph.net",
        "relay.current.fyi",
        "relay.snort.social"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Add Relay")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Relay URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("wss://relay.example.com", text: $relayUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .focused($isTextFieldFocused)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Relays")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(suggestedRelays, id: \.self) { relay in
                        Button(action: {
                            relayUrl = relay
                            isTextFieldFocused = true
                        }) {
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                Text(relay)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                Spacer(minLength: 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    onAdd(relayUrl)
                }
                .disabled(relayUrl.isEmpty)
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

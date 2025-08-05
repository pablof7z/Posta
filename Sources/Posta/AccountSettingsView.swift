import SwiftUI
import NDKSwift

struct AccountSettingsView: View {
    @Environment(NDKManager.self) var ndkManager
    @State private var showingAddAccount = false
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: NDKSession?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // Current Sessions
            Section("My Accounts") {
                ForEach(ndkManager.authManager?.availableSessions ?? [], id: \.id) { session in
                    SessionRow(
                        session: session,
                        isActive: session.id == ndkManager.authManager?.activeSession?.id,
                        onTap: {
                            Task {
                                try? await ndkManager.authManager?.switchToSession(session)
                            }
                        },
                        onDelete: {
                            sessionToDelete = session
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            
            // Add Account
            Section {
                Button(action: { showingAddAccount = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Add Account")
                    }
                }
            }
            
            // Sign Out
            if ndkManager.authManager?.activeSession != nil {
                Section {
                    Button(action: {
                        ndkManager.authManager?.logout()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddAccount) {
            PostaAuthView()
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        try? await ndkManager.authManager?.removeSession(session)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this account? This action cannot be undone.")
        }
    }
}

struct SessionRow: View {
    let session: NDKSession
    let isActive: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(String(session.pubkey.prefix(8)) + "...")
                        .font(.headline)
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                HStack {
                    Image(systemName: session.signerType == "bunker" ? "lock.shield.fill" : "key.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text((session.signerType ?? "readonly").capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if session.requiresBiometric {
                        Image(systemName: "faceid")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
            .environment(NDKManager())
    }
}
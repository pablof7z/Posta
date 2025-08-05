import SwiftUI
import NDKSwift

struct PostaAuthView: View {
    @Environment(NDKManager.self) var ndkManager
    @State private var loginInput: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingLogin = true
    @State private var loginMethod: LoginMethod = .privateKey
    
    enum LoginMethod: String, CaseIterable {
        case privateKey = "Private Key"
        case nip46 = "NIP-46 (Bunker)"
        
        var placeholder: String {
            switch self {
            case .privateKey:
                return "Enter hex or nsec..."
            case .nip46:
                return "bunker:// or npub@domain.com"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Posta")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Spacer()
                
                if showingLogin {
                    loginView
                } else {
                    registerView
                }
                
                Spacer()
                
                Button(action: {
                    showingLogin.toggle()
                }) {
                    Text(showingLogin ? "New to Posta? Create Account" : "Already have an account? Login")
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 50)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private var loginView: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Login method picker
            Picker("Login Method", selection: $loginMethod) {
                ForEach(LoginMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Input field based on login method
            TextField(loginMethod.placeholder, text: $loginInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await performLogin()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Text("Login")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isLoading || loginInput.isEmpty)
        }
    }
    
    private var registerView: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("We'll generate a new private key for you")
                .font(.caption)
                .foregroundColor(.gray)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await performRegister()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isLoading)
        }
    }
    
    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let signer: any NDKSigner
            
            switch loginMethod {
            case .privateKey:
                // Check if input is nsec or hex format
                if loginInput.starts(with: "nsec1") {
                    signer = try NDKPrivateKeySigner(nsec: loginInput)
                } else {
                    // Assume hex format
                    signer = try NDKPrivateKeySigner(privateKey: loginInput)
                }
                
            case .nip46:
                let ndk = ndkManager.ndk
                
                // Initialize bunker signer
                if loginInput.starts(with: "bunker://") {
                    // Extract connection token from bunker URL
                    guard let connectionToken = extractConnectionToken(from: loginInput) else {
                        throw AuthError.invalidBunkerUrl
                    }
                    signer = try NDKBunkerSigner.bunker(ndk: ndk, connectionToken: connectionToken)
                } else if loginInput.contains("@") {
                    signer = try NDKBunkerSigner.nip05(ndk: ndk, nip05: loginInput)
                } else {
                    throw AuthError.invalidBunkerUrl
                }
            }
            
            // Add session to auth manager
            guard let authManager = ndkManager.authManager else {
                throw AuthError.authManagerNotInitialized
            }
            _ = try await authManager.addSession(signer)
            
        } catch {
            switch loginMethod {
            case .privateKey:
                errorMessage = "Invalid private key or nsec"
            case .nip46:
                errorMessage = "Failed to connect: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func performRegister() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Generate new private key
            let signer = try NDKPrivateKeySigner.generate()
            
            // Add session to auth manager
            guard let authManager = ndkManager.authManager else {
                throw AuthError.authManagerNotInitialized
            }
            _ = try await authManager.addSession(signer)
            
        } catch {
            errorMessage = "Failed to create account"
        }
        
        isLoading = false
    }
}

enum AuthError: Error {
    case invalidBunkerUrl
    case ndkNotInitialized
    case authManagerNotInitialized
}

// Helper function to extract connection token from bunker URL
private func extractConnectionToken(from bunkerUrl: String) -> String? {
    // bunker://pubkey?relay=wss://relay.url&secret=token
    // We need to extract the token/secret from the URL
    guard let url = URL(string: bunkerUrl),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return nil
    }
    
    // Try to find secret or token parameter
    if let secret = components.queryItems?.first(where: { $0.name == "secret" })?.value {
        return secret
    }
    
    // If no secret parameter, the entire path after bunker:// might be the token
    if let host = url.host, !host.isEmpty {
        return host
    }
    
    return nil
}

#Preview {
    PostaAuthView()
        .environment(NDKManager())
}
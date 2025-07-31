import SwiftUI

// Simple fallback QR scanner implementation
struct QRScannerView: View {
    let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("QR Scanner")
                .font(.title)
                .padding()
            
            Text("QR scanning functionality is not available in this build.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
    }
}

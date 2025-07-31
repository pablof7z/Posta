import SwiftUI
import NDKSwift

// Placeholder RichTextView implementation
struct RichTextView: View {
    let content: String
    
    var body: some View {
        VStack {
            Text("RichText")
                .font(.headline)
            Text(content)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding()
    }
}

// For backwards compatibility, create a simple wrapper for the inline version
struct RichTextInline: View {
    let content: String
    let tags: [Tag]
    let currentUser: NDKUser?
    
    var body: some View {
        RichTextView(content: content)
    }
}

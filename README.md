# Posta - Decentralized Messaging Made Beautiful

<div align="center">
  <img src="Resources/posta-icon.png" alt="Posta Logo" width="200"/>
  
  [![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)](https://developer.apple.com/ios/)
  [![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
  [![NDKSwift](https://img.shields.io/badge/NDKSwift-0.2.0-blue)](https://github.com/pablof7z/NDKSwift)
  [![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
</div>

## Overview

Posta is a modern iOS messaging application built on the [Nostr protocol](https://nostr.com), designed to provide a **Telegram-like** user experience with decentralized, encrypted messaging capabilities. It bridges the gap between familiar messaging UX and the freedom of decentralized communication.

## Philosophy

We believe privacy and user sovereignty shouldn't come at the cost of user experience. Posta makes decentralized messaging accessible to everyone by combining the intuitive interface patterns of popular messaging apps with the security and censorship-resistance of Nostr.

## Features

### 🔐 Secure Authentication
- **Private Key Login**: Import existing Nostr identity (hex/nsec format)
- **NIP-46 Bunker**: Enhanced security with remote signing
- **Account Creation**: Generate new keypairs instantly
- **QR Code Import**: Scan keys from other devices
- **Keychain Integration**: Secure credential storage

### 💬 Modern Messaging
- **Real-time Chat**: Instant message delivery via WebSocket
- **Thread Conversations**: Organized replies and discussions
- **Rich Text**: Links, mentions, and hashtag support
- **Media Previews**: Inline image and link previews
- **Reply Tracking**: See who's engaging with conversations
- **Message Status**: Sent, delivered, and read indicators

### 🎨 Beautiful Design
- **Electric Theme**: Distinctive purple/pink gradient aesthetic
- **Smooth Animations**: Delightful transitions and effects
- **Haptic Feedback**: Tactile responses for interactions
- **Dark/Light Modes**: Automatic and manual theme switching
- **Loading States**: Skeleton screens and progress indicators
- **Pixel Perfect**: Obsessive attention to visual details

### 🌐 Decentralized Architecture
- **Multi-Relay Support**: Connect to multiple Nostr relays
- **Relay Health Monitoring**: Real-time connection status
- **Offline Mode**: SQLite caching for seamless usage
- **Negentropy Sync**: Efficient data synchronization
- **No Central Server**: Your data, your control

### 👤 Profile Management
- **Rich Profiles**: Avatars, display names, bios, and more
- **Follow System**: Build your social graph
- **Lightning Integration**: Bitcoin Lightning addresses
- **NIP-05 Verification**: Domain verification badges
- **Profile Editing**: Update your information anytime

### 🔒 Privacy Features
- **End-to-End Encryption**: NIP-04/NIP-44 encrypted DMs
- **Local Key Storage**: Keys never leave your device
- **Message Deletion**: Remove messages when needed
- **Private Mode**: Toggle between public and private posting
- **No Phone Number**: No personal data required

### ⚙️ Customization
- **Appearance Settings**: Themes, colors, and fonts
- **Notification Controls**: Granular alert preferences
- **Privacy Settings**: Fine-tune your experience
- **Advanced Options**: Power user features
- **Relay Management**: Add custom relay servers

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/pablof7z/Posta.git
cd Posta
```

2. Install XcodeGen if you haven't already:
```bash
brew install xcodegen
```

3. Generate the Xcode project:
```bash
./refresh-project.sh
```

4. Open the project in Xcode:
```bash
open Posta.xcodeproj
```

5. Build and run the project on your device or simulator

### TestFlight

Coming soon! We'll be releasing Posta on TestFlight for beta testing.

## Development

### Building

```bash
# Refresh project after file changes
./refresh-project.sh

# Build with clean output
./build.sh

# Build for specific device
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro" ./build.sh
```

### Deploying to TestFlight

```bash
./deploy.sh
```

## Architecture

Posta follows clean architecture principles:

- **SwiftUI Views**: Modern declarative UI
- **NDKSwift Core**: Nostr protocol handling
- **SQLite Cache**: Local data persistence
- **Combine Framework**: Reactive data flow
- **Modular Design**: Separated concerns

### Key Components

- `PostaApp.swift` - Application entry point
- `NDKManager.swift` - Nostr connection management
- `RelayManager.swift` - Multi-relay coordination
- `ThemeManager.swift` - Appearance customization
- `ContentView.swift` - Main navigation structure

## Roadmap

- [ ] Group messaging support
- [ ] Voice messages
- [ ] Video calls over Nostr
- [ ] File sharing with encryption
- [ ] Message reactions and emojis
- [ ] Read receipts
- [ ] Typing indicators
- [ ] Message search
- [ ] Export/backup conversations
- [ ] Desktop companion app

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Why Posta?

- **User-Friendly**: Familiar interface for easy adoption
- **Truly Private**: No phone numbers, no central servers
- **Censorship-Resistant**: Your messages can't be deleted by others
- **Open Protocol**: Built on open standards
- **Beautiful Design**: A joy to use daily
- **Fast & Reliable**: Optimized for performance

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [NDKSwift](https://github.com/pablof7z/NDKSwift)
- Uses the [Nostr Protocol](https://nostr.com)
- Inspired by Telegram's excellent UX
- Community-driven development

## Contact

- Nostr: `npub1l2vyh47mk2p0qlsku7hg0vn29faehy9hy34ygaclpn66ukqp3afqutajft`
- GitHub: [@pablof7z](https://github.com/pablof7z)

---

<div align="center">
  Made with ⚡ for the decentralized future
</div>
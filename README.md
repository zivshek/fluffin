# Fluffin 🎬

A smooth and feature-rich Jellyfin client for Android and iOS, built with Flutter.

## Features

- **Smooth Video Playback**: Powered by media_kit with mpv backend for excellent performance
- **Smart Subtitle Management**: Remembers your preferred subtitle settings
- **Auto Skip Intros**: Automatically skip intro sequences (when supported by Jellyfin)
- **Magic Keyboard Support**: Full keyboard navigation support for iOS
- **Cross-Platform**: Native experience on both Android and iOS
- **Modern UI**: Clean, intuitive interface with dark mode support

## Key Advantages Over Other Clients

- **Remembers Subtitle Preferences**: Unlike Streamify, Fluffin remembers your last chosen subtitle language
- **Auto Skip Features**: Automatically skip intros and outros when available
- **Free and Open Source**: No paid subscriptions required
- **Keyboard Navigation**: Full support for external keyboards on iOS
- **Optimized Performance**: Uses mpv backend for smooth playback

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode for platform-specific builds
- A running Jellyfin server

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd fluffin
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate model files:
```bash
flutter packages pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## Configuration

On first launch, you'll need to:

1. Enter your Jellyfin server URL
2. Provide your username and password
3. Configure your preferred settings (subtitles, auto-skip, etc.)

## Architecture

- **State Management**: Provider pattern for clean state management
- **API Layer**: Dio-based HTTP client for Jellyfin API communication
- **Video Playback**: media_kit with mpv backend for optimal performance
- **Navigation**: go_router for declarative routing
- **Storage**: SharedPreferences for settings, SecureStorage for credentials

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Jellyfin team for the excellent media server
- media_kit developers for the Flutter video player
- Flutter team for the amazing framework
# Jellyfin Dart

A comprehensive Dart/Flutter wrapper for the Jellyfin Media Server API.

## Features

- **Complete API Coverage**: Authentication, Library, Playback, User management, System info
- **Type Safety**: Full Dart type definitions for all API responses
- **Error Handling**: Structured error responses with proper exception handling
- **Streaming Support**: Direct streaming URLs with device profile support
- **Session Management**: Automatic authentication header management
- **Playback Reporting**: Built-in playback progress and session reporting

## Quick Start

```dart
import 'package:jellyfin_dart/jellyfin_dart.dart';

// Create client
final client = JellyfinClient(
  baseUrl: 'https://your-jellyfin-server.com',
  deviceId: 'your-device-id',
  clientName: 'Your App Name',
  clientVersion: '1.0.0',
);

// Authenticate
final authResult = await client.authentication.authenticateByName(
  username: 'your-username',
  password: 'your-password',
);

if (authResult.isSuccess) {
  print('Logged in as: ${authResult.data!.user.name}');
  
  // Get library items
  final libraryResult = await client.library.getItems(
    includeItemTypes: ['Movie', 'Series'],
    limit: 20,
  );
  
  if (libraryResult.isSuccess) {
    for (final item in libraryResult.data!.items) {
      print('${item.name} (${item.type})');
    }
  }
}

// Clean up
client.dispose();
```

## API Endpoints

### Authentication
- `authenticateByName()` - Username/password authentication
- `authenticateWithApiKey()` - API key authentication
- `logout()` - End current session
- `getCurrentSession()` - Get session information

### Library
- `getLibraries()` - Get all libraries/collections
- `getItems()` - Get items with filtering and pagination
- `getItem()` - Get specific item by ID
- `search()` - Search for items
- `getLatest()` - Get latest added items
- `getResumeItems()` - Get continue watching items

### Playback
- `getStreamUrl()` - Get direct streaming URL
- `getPlaybackInfo()` - Get playback information and media sources
- `reportPlaybackStart()` - Report playback started
- `reportPlaybackProgress()` - Report playback progress
- `reportPlaybackStopped()` - Report playback stopped
- `getSubtitleUrl()` - Get subtitle stream URL

### User Management
- `getCurrentUser()` - Get current user info
- `getAllUsers()` - Get all users (admin only)
- `updateUserConfiguration()` - Update user preferences
- `markPlayed()` / `markUnplayed()` - Mark items as played/unplayed
- `addToFavorites()` / `removeFromFavorites()` - Manage favorites
- `updatePlaybackPosition()` - Update resume position

### System
- `getSystemInfo()` - Get detailed system information
- `getPublicSystemInfo()` - Get public system info (no auth)
- `ping()` - Ping server
- `getConfiguration()` - Get server configuration
- `getLogs()` - Get server logs (admin only)

## Error Handling

All API calls return a `JellyfinResponse<T>` object:

```dart
final response = await client.library.getItems();

if (response.isSuccess) {
  // Use response.data
  final items = response.data!.items;
} else {
  // Handle error
  print('Error: ${response.message}');
  print('Status Code: ${response.statusCode}');
}

// Or use dataOrThrow for exception-based handling
try {
  final items = response.dataOrThrow.items;
} on JellyfinException catch (e) {
  print('Jellyfin error: ${e.message}');
}
```

## Device Profiles

The client automatically provides a comprehensive device profile supporting:
- **Video**: H.264, H.265/HEVC, AV1, VP8, VP9
- **Audio**: AAC, MP3, AC3, E-AC3, FLAC, ALAC, Vorbis, Opus, DTS
- **Containers**: MP4, MKV, WebM
- **Subtitles**: VTT, ASS, SSA (external)
- **Transcoding**: HLS and WebM fallbacks

## Requirements

- Dart SDK 3.0.0 or higher
- Jellyfin Server 10.8.0 or higher (recommended)

## License

MIT License - see LICENSE file for details.
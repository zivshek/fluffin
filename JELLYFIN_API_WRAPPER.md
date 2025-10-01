# Jellyfin Dart API Wrapper

We've built a comprehensive Jellyfin API wrapper that can be used both within Fluffin and as a standalone package for the Dart/Flutter community.

## 🎯 Why We Built This

- **No existing Dart wrapper**: There wasn't a comprehensive Jellyfin API client for Dart/Flutter
- **Type safety**: Full Dart type definitions for all API responses
- **Better error handling**: Structured responses with proper exception handling
- **Future package**: Can be published as a standalone package for the community

## 📁 Package Structure

```
lib/jellyfin_dart/
├── jellyfin_client.dart          # Main client class
├── jellyfin_dart.dart            # Package exports
├── models/
│   └── jellyfin_response.dart    # Response wrapper & exceptions
├── endpoints/
│   ├── authentication.dart       # Auth & session management
│   ├── library.dart             # Library & media browsing
│   ├── playback.dart            # Streaming & playback reporting
│   ├── user.dart                # User management & preferences
│   └── system.dart              # System info & administration
├── pubspec.yaml                 # Package specification
└── README.md                    # Package documentation
```

## 🚀 Key Features

### Complete API Coverage
- **Authentication**: Username/password, API keys, session management
- **Library**: Browse, search, filter, pagination, latest items
- **Playback**: Streaming URLs, device profiles, progress reporting
- **User Management**: Preferences, favorites, playback positions
- **System**: Server info, configuration, logs, admin functions

### Developer Experience
- **Type Safety**: All responses are properly typed
- **Error Handling**: `JellyfinResponse<T>` wrapper with success/error states
- **Async/Await**: Modern Dart async patterns
- **Automatic Headers**: Authentication and device info handled automatically
- **Resource Management**: Proper disposal and cleanup

### Production Ready
- **Device Profiles**: Comprehensive media format support
- **Session Reporting**: Proper playback progress tracking
- **Error Recovery**: Handles token expiration and network issues
- **Performance**: Efficient HTTP client with connection pooling

## 💡 Usage Examples

### Basic Authentication & Library Access
```dart
final client = JellyfinClient(
  baseUrl: 'https://jellyfin.example.com',
  deviceId: 'my-app-device',
  clientName: 'My App',
);

// Authenticate
final authResult = await client.authentication.authenticateByName(
  username: 'user',
  password: 'pass',
);

// Get library items
final itemsResult = await client.library.getItems(
  includeItemTypes: ['Movie', 'Series'],
  limit: 50,
);
```

### Video Streaming
```dart
// Get streaming URL
final streamUrl = client.playback.getStreamUrl(itemId);

// Report playback events
await client.playback.reportPlaybackStart(
  itemId: itemId,
  positionTicks: 0,
);

await client.playback.reportPlaybackProgress(
  itemId: itemId,
  positionTicks: currentPosition,
  isPaused: false,
);
```

### Search & Discovery
```dart
// Search for content
final searchResults = await client.library.search(
  searchTerm: 'star wars',
  includeItemTypes: ['Movie'],
  limit: 20,
);

// Get latest additions
final latestItems = await client.library.getLatest(
  includeItemTypes: ['Movie', 'Episode'],
  limit: 10,
);

// Get continue watching
final resumeItems = await client.library.getResumeItems(limit: 10);
```

## 🔧 Integration with Fluffin

The wrapper is seamlessly integrated into Fluffin:

### JellyfinProvider Updates
- Replaced direct HTTP calls with wrapper methods
- Improved error handling and type safety
- Cleaner code with better separation of concerns

### Search Functionality
- Real server-side search instead of client-side filtering
- Better performance and more accurate results
- Proper pagination support

### Player Integration
- Proper playback reporting to Jellyfin server
- Session management and progress tracking
- Device profile for optimal streaming

## 📦 Future Package Publication

The wrapper is designed to be published as `jellyfin_dart` on pub.dev:

### Package Benefits
- **Community Value**: First comprehensive Jellyfin client for Dart
- **Reusability**: Other Flutter apps can use it
- **Maintenance**: Shared maintenance burden
- **Documentation**: Comprehensive API documentation

### Publication Checklist
- ✅ Complete API coverage
- ✅ Type safety and error handling
- ✅ Comprehensive documentation
- ✅ Example usage
- ✅ Proper package structure
- ⏳ Unit tests (future)
- ⏳ Integration tests (future)
- ⏳ CI/CD pipeline (future)

## 🎉 Benefits for Fluffin

1. **Better Architecture**: Clean separation between API and UI logic
2. **Type Safety**: Compile-time error checking for API responses
3. **Error Handling**: Structured error responses with proper messaging
4. **Maintainability**: Easier to update and extend API functionality
5. **Testing**: Easier to mock and test API interactions
6. **Performance**: Optimized HTTP client with proper connection management

## 🔮 Future Enhancements

- **Caching**: Response caching for better performance
- **Offline Support**: Local database integration
- **Real-time Updates**: WebSocket support for live updates
- **Advanced Features**: Plugins, live TV, sync play support
- **Testing**: Comprehensive test suite
- **Documentation**: Interactive API documentation

The Jellyfin Dart wrapper provides a solid foundation for Fluffin while also contributing valuable tooling to the Flutter/Dart ecosystem.
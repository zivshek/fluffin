import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import '../jellyfin_dart/jellyfin_dart.dart';

class JellyfinProvider extends ChangeNotifier {
  JellyfinClient? _client;

  JellyfinUser? _currentUser;
  List<MediaItem> _libraryItems = [];
  bool _isLoading = false;
  String? _error;

  JellyfinUser? get currentUser => _currentUser;
  List<MediaItem> get libraryItems => _libraryItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn =>
      _currentUser != null && _client?.isAuthenticated == true;

  JellyfinClient? get client => _client;

  Future<bool> login(String serverUrl, String username, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Create new client
      _client = JellyfinClient(
        baseUrl: serverUrl,
        deviceId: 'fluffin-client',
        clientName: 'Fluffin',
        clientVersion: '1.0.0',
      );

      // Authenticate
      final authResponse = await _client!.authentication.authenticateByName(
        username: username,
        password: password,
      );

      if (authResponse.isSuccess) {
        _currentUser = authResponse.data!.user;

        // Save login info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_url', serverUrl);
        await prefs.setString('username', username);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = authResponse.message ?? 'Login failed';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}'; // TODO: Localize this
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadLibrary() async {
    if (!isLoggedIn || _client == null) return;

    _setLoading(true);
    try {
      final response = await _client!.library.getItems(
        includeItemTypes: ['Movie', 'Episode', 'Series'],
        limit: 100,
      );

      if (response.isSuccess) {
        _libraryItems = response.data!.items;
        _error = null;
      } else {
        _error = response.message ?? 'Failed to load library';
      }
    } catch (e) {
      _error = 'Failed to load library: ${e.toString()}'; // TODO: Localize this
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> logout() async {
    if (_client != null) {
      try {
        await _client!.authentication.logout();
      } catch (e) {
        // Ignore logout errors
      }
      _client?.dispose();
      _client = null;
    }

    _currentUser = null;
    _libraryItems = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_url');
    await prefs.remove('username');

    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url');
    final username = prefs.getString('username');

    if (serverUrl != null && username != null) {
      // Create client for potential future auto-login
      _client = JellyfinClient(
        baseUrl: serverUrl,
        deviceId: 'fluffin-client',
        clientName: 'Fluffin',
        clientVersion: '1.0.0',
      );
      // Note: In a real app, you'd want to store and use refresh tokens
      // For now, user will need to re-enter password
    }
  }

  /// Get streaming URL for a media item
  String? getStreamUrl(String itemId) {
    if (_client == null || !isLoggedIn) return null;
    return _client!.playback.getStreamUrl(itemId);
  }

  /// Search for media items
  Future<List<MediaItem>> searchItems(String query) async {
    if (_client == null || !isLoggedIn) return [];

    try {
      final response = await _client!.library.search(
        searchTerm: query,
        includeItemTypes: ['Movie', 'Episode', 'Series'],
        limit: 50,
      );

      return response.isSuccess ? response.data! : [];
    } catch (e) {
      return [];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

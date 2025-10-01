import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import '../services/jellyfin_api.dart';

class JellyfinProvider extends ChangeNotifier {
  final JellyfinApi _api = JellyfinApi();

  JellyfinUser? _currentUser;
  List<MediaItem> _libraryItems = [];
  bool _isLoading = false;
  String? _error;

  JellyfinUser? get currentUser => _currentUser;
  List<MediaItem> get libraryItems => _libraryItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  JellyfinApi get api => _api;

  Future<bool> login(String serverUrl, String username, String password) async {
    _setLoading(true);
    _error = null;

    try {
      _api.setServerUrl(serverUrl);
      _currentUser = await _api.authenticateByName(username, password);

      // Save login info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', serverUrl);
      await prefs.setString('username', username);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}'; // TODO: Localize this
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadLibrary() async {
    if (!isLoggedIn) return;

    _setLoading(true);
    try {
      _libraryItems = await _api.getLibraryItems(
        includeItemTypes: ['Movie', 'Episode', 'Series'],
        limit: 100,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load library: ${e.toString()}'; // TODO: Localize this
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> logout() async {
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
      _api.setServerUrl(serverUrl);
      // Note: In a real app, you'd want to store and use refresh tokens
      // For now, user will need to re-enter password
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

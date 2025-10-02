import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_history.dart';

class LoginHistoryService {
  static const String _serverHistoryKey = 'server_history';
  static const String _userHistoryKey = 'user_history';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Get list of previously used servers
  static Future<List<ServerHistory>> getServerHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_serverHistoryKey) ?? [];

    return historyJson
        .map((json) => ServerHistory.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
  }

  /// Add or update server in history
  static Future<void> addServerToHistory(String url, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getServerHistory();

    // Remove existing entry for this URL
    history.removeWhere((server) => server.url == url);

    // Add new entry at the beginning
    history.insert(
        0,
        ServerHistory(
          url: url,
          name: name,
          lastUsed: DateTime.now(),
        ));

    // Keep only last 10 servers
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }

    // Save back to preferences
    final historyJson =
        history.map((server) => jsonEncode(server.toJson())).toList();

    await prefs.setStringList(_serverHistoryKey, historyJson);
  }

  /// Get list of previously logged in users
  static Future<List<UserHistory>> getUserHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_userHistoryKey) ?? [];

    return historyJson
        .map((json) => UserHistory.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
  }

  /// Add or update user in history
  static Future<void> addUserToHistory({
    required String username,
    required String serverUrl,
    String? displayName,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getUserHistory();

    // Remove existing entry for this user/server combination
    history.removeWhere(
        (user) => user.username == username && user.serverUrl == serverUrl);

    // Add new entry at the beginning
    history.insert(
        0,
        UserHistory(
          username: username,
          serverUrl: serverUrl,
          displayName: displayName,
          lastLogin: DateTime.now(),
        ));

    // Keep only last 20 users
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    // Save back to preferences
    final historyJson =
        history.map((user) => jsonEncode(user.toJson())).toList();

    await prefs.setStringList(_userHistoryKey, historyJson);

    // Store password securely if provided
    if (password != null) {
      final passwordKey = _getPasswordKey(username, serverUrl);
      await _secureStorage.write(key: passwordKey, value: password);
    }
  }

  /// Remove user from history
  static Future<void> removeUserFromHistory(
      String username, String serverUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getUserHistory();

    history.removeWhere(
        (user) => user.username == username && user.serverUrl == serverUrl);

    final historyJson =
        history.map((user) => jsonEncode(user.toJson())).toList();

    await prefs.setStringList(_userHistoryKey, historyJson);

    // Also remove stored password
    await removeStoredPassword(username, serverUrl);
  }

  /// Get stored password for a user
  static Future<String?> getStoredPassword(
      String username, String serverUrl) async {
    final passwordKey = _getPasswordKey(username, serverUrl);
    return await _secureStorage.read(key: passwordKey);
  }

  /// Check if user has stored credentials
  static Future<bool> hasStoredCredentials(
      String username, String serverUrl) async {
    final password = await getStoredPassword(username, serverUrl);
    return password != null && password.isNotEmpty;
  }

  /// Remove stored password for a user
  static Future<void> removeStoredPassword(
      String username, String serverUrl) async {
    final passwordKey = _getPasswordKey(username, serverUrl);
    await _secureStorage.delete(key: passwordKey);
  }

  /// Generate a unique key for storing passwords
  static String _getPasswordKey(String username, String serverUrl) {
    return 'password_${username}_${Uri.parse(serverUrl).host}';
  }

  /// Clear all history and stored passwords
  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverHistoryKey);
    await prefs.remove(_userHistoryKey);

    // Clear all stored passwords
    await _secureStorage.deleteAll();
  }
}

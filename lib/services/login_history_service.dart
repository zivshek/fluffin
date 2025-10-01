import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_history.dart';

class LoginHistoryService {
  static const String _serverHistoryKey = 'server_history';
  static const String _userHistoryKey = 'user_history';

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
  }

  /// Clear all history
  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverHistoryKey);
    await prefs.remove(_userHistoryKey);
  }
}

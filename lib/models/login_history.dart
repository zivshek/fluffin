class ServerHistory {
  final String url;
  final String name;
  final DateTime lastUsed;

  ServerHistory({
    required this.url,
    required this.name,
    required this.lastUsed,
  });

  factory ServerHistory.fromJson(Map<String, dynamic> json) {
    return ServerHistory(
      url: json['url'] as String,
      name: json['name'] as String,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }
}

class UserHistory {
  final String username;
  final String serverUrl;
  final String? displayName;
  final DateTime lastLogin;

  UserHistory({
    required this.username,
    required this.serverUrl,
    this.displayName,
    required this.lastLogin,
  });

  factory UserHistory.fromJson(Map<String, dynamic> json) {
    return UserHistory(
      username: json['username'] as String,
      serverUrl: json['serverUrl'] as String,
      displayName: json['displayName'] as String?,
      lastLogin: DateTime.parse(json['lastLogin'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'serverUrl': serverUrl,
      'displayName': displayName,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }
}

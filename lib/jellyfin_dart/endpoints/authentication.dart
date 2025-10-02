import '../jellyfin_client.dart';
import '../models/jellyfin_response.dart';
import '../../models/jellyfin_user.dart';

class AuthenticationEndpoint {
  final JellyfinClient _client;

  AuthenticationEndpoint(this._client);

  /// Authenticate user by username and password
  Future<JellyfinResponse<AuthenticationResult>> authenticateByName({
    required String username,
    required String password,
  }) async {
    final response = await _client.requestWithoutAuth<Map<String, dynamic>>(
      'POST',
      '/Users/AuthenticateByName',
      data: {
        'Username': username,
        'Pw': password,
      },
    );

    if (response.isSuccess) {
      final data = response.data!;
      final accessToken = data['AccessToken'] as String?;
      final userData = data['User'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        return JellyfinResponse.error(
          message: 'Invalid response from server',
          statusCode: response.statusCode,
        );
      }

      final user = JellyfinUser.fromJson(userData);

      // Set authentication in client
      _client.setAuthentication(accessToken, user.id);

      return JellyfinResponse.success(
        data: AuthenticationResult(
          accessToken: accessToken,
          user: user,
        ),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Authentication failed',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Authenticate with API key
  Future<JellyfinResponse<bool>> authenticateWithApiKey(String apiKey) async {
    // Set API key as token for system calls
    _client.setAuthentication(apiKey, 'system');

    // Verify by making a system info call
    final systemResponse = await _client.system.getSystemInfo();

    if (systemResponse.isSuccess) {
      return JellyfinResponse.success(data: true, statusCode: 200);
    } else {
      _client.clearAuthentication();
      return JellyfinResponse.error(
        message: 'Invalid API key',
        statusCode: 401,
      );
    }
  }

  /// Logout current user
  Future<JellyfinResponse<bool>> logout() async {
    if (!_client.isAuthenticated) {
      return JellyfinResponse.success(data: true, statusCode: 200);
    }

    final response = await _client.request<void>(
      'POST',
      '/Sessions/Logout',
    );

    // Clear authentication regardless of response
    _client.clearAuthentication();

    if (response.isSuccess) {
      return JellyfinResponse.success(
          data: true, statusCode: response.statusCode);
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Logout failed',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get current session info
  Future<JellyfinResponse<SessionInfo>> getCurrentSession() async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Sessions',
      queryParameters: {
        'ControllableByUserId': _client.userId,
      },
    );

    if (response.isSuccess) {
      final sessions = response.data!['Items'] as List;
      if (sessions.isNotEmpty) {
        final currentSession = sessions.firstWhere(
          (session) => session['DeviceId'] == _client.deviceId,
          orElse: () => sessions.first,
        );

        return JellyfinResponse.success(
          data: SessionInfo.fromJson(currentSession),
          statusCode: response.statusCode,
        );
      }
    }

    return JellyfinResponse.error(
      message: response.message ?? 'No active session found',
      statusCode: response.statusCode,
      error: response.error,
    );
  }
}

class AuthenticationResult {
  final String accessToken;
  final JellyfinUser user;

  AuthenticationResult({
    required this.accessToken,
    required this.user,
  });
}

class SessionInfo {
  final String id;
  final String deviceId;
  final String deviceName;
  final String clientName;
  final String? applicationVersion;
  final bool isActive;
  final DateTime lastActivityDate;

  SessionInfo({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.clientName,
    this.applicationVersion,
    required this.isActive,
    required this.lastActivityDate,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['Id'] as String,
      deviceId: json['DeviceId'] as String,
      deviceName: json['DeviceName'] as String,
      clientName: json['Client'] as String,
      applicationVersion: json['ApplicationVersion'] as String?,
      isActive: json['IsActive'] as bool? ?? false,
      lastActivityDate: DateTime.parse(json['LastActivityDate'] as String),
    );
  }
}

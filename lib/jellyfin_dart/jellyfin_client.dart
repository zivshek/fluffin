import 'package:dio/dio.dart';
import 'endpoints/authentication.dart';
import 'endpoints/library.dart';
import 'endpoints/playback.dart';
import 'endpoints/user.dart';
import 'endpoints/system.dart';
import 'models/jellyfin_response.dart';

/// Main Jellyfin API client
class JellyfinClient {
  late final Dio _dio;
  late final String _baseUrl;
  String? _accessToken;
  String? _userId;
  String? _deviceId;
  String? _clientName;
  String? _clientVersion;

  // API endpoints
  late final AuthenticationEndpoint authentication;
  late final LibraryEndpoint library;
  late final PlaybackEndpoint playback;
  late final UserEndpoint user;
  late final SystemEndpoint system;

  JellyfinClient({
    required String baseUrl,
    String? deviceId,
    String? clientName,
    String? clientVersion,
    Duration? timeout,
  }) {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _deviceId = deviceId ?? 'fluffin-client';
    _clientName = clientName ?? 'Fluffin';
    _clientVersion = clientVersion ?? '1.0.0';

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: timeout ?? const Duration(seconds: 30),
      receiveTimeout: timeout ?? const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': '$_clientName/$_clientVersion',
      },
    ));

    _setupInterceptors();
    _initializeEndpoints();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add authentication header if available
        if (_accessToken != null) {
          options.headers['Authorization'] =
              'MediaBrowser Client="$_clientName", Device="$_deviceId", DeviceId="$_deviceId", Version="$_clientVersion", Token="$_accessToken"';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        // Handle common Jellyfin errors
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          _accessToken = null;
          _userId = null;
        }
        handler.next(error);
      },
    ));
  }

  void _initializeEndpoints() {
    authentication = AuthenticationEndpoint(this);
    library = LibraryEndpoint(this);
    playback = PlaybackEndpoint(this);
    user = UserEndpoint(this);
    system = SystemEndpoint(this);
  }

  /// Internal method for making HTTP requests
  Future<JellyfinResponse<T>> request<T>(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.request(
        path,
        options: Options(method: method),
        queryParameters: queryParameters,
        data: data,
      );

      return JellyfinResponse<T>.success(
        data: fromJson != null ? fromJson(response.data) : response.data,
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return JellyfinResponse<T>.error(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode ?? 0,
        error: e,
      );
    } catch (e) {
      return JellyfinResponse<T>.error(
        message: e.toString(),
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Set authentication token and user ID
  void setAuthentication(String accessToken, String userId) {
    _accessToken = accessToken;
    _userId = userId;
  }

  /// Clear authentication
  void clearAuthentication() {
    _accessToken = null;
    _userId = null;
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current user ID
  String? get userId => _userId;

  /// Get device ID
  String get deviceId => _deviceId!;

  /// Get base URL
  String get baseUrl => _baseUrl;

  /// Check if client is authenticated
  bool get isAuthenticated => _accessToken != null && _userId != null;

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}

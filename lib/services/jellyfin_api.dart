import 'package:dio/dio.dart';
import '../models/index.dart';

class JellyfinApi {
  late final Dio _dio;
  String? _baseUrl;
  String? _accessToken;
  String? _userId;

  JellyfinApi() {
    _dio = Dio();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] =
              'MediaBrowser Token="$_accessToken"';
        }
        handler.next(options);
      },
    ));
  }

  void setServerUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<JellyfinUser> authenticateByName(
      String username, String password) async {
    final response = await _dio.post(
      '$_baseUrl/Users/authenticatebyname',
      data: {
        'Username': username,
        'Pw': password,
      },
    );

    _accessToken = response.data['AccessToken'];
    _userId = response.data['User']['Id'];

    return JellyfinUser.fromJson(response.data['User']);
  }

  Future<List<MediaItem>> getLibraryItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    int? startIndex,
  }) async {
    final queryParams = <String, dynamic>{
      'UserId': _userId,
      'Recursive': true,
      'Fields':
          'BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear,Status,EndDate',
    };

    if (parentId != null) {
      queryParams['ParentId'] = parentId;
    }
    if (includeItemTypes != null) {
      queryParams['IncludeItemTypes'] = includeItemTypes.join(',');
    }
    if (limit != null) {
      queryParams['Limit'] = limit;
    }
    if (startIndex != null) {
      queryParams['StartIndex'] = startIndex;
    }

    final response = await _dio.get(
      '$_baseUrl/Users/$_userId/Items',
      queryParameters: queryParams,
    );

    final items = (response.data['Items'] as List)
        .map((item) => MediaItem.fromJson(item))
        .toList();

    return items;
  }

  Future<String> getStreamUrl(
    String itemId, {
    String? audioStreamIndex,
    String? subtitleStreamIndex,
  }) async {
    final queryParams = <String, dynamic>{
      'UserId': _userId,
      'DeviceId': 'fluffin-client',
      'MediaSourceId': itemId,
      'Static': false,
    };

    if (audioStreamIndex != null) {
      queryParams['AudioStreamIndex'] = audioStreamIndex;
    }
    if (subtitleStreamIndex != null) {
      queryParams['SubtitleStreamIndex'] = subtitleStreamIndex;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$_baseUrl/Videos/$itemId/stream?$queryString&api_key=$_accessToken';
  }

  Future<void> reportPlaybackStart(String itemId, int positionTicks) async {
    await _dio.post(
      '$_baseUrl/Sessions/Playing',
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'MediaSourceId': itemId,
        'CanSeek': true,
        'IsMuted': false,
        'IsPaused': false,
        'RepeatMode': 'RepeatNone',
        'PlayMethod': 'DirectStream',
      },
    );
  }

  Future<void> reportPlaybackProgress(
      String itemId, int positionTicks, bool isPaused) async {
    await _dio.post(
      '$_baseUrl/Sessions/Playing/Progress',
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'MediaSourceId': itemId,
        'CanSeek': true,
        'IsMuted': false,
        'IsPaused': isPaused,
        'RepeatMode': 'RepeatNone',
        'PlayMethod': 'DirectStream',
      },
    );
  }

  Future<void> reportPlaybackStopped(String itemId, int positionTicks) async {
    await _dio.post(
      '$_baseUrl/Sessions/Playing/Stopped',
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'MediaSourceId': itemId,
      },
    );
  }
}

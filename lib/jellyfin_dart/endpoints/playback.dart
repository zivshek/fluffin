import '../jellyfin_client.dart';
import '../models/jellyfin_response.dart';

class PlaybackEndpoint {
  final JellyfinClient _client;

  PlaybackEndpoint(this._client);

  /// Get streaming URL for media item
  String getStreamUrl(
    String itemId, {
    String? audioStreamIndex,
    String? subtitleStreamIndex,
    int? maxStreamingBitrate,
    String? videoCodec,
    String? audioCodec,
    String? container,
    bool static = false,
  }) {
    final queryParams = <String, String>{
      'UserId': _client.userId!,
      'DeviceId': _client.deviceId,
      'MediaSourceId': itemId,
      'Static': static.toString(),
    };

    if (audioStreamIndex != null) {
      queryParams['AudioStreamIndex'] = audioStreamIndex;
    }
    if (subtitleStreamIndex != null) {
      queryParams['SubtitleStreamIndex'] = subtitleStreamIndex;
    }
    if (maxStreamingBitrate != null) {
      queryParams['MaxStreamingBitrate'] = maxStreamingBitrate.toString();
    }
    if (videoCodec != null) {
      queryParams['VideoCodec'] = videoCodec;
    }
    if (audioCodec != null) {
      queryParams['AudioCodec'] = audioCodec;
    }
    if (container != null) {
      queryParams['Container'] = container;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final finalUrl = '${_client.baseUrl}/Videos/$itemId/stream?$queryString';
    return finalUrl;
  }

  /// Get playback info for an item
  Future<JellyfinResponse<PlaybackInfo>> getPlaybackInfo(
    String itemId, {
    String? userId,
    int? maxStreamingBitrate,
    int? startTimeTicks,
    String? audioStreamIndex,
    String? subtitleStreamIndex,
  }) async {
    final response = await _client.request<Map<String, dynamic>>(
      'POST',
      '/Items/$itemId/PlaybackInfo',
      queryParameters: {
        'UserId': userId ?? _client.userId!,
      },
      data: {
        'DeviceProfile': _getDeviceProfile(),
        if (maxStreamingBitrate != null)
          'MaxStreamingBitrate': maxStreamingBitrate,
        if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null)
          'SubtitleStreamIndex': subtitleStreamIndex,
      },
    );

    if (response.isSuccess) {
      return JellyfinResponse.success(
        data: PlaybackInfo.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get playback info',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Report playback start
  Future<JellyfinResponse<bool>> reportPlaybackStart({
    required String itemId,
    required int positionTicks,
    String? mediaSourceId,
    bool canSeek = true,
    bool isMuted = false,
    bool isPaused = false,
    String? repeatMode,
    String? playMethod,
  }) async {
    final response = await _client.request<void>(
      'POST',
      '/Sessions/Playing',
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'MediaSourceId': mediaSourceId ?? itemId,
        'CanSeek': canSeek,
        'IsMuted': isMuted,
        'IsPaused': isPaused,
        'RepeatMode': repeatMode ?? 'RepeatNone',
        'PlayMethod': playMethod ?? 'DirectStream',
      },
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Report playback progress
  Future<JellyfinResponse<bool>> reportPlaybackProgress({
    required String itemId,
    required int positionTicks,
    String? mediaSourceId,
    bool canSeek = true,
    bool isMuted = false,
    bool isPaused = false,
    String? repeatMode,
    String? playMethod,
  }) async {
    final response = await _client.request<void>(
      'POST',
      '/Sessions/Playing/Progress',
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'MediaSourceId': mediaSourceId ?? itemId,
        'CanSeek': canSeek,
        'IsMuted': isMuted,
        'IsPaused': isPaused,
        'RepeatMode': repeatMode ?? 'RepeatNone',
        'PlayMethod': playMethod ?? 'DirectStream',
      },
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Report playback stopped
  Future<JellyfinResponse<bool>> reportPlaybackStopped({
    required String itemId,
    required int positionTicks,
    String? mediaSourceId,
  }) async {
    final response = await _client.request<void>(
      'POST',
      '/Sessions/Playing/Stopped',
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'MediaSourceId': mediaSourceId ?? itemId,
      },
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Get subtitle stream
  String getSubtitleUrl(String itemId, int streamIndex,
      {String format = 'vtt'}) {
    return '${_client.baseUrl}/Videos/$itemId/Subtitles/$streamIndex/Stream.$format?api_key=${_client.accessToken}';
  }

  /// Basic device profile for media playback
  Map<String, dynamic> _getDeviceProfile() {
    return {
      'MaxStreamingBitrate': 120000000,
      'MaxStaticBitrate': 100000000,
      'MusicStreamingTranscodingBitrate': 384000,
      'DirectPlayProfiles': [
        {
          'Container': 'webm',
          'Type': 'Video',
          'VideoCodec': 'vp8,vp9,av1',
          'AudioCodec': 'vorbis,opus'
        },
        {
          'Container': 'mp4,m4v',
          'Type': 'Video',
          'VideoCodec': 'h264,h265,hevc,av1',
          'AudioCodec': 'aac,mp3,ac3,eac3,flac,alac'
        },
        {
          'Container': 'mkv',
          'Type': 'Video',
          'VideoCodec': 'h264,h265,hevc,av1,vp8,vp9',
          'AudioCodec': 'aac,mp3,ac3,eac3,flac,alac,vorbis,opus,dts'
        }
      ],
      'TranscodingProfiles': [
        {
          'Container': 'ts',
          'Type': 'Video',
          'VideoCodec': 'h264',
          'AudioCodec': 'aac',
          'Protocol': 'hls'
        },
        {
          'Container': 'webm',
          'Type': 'Video',
          'VideoCodec': 'vpx',
          'AudioCodec': 'vorbis',
          'Protocol': 'http'
        }
      ],
      'ContainerProfiles': [],
      'CodecProfiles': [],
      'SubtitleProfiles': [
        {'Format': 'vtt', 'Method': 'External'},
        {'Format': 'ass', 'Method': 'External'},
        {'Format': 'ssa', 'Method': 'External'}
      ]
    };
  }
}

class PlaybackInfo {
  final List<MediaSource> mediaSources;
  final String playSessionId;

  PlaybackInfo({
    required this.mediaSources,
    required this.playSessionId,
  });

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) {
    return PlaybackInfo(
      mediaSources: (json['MediaSources'] as List? ?? [])
          .map((source) => MediaSource.fromJson(source))
          .toList(),
      playSessionId: json['PlaySessionId'] as String? ?? '',
    );
  }
}

class MediaSource {
  final String id;
  final String? container;
  final int? bitrate;
  final String? path;
  final String? protocol;
  final int? runTimeTicks;
  final bool supportsDirectStream;
  final bool supportsTranscoding;

  MediaSource({
    required this.id,
    this.container,
    this.bitrate,
    this.path,
    this.protocol,
    this.runTimeTicks,
    required this.supportsDirectStream,
    required this.supportsTranscoding,
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      id: json['Id'] as String,
      container: json['Container'] as String?,
      bitrate: json['Bitrate'] as int?,
      path: json['Path'] as String?,
      protocol: json['Protocol'] as String?,
      runTimeTicks: json['RunTimeTicks'] as int?,
      supportsDirectStream: json['SupportsDirectStream'] as bool? ?? false,
      supportsTranscoding: json['SupportsTranscoding'] as bool? ?? false,
    );
  }
}

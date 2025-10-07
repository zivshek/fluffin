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
    int? startTimeTicks,
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
    if (startTimeTicks != null) {
      queryParams['StartTimeTicks'] = startTimeTicks.toString();
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
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? mediaSourceId,
  }) async {
    final response = await _client.request<Map<String, dynamic>>(
      'POST',
      '/Items/$itemId/PlaybackInfo',
      data: {
        'UserId': userId ?? _client.userId!,
        'DeviceProfile': _getDeviceProfile(),
        'IsPlayback': true,
        'AutoOpenLiveStream': true,
        if (maxStreamingBitrate != null)
          'MaxStreamingBitrate': maxStreamingBitrate,
        if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null)
          'SubtitleStreamIndex': subtitleStreamIndex,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
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

  /// Device profile optimized for Media Kit - based on Streamyfin's approach
  Map<String, dynamic> _getDeviceProfile() {
    return {
      'Name': 'Fluffin Media Kit Player',
      'MaxStaticBitrate': 999999999,
      'MaxStreamingBitrate': 999999999,
      'CodecProfiles': [
        {
          'Type': 'Video',
          'Codec': 'h264,mpeg4,divx,xvid,wmv,vc1,vp8,vp9,av1',
        },
        {
          'Type': 'Video',
          'Codec': 'hevc,h265',
          'Conditions': [
            {
              'Condition': 'LessThanEqual',
              'Property': 'VideoLevel',
              'Value': '153',
              'IsRequired': false,
            },
            {
              'Condition': 'NotEquals',
              'Property': 'VideoRangeType',
              'Value': 'DOVI', // No Dolby Vision
              'IsRequired': true,
            },
          ],
        },
        {
          'Type': 'Audio',
          'Codec': 'aac,ac3,eac3,mp3,flac,alac,opus,vorbis,pcm,wma,dts',
        },
      ],
      'DirectPlayProfiles': [
        {
          'Type': 'Video',
          'Container': 'mp4,mkv,avi,mov,flv,ts,m2ts,webm,ogv,3gp,hls',
          'VideoCodec':
              'h264,hevc,mpeg4,divx,xvid,wmv,vc1,vp8,vp9,av1,avi,mpeg,mpeg2video',
          'AudioCodec': 'aac,ac3,eac3,mp3,flac,alac,opus,vorbis,wma,dts,pcm',
        },
        {
          'Type': 'Audio',
          'Container': 'mp3,aac,flac,alac,wav,ogg,wma',
          'AudioCodec':
              'mp3,aac,flac,alac,opus,vorbis,wma,pcm,mpa,wav,ogg,oga,webma,ape',
        },
      ],
      'TranscodingProfiles': [
        {
          'Type': 'Video',
          'Context': 'Streaming',
          'Protocol': 'hls',
          'Container': 'ts',
          'VideoCodec': 'h264,hevc',
          'AudioCodec': 'aac,mp3,ac3,dts',
        },
        {
          'Type': 'Audio',
          'Context': 'Streaming',
          'Protocol': 'http',
          'Container': 'mp3',
          'AudioCodec': 'mp3',
          'MaxAudioChannels': '2',
        },
      ],
      'SubtitleProfiles': [
        {'Format': 'vtt', 'Method': 'External'},
        {'Format': 'ass', 'Method': 'External'},
        {'Format': 'ssa', 'Method': 'External'},
        {'Format': 'srt', 'Method': 'External'},
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
  final String? transcodingUrl;
  final bool supportsDirectStream;
  final bool supportsTranscoding;
  final List<MediaStream> mediaStreams;

  MediaSource({
    required this.id,
    this.container,
    this.bitrate,
    this.path,
    this.protocol,
    this.runTimeTicks,
    this.transcodingUrl,
    required this.supportsDirectStream,
    required this.supportsTranscoding,
    this.mediaStreams = const [],
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      id: json['Id'] as String,
      container: json['Container'] as String?,
      bitrate: json['Bitrate'] as int?,
      path: json['Path'] as String?,
      protocol: json['Protocol'] as String?,
      runTimeTicks: json['RunTimeTicks'] as int?,
      transcodingUrl: json['TranscodingUrl'] as String?,
      supportsDirectStream: json['SupportsDirectStream'] as bool? ?? false,
      supportsTranscoding: json['SupportsTranscoding'] as bool? ?? false,
      mediaStreams: (json['MediaStreams'] as List<dynamic>? ?? [])
          .map((stream) => MediaStream.fromJson(stream as Map<String, dynamic>))
          .toList(),
    );
  }

  List<MediaStream> get audioStreams =>
      mediaStreams.where((stream) => stream.type == 'Audio').toList();

  List<MediaStream> get subtitleStreams =>
      mediaStreams.where((stream) => stream.type == 'Subtitle').toList();
}

class MediaStream {
  final int index;
  final String type;
  final String? codec;
  final String? language;
  final String? displayTitle;
  final bool isDefault;
  final bool isForced;
  final String? title;

  MediaStream({
    required this.index,
    required this.type,
    this.codec,
    this.language,
    this.displayTitle,
    this.isDefault = false,
    this.isForced = false,
    this.title,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) {
    return MediaStream(
      index: json['Index'] as int,
      type: json['Type'] as String,
      codec: json['Codec'] as String?,
      language: json['Language'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      isDefault: json['IsDefault'] as bool? ?? false,
      isForced: json['IsForced'] as bool? ?? false,
      title: json['Title'] as String?,
    );
  }

  String get displayName {
    if (displayTitle != null && displayTitle!.isNotEmpty) {
      return displayTitle!;
    }

    String name = language ?? 'Unknown';
    if (title != null && title!.isNotEmpty) {
      name += ' - $title';
    }
    if (codec != null) {
      name += ' - ${codec!.toUpperCase()}';
    }
    if (isDefault) {
      name += ' - Default';
    }
    if (isForced) {
      name += ' - Forced';
    }

    return name;
  }
}

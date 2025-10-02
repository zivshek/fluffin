import 'media_stream.dart';

class MediaSource {
  final String id;
  final String? container;
  final List<MediaStream>? mediaStreams;

  MediaSource({
    required this.id,
    this.container,
    this.mediaStreams,
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      id: json['Id'] as String? ?? '',
      container: json['Container'] as String?,
      mediaStreams: json['MediaStreams'] != null
          ? (json['MediaStreams'] as List)
              .map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Container': container,
      'MediaStreams': mediaStreams?.map((e) => e.toJson()).toList(),
    };
  }
}

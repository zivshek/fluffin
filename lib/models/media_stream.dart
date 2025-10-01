class MediaStream {
  final int index;
  final String type;
  final String? codec;
  final String? language;
  final String? displayTitle;
  final bool isDefault;

  MediaStream({
    required this.index,
    required this.type,
    this.codec,
    this.language,
    this.displayTitle,
    required this.isDefault,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) {
    return MediaStream(
      index: json['Index'] as int,
      type: json['Type'] as String,
      codec: json['Codec'] as String?,
      language: json['Language'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      isDefault: json['IsDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Index': index,
      'Type': type,
      'Codec': codec,
      'Language': language,
      'DisplayTitle': displayTitle,
      'IsDefault': isDefault,
    };
  }
}

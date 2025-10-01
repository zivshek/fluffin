class JellyfinUser {
  final String id;
  final String name;
  final String? primaryImageTag;

  JellyfinUser({
    required this.id,
    required this.name,
    this.primaryImageTag,
  });

  factory JellyfinUser.fromJson(Map<String, dynamic> json) {
    return JellyfinUser(
      id: json['Id'] as String,
      name: json['Name'] as String,
      primaryImageTag: json['PrimaryImageTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'PrimaryImageTag': primaryImageTag,
    };
  }
}

class MediaItem {
  final String id;
  final String name;
  final String type;
  final String? overview;
  final int? runTimeTicks;
  final String? primaryImageTag;
  final UserData? userData;
  final List<MediaSource>? mediaSources;

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.overview,
    this.runTimeTicks,
    this.primaryImageTag,
    this.userData,
    this.mediaSources,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['Id'] as String,
      name: json['Name'] as String,
      type: json['Type'] as String,
      overview: json['Overview'] as String?,
      runTimeTicks: json['RunTimeTicks'] as int?,
      primaryImageTag: json['PrimaryImageTag'] as String?,
      userData: json['UserData'] != null
          ? UserData.fromJson(json['UserData'] as Map<String, dynamic>)
          : null,
      mediaSources: json['MediaSources'] != null
          ? (json['MediaSources'] as List)
              .map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Type': type,
      'Overview': overview,
      'RunTimeTicks': runTimeTicks,
      'PrimaryImageTag': primaryImageTag,
      'UserData': userData?.toJson(),
      'MediaSources': mediaSources?.map((e) => e.toJson()).toList(),
    };
  }
}

class UserData {
  final bool played;
  final int? playbackPositionTicks;
  final bool isFavorite;

  UserData({
    required this.played,
    this.playbackPositionTicks,
    required this.isFavorite,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      played: json['Played'] as bool? ?? false,
      playbackPositionTicks: json['PlaybackPositionTicks'] as int?,
      isFavorite: json['IsFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Played': played,
      'PlaybackPositionTicks': playbackPositionTicks,
      'IsFavorite': isFavorite,
    };
  }
}

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
      id: json['Id'] as String,
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

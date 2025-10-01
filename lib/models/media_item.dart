import 'user_data.dart';
import 'media_source.dart';

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

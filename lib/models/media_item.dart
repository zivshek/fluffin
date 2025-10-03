import 'user_data.dart';
import 'media_source.dart';

class MediaItem {
  final String id;
  final String name;
  final String type;
  final String? overview;
  final int? runTimeTicks;
  final String? primaryImageTag;
  final DateTime? dateCreated;
  final DateTime? premiereDate;
  final int? productionYear;
  final String? seriesName;
  final int? seasonNumber;
  final int? episodeNumber;
  final UserData? userData;
  final List<MediaSource>? mediaSources;

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.overview,
    this.runTimeTicks,
    this.primaryImageTag,
    this.dateCreated,
    this.premiereDate,
    this.productionYear,
    this.seriesName,
    this.seasonNumber,
    this.episodeNumber,
    this.userData,
    this.mediaSources,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? 'Unknown',
      type: json['Type'] as String? ?? 'Unknown',
      overview: json['Overview'] as String?,
      runTimeTicks: json['RunTimeTicks'] as int?,
      primaryImageTag: json['PrimaryImageTag'] as String?,
      dateCreated: json['DateCreated'] != null
          ? DateTime.tryParse(json['DateCreated'] as String)
          : null,
      premiereDate: json['PremiereDate'] != null
          ? DateTime.tryParse(json['PremiereDate'] as String)
          : null,
      productionYear: json['ProductionYear'] as int?,
      seriesName: json['SeriesName'] as String?,
      seasonNumber: json['ParentIndexNumber'] as int?,
      episodeNumber: json['IndexNumber'] as int?,
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
      'DateCreated': dateCreated?.toIso8601String(),
      'PremiereDate': premiereDate?.toIso8601String(),
      'ProductionYear': productionYear,
      'SeriesName': seriesName,
      'ParentIndexNumber': seasonNumber,
      'IndexNumber': episodeNumber,
      'UserData': userData?.toJson(),
      'MediaSources': mediaSources?.map((e) => e.toJson()).toList(),
    };
  }
}

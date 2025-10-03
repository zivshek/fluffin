class UserData {
  final bool played;
  final int? playbackPositionTicks;
  final bool isFavorite;
  final DateTime? lastPlayedDate;

  UserData({
    required this.played,
    this.playbackPositionTicks,
    required this.isFavorite,
    this.lastPlayedDate,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      played: json['Played'] as bool? ?? false,
      playbackPositionTicks: json['PlaybackPositionTicks'] as int?,
      isFavorite: json['IsFavorite'] as bool? ?? false,
      lastPlayedDate: json['LastPlayedDate'] != null
          ? DateTime.tryParse(json['LastPlayedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Played': played,
      'PlaybackPositionTicks': playbackPositionTicks,
      'IsFavorite': isFavorite,
      'LastPlayedDate': lastPlayedDate?.toIso8601String(),
    };
  }
}

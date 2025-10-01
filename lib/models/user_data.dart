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

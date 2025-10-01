import '../jellyfin_client.dart';
import '../models/jellyfin_response.dart';
import '../../models/jellyfin_user.dart';

class UserEndpoint {
  final JellyfinClient _client;

  UserEndpoint(this._client);

  /// Get current user information
  Future<JellyfinResponse<JellyfinUser>> getCurrentUser() async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Users/${_client.userId}',
    );

    if (response.isSuccess) {
      return JellyfinResponse.success(
        data: JellyfinUser.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get user info',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get all users (admin only)
  Future<JellyfinResponse<List<JellyfinUser>>> getAllUsers() async {
    final response = await _client.request<List<dynamic>>(
      'GET',
      '/Users',
    );

    if (response.isSuccess) {
      final users =
          response.data!.map((user) => JellyfinUser.fromJson(user)).toList();

      return JellyfinResponse.success(
        data: users,
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get users',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Update user configuration
  Future<JellyfinResponse<bool>> updateUserConfiguration({
    String? audioLanguagePreference,
    String? subtitleLanguagePreference,
    bool? displayMissingEpisodes,
    bool? groupedFolders,
    String? subtitleMode,
    bool? enableLocalPassword,
    List<String>? orderedViews,
    List<String>? latestItemsExcludes,
    List<String>? myMediaExcludes,
    List<String>? hidePlayedInLatest,
    bool? rememberAudioSelections,
    bool? rememberSubtitleSelections,
    bool? enableNextEpisodeAutoPlay,
  }) async {
    final data = <String, dynamic>{};

    if (audioLanguagePreference != null) {
      data['AudioLanguagePreference'] = audioLanguagePreference;
    }
    if (subtitleLanguagePreference != null) {
      data['SubtitleLanguagePreference'] = subtitleLanguagePreference;
    }
    if (displayMissingEpisodes != null) {
      data['DisplayMissingEpisodes'] = displayMissingEpisodes;
    }
    if (groupedFolders != null) {
      data['GroupedFolders'] = groupedFolders;
    }
    if (subtitleMode != null) {
      data['SubtitleMode'] = subtitleMode;
    }
    if (enableLocalPassword != null) {
      data['EnableLocalPassword'] = enableLocalPassword;
    }
    if (orderedViews != null) {
      data['OrderedViews'] = orderedViews;
    }
    if (latestItemsExcludes != null) {
      data['LatestItemsExcludes'] = latestItemsExcludes;
    }
    if (myMediaExcludes != null) {
      data['MyMediaExcludes'] = myMediaExcludes;
    }
    if (hidePlayedInLatest != null) {
      data['HidePlayedInLatest'] = hidePlayedInLatest;
    }
    if (rememberAudioSelections != null) {
      data['RememberAudioSelections'] = rememberAudioSelections;
    }
    if (rememberSubtitleSelections != null) {
      data['RememberSubtitleSelections'] = rememberSubtitleSelections;
    }
    if (enableNextEpisodeAutoPlay != null) {
      data['EnableNextEpisodeAutoPlay'] = enableNextEpisodeAutoPlay;
    }

    final response = await _client.request<void>(
      'POST',
      '/Users/${_client.userId}/Configuration',
      data: data,
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Mark item as played
  Future<JellyfinResponse<bool>> markPlayed(String itemId) async {
    final response = await _client.request<void>(
      'POST',
      '/Users/${_client.userId}/PlayedItems/$itemId',
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Mark item as unplayed
  Future<JellyfinResponse<bool>> markUnplayed(String itemId) async {
    final response = await _client.request<void>(
      'DELETE',
      '/Users/${_client.userId}/PlayedItems/$itemId',
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Add item to favorites
  Future<JellyfinResponse<bool>> addToFavorites(String itemId) async {
    final response = await _client.request<void>(
      'POST',
      '/Users/${_client.userId}/FavoriteItems/$itemId',
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Remove item from favorites
  Future<JellyfinResponse<bool>> removeFromFavorites(String itemId) async {
    final response = await _client.request<void>(
      'DELETE',
      '/Users/${_client.userId}/FavoriteItems/$itemId',
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Update playback position
  Future<JellyfinResponse<bool>> updatePlaybackPosition({
    required String itemId,
    required int positionTicks,
  }) async {
    final response = await _client.request<void>(
      'POST',
      '/Users/${_client.userId}/PlayingItems/$itemId/Progress',
      queryParameters: {
        'PositionTicks': positionTicks.toString(),
      },
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Get user's display preferences
  Future<JellyfinResponse<DisplayPreferences>> getDisplayPreferences({
    required String displayPreferencesId,
    String? client,
  }) async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Users/${_client.userId}/DisplayPreferences/$displayPreferencesId',
      queryParameters: {
        if (client != null) 'client': client,
      },
    );

    if (response.isSuccess) {
      return JellyfinResponse.success(
        data: DisplayPreferences.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get display preferences',
      statusCode: response.statusCode,
      error: response.error,
    );
  }
}

class DisplayPreferences {
  final String id;
  final String viewType;
  final String sortBy;
  final String sortOrder;
  final int indexBy;
  final bool rememberIndexing;
  final int primaryImageHeight;
  final int primaryImageWidth;
  final Map<String, String> customPrefs;

  DisplayPreferences({
    required this.id,
    required this.viewType,
    required this.sortBy,
    required this.sortOrder,
    required this.indexBy,
    required this.rememberIndexing,
    required this.primaryImageHeight,
    required this.primaryImageWidth,
    required this.customPrefs,
  });

  factory DisplayPreferences.fromJson(Map<String, dynamic> json) {
    return DisplayPreferences(
      id: json['Id'] as String,
      viewType: json['ViewType'] as String? ?? 'Poster',
      sortBy: json['SortBy'] as String? ?? 'SortName',
      sortOrder: json['SortOrder'] as String? ?? 'Ascending',
      indexBy: json['IndexBy'] as int? ?? 0,
      rememberIndexing: json['RememberIndexing'] as bool? ?? false,
      primaryImageHeight: json['PrimaryImageHeight'] as int? ?? 400,
      primaryImageWidth: json['PrimaryImageWidth'] as int? ?? 300,
      customPrefs: Map<String, String>.from(json['CustomPrefs'] as Map? ?? {}),
    );
  }
}

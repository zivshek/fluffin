import '../jellyfin_client.dart';
import '../models/jellyfin_response.dart';
import '../../models/media_item.dart';

class LibraryEndpoint {
  final JellyfinClient _client;

  LibraryEndpoint(this._client);

  /// Get all libraries/collections
  Future<JellyfinResponse<List<LibraryInfo>>> getLibraries() async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Users/${_client.userId}/Views',
    );

    if (response.isSuccess) {
      final items = (response.data!['Items'] as List)
          .map((item) => LibraryInfo.fromJson(item))
          .toList();

      return JellyfinResponse.success(
        data: items,
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to load libraries',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get items from library with filtering options
  Future<JellyfinResponse<ItemsResult>> getItems({
    String? parentId,
    List<String>? includeItemTypes,
    List<String>? excludeItemTypes,
    List<String>? mediaTypes,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? startIndex,
    List<String>? fields,
    bool recursive = true,
  }) async {
    final queryParams = <String, dynamic>{
      'UserId': _client.userId,
      'Recursive': recursive,
    };

    if (parentId != null) {
      queryParams['ParentId'] = parentId;
    }
    if (includeItemTypes != null) {
      queryParams['IncludeItemTypes'] = includeItemTypes.join(',');
    }
    if (excludeItemTypes != null) {
      queryParams['ExcludeItemTypes'] = excludeItemTypes.join(',');
    }
    if (mediaTypes != null) {
      queryParams['MediaTypes'] = mediaTypes.join(',');
    }
    if (searchTerm != null) {
      queryParams['SearchTerm'] = searchTerm;
    }
    if (sortBy != null) {
      queryParams['SortBy'] = sortBy;
    }
    if (sortOrder != null) {
      queryParams['SortOrder'] = sortOrder;
    }
    if (limit != null) {
      queryParams['Limit'] = limit;
    }
    if (startIndex != null) {
      queryParams['StartIndex'] = startIndex;
    }
    if (fields != null) {
      queryParams['Fields'] = fields.join(',');
    }

    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Users/${_client.userId}/Items',
      queryParameters: queryParams,
    );

    if (response.isSuccess) {
      final data = response.data!;
      final items = (data['Items'] as List)
          .map((item) => MediaItem.fromJson(item))
          .toList();

      return JellyfinResponse.success(
        data: ItemsResult(
          items: items,
          totalRecordCount: data['TotalRecordCount'] as int? ?? items.length,
          startIndex: data['StartIndex'] as int? ?? 0,
        ),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to load items',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get a specific item by ID
  Future<JellyfinResponse<MediaItem>> getItem(String itemId) async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Users/${_client.userId}/Items/$itemId',
    );

    if (response.isSuccess) {
      return JellyfinResponse.success(
        data: MediaItem.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to load item',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Search for items
  Future<JellyfinResponse<List<MediaItem>>> search({
    required String searchTerm,
    List<String>? includeItemTypes,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      'UserId': _client.userId,
      'SearchTerm': searchTerm,
      'Recursive': true,
    };

    if (includeItemTypes != null) {
      queryParams['IncludeItemTypes'] = includeItemTypes.join(',');
    }
    if (limit != null) {
      queryParams['Limit'] = limit;
    }

    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Users/${_client.userId}/Items',
      queryParameters: queryParams,
    );

    if (response.isSuccess) {
      final items = (response.data!['Items'] as List)
          .map((item) => MediaItem.fromJson(item))
          .toList();

      return JellyfinResponse.success(
        data: items,
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Search failed',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get latest media items
  Future<JellyfinResponse<List<MediaItem>>> getLatest({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      'UserId': _client.userId,
    };

    if (parentId != null) {
      queryParams['ParentId'] = parentId;
    }
    if (includeItemTypes != null) {
      queryParams['IncludeItemTypes'] = includeItemTypes.join(',');
    }
    if (limit != null) {
      queryParams['Limit'] = limit;
    }

    final response = await _client.request<List<dynamic>>(
      'GET',
      '/Users/${_client.userId}/Items/Latest',
      queryParameters: queryParams,
    );

    if (response.isSuccess) {
      final items =
          response.data!.map((item) => MediaItem.fromJson(item)).toList();

      return JellyfinResponse.success(
        data: items,
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to load latest items',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get resume items (continue watching)
  Future<JellyfinResponse<List<MediaItem>>> getResumeItems({
    String? parentId,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      'UserId': _client.userId,
      'Recursive': true,
      'Fields': 'BasicSyncInfo,CanDelete,PrimaryImageAspectRatio',
      'EnableImageTypes': 'Primary,Backdrop,Banner,Thumb',
      'ImageTypeLimit': 1,
      'MediaTypes': 'Video',
    };

    if (parentId != null) {
      queryParams['ParentId'] = parentId;
    }
    if (limit != null) {
      queryParams['Limit'] = limit;
    }

    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/Users/${_client.userId}/Items/Resume',
      queryParameters: queryParams,
    );

    if (response.isSuccess) {
      final items = (response.data!['Items'] as List)
          .map((item) => MediaItem.fromJson(item))
          .toList();

      return JellyfinResponse.success(
        data: items,
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to load resume items',
      statusCode: response.statusCode,
      error: response.error,
    );
  }
}

class LibraryInfo {
  final String id;
  final String name;
  final String collectionType;
  final String? primaryImageTag;

  LibraryInfo({
    required this.id,
    required this.name,
    required this.collectionType,
    this.primaryImageTag,
  });

  factory LibraryInfo.fromJson(Map<String, dynamic> json) {
    return LibraryInfo(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? 'Unknown Library',
      collectionType: json['CollectionType'] as String? ?? 'mixed',
      primaryImageTag: json['PrimaryImageTag'] as String?,
    );
  }
}

class ItemsResult {
  final List<MediaItem> items;
  final int totalRecordCount;
  final int startIndex;

  ItemsResult({
    required this.items,
    required this.totalRecordCount,
    required this.startIndex,
  });

  bool get hasMore => startIndex + items.length < totalRecordCount;
}

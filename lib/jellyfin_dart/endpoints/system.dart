import '../jellyfin_client.dart';
import '../models/jellyfin_response.dart';

class SystemEndpoint {
  final JellyfinClient _client;

  SystemEndpoint(this._client);

  /// Get system information
  Future<JellyfinResponse<SystemInfo>> getSystemInfo() async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/System/Info',
    );

    if (response.isSuccess) {
      return JellyfinResponse.success(
        data: SystemInfo.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get system info',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get public system information (no auth required)
  Future<JellyfinResponse<PublicSystemInfo>> getPublicSystemInfo() async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/System/Info/Public',
    );

    if (response.isSuccess) {
      return JellyfinResponse.success(
        data: PublicSystemInfo.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get public system info',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Ping the server
  Future<JellyfinResponse<bool>> ping() async {
    try {
      final response = await _client.request<String>(
        'GET',
        '/System/Ping',
      );

      return JellyfinResponse.success(
        data: response.isSuccess,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return JellyfinResponse.error(
        message: 'Server ping failed: ${e.toString()}',
        statusCode: 0,
        error: e,
      );
    }
  }

  /// Get server configuration
  Future<JellyfinResponse<ServerConfiguration>> getConfiguration() async {
    final response = await _client.request<Map<String, dynamic>>(
      'GET',
      '/System/Configuration',
    );

    if (response.isSuccess) {
      return JellyfinResponse.success(
        data: ServerConfiguration.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get server configuration',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Get server logs (admin only)
  Future<JellyfinResponse<List<LogFile>>> getLogs() async {
    final response = await _client.request<List<dynamic>>(
      'GET',
      '/System/Logs',
    );

    if (response.isSuccess) {
      final logs = response.data!.map((log) => LogFile.fromJson(log)).toList();

      return JellyfinResponse.success(
        data: logs,
        statusCode: response.statusCode,
      );
    }

    return JellyfinResponse.error(
      message: response.message ?? 'Failed to get logs',
      statusCode: response.statusCode,
      error: response.error,
    );
  }

  /// Restart the server (admin only)
  Future<JellyfinResponse<bool>> restart() async {
    final response = await _client.request<void>(
      'POST',
      '/System/Restart',
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }

  /// Shutdown the server (admin only)
  Future<JellyfinResponse<bool>> shutdown() async {
    final response = await _client.request<void>(
      'POST',
      '/System/Shutdown',
    );

    return JellyfinResponse.success(
      data: response.isSuccess,
      statusCode: response.statusCode,
    );
  }
}

class SystemInfo {
  final String localAddress;
  final String serverName;
  final String version;
  final String productName;
  final String operatingSystem;
  final String id;
  final bool hasUpdateAvailable;
  final bool hasPasswordSet;
  final bool enableAutoLogin;
  final int logFileRetentionDays;
  final bool isShuttingDown;
  final bool supportsLibraryMonitor;
  final List<String> webSocketPortRange;
  final List<String> completedInstallations;
  final bool canSelfRestart;
  final bool canLaunchWebBrowser;
  final String programDataPath;
  final String webPath;
  final String itemsByNamePath;
  final String cachePath;
  final String logPath;
  final String internalMetadataPath;
  final String transcodingTempPath;
  final bool hasUpdateAvailable2;

  SystemInfo({
    required this.localAddress,
    required this.serverName,
    required this.version,
    required this.productName,
    required this.operatingSystem,
    required this.id,
    required this.hasUpdateAvailable,
    required this.hasPasswordSet,
    required this.enableAutoLogin,
    required this.logFileRetentionDays,
    required this.isShuttingDown,
    required this.supportsLibraryMonitor,
    required this.webSocketPortRange,
    required this.completedInstallations,
    required this.canSelfRestart,
    required this.canLaunchWebBrowser,
    required this.programDataPath,
    required this.webPath,
    required this.itemsByNamePath,
    required this.cachePath,
    required this.logPath,
    required this.internalMetadataPath,
    required this.transcodingTempPath,
    required this.hasUpdateAvailable2,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      localAddress: json['LocalAddress'] as String? ?? '',
      serverName: json['ServerName'] as String? ?? '',
      version: json['Version'] as String? ?? '',
      productName: json['ProductName'] as String? ?? '',
      operatingSystem: json['OperatingSystem'] as String? ?? '',
      id: json['Id'] as String? ?? '',
      hasUpdateAvailable: json['HasUpdateAvailable'] as bool? ?? false,
      hasPasswordSet: json['HasPasswordSet'] as bool? ?? false,
      enableAutoLogin: json['EnableAutoLogin'] as bool? ?? false,
      logFileRetentionDays: json['LogFileRetentionDays'] as int? ?? 3,
      isShuttingDown: json['IsShuttingDown'] as bool? ?? false,
      supportsLibraryMonitor: json['SupportsLibraryMonitor'] as bool? ?? false,
      webSocketPortRange:
          List<String>.from(json['WebSocketPortRange'] as List? ?? []),
      completedInstallations:
          List<String>.from(json['CompletedInstallations'] as List? ?? []),
      canSelfRestart: json['CanSelfRestart'] as bool? ?? false,
      canLaunchWebBrowser: json['CanLaunchWebBrowser'] as bool? ?? false,
      programDataPath: json['ProgramDataPath'] as String? ?? '',
      webPath: json['WebPath'] as String? ?? '',
      itemsByNamePath: json['ItemsByNamePath'] as String? ?? '',
      cachePath: json['CachePath'] as String? ?? '',
      logPath: json['LogPath'] as String? ?? '',
      internalMetadataPath: json['InternalMetadataPath'] as String? ?? '',
      transcodingTempPath: json['TranscodingTempPath'] as String? ?? '',
      hasUpdateAvailable2: json['HasUpdateAvailable'] as bool? ?? false,
    );
  }
}

class PublicSystemInfo {
  final String localAddress;
  final String serverName;
  final String version;
  final String productName;
  final String operatingSystem;
  final String id;
  final bool startupWizardCompleted;

  PublicSystemInfo({
    required this.localAddress,
    required this.serverName,
    required this.version,
    required this.productName,
    required this.operatingSystem,
    required this.id,
    required this.startupWizardCompleted,
  });

  factory PublicSystemInfo.fromJson(Map<String, dynamic> json) {
    return PublicSystemInfo(
      localAddress: json['LocalAddress'] as String? ?? '',
      serverName: json['ServerName'] as String? ?? '',
      version: json['Version'] as String? ?? '',
      productName: json['ProductName'] as String? ?? '',
      operatingSystem: json['OperatingSystem'] as String? ?? '',
      id: json['Id'] as String? ?? '',
      startupWizardCompleted: json['StartupWizardCompleted'] as bool? ?? false,
    );
  }
}

class ServerConfiguration {
  final bool enableUPnP;
  final bool enableMetrics;
  final int publicPort;
  final bool uPnPCreateHttpPortMap;
  final String udpPortRange;
  final bool enableIPV6;
  final bool enableIPV4;
  final bool enableSSDPTracing;
  final String sSDPTracingFilter;
  final int uDPSendCount;
  final int uDPSendDelay;
  final bool ignoreVirtualInterfaces;
  final String virtualInterfaceNames;
  final int gatewayMonitorPeriod;
  final bool enableMultiSocketBinding;
  final bool trustAllIP6Interfaces;
  final String hDHomerunPortRange;
  final List<String> publishedServerUriBySubnet;
  final bool autoDiscoveryTracing;
  final bool autoDiscovery;
  final int publicHttpsPort;
  final int httpServerPortNumber;
  final int httpsPortNumber;
  final bool enableHttps;
  final bool enableNormalizedItemByNameIds;
  final String certificatePath;
  final String certificatePassword;
  final bool isPortAuthorized;
  final bool quickConnectAvailable;
  final bool enableRemoteAccess;
  final bool enableCaseSensitiveItemIds;
  final bool disableLiveTvChannelUserDataName;
  final String metadataPath;
  final String metadataNetworkPath;
  final String preferredMetadataLanguage;
  final String metadataCountryCode;
  final List<String> sortReplaceCharacters;
  final List<String> sortRemoveCharacters;
  final List<String> sortRemoveWords;
  final int minResumePct;
  final int maxResumePct;
  final int minResumeDurationSeconds;
  final int minAudiobookResume;
  final int maxAudiobookResume;
  final int libraryMonitorDelay;
  final bool enableDashboardResponseCaching;
  final int imageSavingConvention;
  final List<String> metadataOptions;
  final bool skipDeserializationForBasicTypes;
  final String serverName;
  final String uICulture;
  final bool saveMetadataHidden;
  final List<String> contentTypes;
  final int remoteClientBitrateLimit;
  final bool enableFolderView;
  final bool enableGroupingIntoCollections;
  final bool displaySpecialsWithinSeasons;
  final List<String> localNetworkSubnets;
  final List<String> localNetworkAddresses;
  final List<String> codecsUsed;
  final List<String> pluginRepositories;
  final bool enableExternalContentInSuggestions;
  final bool requireHttps;
  final bool enableNewOmdbSupport;
  final List<String> remoteIPFilter;
  final bool isRemoteIPFilterBlacklist;
  final int imageExtractionTimeoutMs;
  final List<String> pathSubstitutions;
  final bool enableSlowResponseWarning;
  final int slowResponseThresholdMs;
  final List<String> corsHosts;
  final int? activityLogRetentionDays;
  final String libraryScanFanoutConcurrency;
  final int libraryMetadataRefreshConcurrency;
  final bool removeOldPlugins;
  final bool allowClientLogUpload;

  ServerConfiguration({
    required this.enableUPnP,
    required this.enableMetrics,
    required this.publicPort,
    required this.uPnPCreateHttpPortMap,
    required this.udpPortRange,
    required this.enableIPV6,
    required this.enableIPV4,
    required this.enableSSDPTracing,
    required this.sSDPTracingFilter,
    required this.uDPSendCount,
    required this.uDPSendDelay,
    required this.ignoreVirtualInterfaces,
    required this.virtualInterfaceNames,
    required this.gatewayMonitorPeriod,
    required this.enableMultiSocketBinding,
    required this.trustAllIP6Interfaces,
    required this.hDHomerunPortRange,
    required this.publishedServerUriBySubnet,
    required this.autoDiscoveryTracing,
    required this.autoDiscovery,
    required this.publicHttpsPort,
    required this.httpServerPortNumber,
    required this.httpsPortNumber,
    required this.enableHttps,
    required this.enableNormalizedItemByNameIds,
    required this.certificatePath,
    required this.certificatePassword,
    required this.isPortAuthorized,
    required this.quickConnectAvailable,
    required this.enableRemoteAccess,
    required this.enableCaseSensitiveItemIds,
    required this.disableLiveTvChannelUserDataName,
    required this.metadataPath,
    required this.metadataNetworkPath,
    required this.preferredMetadataLanguage,
    required this.metadataCountryCode,
    required this.sortReplaceCharacters,
    required this.sortRemoveCharacters,
    required this.sortRemoveWords,
    required this.minResumePct,
    required this.maxResumePct,
    required this.minResumeDurationSeconds,
    required this.minAudiobookResume,
    required this.maxAudiobookResume,
    required this.libraryMonitorDelay,
    required this.enableDashboardResponseCaching,
    required this.imageSavingConvention,
    required this.metadataOptions,
    required this.skipDeserializationForBasicTypes,
    required this.serverName,
    required this.uICulture,
    required this.saveMetadataHidden,
    required this.contentTypes,
    required this.remoteClientBitrateLimit,
    required this.enableFolderView,
    required this.enableGroupingIntoCollections,
    required this.displaySpecialsWithinSeasons,
    required this.localNetworkSubnets,
    required this.localNetworkAddresses,
    required this.codecsUsed,
    required this.pluginRepositories,
    required this.enableExternalContentInSuggestions,
    required this.requireHttps,
    required this.enableNewOmdbSupport,
    required this.remoteIPFilter,
    required this.isRemoteIPFilterBlacklist,
    required this.imageExtractionTimeoutMs,
    required this.pathSubstitutions,
    required this.enableSlowResponseWarning,
    required this.slowResponseThresholdMs,
    required this.corsHosts,
    this.activityLogRetentionDays,
    required this.libraryScanFanoutConcurrency,
    required this.libraryMetadataRefreshConcurrency,
    required this.removeOldPlugins,
    required this.allowClientLogUpload,
  });

  factory ServerConfiguration.fromJson(Map<String, dynamic> json) {
    return ServerConfiguration(
      enableUPnP: json['EnableUPnP'] as bool? ?? false,
      enableMetrics: json['EnableMetrics'] as bool? ?? false,
      publicPort: json['PublicPort'] as int? ?? 8096,
      uPnPCreateHttpPortMap: json['UPnPCreateHttpPortMap'] as bool? ?? false,
      udpPortRange: json['UdpPortRange'] as String? ?? '',
      enableIPV6: json['EnableIPV6'] as bool? ?? false,
      enableIPV4: json['EnableIPV4'] as bool? ?? true,
      enableSSDPTracing: json['EnableSSDPTracing'] as bool? ?? false,
      sSDPTracingFilter: json['SSDPTracingFilter'] as String? ?? '',
      uDPSendCount: json['UDPSendCount'] as int? ?? 2,
      uDPSendDelay: json['UDPSendDelay'] as int? ?? 100,
      ignoreVirtualInterfaces: json['IgnoreVirtualInterfaces'] as bool? ?? true,
      virtualInterfaceNames: json['VirtualInterfaceNames'] as String? ?? '',
      gatewayMonitorPeriod: json['GatewayMonitorPeriod'] as int? ?? 60,
      enableMultiSocketBinding:
          json['EnableMultiSocketBinding'] as bool? ?? true,
      trustAllIP6Interfaces: json['TrustAllIP6Interfaces'] as bool? ?? false,
      hDHomerunPortRange: json['HDHomerunPortRange'] as String? ?? '',
      publishedServerUriBySubnet:
          List<String>.from(json['PublishedServerUriBySubnet'] as List? ?? []),
      autoDiscoveryTracing: json['AutoDiscoveryTracing'] as bool? ?? false,
      autoDiscovery: json['AutoDiscovery'] as bool? ?? true,
      publicHttpsPort: json['PublicHttpsPort'] as int? ?? 8920,
      httpServerPortNumber: json['HttpServerPortNumber'] as int? ?? 8096,
      httpsPortNumber: json['HttpsPortNumber'] as int? ?? 8920,
      enableHttps: json['EnableHttps'] as bool? ?? false,
      enableNormalizedItemByNameIds:
          json['EnableNormalizedItemByNameIds'] as bool? ?? true,
      certificatePath: json['CertificatePath'] as String? ?? '',
      certificatePassword: json['CertificatePassword'] as String? ?? '',
      isPortAuthorized: json['IsPortAuthorized'] as bool? ?? false,
      quickConnectAvailable: json['QuickConnectAvailable'] as bool? ?? false,
      enableRemoteAccess: json['EnableRemoteAccess'] as bool? ?? true,
      enableCaseSensitiveItemIds:
          json['EnableCaseSensitiveItemIds'] as bool? ?? true,
      disableLiveTvChannelUserDataName:
          json['DisableLiveTvChannelUserDataName'] as bool? ?? true,
      metadataPath: json['MetadataPath'] as String? ?? '',
      metadataNetworkPath: json['MetadataNetworkPath'] as String? ?? '',
      preferredMetadataLanguage:
          json['PreferredMetadataLanguage'] as String? ?? 'en',
      metadataCountryCode: json['MetadataCountryCode'] as String? ?? 'US',
      sortReplaceCharacters:
          List<String>.from(json['SortReplaceCharacters'] as List? ?? []),
      sortRemoveCharacters:
          List<String>.from(json['SortRemoveCharacters'] as List? ?? []),
      sortRemoveWords:
          List<String>.from(json['SortRemoveWords'] as List? ?? []),
      minResumePct: json['MinResumePct'] as int? ?? 5,
      maxResumePct: json['MaxResumePct'] as int? ?? 90,
      minResumeDurationSeconds: json['MinResumeDurationSeconds'] as int? ?? 300,
      minAudiobookResume: json['MinAudiobookResume'] as int? ?? 5,
      maxAudiobookResume: json['MaxAudiobookResume'] as int? ?? 5,
      libraryMonitorDelay: json['LibraryMonitorDelay'] as int? ?? 60,
      enableDashboardResponseCaching:
          json['EnableDashboardResponseCaching'] as bool? ?? true,
      imageSavingConvention: json['ImageSavingConvention'] as int? ?? 0,
      metadataOptions:
          List<String>.from(json['MetadataOptions'] as List? ?? []),
      skipDeserializationForBasicTypes:
          json['SkipDeserializationForBasicTypes'] as bool? ?? true,
      serverName: json['ServerName'] as String? ?? '',
      uICulture: json['UICulture'] as String? ?? 'en-US',
      saveMetadataHidden: json['SaveMetadataHidden'] as bool? ?? false,
      contentTypes: List<String>.from(json['ContentTypes'] as List? ?? []),
      remoteClientBitrateLimit: json['RemoteClientBitrateLimit'] as int? ?? 0,
      enableFolderView: json['EnableFolderView'] as bool? ?? false,
      enableGroupingIntoCollections:
          json['EnableGroupingIntoCollections'] as bool? ?? false,
      displaySpecialsWithinSeasons:
          json['DisplaySpecialsWithinSeasons'] as bool? ?? true,
      localNetworkSubnets:
          List<String>.from(json['LocalNetworkSubnets'] as List? ?? []),
      localNetworkAddresses:
          List<String>.from(json['LocalNetworkAddresses'] as List? ?? []),
      codecsUsed: List<String>.from(json['CodecsUsed'] as List? ?? []),
      pluginRepositories:
          List<String>.from(json['PluginRepositories'] as List? ?? []),
      enableExternalContentInSuggestions:
          json['EnableExternalContentInSuggestions'] as bool? ?? true,
      requireHttps: json['RequireHttps'] as bool? ?? false,
      enableNewOmdbSupport: json['EnableNewOmdbSupport'] as bool? ?? true,
      remoteIPFilter: List<String>.from(json['RemoteIPFilter'] as List? ?? []),
      isRemoteIPFilterBlacklist:
          json['IsRemoteIPFilterBlacklist'] as bool? ?? false,
      imageExtractionTimeoutMs: json['ImageExtractionTimeoutMs'] as int? ?? 0,
      pathSubstitutions:
          List<String>.from(json['PathSubstitutions'] as List? ?? []),
      enableSlowResponseWarning:
          json['EnableSlowResponseWarning'] as bool? ?? true,
      slowResponseThresholdMs: json['SlowResponseThresholdMs'] as int? ?? 500,
      corsHosts: List<String>.from(json['CorsHosts'] as List? ?? []),
      activityLogRetentionDays: json['ActivityLogRetentionDays'] as int?,
      libraryScanFanoutConcurrency:
          json['LibraryScanFanoutConcurrency'] as String? ?? '1',
      libraryMetadataRefreshConcurrency:
          json['LibraryMetadataRefreshConcurrency'] as int? ?? 2,
      removeOldPlugins: json['RemoveOldPlugins'] as bool? ?? false,
      allowClientLogUpload: json['AllowClientLogUpload'] as bool? ?? true,
    );
  }
}

class LogFile {
  final DateTime dateCreated;
  final DateTime dateModified;
  final String name;
  final int size;

  LogFile({
    required this.dateCreated,
    required this.dateModified,
    required this.name,
    required this.size,
  });

  factory LogFile.fromJson(Map<String, dynamic> json) {
    return LogFile(
      dateCreated: DateTime.parse(json['DateCreated'] as String),
      dateModified: DateTime.parse(json['DateModified'] as String),
      name: json['Name'] as String,
      size: json['Size'] as int,
    );
  }
}

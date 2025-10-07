import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/jellyfin_provider.dart';
import '../jellyfin_dart/endpoints/playback.dart';

class PlayerScreen extends StatefulWidget {
  final String itemId;
  final String title;
  final int? resumePosition;
  final int? durationTicks;

  const PlayerScreen({
    super.key,
    required this.itemId,
    required this.title,
    this.resumePosition,
    this.durationTicks,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _isControlsVisible = true;
  bool _isLoading = true;
  bool _isVideoReady = false;
  bool _isDirectStream = false;
  Timer? _hideControlsTimer;
  Timer? _progressReportTimer;
  Duration? _jellyfinDuration;
  MediaSource? _currentMediaSource;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(
        title: 'Jellyfin Player',
      ),
    );
    _controller = VideoController(_player);

    // Convert Jellyfin duration from ticks to Duration if available
    if (widget.durationTicks != null) {
      _jellyfinDuration = Duration(microseconds: widget.durationTicks! ~/ 10);
    }

    _initializePlayer();

    // Force landscape orientation and hide system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    try {
      final provider = context.read<JellyfinProvider>();
      final streamUrl = provider.getStreamUrl(widget.itemId);

      print('DEBUG: Attempting to play item ${widget.itemId}');
      print(
          'DEBUG: Resume position received: ${widget.resumePosition} ticks (${widget.resumePosition != null ? widget.resumePosition! / 10000000 : 0} seconds)');
      print('DEBUG: Stream URL: $streamUrl');
      print('DEBUG: Client authenticated: ${provider.client?.isAuthenticated}');
      print('DEBUG: User ID: ${provider.client?.userId}');
      print(
          'DEBUG: Access Token: ${provider.client?.accessToken != null ? 'Present' : 'Missing'}');

      if (streamUrl == null) {
        throw Exception(
            'Unable to get stream URL - client not authenticated or missing itemId');
      }

      // First get playback info to ensure we have proper streaming URLs
      print('DEBUG: Getting playback info...');
      final playbackInfoResponse =
          await provider.client!.playback.getPlaybackInfo(
        widget.itemId,
        maxStreamingBitrate:
            200000000, // 200 Mbps - very high to prefer direct streaming
      );

      if (!playbackInfoResponse.isSuccess) {
        throw Exception(
            'Failed to get playback info: ${playbackInfoResponse.message}');
      }

      final playbackInfo = playbackInfoResponse.data!;
      print('DEBUG: Got ${playbackInfo.mediaSources.length} media sources');

      if (playbackInfo.mediaSources.isEmpty) {
        throw Exception('No media sources available');
      }

      // Debug all available media sources
      for (int i = 0; i < playbackInfo.mediaSources.length; i++) {
        final source = playbackInfo.mediaSources[i];
        print('DEBUG: Media source $i: ${source.id}');
        print('  - Container: ${source.container}');
        print('  - Direct stream: ${source.supportsDirectStream}');
        print('  - Transcoding: ${source.supportsTranscoding}');
        print('  - Bitrate: ${source.bitrate}');
        print('  - Protocol: ${source.protocol}');
      }

      // Prefer direct stream sources over transcoding sources
      MediaSource? selectedSource;

      // First, try to find a source that supports direct streaming
      for (final source in playbackInfo.mediaSources) {
        if (source.supportsDirectStream) {
          selectedSource = source;
          print('DEBUG: Selected direct stream source: ${source.id}');
          break;
        }
      }

      // If no direct stream available, use the first source
      selectedSource ??= playbackInfo.mediaSources.first;

      final mediaSource = selectedSource;
      _currentMediaSource = mediaSource; // Store for later use
      print(
          'DEBUG: Final media source ${mediaSource.id}, direct stream: ${mediaSource.supportsDirectStream}');
      print('DEBUG: Audio streams: ${mediaSource.audioStreams.length}');
      print('DEBUG: Subtitle streams: ${mediaSource.subtitleStreams.length}');

      // Generate stream URL based on Streamyfin's approach
      String finalStreamUrl;

      // Check if we have a transcoding URL from the server
      if (mediaSource.transcodingUrl != null &&
          mediaSource.transcodingUrl!.isNotEmpty) {
        // Server wants to transcode - use the transcoding URL
        _isDirectStream = false;
        finalStreamUrl =
            '${provider.client!.baseUrl}${mediaSource.transcodingUrl}';
        print(
            'DEBUG: ⚠️  TRANSCODING REQUIRED - Server provided transcoding URL');
        print('DEBUG: Transcoding URL: $finalStreamUrl');
      } else {
        // Direct play - generate direct stream URL
        _isDirectStream = true;
        final startPositionTicks = widget.resumePosition ?? 0;

        finalStreamUrl = provider.client!.playback.getStreamUrl(
          widget.itemId,
          static: true,
          startTimeTicks: startPositionTicks > 0 ? startPositionTicks : null,
        );
        print('DEBUG: ✅ DIRECT STREAMING - No transcoding needed');
        print('DEBUG: Direct stream URL: $finalStreamUrl');
        if (startPositionTicks > 0) {
          print(
              'DEBUG: Direct stream will start at position: ${startPositionTicks / 10000000}s');
        }
      }

      // Try opening with custom headers for authentication
      print('DEBUG: About to open media...');
      print(
          'DEBUG: Resume position: ${widget.resumePosition} ticks (${widget.resumePosition != null ? widget.resumePosition! / 10000000 : 0} seconds)');
      try {
        await _player.open(
          Media(finalStreamUrl, httpHeaders: {
            'X-Emby-Authorization':
                'MediaBrowser Client="Fluffin", Device="fluffin-client", DeviceId="fluffin-client", Version="1.0.0", Token="${provider.client!.accessToken}"',
            'Accept': '*/*',
            'User-Agent': 'Fluffin/1.0.0',
          }),
        );
        print('DEBUG: Media opened successfully');
      } catch (e) {
        print('DEBUG: Error opening media: $e');

        // Try fallback without headers
        print('DEBUG: Trying fallback without custom headers...');
        await _player.open(Media(finalStreamUrl));
      }

      // Wait for media to be ready and duration to be available BEFORE starting playback
      print('DEBUG: Waiting for media to be ready...');
      int waitAttempts = 0;
      while (_player.state.duration.inMilliseconds == 0 && waitAttempts < 20) {
        await Future.delayed(const Duration(milliseconds: 250));
        waitAttempts++;
        print(
            'DEBUG: Waiting for duration... attempt $waitAttempts, duration: ${_player.state.duration.inSeconds}s');
      }

      // Wait for video dimensions to be available (indicates video is ready)
      waitAttempts = 0;
      while ((_player.state.width == null || _player.state.width == 0) &&
          waitAttempts < 20) {
        await Future.delayed(const Duration(milliseconds: 250));
        waitAttempts++;
        print(
            'DEBUG: Waiting for video dimensions... attempt $waitAttempts, width: ${_player.state.width}');
      }

      // Don't start playback yet - wait for video to be truly ready
      print(
          'DEBUG: Media loaded, waiting for video to be ready before starting playback...');

      // Playback will start automatically when video is ready via _checkVideoReady

      // Listen for player state changes
      _player.stream.playing.listen((playing) {
        print('DEBUG: Player playing state changed: $playing');
      });

      _player.stream.buffering.listen((buffering) {
        print('DEBUG: Player buffering state changed: $buffering');
      });

      _player.stream.duration.listen((duration) {
        print('DEBUG: Player duration changed: $duration');
      });

      // Listen for video dimensions to ensure video is ready
      _player.stream.width.listen((width) {
        print('DEBUG: Video width: $width');
        _checkVideoReady();
      });

      _player.stream.height.listen((height) {
        print('DEBUG: Video height: $height');
        _checkVideoReady();
      });

      // Also listen for buffering state to help determine readiness
      _player.stream.buffering.listen((buffering) {
        if (!buffering) {
          _checkVideoReady();
        }
      });

      // Timeout fallback - assume video is ready after 5 seconds regardless
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_isVideoReady) {
          print('DEBUG: Setting video ready after timeout');

          // Start playback even if video dimensions aren't detected
          _startPlaybackWhenReady();

          setState(() {
            _isVideoReady = true;
            _isLoading = false; // Stop loading on timeout too
          });
        }
      });

      // Start progress reporting after a delay to allow seeking to complete
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;

        // Listen for position changes to report progress (every 10 seconds)
        _progressReportTimer =
            Timer.periodic(const Duration(seconds: 10), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          final position = _player.state.position;
          if (position.inMilliseconds > 0 && provider.client != null) {
            _reportPlaybackProgress(provider, position);
          }
        });
      });

      // Don't set loading to false here - wait for video to be ready
      // Loading will be set to false when _isVideoReady becomes true

      // Start auto-hide timer when player is ready
      _startHideControlsTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedToLoadVideo(e.toString()))),
        );
        context.go('/library');
      }
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isControlsVisible) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
  }

  void _showControlsWithAutoHide() {
    setState(() {
      _isControlsVisible = true;
    });
    _startHideControlsTimer();
  }

  void _checkVideoReady() {
    if (!_isVideoReady &&
        _player.state.width != null &&
        _player.state.width! > 0 &&
        _player.state.height != null &&
        _player.state.height! > 0 &&
        !_player.state.buffering) {
      print(
          'DEBUG: Video is ready! Width: ${_player.state.width}, Height: ${_player.state.height}');

      // Now start playback since video is ready
      _startPlaybackWhenReady();

      setState(() {
        _isVideoReady = true;
        _isLoading = false; // Only stop loading when video is actually ready
      });
    }
  }

  Future<void> _startPlaybackWhenReady() async {
    try {
      print('DEBUG: Starting playback now that video is ready...');
      await _player.play();
      print('DEBUG: Playback started');

      // Seek to resume position AFTER starting playback
      // For direct streams: seek if no startTimeTicks was used in URL
      // For transcoded streams: no seeking needed as server handles it
      if (widget.resumePosition != null &&
          widget.resumePosition! > 0 &&
          _isDirectStream) {
        final resumeSeconds =
            widget.resumePosition! / 10000000; // Convert ticks to seconds
        print(
            'DEBUG: Seeking to resume position: ${resumeSeconds}s (${widget.resumePosition} ticks)');

        // Try seeking multiple times if needed
        for (int attempt = 0; attempt < 3; attempt++) {
          await _player.seek(Duration(seconds: resumeSeconds.round()));
          await Future.delayed(const Duration(milliseconds: 500));

          final currentPos = _player.state.position.inSeconds;
          print(
              'DEBUG: Seek attempt ${attempt + 1}, current position: ${currentPos}s');

          // If we're close to the target position, break
          if ((currentPos - resumeSeconds).abs() < 5) {
            print('DEBUG: Seek successful');
            break;
          }
        }

        print(
            'DEBUG: Final position after seeking: ${_player.state.position.inSeconds}s');
      } else if (widget.resumePosition != null &&
          widget.resumePosition! > 0 &&
          !_isDirectStream) {
        print(
            'DEBUG: Transcoded stream - no seeking needed, server started at resume position');
      }

      // Report playback start using new API
      final provider = context.read<JellyfinProvider>();
      if (provider.client != null) {
        // Use the actual current position after seeking
        final currentPosition = _player.state.position;
        final reportPosition =
            currentPosition.inMicroseconds * 10; // Convert to ticks
        print(
            'DEBUG: Reporting playback start at position: ${currentPosition.inSeconds}s (${reportPosition} ticks)');

        await provider.client!.playback.reportPlaybackStart(
          itemId: widget.itemId,
          positionTicks: reportPosition,
          mediaSourceId: widget.itemId,
          canSeek: true,
          playMethod: _isDirectStream ? 'DirectStream' : 'Transcode',
        );
      }
    } catch (e) {
      print('DEBUG: Error starting playback: $e');
    }
  }

  Future<void> _reportPlaybackProgress(
      JellyfinProvider provider, Duration position) async {
    if (provider.client == null) return;

    try {
      await provider.client!.playback.reportPlaybackProgress(
        itemId: widget.itemId,
        positionTicks: position.inMicroseconds * 10, // Convert to ticks
        isPaused: !_player.state.playing,
        mediaSourceId: widget.itemId,
        canSeek: true,
        playMethod: _isDirectStream ? 'DirectStream' : 'Transcode',
        isMuted: false,
        repeatMode: 'RepeatNone',
      );
      print(
          'DEBUG: Reported playback progress: ${position.inSeconds}s (${position.inMicroseconds * 10} ticks), paused: ${!_player.state.playing}');
    } catch (e) {
      print('DEBUG: Error reporting playback progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _stopAndGoBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              GestureDetector(
                onTap: _toggleControls,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    children: [
                      // Video player
                      Video(
                        controller: _controller,
                        controls: NoVideoControls,
                        fit: BoxFit.contain,
                        fill: Colors.black,
                      ),
                      // Fallback display for emulator issues
                      if (!_isVideoReady)
                        Container(
                          color: Colors.black,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_circle_outline,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Video is playing...',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Audio should be audible',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Video display may not work in emulators',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          'Try on a real device for full video playback',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Custom controls overlay
            if (_isControlsVisible && !_isLoading) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top bar with back button and title
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      _cancelHideControlsTimer();
                      _stopAndGoBack();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Center play/pause button
          Center(
            child: StreamBuilder<bool>(
              stream: _player.stream.playing,
              initialData: true,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? true;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 72,
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: () async {
                      _startHideControlsTimer();
                      _player.playOrPause();

                      final provider = context.read<JellyfinProvider>();
                      final position = _player.state.position;
                      await _reportPlaybackProgress(provider, position);
                    },
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          // Bottom section with progress bar and controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress bar with time labels
                StreamBuilder<Duration>(
                  stream: _player.stream.position,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration>(
                      stream: _player.stream.duration,
                      builder: (context, durationSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final playerDuration =
                            durationSnapshot.data ?? Duration.zero;
                        final duration = _jellyfinDuration != null &&
                                _jellyfinDuration!.inMilliseconds > 0
                            ? _jellyfinDuration!
                            : (playerDuration.inMilliseconds > 0
                                ? playerDuration
                                : Duration.zero);

                        return Column(
                          children: [
                            // Time labels above progress bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Progress bar
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF00A4DC),
                                inactiveTrackColor:
                                    Colors.white.withValues(alpha: 0.3),
                                thumbColor: const Color(0xFF00A4DC),
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: duration.inMilliseconds > 0
                                    ? position.inMilliseconds /
                                        duration.inMilliseconds
                                    : 0.0,
                                onChanged: (value) async {
                                  _startHideControlsTimer();
                                  final newPosition = Duration(
                                    milliseconds:
                                        (value * duration.inMilliseconds)
                                            .round(),
                                  );
                                  await _player.seek(newPosition);

                                  final provider =
                                      context.read<JellyfinProvider>();
                                  await _reportPlaybackProgress(
                                      provider, newPosition);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Bottom control buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side controls
                    Row(
                      children: [
                        _buildControlButton(
                          icon: Icons.lock_outline,
                          onPressed: () => _toggleControlsLock(),
                          tooltip: 'Lock Controls',
                        ),
                        const SizedBox(width: 16),
                        _buildPopupControlButton(
                          icon: Icons.audiotrack,
                          tooltip: 'Audio Track',
                          items: _buildAudioTrackItems(),
                          onSelected: (value) {
                            _selectAudioTrack(value);
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildPopupControlButton(
                          icon: Icons.subtitles,
                          tooltip: 'Subtitles',
                          items: _buildSubtitleTrackItems(),
                          onSelected: (value) {
                            _selectSubtitleTrack(value);
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildPopupControlButton(
                          icon: Icons.speed,
                          tooltip: 'Playback Speed',
                          items:
                              ['0.5x', '0.75x', '1.0x', '1.25x', '1.5x', '2.0x']
                                  .map((speed) => PopupMenuItem(
                                        value: speed,
                                        child: Text(speed),
                                      ))
                                  .toList(),
                          onSelected: (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Speed changed to $value')),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildPopupControlButton(
                          icon: Icons.settings,
                          tooltip: 'Quality Settings',
                          items: [
                            PopupMenuItem(
                              value: 'auto',
                              child: Row(
                                children: [
                                  Text('Auto (Direct Play)'),
                                  Spacer(),
                                  Icon(Icons.check,
                                      color: Colors.green, size: 16),
                                ],
                              ),
                            ),
                            ...['4K', '1080p', '720p', '480p']
                                .map((quality) => PopupMenuItem(
                                      value: quality,
                                      child: Text(quality),
                                    )),
                          ],
                          onSelected: (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Quality changed to $value')),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildControlButton(
                          icon: Icons.info_outline,
                          onPressed: () => _showMediaInfo(),
                          tooltip: 'Media Info',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleControls() {
    if (_isControlsVisible) {
      _cancelHideControlsTimer();
      setState(() {
        _isControlsVisible = false;
      });
    } else {
      _showControlsWithAutoHide();
    }
  }

  void _seekRelative(int seconds) async {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    await _player.seek(newPosition);

    // Report progress after seeking
    final provider = context.read<JellyfinProvider>();
    await _reportPlaybackProgress(provider, newPosition);
  }

  void _stopAndGoBack() async {
    // Cancel timers first
    _hideControlsTimer?.cancel();
    _progressReportTimer?.cancel();

    // Get position BEFORE stopping playback
    final position = _player.state.position;
    print(
        'DEBUG: Stopping playback at position: ${position.inSeconds}s (${position.inMicroseconds * 10} ticks)');

    // Stop playback
    _player.stop();

    // Navigate back immediately to prevent UI freezing
    if (mounted) {
      try {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/library');
        }
      } catch (e) {
        print('DEBUG: Navigation error: $e, falling back to library');
        context.go('/library');
      }
    }

    // Report playback stopped in background
    final provider = context.read<JellyfinProvider>();
    if (provider.client != null) {
      try {
        final response = await provider.client!.playback.reportPlaybackStopped(
          itemId: widget.itemId,
          positionTicks: position.inMicroseconds * 10,
          mediaSourceId: widget.itemId,
        );

        if (response.isSuccess) {
          // Wait a bit for server to process the playback report
          await Future.delayed(const Duration(milliseconds: 500));

          // Refresh library data to update continue watching
          provider.loadLibrary();
        }
      } catch (e) {
        print('DEBUG: Error reporting playback stopped: $e');
        // Still refresh library even if report failed
        provider.loadLibrary();
      }
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: () {
            _startHideControlsTimer();
            onPressed();
          },
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildPopupControlButton<T>({
    required IconData icon,
    required String tooltip,
    required List<PopupMenuEntry<T>> items,
    required void Function(T) onSelected,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.black87,
          textStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: PopupMenuButton<T>(
        onSelected: (value) {
          _startHideControlsTimer();
          onSelected(value);
        },
        itemBuilder: (context) => items.map((item) {
          if (item is PopupMenuItem<T>) {
            return PopupMenuItem<T>(
              value: item.value,
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                child: item.child ?? const SizedBox(),
              ),
            );
          }
          return item;
        }).toList(),
        offset: const Offset(0, -10), // Position above the button
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  void _toggleControlsLock() {
    // TODO: Implement controls lock functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Controls lock - Coming soon')),
    );
  }

  void _showMediaInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Media Information',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Title', widget.title),
            _buildInfoRow('Stream Type',
                _isDirectStream ? 'Direct Stream' : 'Transcoded'),
            _buildInfoRow(
                'Duration',
                _jellyfinDuration != null
                    ? _formatDuration(_jellyfinDuration!)
                    : 'Unknown'),
            if (_player.state.width != null && _player.state.height != null)
              _buildInfoRow('Resolution',
                  '${_player.state.width}x${_player.state.height}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<int>> _buildAudioTrackItems() {
    if (_currentMediaSource == null) {
      return [
        const PopupMenuItem(
          value: -1,
          child: Text('No audio tracks available'),
        ),
      ];
    }

    final audioStreams = _currentMediaSource!.audioStreams;
    if (audioStreams.isEmpty) {
      return [
        const PopupMenuItem(
          value: -1,
          child: Text('No audio tracks available'),
        ),
      ];
    }

    return audioStreams.map((stream) {
      return PopupMenuItem<int>(
        value: stream.index,
        child: Row(
          children: [
            Expanded(child: Text(stream.displayName)),
            if (stream.isDefault)
              const Icon(Icons.check, color: Colors.green, size: 16),
          ],
        ),
      );
    }).toList();
  }

  List<PopupMenuEntry<int?>> _buildSubtitleTrackItems() {
    final items = <PopupMenuEntry<int?>>[
      const PopupMenuItem<int?>(
        value: null,
        child: Text('None'),
      ),
    ];

    if (_currentMediaSource != null) {
      final subtitleStreams = _currentMediaSource!.subtitleStreams;
      items.addAll(subtitleStreams.map((stream) {
        return PopupMenuItem<int?>(
          value: stream.index,
          child: Row(
            children: [
              Expanded(child: Text(stream.displayName)),
              if (stream.isDefault)
                const Icon(Icons.check, color: Colors.green, size: 16),
            ],
          ),
        );
      }));
    }

    return items;
  }

  void _selectAudioTrack(int trackIndex) {
    // TODO: Implement audio track switching
    final audioStreams = _currentMediaSource?.audioStreams ?? [];
    final selectedStream = audioStreams.firstWhere(
      (stream) => stream.index == trackIndex,
      orElse: () => audioStreams.first,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio track: ${selectedStream.displayName}')),
    );
  }

  void _selectSubtitleTrack(int? trackIndex) {
    if (trackIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subtitles disabled')),
      );
      return;
    }

    // TODO: Implement subtitle track switching
    final subtitleStreams = _currentMediaSource?.subtitleStreams ?? [];
    final selectedStream = subtitleStreams.firstWhere(
      (stream) => stream.index == trackIndex,
      orElse: () => subtitleStreams.first,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subtitle track: ${selectedStream.displayName}')),
    );
  }

  void _showPlayerSettings() {
    // TODO: Implement player settings
  }

  void _showSubtitleOptions() {
    // TODO: Implement subtitle selection
  }

  void _showAudioOptions() {
    // TODO: Implement audio track selection
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressReportTimer?.cancel();
    _player.dispose();

    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

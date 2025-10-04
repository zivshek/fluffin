import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/jellyfin_provider.dart';

class PlayerScreen extends StatefulWidget {
  final String itemId;
  final String title;
  final int? resumePosition;

  const PlayerScreen({
    super.key,
    required this.itemId,
    required this.title,
    this.resumePosition,
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
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(
        title: 'Jellyfin Player',
      ),
    );
    _controller = VideoController(_player);
    _initializePlayer();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    try {
      final provider = context.read<JellyfinProvider>();
      final streamUrl = provider.getStreamUrl(widget.itemId);

      print('DEBUG: Attempting to play item ${widget.itemId}');
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
          await provider.client!.playback.getPlaybackInfo(widget.itemId);

      if (!playbackInfoResponse.isSuccess) {
        throw Exception(
            'Failed to get playback info: ${playbackInfoResponse.message}');
      }

      final playbackInfo = playbackInfoResponse.data!;
      print('DEBUG: Got ${playbackInfo.mediaSources.length} media sources');

      if (playbackInfo.mediaSources.isEmpty) {
        throw Exception('No media sources available');
      }

      // Use the first available media source
      final mediaSource = playbackInfo.mediaSources.first;
      print(
          'DEBUG: Using media source ${mediaSource.id}, direct stream: ${mediaSource.supportsDirectStream}');

      // Try different streaming approaches
      String finalStreamUrl;

      if (mediaSource.supportsDirectStream) {
        // Try direct stream first
        finalStreamUrl =
            provider.client!.playback.getStreamUrl(widget.itemId, static: true);
        print('DEBUG: Trying direct stream URL: $finalStreamUrl');
      } else {
        // Use transcoded stream with compatible format
        finalStreamUrl = provider.client!.playback.getStreamUrl(
          widget.itemId,
          container: 'mp4',
          videoCodec: 'h264',
          audioCodec: 'aac',
          maxStreamingBitrate: 8000000, // 8 Mbps
        );
        print('DEBUG: Trying transcoded stream URL: $finalStreamUrl');
      }

      // Try opening with custom headers for authentication
      print('DEBUG: About to open media...');
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

      // Start playing immediately
      await _player.play();

      // Seek to resume position if provided
      if (widget.resumePosition != null && widget.resumePosition! > 0) {
        final resumeSeconds =
            widget.resumePosition! / 10000000; // Convert ticks to seconds
        await _player.seek(Duration(seconds: resumeSeconds.round()));
      }

      // Report playback start using new API
      if (provider.client != null) {
        await provider.client!.playback.reportPlaybackStart(
          itemId: widget.itemId,
          positionTicks: widget.resumePosition ?? 0,
        );
      }

      // Listen for player state changes
      _player.stream.playing.listen((playing) {
        print('DEBUG: Player playing state changed: $playing');
      });

      _player.stream.buffering.listen((buffering) {
        print('DEBUG: Player buffering state changed: $buffering');
      });

      _player.stream.duration.listen((duration) {
        print('DEBUG: Player duration changed: $duration');
        if (duration.inMilliseconds > 0 && !_isVideoReady) {
          setState(() {
            _isVideoReady = true;
          });
        }
      });

      // Listen for video dimensions to ensure video is ready
      _player.stream.width.listen((width) {
        print('DEBUG: Video width: $width');
        if (width != null && width > 0) {
          setState(() {
            _isVideoReady = true;
          });
        }
      });

      _player.stream.height.listen((height) {
        print('DEBUG: Video height: $height');
      });

      // Fallback timeout - if video doesn't show dimensions after 10 seconds,
      // assume it's an emulator issue but keep the audio playing
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && !_isVideoReady) {
          print(
              'DEBUG: Video dimensions not detected after 10s - likely emulator issue');
          // Don't set _isVideoReady to true here, keep showing the fallback message
        }
      });

      // Listen for position changes to report progress
      _player.stream.position.listen((position) {
        if (position.inMilliseconds > 0 && provider.client != null) {
          provider.client!.playback.reportPlaybackProgress(
            itemId: widget.itemId,
            positionTicks: position.inMicroseconds * 10, // Convert to ticks
            isPaused: !_player.state.playing,
          );
        }
      });

      setState(() => _isLoading = false);

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
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
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _cancelHideControlsTimer();
                      _stopAndGoBack();
                    },
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {
                      _startHideControlsTimer(); // Reset timer on interaction
                      _showPlayerSettings();
                    },
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
              initialData: true, // Assume playing initially since we auto-start
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? true;
                return IconButton(
                  iconSize: 64,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _startHideControlsTimer(); // Reset timer on interaction
                    _player.playOrPause();
                  },
                );
              },
            ),
          ),

          const Spacer(),

          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress bar
                StreamBuilder<Duration>(
                  stream: _player.stream.position,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration>(
                      stream: _player.stream.duration,
                      builder: (context, durationSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = durationSnapshot.data ?? Duration.zero;

                        return Column(
                          children: [
                            Slider(
                              value: duration.inMilliseconds > 0
                                  ? position.inMilliseconds /
                                      duration.inMilliseconds
                                  : 0.0,
                              onChanged: (value) {
                                _startHideControlsTimer(); // Reset timer on interaction
                                final newPosition = Duration(
                                  milliseconds:
                                      (value * duration.inMilliseconds).round(),
                                );
                                _player.seek(newPosition);
                              },
                              activeColor: const Color(0xFF00A4DC),
                              inactiveColor:
                                  Colors.white.withValues(alpha: 0.3),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () {
                        _startHideControlsTimer(); // Reset timer on interaction
                        _seekRelative(-10);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.subtitles, color: Colors.white),
                      onPressed: () {
                        _startHideControlsTimer(); // Reset timer on interaction
                        _showSubtitleOptions();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.audiotrack, color: Colors.white),
                      onPressed: () {
                        _startHideControlsTimer(); // Reset timer on interaction
                        _showAudioOptions();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () {
                        _startHideControlsTimer(); // Reset timer on interaction
                        _seekRelative(10);
                      },
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

  void _seekRelative(int seconds) {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    _player.seek(newPosition);
  }

  void _stopAndGoBack() {
    // Stop playback and report to server
    _player.stop();

    final position = _player.state.position;
    final provider = context.read<JellyfinProvider>();
    if (provider.client != null) {
      provider.client!.playback.reportPlaybackStopped(
        itemId: widget.itemId,
        positionTicks: position.inMicroseconds * 10,
      );
    }

    // Navigate back to library
    context.go('/library');
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
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/jellyfin_provider.dart';

class PlayerScreen extends StatefulWidget {
  final String itemId;
  final String title;

  const PlayerScreen({
    super.key,
    required this.itemId,
    required this.title,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _isControlsVisible = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initializePlayer();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    try {
      final provider = context.read<JellyfinProvider>();
      final streamUrl = provider.getStreamUrl(widget.itemId);

      if (streamUrl == null) {
        throw Exception('Unable to get stream URL');
      }

      await _player.open(Media(streamUrl));

      // Report playback start using new API
      if (provider.client != null) {
        await provider.client!.playback.reportPlaybackStart(
          itemId: widget.itemId,
          positionTicks: 0,
        );
      }

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedToLoadVideo(e.toString()))),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GestureDetector(
              onTap: _toggleControls,
              child: Video(
                controller: _controller,
                controls: NoVideoControls,
              ),
            ),

          // Custom controls overlay
          if (_isControlsVisible && !_isLoading) _buildControlsOverlay(),
        ],
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
                    onPressed: () => Navigator.of(context).pop(),
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
                    onPressed: _showPlayerSettings,
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
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return IconButton(
                  iconSize: 64,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: () => _player.playOrPause(),
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
                      onPressed: () => _seekRelative(-10),
                    ),
                    IconButton(
                      icon: const Icon(Icons.subtitles, color: Colors.white),
                      onPressed: _showSubtitleOptions,
                    ),
                    IconButton(
                      icon: const Icon(Icons.audiotrack, color: Colors.white),
                      onPressed: _showAudioOptions,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () => _seekRelative(10),
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
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });

    if (_isControlsVisible) {
      // Auto-hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isControlsVisible = false;
          });
        }
      });
    }
  }

  void _seekRelative(int seconds) {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    _player.seek(newPosition);
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
    // Report playback stopped
    final position = _player.state.position;
    final provider = context.read<JellyfinProvider>();
    if (provider.client != null) {
      provider.client!.playback.reportPlaybackStopped(
        itemId: widget.itemId,
        positionTicks: position.inMicroseconds * 10,
      );
    }

    _player.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }
}

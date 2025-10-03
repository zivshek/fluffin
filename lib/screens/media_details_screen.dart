import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/jellyfin_provider.dart';
import '../models/index.dart';

class MediaDetailsScreen extends StatefulWidget {
  final String itemId;
  final MediaItem? item;

  const MediaDetailsScreen({
    super.key,
    required this.itemId,
    this.item,
  });

  @override
  State<MediaDetailsScreen> createState() => _MediaDetailsScreenState();
}

class _MediaDetailsScreenState extends State<MediaDetailsScreen> {
  MediaItem? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMediaDetails();
  }

  Future<void> _loadMediaDetails() async {
    if (widget.item != null) {
      setState(() {
        _item = widget.item;
        _isLoading = false;
      });
    } else {
      // Load item details from API if not provided
      // TODO: Implement API call to get detailed item info
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF00A4DC),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Media not found'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(),
                _buildMediaInfo(),
                _buildDescription(),
                _buildAudioSubtitleSelection(),
                _buildCastSection(),
                _buildRecommendationsSection(),
                _buildTechnicalDetails(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final provider = context.read<JellyfinProvider>();
    final backdropUrl =
        provider.getImageUrl(_item!.id, imageType: 'Backdrop', maxWidth: 800);

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF00A4DC),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop image
            if (backdropUrl != null)
              Image.network(
                backdropUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, size: 64, color: Colors.grey),
                ),
              )
            else
              Container(
                color: Colors.grey[800],
                child: const Icon(Icons.movie, size: 64, color: Colors.grey),
              ),
            // Gradient overlay for better visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(
                        0.3), // Darker at top for back button visibility
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final provider = context.read<JellyfinProvider>();
    final posterUrl =
        provider.getImageUrl(_item!.id, maxWidth: 300, maxHeight: 450);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: posterUrl != null
                  ? DecorationImage(
                      image: NetworkImage(posterUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: posterUrl == null
                ? const Icon(Icons.movie, size: 32, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _item!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PG-13', // TODO: Get from item data
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    const Text('8.5',
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold)), // TODO: Get from item data
                    const SizedBox(width: 8),
                    Text(_formatRuntime(_item!.runTimeTicks)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildGenreChip('Action'), // TODO: Get from item data
                    _buildGenreChip('Drama'),
                    _buildGenreChip('Thriller'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/player', extra: {
                        'itemId': _item!.id,
                        'title': _item!.name,
                      });
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A4DC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    return Chip(
      label: Text(genre),
      backgroundColor: Colors.grey[200],
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildMediaInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Resolution', '1920x1080'), // TODO: Get from media sources
          _buildInfoRow('Studio', 'Warner Bros'), // TODO: Get from item data
          _buildInfoRow('Release Year', '2024'), // TODO: Get from item data
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (_item!.overview == null || _item!.overview!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _item!.overview!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSubtitleSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio & Subtitles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSelectionRow(
              'Audio', 'English (AC3 5.1)'), // TODO: Get from media streams
          _buildSelectionRow(
              'Subtitles', 'English'), // TODO: Get from media streams
        ],
      ),
    );
  }

  Widget _buildSelectionRow(String label, String current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(current,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _buildCastSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cast',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // TODO: Get from item data
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Actor Name', // TODO: Get from item data
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Recommendations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // TODO: Get recommendations from API
              itemBuilder: (context, index) {
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.movie,
                              size: 32, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Related Movie', // TODO: Get from recommendations
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technical Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('File Size', '2.1 GB'), // TODO: Get from media sources
          _buildInfoRow(
              'Video Format', 'H.264'), // TODO: Get from media streams
          _buildInfoRow(
              'Audio Format', 'AC3 5.1'), // TODO: Get from media streams
          _buildInfoRow('Container', 'MKV'), // TODO: Get from media sources
          _buildInfoRow('Bitrate', '8.5 Mbps'), // TODO: Get from media sources
        ],
      ),
    );
  }

  String _formatRuntime(int? runTimeTicks) {
    if (runTimeTicks == null) return '';

    final minutes = (runTimeTicks / 600000000).round();
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}

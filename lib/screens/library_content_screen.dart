import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/jellyfin_provider.dart';
import '../models/index.dart';

class LibraryContentScreen extends StatefulWidget {
  const LibraryContentScreen({super.key});

  @override
  State<LibraryContentScreen> createState() => _LibraryContentScreenState();
}

class _LibraryContentScreenState extends State<LibraryContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JellyfinProvider>().loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<JellyfinProvider>(
          builder: (context, provider, _) {
            return Text(provider.currentUser?.name ?? 'Library');
          },
        ),
        backgroundColor: const Color(0xFF00A4DC),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/libraries'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => context.go('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Consumer<JellyfinProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadLibrary(),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (provider.libraryItems.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noMediaFound),
            );
          }

          return _buildLibraryContent(provider.libraryItems);
        },
      ),
    );
  }

  Widget _buildLibraryContent(List<MediaItem> items) {
    // Group items by type for better organization
    final movies = items.where((item) => item.type == 'Movie').toList();
    final series = items.where((item) => item.type == 'Series').toList();
    final episodes = items.where((item) => item.type == 'Episode').toList();
    final continueWatching = items
        .where((item) => item.userData?.playbackPositionTicks != null)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Continue Watching Section
          if (continueWatching.isNotEmpty)
            _buildContinueWatchingSection(continueWatching),

          // Next Up Section (episodes from series in continue watching)
          if (episodes.isNotEmpty)
            _buildNextUpSection(episodes.take(4).toList()),

          // Library Categories Section
          _buildLibraryCategoriesSection(movies, series),

          // Movies Section
          if (movies.isNotEmpty) _buildMoviesSection(movies),

          // TV Shows Section
          if (series.isNotEmpty) _buildTVShowsSection(series),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContinueWatchingSection(List<MediaItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Continue Watching',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length.clamp(0, 10),
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: _ContinueWatchingCard(item: items[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNextUpSection(List<MediaItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Next up',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length.clamp(0, 6),
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: _NextUpCard(item: items[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLibraryCategoriesSection(
      List<MediaItem> movies, List<MediaItem> series) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Library',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (movies.isNotEmpty)
                Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  child: _LibraryCategoryCard(
                    title: 'Movies',
                    count: movies.length,
                    backgroundImage: movies.first,
                  ),
                ),
              if (series.isNotEmpty)
                Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  child: _LibraryCategoryCard(
                    title: 'TV Shows',
                    count: series.length,
                    backgroundImage: series.first,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMoviesSection(List<MediaItem> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Movies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to movies view
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Color(0xFF00A4DC)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              // Make width responsive for different screen sizes
              final screenWidth = MediaQuery.of(context).size.width;
              final cardWidth =
                  screenWidth > 600 ? 150.0 : 130.0; // Larger cards on tablets

              return Container(
                width: cardWidth,
                margin: const EdgeInsets.only(right: 16),
                child: _PosterCard(item: movies[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTVShowsSection(List<MediaItem> series) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'TV Shows',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to TV shows view
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Color(0xFF00A4DC)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: series.length,
            itemBuilder: (context, index) {
              // Make width responsive for different screen sizes
              final screenWidth = MediaQuery.of(context).size.width;
              final cardWidth =
                  screenWidth > 600 ? 150.0 : 130.0; // Larger cards on tablets

              return Container(
                width: cardWidth,
                margin: const EdgeInsets.only(right: 16),
                child: _PosterCard(item: series[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final MediaItem item;

  const _ContinueWatchingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JellyfinProvider>();
    final imageUrl =
        provider.getImageUrl(item.id, maxWidth: 500, maxHeight: 280);
    final progress = _calculateProgress(item);
    final remainingTime = _calculateRemainingTime(item);

    return InkWell(
      onTap: () {
        context.go('/player', extra: {
          'itemId': item.id,
          'title': item.name,
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image with play button
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (imageUrl == null)
                    const Center(
                      child: Icon(Icons.movie, size: 48, color: Colors.grey),
                    ),
                  // Play button
                  const Center(
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                  // Progress bar at bottom of image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A4DC),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title underneath
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Remaining time
          Text(
            'Remaining time: $remainingTime',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateProgress(MediaItem item) {
    final position = item.userData?.playbackPositionTicks ?? 0;
    final duration = item.runTimeTicks ?? 1;
    return duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;
  }

  String _calculateRemainingTime(MediaItem item) {
    final position = item.userData?.playbackPositionTicks ?? 0;
    final duration = item.runTimeTicks ?? 0;
    final remaining = duration - position;

    if (remaining <= 0) return '0m';

    final minutes =
        (remaining / 600000000).round(); // Convert from ticks to minutes
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}

class _NextUpCard extends StatelessWidget {
  final MediaItem item;

  const _NextUpCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JellyfinProvider>();
    final imageUrl =
        provider.getImageUrl(item.id, maxWidth: 500, maxHeight: 280);

    return InkWell(
      onTap: () {
        context.go('/player', extra: {
          'itemId': item.id,
          'title': item.name,
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image with play button
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (imageUrl == null)
                    const Center(
                      child: Icon(Icons.tv, size: 32, color: Colors.grey),
                    ),
                  // Play button
                  const Center(
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title underneath
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Episode info
          Text(
            'S2E1:Hello',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LibraryCategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final MediaItem backgroundImage;

  const _LibraryCategoryCard({
    required this.title,
    required this.count,
    required this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JellyfinProvider>();
    final imageUrl =
        provider.getImageUrl(backgroundImage.id, maxWidth: 400, maxHeight: 240);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to category view
        },
        child: Stack(
          children: [
            // Background image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            // Dark overlay
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            // Title
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final MediaItem item;

  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JellyfinProvider>();
    final imageUrl =
        provider.getImageUrl(item.id, maxWidth: 300, maxHeight: 450);

    return InkWell(
      onTap: () {
        context.go('/media-details', extra: {
          'itemId': item.id,
          'item': item,
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Poster image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Center(
                      child: Icon(Icons.movie, size: 32, color: Colors.grey),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // Year (if available)
          Text(
            '2024', // TODO: Extract year from item data
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

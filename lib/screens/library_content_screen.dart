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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Continue Watching Section
          if (items.any((item) => item.userData?.playbackPositionTicks != null))
            _buildSection(
              'Continue Watching',
              items
                  .where((item) => item.userData?.playbackPositionTicks != null)
                  .toList(),
              isHorizontal: true,
            ),

          // Recently Added
          _buildSection(
            'Recently Added',
            items.take(10).toList(),
            isHorizontal: true,
          ),

          // Movies Section
          if (movies.isNotEmpty) _buildSection('Movies', movies),

          // TV Shows Section
          if (series.isNotEmpty) _buildSection('TV Shows', series),

          // Episodes Section (if any standalone episodes)
          if (episodes.isNotEmpty) _buildSection('Episodes', episodes),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<MediaItem> items,
      {bool isHorizontal = false}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (items.length > 6)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full section view
                  },
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        if (isHorizontal)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length.clamp(0, 10),
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: _MediaCard(item: items[index], isCompact: true),
                );
              },
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length.clamp(0, 6),
            itemBuilder: (context, index) {
              return _MediaCard(item: items[index]);
            },
          ),
      ],
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaItem item;
  final bool isCompact;

  const _MediaCard({required this.item, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.go('/player', extra: {
            'itemId': item.id,
            'title': item.name,
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[300],
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.movie, size: 48, color: Colors.grey),
                    ),
                    // Progress indicator for continue watching
                    if (item.userData?.playbackPositionTicks != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: _calculateProgress(item),
                          backgroundColor: Colors.black26,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00A4DC),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!isCompact)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.overview != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.overview!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(MediaItem item) {
    final position = item.userData?.playbackPositionTicks ?? 0;
    final duration = item.runTimeTicks ?? 1;
    return duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;
  }
}

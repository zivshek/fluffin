import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/login_history_service.dart';
import '../models/login_history.dart';

class LibrarySelectionScreen extends StatefulWidget {
  const LibrarySelectionScreen({super.key});

  @override
  State<LibrarySelectionScreen> createState() => _LibrarySelectionScreenState();
}

class _LibrarySelectionScreenState extends State<LibrarySelectionScreen> {
  List<UserHistory> _userHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserHistory();
  }

  Future<void> _loadUserHistory() async {
    final history = await LoginHistoryService.getUserHistory();
    setState(() {
      _userHistory = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.library),
        backgroundColor: const Color(0xFF00A4DC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () {
              // TODO: Sync/backup functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLibraryDialog(),
          ),
        ],
      ),
      body: _userHistory.isEmpty ? _buildEmptyState() : _buildLibraryList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Library tab selected
        onTap: (index) {
          switch (index) {
            case 0:
              // Home - could be recent/continue watching
              break;
            case 1:
              // Already on Library
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.video_library),
            label: AppLocalizations.of(context)!.library,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Libraries Added',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a Jellyfin server to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddLibraryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A4DC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userHistory.length,
      itemBuilder: (context, index) {
        final library = _userHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF00A4DC),
              child: const Icon(Icons.account_circle, color: Colors.white),
            ),
            title: Text(library.displayName ?? library.username),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(library.serverUrl),
                Text(
                  'Last accessed: ${_formatLastAccess(library.lastLogin)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  _removeLibrary(library);
                }
              },
            ),
            onTap: () => _connectToLibrary(library),
          ),
        );
      },
    );
  }

  String _formatLastAccess(DateTime lastLogin) {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showAddLibraryDialog() {
    context.go('/login');
  }

  Future<void> _connectToLibrary(UserHistory library) async {
    // For now, redirect to login with pre-filled info
    // In the future, we could try to auto-connect with stored tokens
    context.go('/login');
  }

  Future<void> _removeLibrary(UserHistory library) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Library'),
        content: Text('Remove ${library.displayName ?? library.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LoginHistoryService.removeUserFromHistory(
        library.username,
        library.serverUrl,
      );
      _loadUserHistory();
    }
  }
}

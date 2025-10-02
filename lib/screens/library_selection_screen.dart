import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/login_history_service.dart';
import '../models/login_history.dart';
import '../providers/jellyfin_provider.dart';

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
        currentIndex: 0, // Libraries tab selected
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on Libraries
              break;
            case 1:
              context.go('/settings');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.video_library),
            label: 'Libraries',
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
            leading: Stack(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF00A4DC),
                  child: Icon(Icons.account_circle, color: Colors.white),
                ),
                // Show lock icon if credentials are stored
                FutureBuilder<bool>(
                  future: LoginHistoryService.hasStoredCredentials(
                    library.username,
                    library.serverUrl,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
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
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
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
    // Check if we have stored credentials
    final hasCredentials = await LoginHistoryService.hasStoredCredentials(
      library.username,
      library.serverUrl,
    );

    if (hasCredentials) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Get stored password
        final password = await LoginHistoryService.getStoredPassword(
          library.username,
          library.serverUrl,
        );

        if (password != null && mounted) {
          // Attempt auto-login
          final provider = context.read<JellyfinProvider>();
          final success = await provider.login(
            library.serverUrl,
            library.username,
            password,
          );

          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog

            if (success) {
              // Update last login time
              await LoginHistoryService.addUserToHistory(
                username: library.username,
                serverUrl: library.serverUrl,
                displayName: library.displayName,
                password: password,
              );

              // Navigate to library
              context.go('/library');
            } else {
              // Auto-login failed, redirect to login screen
              _showLoginFailedDialog(library);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showLoginFailedDialog(library);
        }
      }
    } else {
      // No stored credentials, redirect to login with pre-filled info
      context.go('/login', extra: {
        'serverUrl': library.serverUrl,
        'username': library.username,
      });
    }
  }

  void _showLoginFailedDialog(UserHistory library) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: const Text(
            'Stored credentials are no longer valid. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Redirect to login with pre-filled info
              context.go('/login', extra: {
                'serverUrl': library.serverUrl,
                'username': library.username,
              });
            },
            child: const Text('Login Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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

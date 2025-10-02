import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/jellyfin_provider.dart';
import '../services/login_history_service.dart';
import '../models/login_history.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledServerUrl;
  final String? prefilledUsername;

  const LoginScreen({
    super.key,
    this.prefilledServerUrl,
    this.prefilledUsername,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<ServerHistory> _serverHistory = [];
  List<UserHistory> _userHistory = [];
  bool _showServerDropdown = false;
  bool _showUserHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();

    // Pre-fill fields if provided
    if (widget.prefilledServerUrl != null) {
      _serverController.text = widget.prefilledServerUrl!;
    }
    if (widget.prefilledUsername != null) {
      _usernameController.text = widget.prefilledUsername!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JellyfinProvider>().tryAutoLogin();
    });
  }

  Future<void> _loadHistory() async {
    final serverHistory = await LoginHistoryService.getServerHistory();
    final userHistory = await LoginHistoryService.getUserHistory();

    setState(() {
      _serverHistory = serverHistory;
      _userHistory = userHistory;
    });

    // Pre-fill with most recent server if available and no prefilled value
    if (serverHistory.isNotEmpty &&
        _serverController.text.isEmpty &&
        widget.prefilledServerUrl == null) {
      _serverController.text = serverHistory.first.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.signIn),
        backgroundColor: const Color(0xFF00A4DC),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/libraries'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<JellyfinProvider>(
            builder: (context, provider, _) {
              if (provider.isLoggedIn) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/library');
                });
              }

              return Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_filled,
                      size: 80,
                      color: Color(0xFF00A4DC),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.appTitle,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00A4DC),
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.appSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Server URL with dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _serverController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.serverUrl,
                            hintText:
                                AppLocalizations.of(context)!.serverUrlHint,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.dns),
                            suffixIcon: _serverHistory.isNotEmpty
                                ? IconButton(
                                    icon: Icon(_showServerDropdown
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down),
                                    onPressed: () {
                                      setState(() {
                                        _showServerDropdown =
                                            !_showServerDropdown;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterServerUrl;
                            }
                            return null;
                          },
                        ),

                        // Server history dropdown
                        if (_showServerDropdown && _serverHistory.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: _serverHistory.map((server) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.history, size: 20),
                                  title: Text(server.name),
                                  subtitle: Text(server.url),
                                  onTap: () {
                                    _serverController.text = server.url;
                                    setState(() {
                                      _showServerDropdown = false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Show user history if available
                    if (_userHistory.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            'Recent Users',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showUserHistory = !_showUserHistory;
                              });
                            },
                            child: Text(_showUserHistory ? 'Hide' : 'Show'),
                          ),
                        ],
                      ),
                      if (_showUserHistory)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _userHistory.take(5).map((user) {
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF00A4DC),
                                  child: Text(
                                    user.displayName
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        user.username
                                            .substring(0, 1)
                                            .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(user.displayName ?? user.username),
                                subtitle: Text(user.serverUrl),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () async {
                                    await LoginHistoryService
                                        .removeUserFromHistory(
                                      user.username,
                                      user.serverUrl,
                                    );
                                    _loadHistory();
                                  },
                                ),
                                onTap: () {
                                  _serverController.text = user.serverUrl;
                                  _usernameController.text = user.username;
                                  setState(() {
                                    _showUserHistory = false;
                                  });
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],

                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.username,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!
                              .pleaseEnterUsername;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!
                              .pleaseEnterPassword;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF00A4DC),
                          foregroundColor: Colors.white,
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(AppLocalizations.of(context)!.signIn),
                      ),
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Connection Error',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.error!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                            if (provider.error!.contains('XMLHttpRequest') ||
                                provider.error!.contains('CORS')) ...[
                              const SizedBox(height: 8),
                              Text(
                                'This is a CORS issue. Try running on desktop instead of web, or configure your Jellyfin server to allow web requests.',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final serverUrl = _serverController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      final success = await context.read<JellyfinProvider>().login(
            serverUrl,
            username,
            password,
          );

      if (success && mounted) {
        // Save to history
        final provider = context.read<JellyfinProvider>();
        await LoginHistoryService.addServerToHistory(
          serverUrl,
          provider.currentUser?.name ?? 'Jellyfin Server',
        );
        await LoginHistoryService.addUserToHistory(
          username: username,
          serverUrl: serverUrl,
          displayName: provider.currentUser?.name,
          password: password, // Store password securely
        );

        if (mounted) {
          context.go('/library');
        }
      }
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

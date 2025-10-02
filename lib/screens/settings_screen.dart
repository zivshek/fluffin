import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/jellyfin_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: const Color(0xFF00A4DC),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              _buildSection(
                context,
                AppLocalizations.of(context)!.appearance,
                [
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.darkMode),
                    subtitle:
                        Text(AppLocalizations.of(context)!.darkModeDescription),
                    value: settings.isDarkMode,
                    onChanged: settings.setDarkMode,
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.language),
                    subtitle:
                        Text(_getLanguageName(context, settings.appLanguage)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showLanguageDialog(context, settings),
                  ),
                ],
              ),
              _buildSection(
                context,
                AppLocalizations.of(context)!.playback,
                [
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.autoSkipIntros),
                    subtitle: Text(AppLocalizations.of(context)!
                        .autoSkipIntrosDescription),
                    value: settings.autoSkipIntros,
                    onChanged: settings.setAutoSkipIntros,
                  ),
                  SwitchListTile(
                    title:
                        Text(AppLocalizations.of(context)!.rememberSubtitles),
                    subtitle: Text(AppLocalizations.of(context)!
                        .rememberSubtitlesDescription),
                    value: settings.rememberSubtitles,
                    onChanged: settings.setRememberSubtitles,
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!
                        .preferredSubtitleLanguage),
                    subtitle:
                        Text(settings.preferredSubtitleLanguage.toUpperCase()),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showSubtitleLanguageDialog(context, settings),
                  ),
                ],
              ),
              _buildSection(
                context,
                AppLocalizations.of(context)!.account,
                [
                  Consumer<JellyfinProvider>(
                    builder: (context, jellyfinProvider, _) {
                      return ListTile(
                        title: Text(AppLocalizations.of(context)!.currentUser),
                        subtitle: Text(
                            jellyfinProvider.currentUser?.name ?? 'Unknown'),
                        leading: const Icon(Icons.person),
                      );
                    },
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.logout),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
              _buildSection(
                context,
                AppLocalizations.of(context)!.about,
                [
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.version),
                    subtitle: const Text('1.0.0+1'),
                    leading: const Icon(Icons.info),
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.licenses),
                    leading: const Icon(Icons.description),
                    onTap: () => showLicensePage(context: context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF00A4DC),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  String _getLanguageName(BuildContext context, String languageCode) {
    switch (languageCode) {
      case 'en':
        return AppLocalizations.of(context)!.english;
      case 'es':
        return AppLocalizations.of(context)!.spanish;
      case 'fr':
        return AppLocalizations.of(context)!.french;
      case 'de':
        return AppLocalizations.of(context)!.german;
      default:
        return AppLocalizations.of(context)!.english;
    }
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
                context, settings, 'en', AppLocalizations.of(context)!.english),
            _buildLanguageOption(
                context, settings, 'es', AppLocalizations.of(context)!.spanish),
            _buildLanguageOption(
                context, settings, 'fr', AppLocalizations.of(context)!.french),
            _buildLanguageOption(
                context, settings, 'de', AppLocalizations.of(context)!.german),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, SettingsProvider settings,
      String code, String name) {
    return RadioListTile<String>(
      title: Text(name),
      value: code,
      groupValue: settings.appLanguage,
      onChanged: (value) {
        if (value != null) {
          settings.setAppLanguage(value);
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showSubtitleLanguageDialog(
      BuildContext context, SettingsProvider settings) {
    final TextEditingController controller =
        TextEditingController(text: settings.preferredSubtitleLanguage);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.preferredSubtitleLanguage),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.languageCode,
            hintText: 'en, es, fr, de, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              settings.setPreferredSubtitleLanguage(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<JellyfinProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }
}

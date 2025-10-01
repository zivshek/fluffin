import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _autoSkipIntros = true;
  bool _rememberSubtitles = true;
  String _preferredSubtitleLanguage = 'en';
  String _preferredAudioLanguage = 'en';
  double _playbackSpeed = 1.0;
  String _appLanguage = 'en';

  bool get isDarkMode => _isDarkMode;
  bool get autoSkipIntros => _autoSkipIntros;
  bool get rememberSubtitles => _rememberSubtitles;
  String get preferredSubtitleLanguage => _preferredSubtitleLanguage;
  String get preferredAudioLanguage => _preferredAudioLanguage;
  double get playbackSpeed => _playbackSpeed;
  String get appLanguage => _appLanguage;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _autoSkipIntros = prefs.getBool('auto_skip_intros') ?? true;
    _rememberSubtitles = prefs.getBool('remember_subtitles') ?? true;
    _preferredSubtitleLanguage = prefs.getString('subtitle_language') ?? 'en';
    _preferredAudioLanguage = prefs.getString('audio_language') ?? 'en';
    _playbackSpeed = prefs.getDouble('playback_speed') ?? 1.0;
    _appLanguage = prefs.getString('app_language') ?? 'en';

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }

  Future<void> setAutoSkipIntros(bool value) async {
    _autoSkipIntros = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_skip_intros', value);
    notifyListeners();
  }

  Future<void> setRememberSubtitles(bool value) async {
    _rememberSubtitles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_subtitles', value);
    notifyListeners();
  }

  Future<void> setPreferredSubtitleLanguage(String language) async {
    _preferredSubtitleLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subtitle_language', language);
    notifyListeners();
  }

  Future<void> setPreferredAudioLanguage(String language) async {
    _preferredAudioLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_language', language);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_speed', speed);
    notifyListeners();
  }

  Future<void> setAppLanguage(String language) async {
    _appLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language);
    notifyListeners();
  }
}

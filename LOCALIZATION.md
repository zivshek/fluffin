# Fluffin Localization

Fluffin now supports multiple languages through Flutter's internationalization (l10n) system.

## Supported Languages

- **English (en)** - Default language
- **Spanish (es)** - Español
- **French (fr)** - Français  
- **German (de)** - Deutsch

## Adding New Languages

1. Create a new `.arb` file in `lib/l10n/` following the pattern `app_[locale].arb`
2. Copy the structure from `app_en.arb` and translate all strings
3. Add the new locale to the `supportedLocales` list in `lib/main.dart`
4. Run `flutter gen-l10n` to generate the localization files

## Localized Features

- Login screen (server URL, username, password, validation messages)
- Home screen (app title, settings, error messages)
- Settings dialog (all setting labels)
- Player screen (error messages, control labels)
- Navigation and buttons

## Language Selection

Users can change the app language through the settings menu. The selected language is persisted and will be remembered on app restart.

## Technical Implementation

- Uses Flutter's built-in `flutter_localizations` package
- ARB (Application Resource Bundle) files for translations
- Automatic code generation via `flutter gen-l10n`
- Language preference stored in SharedPreferences
- Fallback to English if selected language is not available

## Files Structure

```
lib/l10n/
├── app_en.arb    # English (template)
├── app_es.arb    # Spanish
├── app_fr.arb    # French
└── app_de.arb    # German

l10n.yaml         # Configuration file
```

The generated localization files are automatically created in `.dart_tool/flutter_gen/gen_l10n/` and should not be manually edited.
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Vlogger',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'uploadVideo': 'Upload Video',
      'editVideo': 'Edit Video',
      'deleteVideo': 'Delete Video',
      'save': 'Save',
      'cancel': 'Cancel',
      'error': 'Error',
      'success': 'Success',
    },
    'tr': {
      'appName': 'Vlogger',
      'login': 'Giriş Yap',
      'register': 'Kayıt Ol',
      'email': 'E-posta',
      'password': 'Şifre',
      'forgotPassword': 'Şifremi Unuttum',
      'home': 'Ana Sayfa',
      'profile': 'Profil',
      'settings': 'Ayarlar',
      'logout': 'Çıkış Yap',
      'uploadVideo': 'Video Yükle',
      'editVideo': 'Video Düzenle',
      'deleteVideo': 'Video Sil',
      'save': 'Kaydet',
      'cancel': 'İptal',
      'error': 'Hata',
      'success': 'Başarılı',
    },
  };

  String get appName => _localizedValues[locale.languageCode]!['appName']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgotPassword']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get uploadVideo => _localizedValues[locale.languageCode]!['uploadVideo']!;
  String get editVideo => _localizedValues[locale.languageCode]!['editVideo']!;
  String get deleteVideo => _localizedValues[locale.languageCode]!['deleteVideo']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 
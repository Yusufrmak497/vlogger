class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://api.vlogger.com';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  
  // Collections
  static const String usersCollection = 'users';
  static const String videosCollection = 'videos';
  static const String commentsCollection = 'comments';
  
  // Video Settings
  static const int maxVideoDuration = 60; // seconds
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  
  // Cache Settings
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const Duration cacheDuration = Duration(days: 7);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Error Messages
  static const String genericError = 'Bir hata oluştu. Lütfen tekrar deneyin.';
  static const String networkError = 'İnternet bağlantınızı kontrol edin.';
  static const String authError = 'Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.';
  
  // Success Messages
  static const String videoUploadSuccess = 'Video başarıyla yüklendi.';
  static const String profileUpdateSuccess = 'Profil başarıyla güncellendi.';
} 
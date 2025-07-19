import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/video_player_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../models/video.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String videoPlayer = '/video-player';
  static const String camera = '/camera';
  static const String notificationSettings = '/notification-settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(),
      profile: (context) => const ProfileScreen(),
      videoPlayer: (context) {
        final video = ModalRoute.of(context)!.settings.arguments as Video;
        return VideoPlayerScreen(video: video);
      },
      camera: (context) => CameraScreen(
        isFullScreen: true,
        onVideoSaved: (path) {}, // Dummy callback
      ),
      notificationSettings: (context) => const NotificationSettingsScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case videoPlayer:
        final video = settings.arguments as Video;
        return MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video));
      case camera:
        return MaterialPageRoute(
          builder: (_) => CameraScreen(
            isFullScreen: true,
            onVideoSaved: (path) {}, // Dummy callback
          ),
        );
      case notificationSettings:
        return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 
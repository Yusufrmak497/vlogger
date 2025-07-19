import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/camera_screen.dart';

import '../screens/video_player_screen.dart';
import '../screens/group_detail_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/group_settings_screen.dart';
import '../screens/add_friend_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/group.dart';
import '../models/video.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case '/camera':
        return MaterialPageRoute(
          builder: (_) => CameraScreen(
            isFullScreen: true,
            onVideoSaved: (path) {}, // Dummy callback, gerçek kullanımda HomeScreen'den gelmeli
          ),
        );
    
      case '/video-player':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            video: args['video'] as Video,
          ),
        );
      case '/group-detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => GroupDetailScreen(
            group: args['group'] as Group,
          ),
        );
      case '/create-group':
        return MaterialPageRoute(builder: (_) => const CreateGroupScreen());
      case '/group-settings':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => GroupSettingsScreen(
            group: args['group'] as Group,
          ),
        );
      case '/add-friend':
        return MaterialPageRoute(builder: (_) => const AddFriendScreen());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Sayfa bulunamadı')),
          ),
        );
    }
  }
} 
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Bildirim türleri
  static const String newVideoNotification = 'new_video';
  static const String likeNotification = 'like';
  static const String commentNotification = 'comment';
  static const String friendRequestNotification = 'friend_request';
  static const String groupInviteNotification = 'group_invite';
  static const String mentionNotification = 'mention';

  Future<void> initialize() async {
    print('NotificationService: initialize başladı');
    
    // Local notifications setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Firebase Cloud Messaging setup
    await _setupFirebaseMessaging();
    
    print('NotificationService: initialize tamamlandı');
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // İzinleri iste
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('NotificationService: FCM izin durumu: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // FCM token al
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('NotificationService: FCM Token: $token');
          await _saveFCMToken(token);
        }

        // Token yenilendiğinde
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('NotificationService: FCM Token yenilendi: $newToken');
          _saveFCMToken(newToken);
        });

        // Foreground mesajları dinle
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Background mesajları dinle
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Notification tıklandığında
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
      }
    } catch (e) {
      print('NotificationService: FCM setup hatası: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _database.ref('users/${user.uid}/fcmToken').set(token);
        print('NotificationService: FCM token kaydedildi');
      }
    } catch (e) {
      print('NotificationService: FCM token kaydetme hatası: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('NotificationService: Foreground mesaj alındı: ${message.data}');
    
    // Local notification göster
    showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'Yeni Bildirim',
      body: message.notification?.body ?? '',
      payload: json.encode(message.data),
    );
  }

  void _handleNotificationOpened(RemoteMessage message) {
    print('NotificationService: Notification tıklandı: ${message.data}');
    // Bildirim tıklandığında yapılacak işlemler
    _handleNotificationAction(message.data);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('NotificationService: Local notification tıklandı: ${response.payload}');
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationAction(data);
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'];
    final targetId = data['targetId'];
    
    switch (type) {
      case newVideoNotification:
        // Yeni video sayfasına git
        print('NotificationService: Yeni video bildirimi: $targetId');
        break;
      case likeNotification:
        // Beğeni bildirimi
        print('NotificationService: Beğeni bildirimi: $targetId');
        break;
      case commentNotification:
        // Yorum bildirimi
        print('NotificationService: Yorum bildirimi: $targetId');
        break;
      case friendRequestNotification:
        // Arkadaşlık isteği bildirimi
        print('NotificationService: Arkadaşlık isteği bildirimi: $targetId');
        break;
      case groupInviteNotification:
        // Grup daveti bildirimi
        print('NotificationService: Grup daveti bildirimi: $targetId');
        break;
      case mentionNotification:
        // Mention bildirimi
        print('NotificationService: Mention bildirimi: $targetId');
        break;
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vlogger_channel',
      'Vlogger Bildirimleri',
      channelDescription: 'Vlogger uygulaması bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFF6750A4),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(id, title, body, platformChannelSpecifics, payload: payload);
  }

  // Bildirim gönderme fonksiyonları
  Future<void> sendVideoNotification({
    required String userId,
    required String videoId,
    required String videoTitle,
    required String senderName,
  }) async {
    await _sendNotification(
      userId: userId,
      type: newVideoNotification,
      title: 'Yeni Video',
      body: '$senderName yeni bir video paylaştı: $videoTitle',
      data: {
        'type': newVideoNotification,
        'targetId': videoId,
        'videoTitle': videoTitle,
        'senderName': senderName,
      },
    );
  }

  Future<void> sendLikeNotification({
    required String userId,
    required String videoId,
    required String likerName,
  }) async {
    await _sendNotification(
      userId: userId,
      type: likeNotification,
      title: 'Yeni Beğeni',
      body: '$likerName videonuzu beğendi',
      data: {
        'type': likeNotification,
        'targetId': videoId,
        'likerName': likerName,
      },
    );
  }

  Future<void> sendCommentNotification({
    required String userId,
    required String videoId,
    required String commenterName,
    required String comment,
  }) async {
    await _sendNotification(
      userId: userId,
      type: commentNotification,
      title: 'Yeni Yorum',
      body: '$commenterName videonuzu yorumladı: $comment',
      data: {
        'type': commentNotification,
        'targetId': videoId,
        'commenterName': commenterName,
        'comment': comment,
      },
    );
  }

  Future<void> sendFriendRequestNotification({
    required String userId,
    required String senderName,
  }) async {
    await _sendNotification(
      userId: userId,
      type: friendRequestNotification,
      title: 'Arkadaşlık İsteği',
      body: '$senderName size arkadaşlık isteği gönderdi',
      data: {
        'type': friendRequestNotification,
        'senderName': senderName,
      },
    );
  }

  Future<void> sendGroupInviteNotification({
    required String userId,
    required String groupName,
    required String inviterName,
  }) async {
    await _sendNotification(
      userId: userId,
      type: groupInviteNotification,
      title: 'Grup Daveti',
      body: '$inviterName sizi $groupName grubuna davet etti',
      data: {
        'type': groupInviteNotification,
        'groupName': groupName,
        'inviterName': inviterName,
      },
    );
  }

  Future<void> _sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Kullanıcının FCM token'ını al
      final tokenSnapshot = await _database.ref('users/$userId/fcmToken').get();
      if (!tokenSnapshot.exists) {
        print('NotificationService: Kullanıcının FCM token\'ı bulunamadı: $userId');
        return;
      }

      final fcmToken = tokenSnapshot.value as String;
      
      // Bildirim verilerini Firebase'e kaydet
      final notificationRef = _database.ref('notifications').push();
      await notificationRef.set({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': ServerValue.timestamp,
        'read': false,
      });

      // FCM ile bildirim gönder (gerçek uygulamada Firebase Functions kullanılır)
      print('NotificationService: Bildirim gönderildi - Kullanıcı: $userId, Tür: $type');
      
    } catch (e) {
      print('NotificationService: Bildirim gönderme hatası: $e');
    }
  }

  // Okunmamış bildirim sayısını al
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _database
          .ref('notifications')
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists) return 0;

      int count = 0;
      for (var child in snapshot.children) {
        final data = child.value as Map<dynamic, dynamic>;
        if (data['read'] == false) {
          count++;
        }
      }
      return count;
    } catch (e) {
      print('NotificationService: Okunmamış bildirim sayısı alma hatası: $e');
      return 0;
    }
  }

  // Bildirimleri okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _database.ref('notifications/$notificationId/read').set(true);
    } catch (e) {
      print('NotificationService: Bildirim okundu işaretleme hatası: $e');
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _database
          .ref('notifications')
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists) return;

      for (var child in snapshot.children) {
        await child.ref.child('read').set(true);
      }
    } catch (e) {
      print('NotificationService: Tüm bildirimleri okundu işaretleme hatası: $e');
    }
  }

  // Bildirim ayarlarını kaydet
  Future<void> saveNotificationSettings(String userId, Map<String, bool> settings) async {
    try {
      await _database.ref('users/$userId/notificationSettings').set(settings);
    } catch (e) {
      print('NotificationService: Bildirim ayarları kaydetme hatası: $e');
    }
  }

  // Bildirim ayarlarını al
  Future<Map<String, bool>> getNotificationSettings(String userId) async {
    try {
      final snapshot = await _database.ref('users/$userId/notificationSettings').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Map<String, bool>.from(data);
      }
    } catch (e) {
      print('NotificationService: Bildirim ayarları alma hatası: $e');
    }
    
    // Varsayılan ayarlar
    return {
      newVideoNotification: true,
      likeNotification: true,
      commentNotification: true,
      friendRequestNotification: true,
      groupInviteNotification: true,
      mentionNotification: true,
    };
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('NotificationService: Background mesaj alındı: ${message.data}');
  // Background'da local notification göster
}
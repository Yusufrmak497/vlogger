import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> showNewVlogNotification({
    required String groupName,
    required String uploaderName,
    String? vlogId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'new_vlog_channel',
      'Yeni Vlog Bildirimleri',
      channelDescription: 'Gruplarda paylaşılan yeni vloglar için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF6750A4),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond, // Unique ID
      'Yeni Vlog',
      '$uploaderName, $groupName grubunda yeni bir vlog paylaştı!',
      details,
      payload: vlogId,
    );
  }

  Future<void> showNewMessageNotification({
    required String groupName,
    required String senderName,
    required String message,
    String? groupId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'new_message_channel',
      'Yeni Mesaj Bildirimleri',
      channelDescription: 'Gruplardaki yeni mesajlar için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF6750A4),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond, // Unique ID
      '$groupName - $senderName',
      message,
      details,
      payload: groupId,
    );
  }
} 
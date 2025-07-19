import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_popup.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  List<Map<String, dynamic>> _notifications = [];
  Map<String, UserModel?> _userCache = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _database
          .ref('notifications')
          .orderByChild('userId')
          .equalTo(_currentUserId)
          .get();

      if (snapshot.exists) {
        final List<Map<String, dynamic>> notifications = [];
        for (var child in snapshot.children) {
          final data = child.value as Map<dynamic, dynamic>;
          notifications.add({
            'id': child.key,
            ...Map<String, dynamic>.from(data),
          });
        }
        
        // Tarihe göre sırala (en yeni önce)
        notifications.sort((a, b) {
          final aTime = a['timestamp'] ?? 0;
          final bTime = b['timestamp'] ?? 0;
          return bTime.compareTo(aTime);
        });

        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        
        // Bildirimler yüklendikten sonra kullanıcı bilgilerini yükle
        await _loadUserProfiles();
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Bildirimler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfiles() async {
    // Her bildirim için gönderen kullanıcının bilgilerini yükle
    for (final notification in _notifications) {
      final senderId = notification['data']?['senderId'] ?? notification['data']?['likerName'] ?? notification['data']?['commenterName'];
      if (senderId != null && !_userCache.containsKey(senderId)) {
        try {
          final user = await _userService.getUserProfile(senderId);
          setState(() {
            _userCache[senderId] = user;
          });
        } catch (e) {
          print('Kullanıcı bilgileri yüklenirken hata: $e');
          setState(() {
            _userCache[senderId] = null;
          });
        }
      }
    }
  }

  String _getSenderName(Map<String, dynamic> notification) {
    final data = notification['data'] ?? {};
    final senderId = data['senderId'];
    final senderName = data['senderName'] ?? data['likerName'] ?? data['commenterName'];
    
    if (senderId != null && _userCache.containsKey(senderId)) {
      final user = _userCache[senderId];
      if (user != null && user.name.isNotEmpty) {
        return user.name;
      }
    }
    
    return senderName ?? 'Bilinmeyen Kullanıcı';
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      setState(() {
        _loadNotifications();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirim işaretlenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _database.ref('notifications/$notificationId').remove();
      setState(() {
        _loadNotifications();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirim silinirken hata: $e')),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationService.newVideoNotification:
        return Icons.video_library;
      case NotificationService.likeNotification:
        return Icons.favorite;
      case NotificationService.commentNotification:
        return Icons.comment;
      case NotificationService.friendRequestNotification:
        return Icons.person_add;
      case NotificationService.groupInviteNotification:
        return Icons.group_add;
      case NotificationService.mentionNotification:
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case NotificationService.newVideoNotification:
        return Colors.blue;
      case NotificationService.likeNotification:
        return Colors.red;
      case NotificationService.commentNotification:
        return Colors.green;
      case NotificationService.friendRequestNotification:
        return Colors.orange;
      case NotificationService.groupInviteNotification:
        return Colors.purple;
      case NotificationService.mentionNotification:
        return Colors.teal;
      default:
        return const Color(0xFF6750A4);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Şimdi';
    
    final now = DateTime.now();
    final notificationTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(notificationTime);
    
    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () async {
                try {
                  await _notificationService.markAllAsRead(_currentUserId!);
                  setState(() {
                    _loadNotifications();
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tüm bildirimler okundu olarak işaretlendi')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                }
              },
              tooltip: 'Tümünü okundu işaretle',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz bildiriminiz yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final type = notification['type'] ?? '';
                    final isRead = notification['read'] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: isRead ? Colors.white : Colors.blue.shade50,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getNotificationColor(type).withValues(alpha: 0.1),
                          child: Icon(
                            _getNotificationIcon(type),
                            color: _getNotificationColor(type),
                          ),
                        ),
                        title: Text(
                          notification['title'] ?? 'Bildirim',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification['body'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(notification['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'mark_read':
                                _markAsRead(notification['id']);
                                break;
                              case 'delete':
                                _deleteNotification(notification['id']);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (!isRead)
                              const PopupMenuItem(
                                value: 'mark_read',
                                child: Row(
                                  children: [
                                    Icon(Icons.check, size: 16),
                                    SizedBox(width: 8),
                                    Text('Okundu işaretle'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Sil', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Bildirime tıklandığında okundu işaretle
                          if (!isRead) {
                            _markAsRead(notification['id']);
                          }
                          
                          // Bildirim türüne göre işlem yap
                          _handleNotificationTap(notification);
                        },
                      ),
                    );
                  },
                ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] ?? '';
    final data = notification['data'] ?? {};
    
    switch (type) {
      case NotificationService.newVideoNotification:
        // Video oynatıcıya git
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video açılıyor: ${data['videoTitle'] ?? ''}')),
        );
        break;
      case NotificationService.likeNotification:
        // Video oynatıcıya git
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data['likerName'] ?? ''} videonuzu beğendi')),
        );
        break;
      case NotificationService.commentNotification:
        // Video oynatıcıya git
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data['commenterName'] ?? ''} videonuzu yorumladı')),
        );
        break;
      case NotificationService.friendRequestNotification:
        // Profil popup'ını göster
        _showProfilePopup(notification);
        break;
      case NotificationService.groupInviteNotification:
        // Grup detayına git
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data['inviterName'] ?? ''} sizi ${data['groupName'] ?? ''} grubuna davet etti')),
        );
        break;
      case NotificationService.mentionNotification:
        // Mention'ın olduğu yere git
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Birisi sizi etiketledi')),
        );
        break;
    }
  }

  void _showProfilePopup(Map<String, dynamic> notification) {
    final data = notification['data'] ?? {};
    final senderName = data['senderName'] ?? 'Bilinmeyen Kullanıcı';
    
    // Gerçek uygulamada Firebase'den gelecek
    final friendsList = <Map<String, dynamic>>[];
    final mutualFriendsList = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      builder: (context) => ProfilePopup(
        userId: data['senderId'] ?? '',
        userName: senderName,
        profileImageUrl: null,
        coverImageUrl: null,
        friendsCount: 0,
        mutualFriendsCount: 0,
        vlogCount: 0,
        friendsList: friendsList,
        mutualFriendsList: mutualFriendsList,
        onAcceptFriendRequest: () {
          Navigator.of(context).pop();
          _handleAcceptFriendRequest(notification);
        },
        onRejectFriendRequest: () {
          Navigator.of(context).pop();
          _handleRejectFriendRequest(notification);
        },
        onViewProfile: () {
          Navigator.of(context).pop();
          _handleViewProfile(notification);
        },
        onViewFriends: () {
          Navigator.of(context).pop();
          _handleViewFriends(notification);
        },
        onViewMutualFriends: () {
          Navigator.of(context).pop();
          _handleViewMutualFriends(notification);
        },
      ),
    );
  }

  void _handleAcceptFriendRequest(Map<String, dynamic> notification) {
    // Arkadaşlık isteğini kabul et
    _deleteNotification(notification['id']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_getSenderName(notification)} ile arkadaş oldunuz')),
    );
  }

  void _handleRejectFriendRequest(Map<String, dynamic> notification) {
    // Arkadaşlık isteğini reddet
    _deleteNotification(notification['id']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_getSenderName(notification)} arkadaşlık isteği reddedildi')),
    );
  }

  void _handleViewProfile(Map<String, dynamic> notification) {
    // Profil sayfasına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_getSenderName(notification)} profilini görüntüle')),
    );
  }

  void _handleViewFriends(Map<String, dynamic> notification) {
    // Arkadaş listesi sayfasına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_getSenderName(notification)} arkadaş listesini görüntüle')),
    );
  }

  void _handleViewMutualFriends(Map<String, dynamic> notification) {
    // Ortak arkadaşlar sayfasına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_getSenderName(notification)} ile ortak arkadaşları görüntüle')),
    );
  }
} 
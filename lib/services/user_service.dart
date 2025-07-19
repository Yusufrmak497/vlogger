import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class UserService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Kullanıcı ekle
  Future<void> createUser(UserModel user) async {
    await _db.child('users').child(user.id).set(user.toJson());
  }

  // Kullanıcı profilini getir
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final snapshot = await _db.child('users').child(userId).get();
      if (snapshot.exists && snapshot.value is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('UserService: getUserProfile hatası: $e');
      return null;
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.child('users').child(userId).update(data);
    } catch (e) {
      print('UserService: updateUserProfile hatası: $e');
      rethrow;
    }
  }

  // Kullanıcıyı sil
  Future<void> deleteUser(String userId) async {
    try {
      await _db.child('users').child(userId).remove();
    } catch (e) {
      print('UserService: deleteUser hatası: $e');
      rethrow;
    }
  }

  // Takip et
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await _db.child('users').child(currentUserId).child('following').child(targetUserId).set(true);
      await _db.child('users').child(targetUserId).child('followers').child(currentUserId).set(true);
    } catch (e) {
      print('UserService: followUser hatası: $e');
      rethrow;
    }
  }

  // Takipten çıkar
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await _db.child('users').child(currentUserId).child('following').child(targetUserId).remove();
      await _db.child('users').child(targetUserId).child('followers').child(currentUserId).remove();
    } catch (e) {
      print('UserService: unfollowUser hatası: $e');
      rethrow;
    }
  }

  // Tüm kullanıcıları getir
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _db.child('users').get();
      final List<UserModel> users = [];
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          try {
            if (entry.value is Map) {
            users.add(UserModel.fromJson(Map<String, dynamic>.from(entry.value as Map)));
            } else {
              print('UserService: Kullanıcı verisi Map değil, atlanıyor: ${entry.key}');
            }
          } catch (e) {
            print('Error parsing user: $e');
          }
        }
      }
      return users;
    } catch (e) {
      print('UserService: getAllUsers hatası: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  // Kullanıcının arkadaşlarını getir
  Future<List<String>> getUserFriends(String userId) async {
    try {
      final snapshot = await _db.child('users').child(userId).child('following').get();
      final List<String> friends = [];
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        friends.addAll(data.keys);
      }
      return friends;
    } catch (e) {
      print('UserService: getUserFriends hatası: $e');
      return [];
    }
  }

  // Kullanıcının takipçilerini getir
  Future<List<String>> getUserFollowers(String userId) async {
    try {
      final snapshot = await _db.child('users').child(userId).child('followers').get();
      final List<String> followers = [];
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        followers.addAll(data.keys);
      }
      return followers;
    } catch (e) {
      print('UserService: getUserFollowers hatası: $e');
      return [];
    }
  }

  // Arkadaşlık durumunu kontrol et
  Future<bool> isFriend(String currentUserId, String targetUserId) async {
    try {
      final snapshot = await _db.child('users').child(currentUserId).child('following').child(targetUserId).get();
      return snapshot.exists;
    } catch (e) {
      print('UserService: isFriend hatası: $e');
      return false;
    }
  }

  // Arkadaşlık isteği gönder
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      final requestId = '${fromUserId}_${toUserId}_${DateTime.now().millisecondsSinceEpoch}';
      await _db.child('friendRequests').child(requestId).set({
        'id': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': 'pending', // pending, accepted, rejected
        'createdAt': DateTime.now().toIso8601String(),
      });
      // Gönderen kullanıcının adını çek
      final senderUser = await getUserProfile(fromUserId);
      // Bildirim gönder
      await NotificationService().sendFriendRequestNotification(
        userId: toUserId,
        senderName: senderUser?.name ?? "Bir kullanıcı",
      );
    } catch (e) {
      print('UserService: sendFriendRequest hatası: $e');
      rethrow;
    }
  }

  // Gelen arkadaşlık isteklerini getir
  Future<List<Map<String, dynamic>>> getIncomingFriendRequests(String userId) async {
    try {
      final snapshot = await _db.child('friendRequests').orderByChild('toUserId').equalTo(userId).get();
      final List<Map<String, dynamic>> requests = [];
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          final request = Map<String, dynamic>.from(entry.value as Map);
          if (request['status'] == 'pending') {
            requests.add(request);
          }
        }
      }
      return requests;
    } catch (e) {
      print('UserService: getIncomingFriendRequests hatası: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  // Giden arkadaşlık isteklerini getir
  Future<List<Map<String, dynamic>>> getOutgoingFriendRequests(String userId) async {
    try {
      final snapshot = await _db.child('friendRequests').orderByChild('fromUserId').equalTo(userId).get();
      final List<Map<String, dynamic>> requests = [];
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          final request = Map<String, dynamic>.from(entry.value as Map);
          if (request['status'] == 'pending') {
            requests.add(request);
          }
        }
      }
      return requests;
    } catch (e) {
      print('UserService: getOutgoingFriendRequests hatası: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  // Arkadaşlık isteğini kabul et
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final snapshot = await _db.child('friendRequests').child(requestId).get();
      if (snapshot.exists) {
        final request = Map<String, dynamic>.from(snapshot.value as Map);
        final fromUserId = request['fromUserId'];
        final toUserId = request['toUserId'];
        
        // İsteği kabul edildi olarak işaretle
        await _db.child('friendRequests').child(requestId).child('status').set('accepted');
        
        // Karşılıklı arkadaşlık kur
        await followUser(fromUserId, toUserId);
        await followUser(toUserId, fromUserId);
      }
    } catch (e) {
      print('UserService: acceptFriendRequest hatası: $e');
      rethrow;
    }
  }

  // Arkadaşlık isteğini reddet
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _db.child('friendRequests').child(requestId).child('status').set('rejected');
    } catch (e) {
      print('UserService: rejectFriendRequest hatası: $e');
      rethrow;
    }
  }

  // Arkadaşlık isteği durumunu kontrol et
  Future<String?> getFriendRequestStatus(String fromUserId, String toUserId) async {
    try {
      final snapshot = await _db.child('friendRequests').orderByChild('fromUserId').equalTo(fromUserId).get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          final request = Map<String, dynamic>.from(entry.value as Map);
          if (request['toUserId'] == toUserId) {
            return request['status'];
          }
        }
      }
      return null; // İstek yok
    } catch (e) {
      print('UserService: getFriendRequestStatus hatası: $e');
      return null;
    }
  }

  Future<void> setDefaultProfileImagesForAllUsers() async {
    final snapshot = await _db.child('users').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final entry in data.entries) {
        final userId = entry.key;
        final userData = Map<String, dynamic>.from(entry.value as Map);
        if (userData['profileImageUrl'] == null || (userData['profileImageUrl'] as String).isEmpty) {
          await _db.child('users').child(userId).update({
            'profileImageUrl': 'https://picsum.photos/200/200',
          });
        }
      }
    }
  }
} 
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class MessageService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mesaj gönder
  Future<void> sendMessage(String groupId, String content, {String? imageUrl, String? videoUrl, String? replyTo, String? replyToMessage, String? replyToSender}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    final messageId = _db.child('groups').child(groupId).child('messages').push().key;
    if (messageId == null) throw Exception('Mesaj ID oluşturulamadı');

    final message = Message(
      id: messageId,
      groupId: groupId,
      senderId: user.uid,
      senderName: user.displayName ?? 'Anonim',
      content: content,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      replyTo: replyTo,
      replyToMessage: replyToMessage,
      replyToSender: replyToSender,
    );

    await _db.child('groups').child(groupId).child('messages').child(messageId).set(message.toMap());
  }

  // Grup mesajlarını dinle (gerçek zamanlı)
  Stream<List<Message>> watchGroupMessages(String groupId) {
    return _db.child('groups').child(groupId).child('messages').onValue.map((event) {
      final List<Message> messages = [];
      
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        for (final entry in data.entries) {
          try {
            final messageData = Map<String, dynamic>.from(entry.value as Map);
            messages.add(Message.fromMap(messageData));
          } catch (e) {
            print('Mesaj parse hatası: $e');
          }
        }
      }
      
      // Mesajları tarihe göre sırala
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Son mesajları getir
  Future<List<Message>> getGroupMessages(String groupId, {int limit = 50}) async {
    final snapshot = await _db.child('groups').child(groupId).child('messages')
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();
    
    final List<Message> messages = [];
    
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final entry in data.entries) {
        try {
          final messageData = Map<String, dynamic>.from(entry.value as Map);
          messages.add(Message.fromMap(messageData));
        } catch (e) {
          print('Mesaj parse hatası: $e');
        }
      }
    }
    
    // Mesajları tarihe göre sırala
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  // Mesaj sil
  Future<void> deleteMessage(String groupId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Mesajı getir ve gönderen kişi kontrolü yap
    final snapshot = await _db.child('groups').child(groupId).child('messages').child(messageId).get();
    if (snapshot.exists) {
      final messageData = Map<String, dynamic>.from(snapshot.value as Map);
      if (messageData['senderId'] != user.uid) {
        throw Exception('Bu mesajı silemezsiniz');
      }
    }

    // Mesajı tamamen silmek yerine isDeleted: true olarak işaretle
    await _db.child('groups').child(groupId).child('messages').child(messageId).update({
      'isDeleted': true,
      'content': '',
      'imageUrl': null,
      'videoUrl': null,
    });
  }

  // Mesaj düzenle
  Future<void> editMessage(String groupId, String messageId, String newContent) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Mesajı getir ve gönderen kişi kontrolü yap
    final snapshot = await _db.child('groups').child(groupId).child('messages').child(messageId).get();
    if (snapshot.exists) {
      final messageData = Map<String, dynamic>.from(snapshot.value as Map);
      if (messageData['senderId'] != user.uid) {
        throw Exception('Bu mesajı düzenleyemezsiniz');
      }
    }

    await _db.child('groups').child(groupId).child('messages').child(messageId).update({
      'content': newContent,
      'edited': true,
      'editedAt': DateTime.now().toIso8601String(),
    });
  }

  // Mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(String groupId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.child('groups').child(groupId).child('messages').child(messageId).update({
      'isRead': true,
    });
  }
} 
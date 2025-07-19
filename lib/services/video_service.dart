import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/video.dart';
import '../services/user_service.dart';

class VideoService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Video dosyasını Firebase Storage'a yükle
  Future<String> uploadVideoFile(String videoPath, String userId) async {
    final file = File(videoPath);
    final fileName = 'videos/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child(fileName);
    
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  }

  // Video yükle
  Future<void> uploadVideo(Video video) async {
    await _db.child('videos').child(video.id).set(video.toJson());
  }

  // Video getir
  Future<Video?> getVideo(String videoId) async {
    final snapshot = await _db.child('videos').child(videoId).get();
    if (snapshot.exists) {
      return Video.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  // Kullanıcının videolarını getir
  Future<List<Video>> getUserVideos(String userId) async {
    final snapshot = await _db.child('videos').orderByChild('userId').equalTo(userId).get();
    final List<Video> videos = [];
    
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final entry in data.entries) {
        try {
          videos.add(Video.fromJson(Map<String, dynamic>.from(entry.value as Map)));
        } catch (e) {
          print('Error parsing video: $e');
        }
      }
    }
    
    // Videoları tarihe göre sırala (en yeni önce)
    videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return videos;
  }

  // Grup videolarını getir
  Future<List<Video>> getGroupVideos(String groupId) async {
    final snapshot = await _db.child('groups').child(groupId).child('videos').get();
    final List<Video> videos = [];
    
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final entry in data.entries) {
        try {
          videos.add(Video.fromJson(Map<String, dynamic>.from(entry.value as Map)));
        } catch (e) {
          print('Error parsing video: $e');
        }
      }
    }
    
    // Videoları tarihe göre sırala (en yeni önce)
    videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return videos;
  }

  // Video güncelle
  Future<void> updateVideo(String videoId, Map<String, dynamic> data) async {
    await _db.child('videos').child(videoId).update(data);
  }

  // Video sil
  Future<void> deleteVideo(String videoId) async {
    await _db.child('videos').child(videoId).remove();
  }

  // Video beğen
  Future<void> likeVideo(String videoId, String userId) async {
    await _db.child('videos').child(videoId).child('likes').child(userId).set(true);
    
    // Beğeni sayısını güncelle
    final snapshot = await _db.child('videos').child(videoId).child('likes').get();
    if (snapshot.exists) {
      final likesCount = (snapshot.value as Map).length;
      await _db.child('videos').child(videoId).update({'likes': likesCount});
    }
  }

  // Video beğeniyi kaldır
  Future<void> unlikeVideo(String videoId, String userId) async {
    await _db.child('videos').child(videoId).child('likes').child(userId).remove();
    
    // Beğeni sayısını güncelle
    final snapshot = await _db.child('videos').child(videoId).child('likes').get();
    if (snapshot.exists) {
      final likesCount = (snapshot.value as Map).length;
      await _db.child('videos').child(videoId).update({'likes': likesCount});
    } else {
      await _db.child('videos').child(videoId).update({'likes': 0});
    }
  }



  // Video görüntülenme sayısını artır
  Future<void> incrementViews(String videoId) async {
    final snapshot = await _db.child('videos').child(videoId).child('views').get();
    int currentViews = 0;
    if (snapshot.exists) {
      currentViews = snapshot.value as int;
    }
    await _db.child('videos').child(videoId).update({'views': currentViews + 1});
  }

  // Videoları gerçek zamanlı dinle
  Stream<DatabaseEvent> watchUserVideos(String userId) {
    return _db.child('videos').orderByChild('userId').equalTo(userId).onValue;
  }

  // Grup videolarını gerçek zamanlı dinle
  Stream<DatabaseEvent> watchGroupVideos(String groupId) {
    return _db.child('groups').child(groupId).child('videos').onValue;
  }

  // Videoyu gruba paylaş
  Future<void> shareVideoToGroup({
    required String videoUrl,
    required String videoTitle,
    required String groupId,
    required String userId,
  }) async {
    final videoId = '${DateTime.now().millisecondsSinceEpoch}_$userId';
    
    // Kullanıcının username'ini al
    String username = 'user'; // Varsayılan değer
    try {
      final user = await UserService().getUserProfile(userId);
      if (user != null) {
        username = user.username;
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
    }
    
    final video = Video(
      id: videoId,
      userId: userId,
      username: username,
      title: videoTitle,
      description: '',
      url: videoUrl,
      thumbnailUrl: '', // Thumbnail eklenebilir
      likes: 0,
      views: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Video'yu ana videos tablosuna ekle
    await _db.child('videos').child(videoId).set(video.toJson());
    
    // Video'yu grup videos tablosuna ekle
    await _db.child('groups').child(groupId).child('videos').child(videoId).set(video.toJson());
    
    // Grubun son vlog güncellemesini yap
    await _db.child('groups').child(groupId).update({
      'lastVlog': DateTime.now().toIso8601String(),
    });
  }
} 
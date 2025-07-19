import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'dart:async';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Kullanıcı girişi - Firebase Auth ile
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('AuthService: Giriş denemesi başladı');
      print('AuthService: Email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('AuthService: Firebase Auth başarılı');
      print('AuthService: User ID: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        // Kullanıcı veritabanında var mı kontrol et, yoksa oluştur
        await _ensureUserInDatabase(userCredential.user!);
        
        // Firebase Auth stream'i otomatik olarak güncellenecek
        return {
          'success': true,
          'user': userCredential.user,
        };
      } else {
        return {
          'success': false,
          'error': 'Kullanıcı bulunamadı',
        };
      }
    } on FirebaseAuthException catch (e) {
      print('AuthService: FirebaseAuthException caught: ${e.code} - ${e.message}');
      String errorMessage = 'Bir hata oluştu';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Yanlış şifre';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        case 'user-disabled':
          errorMessage = 'Bu hesap devre dışı bırakılmış';
          break;
        case 'too-many-requests':
          errorMessage = 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin';
          break;
        case 'network-request-failed':
          errorMessage = 'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/şifre girişi etkin değil';
          break;
        default:
          errorMessage = 'Giriş hatası: ${e.message ?? e.code}';
          break;
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('AuthService: Unexpected error during sign in: $e');
      return {
        'success': false,
        'error': 'Beklenmeyen bir hata oluştu: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createUserWithEmailAndPassword(String email, String password, String name, String username) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Kullanıcı profilini güncelle
        await userCredential.user!.updateDisplayName(name);
        
        // Kullanıcıyı Realtime Database'e kaydet
        await _createUserInDatabase(userCredential.user!, name, username);
        
        // Firebase Auth stream'i otomatik olarak güncellenecek
        return {
          'success': true,
          'user': userCredential.user,
        };
      } else {
        throw Exception('Kayıt başarısız');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Bir hata oluştu';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu email adresi zaten kullanımda';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/şifre girişi etkin değil';
          break;
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Beklenmeyen bir hata oluştu: $e',
      };
    }
  }

  // Kullanıcıyı Realtime Database'e kaydet
  Future<void> _createUserInDatabase(User firebaseUser, String name, String username) async {
    try {
      final userModel = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: firebaseUser.email ?? '',
        username: firebaseUser.email?.split('@')[0] ?? 'user',
        profileImageUrl: firebaseUser.photoURL ?? 'https://picsum.photos/200/200', // Default profil fotoğrafı
        coverImageUrl: null,
        bio: 'Yeni kullanıcı',
        followers: [],
        following: [],
        groups: [],
        vlogs: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _userService.createUser(userModel);
      print('AuthService: Kullanıcı Realtime Database\'e kaydedildi: ${firebaseUser.uid}');
    } catch (e) {
      print('AuthService: Kullanıcı kaydetme hatası: $e');
    }
  }

  // Kullanıcının veritabanında var olduğundan emin ol
  Future<void> _ensureUserInDatabase(User firebaseUser) async {
    try {
      final existingUser = await _userService.getUserProfile(firebaseUser.uid);
      if (existingUser == null) {
        // Kullanıcı veritabanında yok, oluştur
        await _createUserInDatabase(firebaseUser, firebaseUser.displayName ?? 'Kullanıcı', firebaseUser.email?.split('@')[0] ?? 'user');
        print('AuthService: Giriş yapan kullanıcı veritabanına eklendi: ${firebaseUser.uid}');
      } else {
        print('AuthService: Kullanıcı zaten veritabanında mevcut: ${firebaseUser.uid}');
      }
    } catch (e) {
      print('AuthService: Kullanıcı kontrol hatası: $e');
    }
  }

  Future<void> signOut() async {
    try {
      print('AuthService: Çıkış işlemi başladı');
      print('AuthService: Mevcut kullanıcı: ${_auth.currentUser?.uid}');
      
      // Firebase Auth'dan çıkış yap
      await _auth.signOut();
      print('AuthService: Firebase Auth çıkış başarılı');
      print('AuthService: Çıkış sonrası kullanıcı: ${_auth.currentUser?.uid}');
      
      // Ek kontrol - kullanıcının gerçekten çıkış yaptığından emin ol
      if (_auth.currentUser != null) {
        print('AuthService: UYARI: Kullanıcı hala giriş yapmış durumda!');
        // Tekrar çıkış yapmayı dene
        await _auth.signOut();
        print('AuthService: İkinci çıkış denemesi sonrası kullanıcı: ${_auth.currentUser?.uid}');
      }
      
    } on FirebaseAuthException catch (e) {
      print('AuthService: Firebase Auth çıkış hatası: $e');
      if (e.code == 'requires-recent-login') {
        print('AuthService: Çıkış için yeniden kimlik doğrulama gerekiyor.');
      }
      rethrow;
    } catch (e) {
      print('AuthService: Beklenmeyen çıkış hatası: $e');
      rethrow;
    }
  }

  UserModel? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Kullanıcı',
        email: firebaseUser.email ?? '',
        username: firebaseUser.email?.split('@')[0] ?? 'user',
        profileImageUrl: firebaseUser.photoURL,
        coverImageUrl: null,
        bio: 'Yeni kullanıcı',
        followers: [],
        following: [],
        groups: [],
        vlogs: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return null;
  }

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      print('AuthService Stream: Firebase User: ${firebaseUser?.uid}');
      print('AuthService Stream: Firebase User Email: ${firebaseUser?.email}');
      
      if (firebaseUser != null) {
        final userModel = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Kullanıcı',
          email: firebaseUser.email ?? '',
          username: firebaseUser.email?.split('@')[0] ?? 'user',
          profileImageUrl: firebaseUser.photoURL,
          coverImageUrl: null,
          bio: 'Yeni kullanıcı',
          followers: [],
          following: [],
          groups: [],
          vlogs: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        print('AuthService Stream: UserModel oluşturuldu: ${userModel.id}');
        return userModel;
      } else {
        print('AuthService Stream: Firebase User null');
        return null;
      }
    });
  }

  Future<Map<String, dynamic>> updateUserProfile(UserModel updatedUser) async {
    return {
      'success': true,
      'user': updatedUser,
    };
  }

  Future<UserModel?> getUserFromStorage(String userId) async {
    // Gerçek uygulamada Firebase'den gelecek
    return null;
  }

  // Şifre sıfırlama - Firebase Auth ile
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Şifre sıfırlama linki email adresinize gönderildi',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Bir hata oluştu';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Beklenmeyen bir hata oluştu: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Kullanıcı girişi yapılmamış',
        };
      }
      
      final userId = currentUser.uid;
      
      // 1. Realtime Database'den kullanıcı verilerini sil
      try {
        await _userService.deleteUser(userId);
        print('AuthService: Kullanıcı verileri Realtime Database\'den silindi: $userId');
      } catch (e) {
        print('AuthService: Realtime Database silme hatası: $e');
        // Realtime Database silme hatası olsa bile devam et
      }
      
      // 2. Firebase Auth'dan kullanıcıyı sil
      await currentUser.delete();
      print('AuthService: Kullanıcı Firebase Auth\'dan silindi: $userId');
      
      return {
        'success': true,
        'message': 'Hesap başarıyla silindi',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Bir hata oluştu';
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage = 'Hesap silmek için tekrar giriş yapmanız gerekiyor';
          break;
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Beklenmeyen bir hata oluştu: $e',
      };
    }
  }
} 
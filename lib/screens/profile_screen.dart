import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import '../widgets/friend_card.dart';
import '../widgets/profile_popup.dart';
import '../screens/my_vlogs_screen.dart';
import '../screens/my_groups_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../services/group_service.dart'; // GroupService'i ekledim

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  UserModel? _userModel;
  bool _isLoading = true;
  int _groupCount = 0; // Grup sayısı için ayrı değişken

  File? _selectedProfileImage;
  File? _selectedCoverImage;
  final ImagePicker _imagePicker = ImagePicker();

  List<UserModel> _friends = [];
  bool _isFriendsLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchFriends();
    _fetchGroupCount(); // Grup sayısını ayrı çek
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her açıldığında grup sayısını güncelle
    _fetchGroupCount();
  }

  Future<void> _fetchUserProfile() async {
    print('Profil: _fetchUserProfile başladı');
    final firebaseUser = FirebaseAuth.instance.currentUser;
    print('Profil: Firebase currentUser: ${firebaseUser?.uid}');
    if (firebaseUser != null) {
      final user = await UserService().getUserProfile(firebaseUser.uid);
      print('Profil: UserService.getUserProfile sonucu: $user');
      if (user != null) {
        setState(() {
          _userModel = user;
          _usernameController.text = user.username;
          _displayNameController.text = user.name;
          _bioController.text = user.bio ?? '';
          _isLoading = false;
        });
        print('Profil: setState ile kullanıcı verisi ekrana aktarıldı. username: ${user.username}, name: ${user.name}, bio: ${user.bio}');
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Profil: UserService.getUserProfile null döndü.');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Profil: Firebase currentUser null.');
    }
    print('Profil: _fetchUserProfile bitti');
  }

  Future<void> _fetchGroupCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final groups = await GroupService().getUserGroups(user.uid);
      setState(() {
        _groupCount = groups.length;
      });
      print('Profil: Kullanıcının grup sayısı: $_groupCount');
    }
  }

  Future<void> _fetchFriends() async {
    if (_userModel == null) return;
    setState(() { _isFriendsLoading = true; });
    final userService = UserService();
    final List<UserModel> friends = [];
    for (final friendId in _userModel!.following) {
      final friend = await userService.getUserProfile(friendId);
      if (friend != null) friends.add(friend);
    }
    setState(() {
      _friends = friends;
      _isFriendsLoading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userModel == null && !_isLoading) {
      Future.microtask(() {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      // AppBar kaldırıldı
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userModel == null
              ? const Center(child: Text('Kullanıcı profili bulunamadı'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 60),
                      _buildStatsSection(),
                      const SizedBox(height: 24),
                      _buildProfileInfo(),
                      const SizedBox(height: 24),
                      _buildMenuSection(),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: [
        // Cover Photo
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6750A4),
                const Color(0xFF8B5CF6),
                const Color(0xFFA855F7),
              ],
            ),
            image: _userModel?.coverImageUrl != null && _userModel!.coverImageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_userModel!.coverImageUrl!),
                    fit: BoxFit.cover,
                    opacity: 0.7,
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        // Profile Photo
        Positioned(
          left: 20,
          bottom: -60,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF8F2FF),
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              color: Colors.white,
            ),
            child: _userModel?.profileImageUrl != null && _userModel!.profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _userModel!.profileImageUrl!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => _buildProfilePlaceholder(),
                    ),
                  )
                : _buildProfilePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePlaceholder() {
    final name = _userModel?.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF6750A4),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Gruplar', '$_groupCount', Icons.group, onTap: null),
          _buildStatItem('Arkadaşlar', '${_userModel?.following.length ?? 0}', Icons.people, onTap: _showFriendsModal),
          _buildStatItem('Vloglar', '${_userModel?.vlogs.length ?? 0}', Icons.video_library, onTap: null),
          _buildStatItem('Takip', '${_userModel?.followers.length ?? 0}', Icons.favorite, onTap: null),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String count, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6750A4),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    if (_userModel == null) return;
    // PROFİL FOTOĞRAFI ZORUNLU
    if (_userModel!.profileImageUrl == null || _userModel!.profileImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil fotoğrafı seçmelisiniz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await UserService().updateUserProfile(
        userId: _userModel!.id,
        data: {
          'username': _usernameController.text.trim(),
          'name': _displayNameController.text.trim(),
          'bio': _bioController.text.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      // Güncellenen veriyi tekrar çek
      await _fetchUserProfile();
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Color(0xFF6750A4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Form key ekle
  final _formKey = GlobalKey<FormState>();

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            print('profile info tapped'); // DEBUG
            if (_userModel != null) {
              showDialog(
                context: context,
                builder: (context) => ProfilePopup(
                  userId: _userModel!.id,
                  userName: _userModel!.name,
                  profileImageUrl: _userModel!.profileImageUrl,
                  coverImageUrl: _userModel!.coverImageUrl,
                  friendsCount: _userModel!.followers.length,
                  mutualFriendsCount: 0,
                  vlogCount: _userModel!.vlogs.length,
                  friendsList: null,
                  mutualFriendsList: null,
                  onAcceptFriendRequest: null,
                  onRejectFriendRequest: null,
                  onViewProfile: null,
                  onViewFriends: null,
                  onViewMutualFriends: null,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı adı ve ad soyad
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${_userModel?.username ?? ''}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6750A4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userModel?.name ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bio
                Expanded(
                  flex: 3,
                  child: (_userModel?.bio != null && _userModel!.bio!.isNotEmpty)
                      ? Text(
                          _userModel!.bio!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.right,
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6750A4),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6750A4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF6750A4).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Kaydet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Profili Düzenle',
            subtitle: 'Kişisel bilgilerini güncelle',
            onTap: () {
              _showEditProfileDialog();
            },
          ),
          _buildMenuItem(
            icon: Icons.group_outlined,
            title: 'Gruplarım',
            subtitle: 'Katıldığın grupları görüntüle',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyGroupsScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.video_library_outlined,
            title: 'Vloglarım',
            subtitle: 'Oluşturduğun vlogları görüntüle',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyVlogsScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Bildirim Ayarları',
            subtitle: 'Bildirim tercihlerini yönet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6750A4).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6750A4), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1C1B1F),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF6750A4),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showLogoutDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isProfile) {
          _selectedProfileImage = File(image.path);
        } else {
          _selectedCoverImage = File(image.path);
        }
      });
    }
  }



  Future<String?> _uploadImageToStorage(File file, String path) async {
    final bucket = 'gs://vlogger-57c93.firebasestorage.app';
    print('Storage upload başlıyor: $bucket/$path');
    try {
      // Dosyayı doğrudan yükle (özgün kalite)
      final storage = FirebaseStorage.instanceFor(bucket: bucket);
      final ref = storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      // Yükleme ilerlemesini dinle
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / (snapshot.totalBytes == 0 ? 1 : snapshot.totalBytes);
        print('Yükleme ilerlemesi: \u001b[38;5;2m${(progress * 100).toStringAsFixed(2)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)\u001b[0m');
      }, onError: (e) {
        print('Upload error: $e');
      });

      final completedTask = await uploadTask;
      final url = await completedTask.ref.getDownloadURL();
      print('Storage upload tamamlandı: $url');
      return url;
    } catch (e) {
      print('Storage upload error: $e');
      return null;
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kapak fotoğrafı (tıklanabilir)
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: _userModel?.coverImageUrl != null
                              ? NetworkImage('${_userModel!.coverImageUrl}?${DateTime.now().millisecondsSinceEpoch}')
                              : const NetworkImage('https://picsum.photos/800/400'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
                  // Profil fotoğrafı (tıklanabilir)
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: GestureDetector(
                      onTap: () => _pickImage(true),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          image: DecorationImage(
                            image: _userModel?.profileImageUrl != null
                                ? NetworkImage('${_userModel!.profileImageUrl}?${DateTime.now().millisecondsSinceEpoch}')
                                : const NetworkImage('https://picsum.photos/200'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
                  // Form alanları
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      border: OutlineInputBorder(),
                    ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kullanıcı adı gerekli';
                        }
                        if (value.length < 3) {
                          return 'Kullanıcı adı en az 3 karakter olmalıdır';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir';
                        }
                        return null;
                      },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder(),
                    ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ad soyad gerekli';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Ad ve soyad giriniz';
                        }
                        return null;
                      },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Biyografi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            Navigator.pop(context);
                          },
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            print('Kaydet butonuna basıldı');
                            FocusScope.of(context).unfocus();
                              
                              // Form validation
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              
                            if (_userModel == null) return;
                            setState(() { _isLoading = true; });
                            String? profileImageUrl = _userModel!.profileImageUrl;
                            String? coverImageUrl = _userModel!.coverImageUrl;
                            // Profil fotoğrafı seçildiyse Storage'a yükle
                            if (_selectedProfileImage != null) {
                              profileImageUrl = await _uploadImageToStorage(
                                _selectedProfileImage!,
                                'profile_images/${_userModel!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                              );
                            }
                            // Kapak fotoğrafı seçildiyse Storage'a yükle
                            if (_selectedCoverImage != null) {
                              coverImageUrl = await _uploadImageToStorage(
                                _selectedCoverImage!,
                                'cover_images/${_userModel!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                              );
                            }
                            try {
                              await UserService().updateUserProfile(
                                userId: _userModel!.id,
                                data: {
                                  'username': _usernameController.text.trim(),
                                  'name': _displayNameController.text.trim(),
                                  'bio': _bioController.text.trim(),
                                  'profileImageUrl': profileImageUrl,
                                  'coverImageUrl': coverImageUrl,
                                  'updatedAt': DateTime.now().toIso8601String(),
                                },
                              );
                              print('Profil: updateUserProfile tamamlandı');
                              await _fetchUserProfile(); // fetchUserProfile bittikten sonra dialogu kapat
                              print('Profil: _fetchUserProfile çağrısı bitti');
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profil başarıyla güncellendi'),
                                  backgroundColor: Color(0xFF6750A4),
                                ),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              setState(() {
                                _isEditing = false;
                              });
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profil güncellenemedi: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6750A4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFriendsModal() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arkadaşlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6750A4)),
              ),
              const SizedBox(height: 12),
              _isFriendsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _friends.isEmpty
                      ? const Text('Henüz arkadaşın yok.')
                      : Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _friends.length,
                            itemBuilder: (context, index) {
                              final friend = _friends[index];
                              return GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (context) => ProfilePopup(
                                    userId: friend.id,
                                    userName: friend.name,
                                    profileImageUrl: friend.profileImageUrl,
                                    coverImageUrl: friend.coverImageUrl,
                                    friendsCount: friend.followers.length,
                                    mutualFriendsCount: 0, // İstersen mutual hesaplayabilirsin
                                    vlogCount: friend.vlogs.length,
                                    friendsList: null,
                                    mutualFriendsList: null,
                                    onAcceptFriendRequest: null,
                                    onRejectFriendRequest: null,
                                    onViewProfile: null,
                                    onViewFriends: null,
                                    onViewMutualFriends: null,
                                  ),
                                ),
                                child: FriendCard(
                                  friend: friend,
                                  onRemove: () async {
                                    await UserService().unfollowUser(_userModel!.id, friend.id);
                                    setState(() {
                                      _friends.removeAt(index);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${friend.name} arkadaşlıktan çıkarıldı')),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
    _fetchFriends();
  }

  void _showFriendInfoCard(UserModel friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: friend.profileImageUrl != null && friend.profileImageUrl!.isNotEmpty
                  ? NetworkImage(friend.profileImageUrl!)
                  : null,
              backgroundColor: const Color(0xFF6750A4),
              child: (friend.profileImageUrl == null || friend.profileImageUrl!.isEmpty)
                  ? Text(
                      friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              friend.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6750A4)),
            ),
            const SizedBox(height: 8),
            Text(
              '@${friend.username}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              print('ProfileScreen: Logout butonuna basıldı');
              Navigator.pop(context);
              
              // Loading göster
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Çıkış yapılıyor...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
              
              try {
                print('ProfileScreen: Çıkış işlemi başladı');
                print('ProfileScreen: Mevcut kullanıcı: ${FirebaseAuth.instance.currentUser?.uid}');
                print('ProfileScreen: Mevcut kullanıcı email: ${FirebaseAuth.instance.currentUser?.email}');
                
                await AuthService().signOut();
                print('ProfileScreen: Çıkış işlemi başarılı');
                print('ProfileScreen: Çıkış sonrası kullanıcı: ${FirebaseAuth.instance.currentUser?.uid}');
                print('ProfileScreen: Çıkış sonrası kullanıcı email: ${FirebaseAuth.instance.currentUser?.email}');
                
                // AuthWrapper otomatik olarak LoginScreen'e yönlendirecek
                // Manuel yönlendirmeye gerek yok
                
                // Ek güvenlik için manuel yönlendirme ekle
                if (mounted && FirebaseAuth.instance.currentUser == null) {
                  print('ProfileScreen: Manuel yönlendirme yapılıyor');
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                } else {
                  print('ProfileScreen: Manuel yönlendirme yapılmadı - kullanıcı hala mevcut');
                }
                
              } catch (e) {
                print('ProfileScreen: Çıkış hatası: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yapılırken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/user_service.dart'; // Added import for UserService
import '../widgets/profile_popup.dart'; // Added import for ProfilePopup
import '../services/group_service.dart'; // Added import for GroupService
import '../models/user_model.dart';

class GroupSettingsScreen extends StatefulWidget {
  final Group group;

  const GroupSettingsScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _showEditGroupNameDialog() {
    final TextEditingController nameController = TextEditingController(text: widget.group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grup Adını Düzenle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Grup adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                // TODO: Grup adını güncelle
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Grup adı "${nameController.text}" olarak güncellendi')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF6750A4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Gruptan Çık',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // İçerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Uyarı Mesajı
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu gruptan çıktığınızda:\n• Grup mesajlarını göremezsiniz\n• Grup medyasına erişemezsiniz\n• Grup ayarlarını değiştiremezsiniz',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Grup Bilgileri
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF6750A4),
                            child: Text(
                              widget.group.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.group.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.group.members.length} üye',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Seçenekler
                    Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.archive, color: Color(0xFF6750A4)),
                          title: const Text('Grubu Arşivle'),
                          subtitle: const Text('Grubu gizle ama çıkma'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Grup arşivlendi')),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.notifications_off, color: Color(0xFF6750A4)),
                          title: const Text('Bildirimleri Kapat'),
                          subtitle: const Text('Sadece bildirimleri kapat'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Grup bildirimleri kapatıldı')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Çıkış Butonu
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Modal'ı kapat
                          _confirmLeaveGroup();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Gruptan Çık',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // İptal Butonu
                    Container(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'İptal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Son Onay'),
        content: const Text('Bu gruptan çıkmak istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Grup ayarlarından çık
              Navigator.pop(context); // Grup detayından çık
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.group.name} grubundan çıktınız'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    bool messageNotifications = true;
    bool mediaNotifications = true;
    bool groupActivityNotifications = true;
    bool soundEnabled = true;
    bool vibrationEnabled = true;
    String selectedSound = 'Varsayılan';
    String quietHours = 'Kapalı';
    bool showPreview = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Başlık ve Kapatma
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF6750A4),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Bildirim Ayarları',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Bildirim Türleri
                    const Text(
                      'Bildirim Türleri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6750A4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Mesaj Bildirimleri'),
                      subtitle: const Text('Yeni mesajlar için bildirim al'),
                      value: messageNotifications,
                      onChanged: (value) => setState(() => messageNotifications = value),
                      activeColor: const Color(0xFF6750A4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    SwitchListTile(
                      title: const Text('Medya Bildirimleri'),
                      subtitle: const Text('Fotoğraf, video ve dosya paylaşımları için bildirim al'),
                      value: mediaNotifications,
                      onChanged: (value) => setState(() => mediaNotifications = value),
                      activeColor: const Color(0xFF6750A4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    SwitchListTile(
                      title: const Text('Grup Aktivitesi'),
                      subtitle: const Text('Üye ekleme, çıkarma gibi aktiviteler için bildirim al'),
                      value: groupActivityNotifications,
                      onChanged: (value) => setState(() => groupActivityNotifications = value),
                      activeColor: const Color(0xFF6750A4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    const Divider(),
                    
                    // Ses ve Titreşim
                    const Text(
                      'Ses ve Titreşim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6750A4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Ses'),
                      subtitle: const Text('Bildirim sesi çal'),
                      value: soundEnabled,
                      onChanged: (value) => setState(() => soundEnabled = value),
                      activeColor: const Color(0xFF6750A4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    SwitchListTile(
                      title: const Text('Titreşim'),
                      subtitle: const Text('Bildirim titreşimi'),
                      value: vibrationEnabled,
                      onChanged: (value) => setState(() => vibrationEnabled = value),
                      activeColor: const Color(0xFF6750A4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    ListTile(
                      title: const Text('Bildirim Sesi'),
                      subtitle: Text(selectedSound),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Bildirim Sesi Seç'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                'Varsayılan',
                                'Ding',
                                'Chime',
                                'Bell',
                                'Sessiz',
                              ].map((sound) => ListTile(
                                title: Text(sound),
                                trailing: selectedSound == sound ? const Icon(Icons.check, color: Color(0xFF6750A4)) : null,
                                onTap: () {
                                  setState(() => selectedSound = sound);
                                  Navigator.pop(context);
                                },
                              )).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    
                    // Sessiz Saatler
                    const Text(
                      'Sessiz Saatler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6750A4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Sessiz Saatler'),
                      subtitle: Text(quietHours),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sessiz Saatler'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                'Kapalı',
                                '22:00 - 08:00',
                                '23:00 - 07:00',
                                '00:00 - 06:00',
                                'Özel',
                              ].map((hours) => ListTile(
                                title: Text(hours),
                                trailing: quietHours == hours ? const Icon(Icons.check, color: Color(0xFF6750A4)) : null,
                                onTap: () {
                                  setState(() => quietHours = hours);
                                  Navigator.pop(context);
                                },
                              )).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    
                    // Görünüm
                    const Text(
                      'Görünüm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6750A4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Mesaj Önizlemesi'),
                      subtitle: const Text('Bildirimde mesaj içeriğini göster'),
                      value: showPreview,
                      onChanged: (value) => setState(() => showPreview = value),
                      activeColor: const Color(0xFF6750A4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String?> _userNameCache = {}; // userId -> full name

  Future<String> _getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId] ?? 'Kullanıcı';
    }
    try {
      final user = await UserService().getUserProfile(userId);
      final name = user?.name ?? 'Kullanıcı';
      setState(() {
        _userNameCache[userId] = name;
      });
      return name;
    } catch (e) {
      setState(() {
        _userNameCache[userId] = 'Kullanıcı';
      });
      return 'Kullanıcı';
    }
  }

  void _showAddMemberModal() async {
    final allUsers = await UserService().getAllUsers();
    final currentMembers = widget.group.members;
    final nonMembers = allUsers.where((u) => !currentMembers.contains(u.id)).toList();

    showModalBottomSheet(
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
                'Kullanıcı Ekle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6750A4)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: nonMembers.isEmpty
                    ? const Center(child: Text('Eklenebilecek başka kullanıcı yok.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: nonMembers.length,
                        itemBuilder: (context, index) {
                          final user = nonMembers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                                  : null,
                            ),
                            title: Text(user.name),
                            subtitle: Text('@${user.username}'),
                            onTap: () async {
                              // Gruba ekle
                              await GroupService().addMemberToGroup(widget.group.id, user.id);
                              if (mounted) {
                                Navigator.pop(context);
                                setState(() {
                                  widget.group.members.add(user.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${user.name} gruba eklendi')),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        title: const Text(
          'Grup Ayarları',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // Grup Bilgileri
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.group.members.length} üye',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Medya Bölümü
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Medya İstatistikleri
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaStat('Fotoğraflar', 0, Icons.image), // Placeholder for actual count
                    ),
                    Expanded(
                      child: _buildMediaStat('Videolar', 0, Icons.videocam), // Placeholder for actual count
                    ),
                    Expanded(
                      child: _buildMediaStat('Dosyalar', 0, Icons.insert_drive_file), // Placeholder for actual count
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Medya Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 0, // Placeholder for actual count
                  itemBuilder: (context, index) {
                    return _buildMediaItem('https://picsum.photos/200/200?random=1', 'Ali', false); // Placeholder
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Üyeler Bölümü
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Üyeler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Color(0xFF6750A4)),
                        tooltip: 'Üye Ekle',
                        onPressed: _showAddMemberModal,
                      ),
                    ],
                  ),
                ),
                ...widget.group.members.map((member) => FutureBuilder<UserModel?>(
                  future: UserService().getUserProfile(member),
                  builder: (context, userSnapshot) {
                    final user = userSnapshot.data;
                    final displayName = user?.name ?? 'Kullanıcı';
                    return ListTile(
                      leading: user != null && user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(user.profileImageUrl!),
                            )
                          : CircleAvatar(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                      title: Text(displayName),
                      subtitle: const Text('Üye'),
                      trailing: const Icon(Icons.more_vert, color: Colors.grey),
                      onTap: () async {
                        // Üye profilini göster
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return user != null
                                ? ProfilePopup(
                                    userId: user.id,
                                    userName: user.name,
                                    profileImageUrl: user.profileImageUrl,
                                    coverImageUrl: user.coverImageUrl,
                                    friendsCount: user.followers.length,
                                    mutualFriendsCount: 0,
                                    vlogCount: user.vlogs.length,
                                    friendsList: null,
                                    mutualFriendsList: null,
                                    onAcceptFriendRequest: null,
                                    onRejectFriendRequest: null,
                                    onViewProfile: null,
                                    onViewFriends: null,
                                    onViewMutualFriends: null,
                                  )
                                : AlertDialog(
                                    title: const Text('Kullanıcı bulunamadı'),
                                    content: const Text('Kullanıcı profili getirilemedi.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Kapat'),
                                      ),
                                    ],
                                  );
                          },
                        );
                      },
                    );
                  },
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Ayarlar Bölümü
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Ayarlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF6750A4)),
                  title: const Text('Grup Adını Düzenle'),
                  onTap: _showEditGroupNameDialog,
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF6750A4)),
            title: const Text('Bildirim Ayarları'),
                  onTap: _showNotificationSettings,
                ),
                ListTile(
                  leading: const Icon(Icons.visibility, color: Color(0xFF6750A4)),
                  title: const Text('Grup Gizliliği'),
            onTap: () {
                    // TODO: Gizlilik ayarları
            },
          ),
                const Divider(),
          ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Gruptan Çık', style: TextStyle(color: Colors.red)),
                  onTap: _showLeaveGroupConfirmation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMediaStat(String title, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6750A4), size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
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
    );
  }

  Widget _buildMediaItem(String imageUrl, String sender, bool isVideo) {
    return GestureDetector(
      onTap: () {
        // TODO: Medyayı tam ekran göster
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            if (isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sender,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
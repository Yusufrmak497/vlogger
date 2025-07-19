import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final settings = await _notificationService.getNotificationSettings(currentUser.id);
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Bildirim ayarları yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      setState(() {
        _settings[key] = value;
      });

      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _notificationService.saveNotificationSettings(currentUser.id, _settings);
      }
    } catch (e) {
      print('Bildirim ayarı güncellenirken hata: $e');
      // Hata durumunda eski değere geri dön
      setState(() {
        _settings[key] = !value;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayar güncellenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required String settingKey,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, color: const Color(0xFF6750A4)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ),
      value: _settings[settingKey] ?? true,
      onChanged: (value) => _updateSetting(settingKey, value),
      activeColor: const Color(0xFF6750A4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  const Text(
                    'Bildirim Türleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6750A4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hangi bildirimleri almak istediğinizi seçin',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bildirim ayarları
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          title: 'Yeni Videolar',
                          subtitle: 'Takip ettiğiniz kişiler yeni video paylaştığında',
                          settingKey: NotificationService.newVideoNotification,
                          icon: Icons.video_library,
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          title: 'Beğeniler',
                          subtitle: 'Videolarınız beğenildiğinde',
                          settingKey: NotificationService.likeNotification,
                          icon: Icons.favorite,
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          title: 'Yorumlar',
                          subtitle: 'Videolarınız yorumlandığında',
                          settingKey: NotificationService.commentNotification,
                          icon: Icons.comment,
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          title: 'Arkadaşlık İstekleri',
                          subtitle: 'Yeni arkadaşlık istekleri geldiğinde',
                          settingKey: NotificationService.friendRequestNotification,
                          icon: Icons.person_add,
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          title: 'Grup Davetleri',
                          subtitle: 'Bir gruba davet edildiğinizde',
                          settingKey: NotificationService.groupInviteNotification,
                          icon: Icons.group_add,
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          title: 'Mentionlar',
                          subtitle: 'Birisi sizi etiketlediğinde',
                          settingKey: NotificationService.mentionNotification,
                          icon: Icons.alternate_email,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Genel ayarlar
                  const Text(
                    'Genel Ayarlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6750A4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.notifications_off,
                            color: Color(0xFF6750A4),
                          ),
                          title: const Text(
                            'Tüm Bildirimleri Kapat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text(
                            'Geçici olarak tüm bildirimleri devre dışı bırak',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Switch(
                            value: false, // Bu özellik daha sonra eklenebilir
                            onChanged: null,
                            activeColor: const Color(0xFF6750A4),
                          ),
                        ),
                        const Divider(height: 1),
                                                 ListTile(
                           leading: const Icon(
                             Icons.volume_up,
                             color: Color(0xFF6750A4),
                           ),
                          title: const Text(
                            'Bildirim Sesi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text(
                            'Bildirim geldiğinde ses çal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Switch(
                            value: true, // Bu özellik daha sonra eklenebilir
                            onChanged: null,
                            activeColor: const Color(0xFF6750A4),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.vibration,
                            color: Color(0xFF6750A4),
                          ),
                          title: const Text(
                            'Titreşim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text(
                            'Bildirim geldiğinde titreşim ver',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Switch(
                            value: true, // Bu özellik daha sonra eklenebilir
                            onChanged: null,
                            activeColor: const Color(0xFF6750A4),
                          ),
                        ),
                      ],
                    ),
                  ),



                  // Bilgi kartı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bildirim İzinleri',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bildirimleri almak için cihaz ayarlarından izin vermeniz gerekebilir.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 
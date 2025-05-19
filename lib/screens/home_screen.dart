import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'login_screen.dart';
import 'group_detail_screen.dart';
import '../models/group.dart';
import 'add_friend_screen.dart';
import 'edit_profile_screen.dart';
import 'create_group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _recordedVideos = [];
  List<Group> groups = [
    Group(
      id: '1',
      name: 'Okul Arkadaşları',
      createdBy: 'user1',
      members: ['Ahmet K.', 'Mehmet Y.', 'Zeynep A.'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Group(
      id: '2',
      name: 'İş Arkadaşları',
      createdBy: 'user1',
      members: ['Can B.', 'Deniz M.', 'Elif S.', 'Burak T.'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  void _handleVideoSaved(String videoPath) {
    setState(() {
      _recordedVideos.insert(0, videoPath);
      _selectedIndex = 2; // Switch to edit tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: _selectedIndex == 0 ? _buildHomeAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          const SizedBox(), // Placeholder for camera tab
          _buildEditContent(),
          _buildProfileContent(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            // Camera tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(
                  isFullScreen: true,
                  onVideoSaved: _handleVideoSaved,
                ),
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF6750A4)),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: Color(0xFF6750A4)),
            label: 'Kamera',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit, color: Color(0xFF6750A4)),
            label: 'Düzenle',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF6750A4)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF6750A4),
      title: const Text(
        'Vlogger',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.group_add, color: Colors.white),
          onPressed: () async {
            final newGroup = await Navigator.push<Group>(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGroupScreen(),
              ),
            );

            if (newGroup != null) {
              setState(() {
                groups.insert(0, newGroup);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${newGroup.name} grubu oluşturuldu')),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddFriendScreen(),
              ),
            );
          },
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return groups.isEmpty
        ? const Center(
            child: Text(
              'Henüz grup yok\nYeni bir grup oluşturmak için + butonuna tıklayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(group: group),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEADDFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6750A4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '3 yeni bildirim',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Son güncelleme: ${_formatTimeAgo(group.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: group.members.length,
                          itemBuilder: (context, memberIndex) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://picsum.photos/150/200?random=${index * 10 + memberIndex}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        group.members[memberIndex],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
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

  Widget _buildEditContent() {
    if (_recordedVideos.isEmpty) {
      return const Center(
        child: Text(
          'Henüz video yok\nYeni bir video çekmek için kamera butonuna tıklayın',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recordedVideos.length,
      itemBuilder: (context, index) {
        final videoPath = _recordedVideos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
            ),
            title: Text('Video ${index + 1}'),
            subtitle: Text(videoPath),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show video options
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            // Cover Photo
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage('https://picsum.photos/800/400'),
                  fit: BoxFit.cover,
                ),
                color: Colors.grey[300],
              ),
            ),
            // Profile Picture
            Positioned(
              bottom: -50,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage('https://picsum.photos/200'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kullanıcı Adı',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '@kullanici',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profili Düzenle',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.group_outlined,
                  title: 'Gruplarım',
                  onTap: () {},
                ),
                _buildProfileMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Ayarlar',
                  onTap: () {},
                ),
                _buildProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Yardım',
                  onTap: () {},
                ),
                const Spacer(),
                _buildProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Çıkış Yap',
                  onTap: () => _showLogoutDialog(context),
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Gruplar', '12'),
          _buildStatItem('Vloglar', '48'),
          _buildStatItem('Arkadaşlar', '156'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6750A4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF6750A4),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Grup Oluştur'),
        content: TextField(
          controller: groupNameController,
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
              if (groupNameController.text.isNotEmpty) {
                // TODO: Implement group creation
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${groupNameController.text} grubu oluşturuldu')),
                );
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement actual logout logic here
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }
} 
 
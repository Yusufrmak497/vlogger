import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomLeft,
              children: [
                // Kapak Fotoğrafı
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: const DecorationImage(
                      image: NetworkImage('https://picsum.photos/800/400'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Profil Fotoğrafı
                Positioned(
                  left: 16,
                  bottom: -50,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF8F2FF),
                        width: 4,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage('https://picsum.photos/200'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '@yusuf',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6750A4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Yusuf İrmak',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatColumn('Gruplar', '12'),
                      const SizedBox(width: 32),
                      _buildStatColumn('Arkadaşlar', '256'),
                      const SizedBox(width: 32),
                      _buildStatColumn('Vloglar', '48'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Profili Düzenle',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.group_outlined,
              title: 'Gruplarım',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.video_library_outlined,
              title: 'Vloglarım',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.bookmark_outline,
              title: 'Kaydedilenler',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Yardım',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6750A4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6750A4)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1C1B1F),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF6750A4),
      ),
      onTap: onTap,
    );
  }
} 
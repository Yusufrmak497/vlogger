import 'package:flutter/material.dart';
import '../models/group.dart';

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF6750A4)),
            title: const Text('Grup Adını Düzenle'),
            onTap: () {
              // TODO: Implement group name editing
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFF6750A4)),
            title: const Text('Üyeleri Yönet'),
            onTap: () {
              // TODO: Implement member management
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF6750A4)),
            title: const Text('Bildirim Ayarları'),
            onTap: () {
              // TODO: Implement notification settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Grubu Sil', style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Implement group deletion
            },
          ),
        ],
      ),
    );
  }
} 
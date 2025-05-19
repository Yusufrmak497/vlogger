import 'package:flutter/material.dart';
import '../models/group.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedFriends = [];

  // Örnek arkadaş listesi - gerçek uygulamada API'den gelecek
  final List<Map<String, dynamic>> _friends = [
    {'id': '1', 'name': 'Ahmet K.', 'avatar': 'https://picsum.photos/200?random=1'},
    {'id': '2', 'name': 'Mehmet Y.', 'avatar': 'https://picsum.photos/200?random=2'},
    {'id': '3', 'name': 'Zeynep A.', 'avatar': 'https://picsum.photos/200?random=3'},
    {'id': '4', 'name': 'Can B.', 'avatar': 'https://picsum.photos/200?random=4'},
    {'id': '5', 'name': 'Deniz M.', 'avatar': 'https://picsum.photos/200?random=5'},
  ];

  void _createGroup() {
    if (_groupNameController.text.isEmpty || _selectedFriends.isEmpty) return;

    // Seçilen arkadaşların isimlerini al
    final selectedFriendNames = _friends
        .where((friend) => _selectedFriends.contains(friend['id']))
        .map((friend) => friend['name'] as String)
        .toList();

    // Yeni grup oluştur
    final newGroup = Group(
      id: DateTime.now().toString(), // Geçici ID
      name: _groupNameController.text,
      createdBy: 'user1', // Gerçek uygulamada mevcut kullanıcı ID'si
      members: selectedFriendNames,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, newGroup);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        title: const Text(
          'Grup Kur',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _selectedFriends.isEmpty || _groupNameController.text.isEmpty
                ? null
                : _createGroup,
            child: const Text(
              'Oluştur',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'Grup adı',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.group, color: Color(0xFF6750A4)),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Arkadaşlarım',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6750A4),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                final isSelected = _selectedFriends.contains(friend['id']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(friend['avatar']),
                    ),
                    title: Text(friend['name']),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedFriends.add(friend['id']);
                          } else {
                            _selectedFriends.remove(friend['id']);
                          }
                        });
                      },
                      activeColor: const Color(0xFF6750A4),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 
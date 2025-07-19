import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();
  
  List<UserModel> _friends = [];
  Set<String> _selectedFriends = {};
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _currentUserId = currentUser.uid;
        final friendIds = await _userService.getUserFriends(currentUser.uid);
        final friends = <UserModel>[];
        
        for (final friendId in friendIds) {
          final friend = await _userService.getUserProfile(friendId);
          if (friend != null) {
            friends.add(friend);
          }
      }
      
      setState(() {
          _friends = friends;
        _isLoading = false;
      });
      }
    } catch (e) {
      print('Arkadaşlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedFriends.isEmpty || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir arkadaş seçmelisiniz')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Seçilen arkadaşların ID'lerini al
      final selectedFriendIds = _friends
          .where((friend) => _selectedFriends.contains(friend.id))
          .map((friend) => friend.id)
          .toList();

      // Mevcut kullanıcıyı da gruba ekle
      selectedFriendIds.add(_currentUserId!);

      // Yeni grup oluştur
      final newGroup = Group(
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        name: _groupNameController.text,
        createdBy: _currentUserId!,
        members: selectedFriendIds, // GroupService kaydederken Map'e çeviriyor
        createdAt: DateTime.now(),
      );

      // Firebase'e kaydet
      await _groupService.createGroup(newGroup);

      if (mounted) {
        Navigator.pop(context, newGroup);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newGroup.name} grubu başarıyla oluşturuldu')),
        );
      }
    } catch (e) {
      print('Grup oluşturulurken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup oluşturulamadı: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
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
      body: Form(
        key: _formKey,
        child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
              child: TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'Grup adı',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.group, color: Color(0xFF6750A4)),
              ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Grup adı gerekli';
                  }
                  if (value.length < 3) {
                    return 'Grup adı en az 3 karakter olmalıdır';
                  }
                  return null;
                },
              onChanged: (value) => setState(() {}),
            ),
          ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextFormField(
                controller: _groupDescriptionController,
                decoration: const InputDecoration(
                  hintText: 'Grup açıklaması (isteğe bağlı)',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.description, color: Color(0xFF6750A4)),
                ),
                maxLines: 3,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz arkadaşınız yok\nArkadaş eklemek için + butonuna tıklayın',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final isSelected = _selectedFriends.contains(friend.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: friend.profileImageUrl != null
                                    ? NetworkImage(friend.profileImageUrl!)
                                    : null,
                                child: friend.profileImageUrl == null
                                    ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?')
                                    : null,
                              ),
                              title: Text(friend.name),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedFriends.add(friend.id);
                                    } else {
                                      _selectedFriends.remove(friend.id);
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
      ),
    );
  }
} 
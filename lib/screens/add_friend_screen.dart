import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();

  
  bool _isSearching = false;
  bool _isLoading = true;
  List<UserModel> _searchResults = [];
  List<UserModel> _allUsers = [];
  String? _currentUserId;
  Set<String> _friends = {}; // Mevcut arkadaşların ID'leri
  Map<String, String> _requestStatus = {}; // İstek durumları (pending, accepted, rejected)

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _loadUsers();
      await _loadFriends();
      await _loadRequestStatuses();
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final allUsers = await _userService.getAllUsers();
      if (_currentUserId != null) {
        _allUsers = allUsers.where((user) => user.id != _currentUserId).toList();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcılar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
        _allUsers = []; // Hata durumunda boş liste
      });
      
      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcılar yüklenemedi. Lütfen daha sonra tekrar deneyin.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadRequestStatuses() async {
    if (_currentUserId == null) return;
    
    try {
      for (final user in _allUsers) {
        final status = await _userService.getFriendRequestStatus(_currentUserId!, user.id);
        if (status != null) {
          _requestStatus[user.id] = status;
        }
      }
      setState(() {});
    } catch (e) {
      print('İstek durumları yüklenirken hata: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      if (_currentUserId != null) {
        // Mevcut arkadaşları yükle
        final friends = await _userService.getUserFriends(_currentUserId!);
        setState(() {
          _friends = friends.toSet();
        });
      }
    } catch (e) {
      print('Arkadaşlar yüklenirken hata: $e');
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = _allUsers
            .where((user) =>
                user.username.toLowerCase().contains(query.toLowerCase()) ||
                user.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _searchResults = [];
      }
    });
  }

  Future<void> _sendFriendRequest(UserModel user) async {
    if (_currentUserId == null) return;

    try {
      await _userService.sendFriendRequest(_currentUserId!, user.id);
      setState(() {
        _requestStatus[user.id] = 'pending';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} kullanıcısına arkadaşlık isteği gönderildi'),
            backgroundColor: const Color(0xFF6750A4),
          ),
        );
      }
    } catch (e) {
      print('Arkadaşlık isteği gönderilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İstek gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelFriendRequest(UserModel user) async {
    if (_currentUserId == null) return;

    try {
      // Giden istekleri bul ve sil
      final outgoingRequests = await _userService.getOutgoingFriendRequests(_currentUserId!);
      for (final request in outgoingRequests) {
        if (request['toUserId'] == user.id) {
          await _userService.rejectFriendRequest(request['id']);
          break;
        }
      }
      
      setState(() {
        _requestStatus.remove(user.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} kullanıcısına gönderilen istek iptal edildi'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('İstek iptal edilirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstek iptal edilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getButtonText(String userId) {
    if (_friends.contains(userId)) {
      return 'Arkadaş';
    } else if (_requestStatus[userId] == 'pending') {
      return 'İstek Gönderildi';
    } else if (_requestStatus[userId] == 'accepted') {
      return 'Arkadaş';
    } else if (_requestStatus[userId] == 'rejected') {
      return 'Reddedildi';
    } else {
      return 'İstek Gönder';
    }
  }

  IconData _getButtonIcon(String userId) {
    if (_friends.contains(userId)) {
      return Icons.person_remove;
    } else if (_requestStatus[userId] == 'pending') {
      return Icons.schedule;
    } else if (_requestStatus[userId] == 'accepted') {
      return Icons.person_remove;
    } else if (_requestStatus[userId] == 'rejected') {
      return Icons.block;
    } else {
      return Icons.person_add;
    }
  }

  Color _getButtonColor(String userId) {
    if (_friends.contains(userId)) {
      return Colors.red;
    } else if (_requestStatus[userId] == 'pending') {
      return Colors.orange;
    } else if (_requestStatus[userId] == 'accepted') {
      return Colors.red;
    } else if (_requestStatus[userId] == 'rejected') {
      return Colors.grey;
    } else {
      return const Color(0xFF6750A4);
    }
  }

  void _handleButtonPress(UserModel user) {
    if (_friends.contains(user.id)) {
      _toggleFriendship(user);
    } else if (_requestStatus[user.id] == 'pending') {
      _cancelFriendRequest(user);
    } else if (_requestStatus[user.id] == null) {
      _sendFriendRequest(user);
    }
  }

  void _showIncomingRequests() async {
    if (_currentUserId == null) return;

    try {
      final requests = await _userService.getIncomingFriendRequests(_currentUserId!);
      
      if (requests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gelen arkadaşlık isteğiniz yok')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gelen Arkadaşlık İstekleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Widget>>(
                  future: Future.wait(
                    requests.map((request) async {
                      final fromUser = await _userService.getUserProfile(request['fromUserId']);
                      if (fromUser == null) return const SizedBox.shrink();
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: fromUser.profileImageUrl != null
                              ? NetworkImage(fromUser.profileImageUrl!)
                              : null,
                          child: fromUser.profileImageUrl == null
                              ? Text(fromUser.name.isNotEmpty ? fromUser.name[0].toUpperCase() : '?')
                              : null,
                        ),
                        title: Text(fromUser.name),
                        subtitle: Text('@${fromUser.username}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await _userService.acceptFriendRequest(request['id']);
                                Navigator.pop(context);
                                await _loadFriends();
                                await _loadRequestStatuses();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${fromUser.name} arkadaş olarak eklendi')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await _userService.rejectFriendRequest(request['id']);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${fromUser.name} isteği reddedildi')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }
                    
                    final widgets = snapshot.data ?? [];
                    return ListView(
                      children: widgets,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Gelen istekler yüklenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İstekler yüklenemedi: $e')),
      );
    }
  }

  Future<void> _toggleFriendship(UserModel user) async {
    if (_currentUserId == null) return;

    try {
      final isCurrentlyFriend = _friends.contains(user.id);
      
      if (isCurrentlyFriend) {
        // Arkadaşlıktan çıkar
        await _userService.unfollowUser(_currentUserId!, user.id);
        setState(() {
          _friends.remove(user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} arkadaşlıktan çıkarıldı'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Arkadaş ekle
        await _userService.followUser(_currentUserId!, user.id);
        setState(() {
          _friends.add(user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} arkadaş olarak eklendi'),
            backgroundColor: const Color(0xFF6750A4),
          ),
        );
      }
    } catch (e) {
      print('Arkadaşlık işlemi sırasında hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        title: const Text(
          'Arkadaş Ekle',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: _showIncomingRequests,
            tooltip: 'Gelen İstekler',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı veya isim ile ara...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Kullanıcılar yükleniyor...'),
                ],
              ),
            )
          : _isSearching
              ? _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Kullanıcı bulunamadı',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              backgroundColor: const Color(0xFF6750A4),
                              child: user.profileImageUrl == null
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            title: Text(user.name),
                            subtitle: Text('@${user.username}'),
                            trailing: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getButtonText(user.id),
                                    style: TextStyle(
                                      color: _getButtonColor(user.id),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      _getButtonIcon(user.id),
                                      color: _getButtonColor(user.id),
                                    ),
                                    onPressed: () => _handleButtonPress(user),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _allUsers.isEmpty ? Icons.error_outline : Icons.search,
                        size: 64,
                        color: _allUsers.isEmpty ? Colors.orange : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _allUsers.isEmpty 
                            ? 'Kullanıcılar yüklenemedi'
                            : 'Arkadaşlarını bulmak için arama yap',
                        style: TextStyle(
                          color: _allUsers.isEmpty ? Colors.orange : Colors.grey[600],
                          fontSize: 16,
                          fontWeight: _allUsers.isEmpty ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (_allUsers.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Firebase izin sorunu nedeniyle kullanıcılar yüklenemedi.\nLütfen daha sonra tekrar deneyin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
} 
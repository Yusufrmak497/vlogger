import 'package:flutter/material.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Örnek kullanıcı listesi (gerçek uygulamada API'den gelecek)
  final List<Map<String, dynamic>> _allUsers = [
    {
      'username': 'ahmet123',
      'name': 'Ahmet Yılmaz',
      'avatar': 'A',
      'isFriend': false,
    },
    {
      'username': 'ayse.k',
      'name': 'Ayşe Kara',
      'avatar': 'A',
      'isFriend': true,
    },
    {
      'username': 'mehmet42',
      'name': 'Mehmet Demir',
      'avatar': 'M',
      'isFriend': false,
    },
  ];

  void _handleSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = _allUsers
            .where((user) =>
                user['username'].toLowerCase().contains(query.toLowerCase()) ||
                user['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _searchResults = [];
      }
    });
  }

  void _toggleFriendship(Map<String, dynamic> user) {
    setState(() {
      user['isFriend'] = !user['isFriend'];
      // Gerçek uygulamada burada API çağrısı yapılacak
      if (user['isFriend']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name']} arkadaş olarak eklendi'),
            backgroundColor: const Color(0xFF6750A4),
          ),
        );
      }
    });
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
      body: _isSearching
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
                          backgroundColor: const Color(0xFF6750A4),
                          child: Text(
                            user['avatar'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['name']),
                        subtitle: Text('@${user['username']}'),
                        trailing: IconButton(
                          icon: Icon(
                            user['isFriend']
                                ? Icons.person_remove
                                : Icons.person_add,
                            color: const Color(0xFF6750A4),
                          ),
                          onPressed: () => _toggleFriendship(user),
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
                    Icons.search,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arkadaşlarını bulmak için arama yap',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 
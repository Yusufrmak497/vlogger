import 'package:flutter/material.dart';

class ProfilePopup extends StatelessWidget {
  final String userId;
  final String userName;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final int friendsCount;
  final int mutualFriendsCount;
  final int vlogCount;
  final List<Map<String, dynamic>>? friendsList;
  final List<Map<String, dynamic>>? mutualFriendsList;
  final VoidCallback? onAcceptFriendRequest;
  final VoidCallback? onRejectFriendRequest;
  final VoidCallback? onViewProfile;
  final VoidCallback? onViewFriends;
  final VoidCallback? onViewMutualFriends;

  const ProfilePopup({
    super.key,
    required this.userId,
    required this.userName,
    this.profileImageUrl,
    this.coverImageUrl,
    required this.friendsCount,
    required this.mutualFriendsCount,
    required this.vlogCount,
    this.friendsList,
    this.mutualFriendsList,
    this.onAcceptFriendRequest,
    this.onRejectFriendRequest,
    this.onViewProfile,
    this.onViewFriends,
    this.onViewMutualFriends,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
              child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kapak fotoğrafı - daha büyük
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  // Kapak fotoğrafı için koşullu DecorationImage
                  image: (coverImageUrl?.isNotEmpty ?? false)
                      ? DecorationImage(
                          image: NetworkImage(coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Profil fotoğrafı - tam görünür
                    Positioned(
                      bottom: -5,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(context, profileImageUrl, userName),
                        child: Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            // Profil fotoğrafı için koşullu DecorationImage
                            image: (profileImageUrl?.isNotEmpty ?? false)
                                ? DecorationImage(
                                    image: NetworkImage(profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // Kapatma butonu
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // İçerik
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15), // Profil fotoğrafı için boşluk
                    // Kullanıcı adı
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // İstatistikler - tıklanabilir
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Arkadaş',
                            friendsCount.toString(),
                            Icons.people,
                            onTap: () => _showAllFriendsDialog(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'Ortak',
                            mutualFriendsCount.toString(),
                            Icons.group,
                            onTap: () => _showAllMutualFriendsDialog(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'Vlog',
                            vlogCount.toString(),
                            Icons.videocam,
                            onTap: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Arkadaş listesi önizlemesi
                    if (friendsList != null && friendsList!.isNotEmpty) ...[
                      const Text(
                        'Arkadaşlar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          itemCount: friendsList!.length > 3 ? 3 : friendsList!.length,
                          itemBuilder: (context, index) {
                            final friend = friendsList![index];
                            return Container(
                              margin: const EdgeInsets.only(right: 0),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showFullScreenImage(
                                      context,
                                      friend['avatar'] != null && friend['avatar'].isNotEmpty ? friend['avatar'] : null,
                                      friend['name'] ?? '',
                                    ),
                                    child: friend['avatar'] != null && friend['avatar'].isNotEmpty
                                        ? CircleAvatar(
                                            radius: 14,
                                            backgroundImage: NetworkImage(friend['avatar']),
                                          )
                                        : CircleAvatar(
                                            radius: 14,
                                            child: Text(
                                              friend['name'] != null && friend['name'].isNotEmpty ? friend['name'][0].toUpperCase() : '?',
                                              style: const TextStyle(fontSize: 10, color: Colors.white),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    friend['name'] ?? 'Arkadaş',
                                    style: const TextStyle(fontSize: 7),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Butonlar
                    if (onAcceptFriendRequest != null || onRejectFriendRequest != null)
                      Row(
                        children: [
                          if (onAcceptFriendRequest != null)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onAcceptFriendRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6750A4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Kabul Et'),
                              ),
                            ),
                          if (onAcceptFriendRequest != null && onRejectFriendRequest != null)
                            const SizedBox(width: 8),
                          if (onRejectFriendRequest != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onRejectFriendRequest,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Reddet'),
                              ),
                            ),
                        ],
                      ),
                    if (onViewProfile != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onViewProfile,
                          child: const Text(
                            'Profili Görüntüle',
                            style: TextStyle(color: Color(0xFF6750A4)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String? imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Tam ekran resim
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl ?? 'https://picsum.photos/400/400'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Kapatma butonu
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Başlık
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.grey.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF6750A4),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllFriendsDialog(BuildContext context) {
    if (friendsList == null || friendsList!.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF6750A4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$userName\'in Arkadaşları (${friendsList!.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              // Arkadaş listesi
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: friendsList!.length,
                  itemBuilder: (context, index) {
                    final friend = friendsList![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              friend['avatar'] != null && friend['avatar'].isNotEmpty ? friend['avatar'] : null,
                              friend['name'] ?? '',
                            ),
                            child: friend['avatar'] != null && friend['avatar'].isNotEmpty
                                ? CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage(friend['avatar']),
                                  )
                                : CircleAvatar(
                                    radius: 22,
                                    child: Text(
                                      friend['name'] != null && friend['name'].isNotEmpty ? friend['name'][0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend['name'] ?? 'Arkadaş',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (friend['status'] != null)
                                  Text(
                                    friend['status'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.withOpacity(0.5),
                            size: 16,
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
      ),
    );
  }

  void _showAllMutualFriendsDialog(BuildContext context) {
    if (mutualFriendsList == null || mutualFriendsList!.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF6750A4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$userName\'in Ortak Arkadaşları (${mutualFriendsList!.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              // Ortak arkadaş listesi
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: mutualFriendsList!.length,
                  itemBuilder: (context, index) {
                    final friend = mutualFriendsList![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              friend['avatar'] != null && friend['avatar'].isNotEmpty ? friend['avatar'] : null,
                              friend['name'] ?? 'Ortak',
                            ),
                            child: friend['avatar'] != null && friend['avatar'].isNotEmpty
                                ? CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage(friend['avatar']),
                                  )
                                : CircleAvatar(
                                    radius: 22,
                                    child: Text(
                                      friend['name'] != null && friend['name'].isNotEmpty ? friend['name'][0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend['name'] ?? 'Ortak',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (friend['status'] != null)
                                  Text(
                                    friend['status'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.withOpacity(0.5),
                            size: 16,
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
      ),
    );
  }
} 
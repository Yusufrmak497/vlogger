import 'package:flutter/material.dart';
import '../models/user_model.dart';

class FriendCard extends StatelessWidget {
  final UserModel friend;
  final VoidCallback onRemove;

  const FriendCard({super.key, required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
        subtitle: Text('@${friend.username}'),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove, color: Colors.red),
          tooltip: 'Arkadaşlıktan çıkar',
          onPressed: onRemove,
        ),
      ),
    );
  }
} 
import 'package:firebase_database/firebase_database.dart';
import '../models/group.dart';

class GroupService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Grup oluştur
  Future<void> createGroup(Group group) async {
    // members alanını Map<String, bool> olarak kaydet
    final membersMap = { for (var id in group.members) id: true };
    await _db.child('groups').child(group.id).set({
      'id': group.id,
      'name': group.name,
      'createdBy': group.createdBy,
      'members': membersMap,
      'lastVlog': group.lastVlog,
      'createdAt': group.createdAt.toIso8601String(),
    });
  }

  // Grup getir
  Future<Group?> getGroup(String groupId) async {
    final snapshot = await _db.child('groups').child(groupId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return Group(
        id: data['id'],
        name: data['name'],
        createdBy: data['createdBy'],
        members: List<String>.from(data['members']),
        lastVlog: data['lastVlog'],
        createdAt: DateTime.parse(data['createdAt']),
      );
    }
    return null;
  }

  // Kullanıcının gruplarını getir
  Future<List<Group>> getUserGroups(String userId) async {
    final snapshot = await _db.child('groups').get();
    final List<Group> groups = [];
    
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final entry in data.entries) {
        final groupData = Map<String, dynamic>.from(entry.value as Map);
        final membersRaw = groupData['members'];
        List<String> membersList = [];
        if (membersRaw is List) {
          membersList = membersRaw.map((e) => e.toString()).toList();
        } else if (membersRaw is Map) {
          membersList = membersRaw.keys.map((e) => e.toString()).toList();
        }
        print('DEBUG: Grup ${groupData['id']} üyeleri: $membersList, userId: $userId, içeriyor mu: ${membersList.contains(userId)}');
        if (membersList.contains(userId)) {
          groups.add(Group(
            id: groupData['id'],
            name: groupData['name'],
            createdBy: groupData['createdBy'],
            members: membersList,
            lastVlog: groupData['lastVlog'],
            createdAt: DateTime.parse(groupData['createdAt']),
          ));
        }
      }
    }
    print('DEBUG: getUserGroups - Kullanıcı $userId için bulunan grup sayısı: ${groups.length}');
    return groups;
  }

  // Grup güncelle
  Future<void> updateGroup(String groupId, Map<String, dynamic> data) async {
    await _db.child('groups').child(groupId).update(data);
  }

  // Gruba üye ekle
  Future<void> addMemberToGroup(String groupId, String userId) async {
    await _db.child('groups').child(groupId).child('members').child(userId).set(true);
  }

  // Gruptan üye çıkar
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await _db.child('groups').child(groupId).child('members').child(userId).remove();
  }

  // Grup sil
  Future<void> deleteGroup(String groupId) async {
    await _db.child('groups').child(groupId).remove();
  }

  // Grup mesajlarını dinle (gerçek zamanlı)
  Stream<DatabaseEvent> watchGroupMessages(String groupId) {
    return _db.child('groups').child(groupId).child('messages').onValue;
  }
} 
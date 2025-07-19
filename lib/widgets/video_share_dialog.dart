import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/video_service.dart';

class VideoShareDialog extends StatefulWidget {
  final String videoPath;
  final String videoTitle;

  const VideoShareDialog({
    super.key,
    required this.videoPath,
    required this.videoTitle,
  });

  @override
  State<VideoShareDialog> createState() => _VideoShareDialogState();
}

class _VideoShareDialogState extends State<VideoShareDialog> {
  final GroupService _groupService = GroupService();
  final VideoService _videoService = VideoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Group> _userGroups = [];
  List<String> _selectedGroups = [];
  bool _isLoading = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final groups = await _groupService.getUserGroups(userId);
        setState(() {
          _userGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Grup yükleme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_selectedGroups.contains(groupId)) {
        _selectedGroups.remove(groupId);
      } else {
        _selectedGroups.add(groupId);
      }
    });
  }

  Future<void> _shareVideo() async {
    if (_selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir grup seçmelisiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı bulunamadı');

      // Video dosyasını Firebase Storage'a yükle
      final videoUrl = await _videoService.uploadVideoFile(widget.videoPath, userId);

      // Seçilen her gruba video paylaş
      for (final groupId in _selectedGroups) {
        await _videoService.shareVideoToGroup(
          videoUrl: videoUrl,
          videoTitle: widget.videoTitle,
          groupId: groupId,
          userId: userId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video başarıyla paylaşıldı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Video paylaşım hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video paylaşımı başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.share, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Video Paylaş',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _userGroups.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Henüz hiçbir gruba dahil değilsiniz',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _userGroups.length,
                          itemBuilder: (context, index) {
                            final group = _userGroups[index];
                            final isSelected = _selectedGroups.contains(group.id);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.grey[300],
                                  child: Icon(
                                    Icons.group,
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                  ),
                                ),
                                title: Text(
                                  group.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('${group.members.length} üye'),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (value) => _toggleGroupSelection(group.id),
                                ),
                                onTap: () => _toggleGroupSelection(group.id),
                              ),
                            );
                          },
                        ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSharing ? null : () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSharing || _selectedGroups.isEmpty 
                          ? null 
                          : _shareVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSharing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Paylaş'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
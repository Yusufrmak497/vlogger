import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/video_service.dart';
import '../models/video.dart';
import 'video_player_screen.dart';

class MyVlogsScreen extends StatefulWidget {
  const MyVlogsScreen({Key? key}) : super(key: key);

  @override
  State<MyVlogsScreen> createState() => _MyVlogsScreenState();
}

class _MyVlogsScreenState extends State<MyVlogsScreen> {
  List<Video> _vlogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVlogs();
  }

  Future<void> _fetchVlogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final videos = await VideoService().getUserVideos(user.uid);
    setState(() {
      _vlogs = videos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vloglarım'),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8F2FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vlogs.isEmpty
              ? const Center(child: Text('Henüz hiç vlog yüklemedin.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vlogs.length,
                  itemBuilder: (context, index) {
                    final vlog = _vlogs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.play_circle_fill, color: Color(0xFF6750A4), size: 40),
                        title: Text(
                          vlog.title.isNotEmpty ? vlog.title : 'Vlog',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          vlog.createdAt.toString().split('.').first.replaceAll('T', ' '),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF6750A4)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(video: vlog),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 
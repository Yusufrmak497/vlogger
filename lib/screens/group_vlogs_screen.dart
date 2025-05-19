import 'package:flutter/material.dart';
import '../models/group.dart';
import 'vlog_player_screen.dart';

class GroupVlogsScreen extends StatelessWidget {
  final Group group;

  const GroupVlogsScreen({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    // Örnek vlog listesi - gerçek uygulamada API'den gelecek
    final List<Map<String, dynamic>> vlogs = [
      {
        'url': group.lastVlog,
        'uploadedBy': 'Ahmet',
        'uploadedAt': DateTime.now().subtract(const Duration(hours: 2)),
        'duration': '2:30',
      },
      {
        'url': group.lastVlog,
        'uploadedBy': 'Mehmet',
        'uploadedAt': DateTime.now().subtract(const Duration(hours: 5)),
        'duration': '1:45',
      },
      {
        'url': group.lastVlog,
        'uploadedBy': 'Ayşe',
        'uploadedAt': DateTime.now().subtract(const Duration(hours: 8)),
        'duration': '3:15',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        title: Text(
          '${group.name} - Vloglar',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vlogs.length,
        itemBuilder: (context, index) {
          final vlog = vlogs[index];
          final timeDiff = DateTime.now().difference(vlog['uploadedAt']);
          String timeAgo;
          
          if (timeDiff.inHours < 24) {
            timeAgo = '${timeDiff.inHours} saat önce';
          } else {
            timeAgo = '${timeDiff.inDays} gün önce';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                if (vlog['url'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VlogPlayerScreen(
                        vlogUrl: vlog['url']!,
                        group: group,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vlog['url'] != null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(vlog['url']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                vlog['duration'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF6750A4),
                          child: Text(
                            vlog['uploadedBy'][0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vlog['uploadedBy'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 
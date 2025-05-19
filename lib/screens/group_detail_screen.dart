import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/notification_service.dart';
import 'group_settings_screen.dart';
import 'camera_screen.dart';
import 'group_vlogs_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'sender': 'Ali',
      'message': 'Selam arkadaşlar!',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'isQuoted': false,
      'quotedMessage': null,
    },
    {
      'id': '2',
      'sender': 'Ayşe',
      'message': 'Merhaba! Nasılsınız?',
      'time': DateTime.now().subtract(const Duration(minutes: 3)),
      'isQuoted': false,
      'quotedMessage': null,
    },
  ];

  bool _isVlogVisible = true;
  Map<String, dynamic>? _selectedMessage;
  Map<String, dynamic>? _quotedMessage;

  void _toggleVlog() {
    setState(() {
      _isVlogVisible = !_isVlogVisible;
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add({
          'id': DateTime.now().toString(),
          'sender': 'Ali',
          'message': _messageController.text,
          'time': DateTime.now(),
          'isQuoted': _quotedMessage != null,
          'quotedMessage': _quotedMessage,
        });
        
        NotificationService().showNewMessageNotification(
          groupName: widget.group.name,
          senderName: 'Ali',
          message: _messageController.text,
          groupId: widget.group.id,
        );
        
        _messageController.clear();
        _quotedMessage = null;
        FocusScope.of(context).unfocus();
      });
    }
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply, color: Color(0xFF6750A4)),
            title: const Text('Yanıtla'),
            onTap: () {
              setState(() {
                _quotedMessage = message;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: Color(0xFF6750A4)),
            title: const Text('Kopyala'),
            onTap: () {
              // TODO: Implement copy functionality
              Navigator.pop(context);
            },
          ),
          if (message['sender'] == 'Ali')
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                setState(() {
                  _messages.removeWhere((m) => m['id'] == message['id']);
                });
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF6750A4)),
            title: const Text('Grup Ayarları'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettingsScreen(group: widget.group),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFF6750A4)),
            title: const Text('Üyeleri Görüntüle'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show members list
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Grubu Sil', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteGroupConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grubu Sil'),
        content: const Text('Bu grubu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement group deletion
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to home screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _handleNewVlog(String path) {
    // Vlog yüklendikten sonra bildirim gönder
    NotificationService().showNewVlogNotification(
      groupName: widget.group.name,
      uploaderName: 'Ali',
      vlogId: DateTime.now().toString(), // Gerçek uygulamada vlog ID'si
    );
    
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        title: Text(
          widget.group.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showGroupOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Vlog Bölümü
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isVlogVisible ? 160 : 0,
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupVlogsScreen(group: widget.group),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.video_library,
                            color: Color(0xFF6750A4),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Grup Vlogları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6750A4),
                            ),
                          ),
                          const Spacer(),
                          FloatingActionButton(
                            mini: true,
                            backgroundColor: const Color(0xFF6750A4),
                            child: const Icon(Icons.videocam, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CameraScreen(
                                    isFullScreen: true,
                                    onVideoSaved: _handleNewVlog,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      widget.group.lastVlog != null
                          ? const Text(
                              'Son vlogları görüntülemek için tıklayın',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            )
                          : const Text(
                              'Henüz vlog paylaşılmamış',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                      const SizedBox(height: 8),
                      if (widget.group.lastVlog != null)
                        Text(
                          'Son vlog: ${DateTime.now().difference(DateTime.now().subtract(const Duration(hours: 2))).inHours} saat önce',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Toggle Butonu
          Material(
            color: Colors.white,
            elevation: 4,
            child: InkWell(
              onTap: _toggleVlog,
              child: Container(
                width: double.infinity,
                height: 24,
                alignment: Alignment.center,
                child: Icon(
                  _isVlogVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6750A4),
                  size: 20,
                ),
              ),
            ),
          ),
          // Mesajlaşma Bölümü
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  if (_quotedMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            color: const Color(0xFF6750A4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _quotedMessage!['sender'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6750A4),
                                  ),
                                ),
                                Text(
                                  _quotedMessage!['message'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _quotedMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isMe = message['sender'] == 'Ali';

                        return GestureDetector(
                          onLongPress: () => _showMessageOptions(message),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: 8,
                                left: isMe ? 64 : 0,
                                right: isMe ? 0 : 64,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF6750A4) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (message['isQuoted'] && message['quotedMessage'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message['quotedMessage']['sender'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isMe ? Colors.white : const Color(0xFF6750A4),
                                            ),
                                          ),
                                          Text(
                                            message['quotedMessage']['message'],
                                            style: TextStyle(
                                              color: isMe ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    message['sender'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message['message'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${message['time'].hour.toString().padLeft(2, '0')}:${message['time'].minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Color(0xFF6750A4)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CameraScreen(
                                    isFullScreen: true,
                                    onVideoSaved: _handleNewVlog,
                                  ),
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Mesaj yazın...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF6750A4)),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
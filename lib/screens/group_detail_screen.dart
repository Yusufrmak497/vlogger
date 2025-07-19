import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import 'group_settings_screen.dart';
import 'camera_screen.dart';
import 'group_vlogs_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';

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
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isVlogVisible = true;
  Message? _quotedMessage;
  Message? _editingMessage;
  String? _currentUserId;
  String? _currentUserName;
  Map<String, UserModel?> _userCache = {}; // Kullanıcı bilgilerini cache'lemek için
  Map<String, double> _slideOffsets = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadMessages();
    _setupRealtimeListener();
  }

  Future<void> _initializeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      final userProfile = await _userService.getUserProfile(user.uid);
      if (userProfile != null) {
        _currentUserName = userProfile.name;
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
      
      final messages = await _messageService.getGroupMessages(widget.group.id);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Mesajlar yüklendikten sonra kullanıcı bilgilerini yükle
      await _loadUserProfiles();
    } catch (e) {
      if (!mounted) return;
      print('Mesajlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfiles() async {
    // Her mesaj için gönderen kullanıcının bilgilerini yükle
    for (final message in _messages) {
      if (!_userCache.containsKey(message.senderId)) {
        try {
          final user = await _userService.getUserProfile(message.senderId);
          setState(() {
            _userCache[message.senderId] = user;
          });
        } catch (e) {
          print('Kullanıcı bilgileri yüklenirken hata: $e');
          setState(() {
            _userCache[message.senderId] = null;
          });
        }
      }
    }
  }

  String _getSenderName(String senderId) {
    final user = _userCache[senderId];
    if (user != null && user.name.isNotEmpty) {
      return user.name;
    }
    // Fallback: Kullanıcı bilgisi yoksa message'daki senderName'i kullan
    return 'Kullanıcı';
  }

  void _setupRealtimeListener() {
    _messageService.watchGroupMessages(widget.group.id).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    });
  }

  void _toggleVlog() {
    setState(() {
      _isVlogVisible = !_isVlogVisible;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty && _currentUserId != null) {
      try {
        await _messageService.sendMessage(
          widget.group.id,
          _messageController.text,
          replyTo: _quotedMessage?.id,
          replyToMessage: _quotedMessage?.content,
          replyToSender: _quotedMessage?.senderName ?? _getSenderName(_quotedMessage?.senderId ?? ''),
        );
        
        // Bildirim gönderme işlemi daha sonra eklenebilir
        print('Yeni mesaj bildirimi gönderildi');
        
        _messageController.clear();
        _quotedMessage = null;
        FocusScope.of(context).unfocus();
      } catch (e) {
        print('Mesaj gönderilirken hata: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    }
  }

  void _showMessageOptions(Message message) {
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
    print('Yeni vlog bildirimi gönderildi');
    
    Navigator.pop(context);
  }

  Future<String?> _pickAndUploadMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (pickedFile == null) return null;
    final file = pickedFile;
    final fileName = '${widget.group.id}_${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}';
    final ref = FirebaseStorage.instance.ref().child('group_media/${widget.group.id}/$fileName');
    final uploadTask = ref.putData(await file.readAsBytes());
    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();
    return url;
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
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupSettingsScreen(group: widget.group),
              ),
            );
          },
          child: Text(
          widget.group.name,
          style: const TextStyle(color: Colors.white),
        ),
          ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                        color: Colors.grey.withOpacity(0.2),
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
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isMe = message.senderId == _currentUserId;
                        final bool isRead = message.isRead;

                        // Eğer mesaj başkasına ait ve okunmadıysa, okundu olarak işaretle
                        if (!isMe && !isRead) {
                          _messageService.markMessageAsRead(widget.group.id, message.id);
                        }

                        return GestureDetector(
                          onLongPress: () => _showMessageOptions(message),
                          onHorizontalDragEnd: (details) {
                            if (!isMe && details.primaryVelocity != null && details.primaryVelocity! > 0) {
                              // Başkasının mesajını sağa kaydırınca yanıtla
                              setState(() {
                                _slideOffsets[message.id] = 0.15; // sağa kaydır
                              });
                              Future.delayed(const Duration(milliseconds: 120), () {
                                setState(() {
                                  _slideOffsets[message.id] = 0.0;
                                  _quotedMessage = message;
                                });
                              });
                            } else if (isMe && details.primaryVelocity != null && details.primaryVelocity! < 0) {
                              // Kendi mesajını sola kaydırınca yanıtla
                              setState(() {
                                _slideOffsets[message.id] = -0.15; // sola kaydır
                              });
                              Future.delayed(const Duration(milliseconds: 120), () {
                                setState(() {
                                  _slideOffsets[message.id] = 0.0;
                                  _quotedMessage = message;
                                });
                              });
                            }
                          },
                          child: AnimatedSlide(
                            key: ValueKey('slide_${message.id}_${_slideOffsets[message.id] ?? 0}'),
                            offset: Offset(_slideOffsets[message.id] ?? 0, 0),
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
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
                                      color: Colors.black.withAlpha(13),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe) ...[
                                      Text(
                                        _getSenderName(message.senderId),
                                        style: const TextStyle(
                                          color: Color(0xFF6750A4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    if (message.replyTo != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.7),
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  bottomLeft: Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    message.replyToSender ?? '',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    message.replyToMessage ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 4,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Mesaj balonunda içerik gösterimi:
                                    if ((message.isDeleted ?? false) == true) ...[
                                      Text(
                                        'Bu mesaj silindi',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ] else ...[
                                      if (message.imageUrl?.isNotEmpty ?? false) ...[
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: InteractiveViewer(
                                                  child: Image.network(message.imageUrl!),
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              message.imageUrl!,
                                              width: 240,
                                              height: 240,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ] else if (message.videoUrl?.isNotEmpty ?? false) ...[
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: AspectRatio(
                                                  aspectRatio: 16/9,
                                                  child: VideoPlayerWidget(url: message.videoUrl!),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 180,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  color: Colors.black12,
                                                ),
                                              ),
                                              const Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      // Sadece imageUrl ve videoUrl yoksa metin göster:
                                      if ((message.imageUrl?.isEmpty ?? true) && (message.videoUrl?.isEmpty ?? true)) ...[
                                        Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ],
                                    // Mesaj balonunda düzenlendi etiketi:
                                    if ((message.edited ?? false) == true) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '(düzenlendi)',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: isMe ? Colors.white70 : Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Icon(
                                              isRead ? Icons.done_all : Icons.done,
                                              size: 18,
                                              color: isRead ? Colors.lightBlueAccent : Colors.grey[300],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: _quotedMessage != null
                        ? Container(
                            key: const ValueKey('reply_box'),
                            margin: const EdgeInsets.only(left: 0, right: 0, bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _quotedMessage!.senderId == _currentUserId
                                        ? const Color(0xFF25D366) // WhatsApp yeşili
                                        : const Color(0xFF6750A4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _quotedMessage!.senderName ?? _getSenderName(_quotedMessage!.senderId),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _quotedMessage!.senderId == _currentUserId
                                              ? const Color(0xFF25D366)
                                              : const Color(0xFF6750A4),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _quotedMessage!.content,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                  splashRadius: 18,
                                  onPressed: () {
                                    setState(() {
                                      _quotedMessage = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Mesaj yazma kutusu
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Color(0xFF6750A4)),
                            onPressed: () async {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.image, color: Color(0xFF6750A4)),
                                        title: const Text('Fotoğraf Gönder'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final url = await _pickAndUploadMedia(isVideo: false);
                                          if (url != null && _currentUserId != null) {
                                            await _messageService.sendMessage(
                                              widget.group.id,
                                              '[Fotoğraf]',
                                              imageUrl: url,
                                            );
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.videocam, color: Color(0xFF6750A4)),
                                        title: const Text('Video Gönder'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final picker = ImagePicker();
                                          final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
                                          if (pickedFile != null && _currentUserId != null) {
                                            final fileName = '${widget.group.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';
                                            final ref = FirebaseStorage.instance.ref().child('group_media/${widget.group.id}/$fileName');
                                            final uploadTask = ref.putData(await pickedFile.readAsBytes());
                                            final snapshot = await uploadTask.whenComplete(() {});
                                            final url = await snapshot.ref.getDownloadURL();
                                            await _messageService.sendMessage(
                                              widget.group.id,
                                              '[Video]',
                                              videoUrl: url,
                                            );
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.insert_drive_file, color: Color(0xFF6750A4)),
                                        title: const Text('Dosya Gönder'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Dosya gönderme desteği eklenebilir
                                        },
                                      ),
                                    ],
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

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}
class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
            _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
} 
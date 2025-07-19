class Message {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;
  final String? videoUrl;
  final String? replyTo;
  final String? replyToMessage;
  final String? replyToSender;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? _isDeleted;
  final bool? _edited;
  final DateTime? editedAt;

  bool get isDeleted => _isDeleted ?? false;
  bool get edited => _edited ?? false;

  Message({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.videoUrl,
    this.replyTo,
    this.replyToMessage,
    this.replyToSender,
    this.isRead = false,
    bool? isDeleted,
    bool? edited,
    this.editedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : _isDeleted = isDeleted,
        _edited = edited,
        createdAt = createdAt ?? timestamp,
        updatedAt = updatedAt ?? timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'replyTo': replyTo,
      'replyToMessage': replyToMessage,
      'replyToSender': replyToSender,
      'isRead': isRead,
      'edited': edited,
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v == 'true';
      return false;
    }
    return Message(
      id: map['id'],
      groupId: map['groupId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      replyTo: map['replyTo'],
      replyToMessage: map['replyToMessage'],
      replyToSender: map['replyToSender'],
      isRead: map['isRead'] ?? false,
      isDeleted: _toBool(map['isDeleted']),
      edited: _toBool(map['edited']),
      editedAt: map['editedAt'] != null ? DateTime.tryParse(map['editedAt']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
} 
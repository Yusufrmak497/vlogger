import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationType {
  like,
  comment,
  follow,
  groupInvite,
  groupMessage,
  videoUpload,
  newFollower,
  newMessage,
  newVlog,
  groupActivity,
}

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String title,
    required String body,
    required String userId,
    required String senderId,
    String? senderName,
    String? senderAvatar,
    NotificationType? type,
    Map<String, dynamic>? data,
    @Default(false) bool isRead,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);
} 
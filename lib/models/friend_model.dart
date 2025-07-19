import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_model.freezed.dart';
part 'friend_model.g.dart';

@freezed
class FriendModel with _$FriendModel {
  const factory FriendModel({
    required String id,
    required String name,
    String? avatarUrl,
    String? status,
    DateTime? createdAt,
  }) = _FriendModel;

  factory FriendModel.fromJson(Map<String, dynamic> json) => _$FriendModelFromJson(json);
} 
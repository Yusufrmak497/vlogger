import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String username,
    required String email,
    String? profileImageUrl,
    String? coverImageUrl,
    String? bio,
    @Default([]) List<String> groups,
    @Default([]) List<String> followers,
    @Default([]) List<String> following,
    @Default([]) List<String> vlogs,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> _parseListOrMap(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is Map) {
        return value.keys.map((e) => e.toString()).toList();
      }
      return [];
    }
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      bio: json['bio'] as String?,
      groups: _parseListOrMap(json['groups']),
      followers: _parseListOrMap(json['followers']),
      following: _parseListOrMap(json['following']),
      vlogs: _parseListOrMap(json['vlogs']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
} 
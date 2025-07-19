import 'package:freezed_annotation/freezed_annotation.dart';

part 'video.freezed.dart';
part 'video.g.dart';

@freezed
class Video with _$Video {
  const factory Video({
    required String id,
    required String userId,
    required String username,
    required String title,
    required String description,
    required String url,
    required String thumbnailUrl,
    int? likes,
    int? views,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
} 
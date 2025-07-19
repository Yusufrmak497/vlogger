import 'package:flutter/services.dart';

class IOSVideoEditorService {
  static const MethodChannel _channel = MethodChannel('ios_video_editor');

  // Video Composition
  static Future<String?> createVideoComposition(List<String> videoPaths) async {
    try {
      final result = await _channel.invokeMethod('createVideoComposition', {
        'videoPaths': videoPaths,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Video composition error: ${e.message}');
      return null;
    }
  }

  // Split Video
  static Future<String?> splitVideo(String videoPath, double splitTime) async {
    try {
      final result = await _channel.invokeMethod('splitVideo', {
        'videoPath': videoPath,
        'splitTime': splitTime,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Video split error: ${e.message}');
      return null;
    }
  }

  // Trim Video
  static Future<String?> trimVideo(String videoPath, double startTime, double endTime) async {
    try {
      final result = await _channel.invokeMethod('trimVideo', {
        'videoPath': videoPath,
        'startTime': startTime,
        'endTime': endTime,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Video trim error: ${e.message}');
      return null;
    }
  }

  // Add Transition
  static Future<String?> addTransition(String videoPath1, String videoPath2, String transitionType) async {
    try {
      final result = await _channel.invokeMethod('addTransition', {
        'videoPath1': videoPath1,
        'videoPath2': videoPath2,
        'transitionType': transitionType,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Transition error: ${e.message}');
      return null;
    }
  }

  // Export Video
  static Future<Map<String, dynamic>?> exportVideo(
    List<String> videoPaths,
    Map<String, dynamic> exportSettings,
  ) async {
    try {
      final result = await _channel.invokeMethod('exportVideo', {
        'videoPaths': videoPaths,
        'exportSettings': exportSettings,
      });
      return result as Map<String, dynamic>?;
    } on PlatformException catch (e) {
      print('Export error: ${e.message}');
      return null;
    }
  }

  // Get Video Thumbnail
  static Future<String?> getVideoThumbnail(String videoPath, double time) async {
    try {
      final result = await _channel.invokeMethod('getVideoThumbnail', {
        'videoPath': videoPath,
        'time': time,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Thumbnail error: ${e.message}');
      return null;
    }
  }

  // Get Video Duration
  static Future<double?> getVideoDuration(String videoPath) async {
    try {
      final result = await _channel.invokeMethod('getVideoDuration', {
        'videoPath': videoPath,
      });
      return result as double?;
    } on PlatformException catch (e) {
      print('Duration error: ${e.message}');
      return null;
    }
  }

  // Apply Filter
  static Future<String?> applyFilter(String videoPath, String filterType) async {
    try {
      final result = await _channel.invokeMethod('applyFilter', {
        'videoPath': videoPath,
        'filterType': filterType,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Filter error: ${e.message}');
      return null;
    }
  }

  // Adjust Speed
  static Future<String?> adjustSpeed(String videoPath, double speed) async {
    try {
      final result = await _channel.invokeMethod('adjustSpeed', {
        'videoPath': videoPath,
        'speed': speed,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Speed adjustment error: ${e.message}');
      return null;
    }
  }

  // Stabilize Video
  static Future<String?> stabilizeVideo(String videoPath, double strength) async {
    try {
      final result = await _channel.invokeMethod('stabilizeVideo', {
        'videoPath': videoPath,
        'strength': strength,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Stabilization error: ${e.message}');
      return null;
    }
  }
} 
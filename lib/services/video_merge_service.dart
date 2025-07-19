import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class VideoMergeService {
  static const MethodChannel _channel = MethodChannel('video_merge_channel');

  static Future<String?> mergeVideos(List<String> videoPaths) async {
    try {
      if (videoPaths.isEmpty) {
        throw Exception('Birleştirilecek video bulunamadı');
      }

      if (videoPaths.length == 1) {
        // Tek video varsa direkt döndür
        return videoPaths.first;
      }

      // Geçici dizin oluştur
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/merged_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      print('Video birleştirme başlıyor...');
      print('Platform: ${Platform.operatingSystem}');
      print('Video paths: $videoPaths');
      print('Output path: $outputPath');

      // Platform channel ile native birleştirme
      final result = await _channel.invokeMethod('mergeVideos', {
        'videoPaths': videoPaths,
        'outputPath': outputPath,
      });

      print('Native birleştirme sonucu: $result');

      if (result is String) {
        // Dosyanın gerçekten var olup olmadığını kontrol et
        final file = File(result);
        if (await file.exists()) {
          print('Birleştirilmiş video dosyası bulundu: $result');
          return result;
        } else {
          print('Birleştirilmiş video dosyası bulunamadı: $result');
          throw Exception('Birleştirilmiş video dosyası oluşturulamadı');
        }
      } else {
        throw Exception('Native birleştirme başarısız: $result');
      }
    } catch (e) {
      print('Video birleştirme hatası: $e');
      return null;
    }
  }

  static Future<String?> _mergeVideosWithFFmpeg(List<String> videoPaths, String outputPath) async {
    try {
      // Native iOS kodu ile birleştirme (AppDelegate.swift'te tanımlı)
      // Bu fonksiyon sadece placeholder, gerçek işlem iOS tarafında yapılıyor
      
      print('Native video birleştirme çağrılıyor...');
      
      // Simülasyon için kısa bekleme
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // İlk videoyu geçici olarak kopyala (gerçek birleştirme iOS'ta yapılıyor)
      final firstVideo = File(videoPaths.first);
      if (await firstVideo.exists()) {
        await firstVideo.copy(outputPath);
        print('Video birleştirme tamamlandı: $outputPath');
        return outputPath;
      } else {
        throw Exception('Video dosyası bulunamadı');
      }
    } catch (e) {
      print('Video birleştirme hatası: $e');
      return null;
    }
  }

  static Future<String?> compressVideo(String videoPath) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      
      return mediaInfo?.file?.path;
    } catch (e) {
      print('Video sıkıştırma hatası: $e');
      return null;
    }
  }

  static Future<void> deleteVideo(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Video silme hatası: $e');
    }
  }
} 
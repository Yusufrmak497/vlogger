import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "video_merge_channel", binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "mergeVideos" {
        guard let args = call.arguments as? [String: Any],
              let videoPaths = args["videoPaths"] as? [String],
              let outputPath = args["outputPath"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "Geçersiz argüman", details: nil))
          return
        }
        self.mergeVideos(videoPaths: videoPaths, outputPath: outputPath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func mergeVideos(videoPaths: [String], outputPath: String, result: @escaping FlutterResult) {
    let mixComposition = AVMutableComposition()
    var insertTime = CMTime.zero
    var maxWidth: CGFloat = 0
    var maxHeight: CGFloat = 0
    var instructions: [AVMutableVideoCompositionInstruction] = []

    // Tüm videoların en büyük boyutunu bul
    for path in videoPaths {
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            maxWidth = max(maxWidth, abs(size.width))
            maxHeight = max(maxHeight, abs(size.height))
        }
    }
    let renderSize = CGSize(width: maxWidth, height: maxHeight)

    var videoTrack: AVMutableCompositionTrack?
    var audioTrack: AVMutableCompositionTrack?

    for path in videoPaths {
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        guard let assetVideoTrack = asset.tracks(withMediaType: .video).first else { continue }
        if videoTrack == nil {
            videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        do {
            try videoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetVideoTrack, at: insertTime)
        } catch {
            result(FlutterError(code: "VIDEO_INSERT_ERROR", message: "Video eklenemedi: \(error)", details: nil))
            return
        }
        // Aspect fit ve ortalama işlemi
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: insertTime, duration: asset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)

        let naturalSize = assetVideoTrack.naturalSize
        let preferredTransform = assetVideoTrack.preferredTransform
        let videoRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let videoSize = CGSize(width: abs(videoRect.width), height: abs(videoRect.height))

        let scale = min(renderSize.width / videoSize.width, renderSize.height / videoSize.height)
        let scaledWidth = videoSize.width * scale
        let scaledHeight = videoSize.height * scale
        let tx = (renderSize.width - scaledWidth) / 2
        let ty = (renderSize.height - scaledHeight) / 2

        var transform = preferredTransform
        transform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        transform = transform.concatenating(CGAffineTransform(translationX: tx, y: ty))
        layerInstruction.setTransform(transform, at: insertTime)
        instruction.layerInstructions = [layerInstruction]
        instructions.append(instruction)

        if let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
            if audioTrack == nil {
                audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            }
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetAudioTrack, at: insertTime)
            } catch {}
        }
        insertTime = CMTimeAdd(insertTime, asset.duration)
    }

    let videoComposition = AVMutableVideoComposition()
    videoComposition.instructions = instructions
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    videoComposition.renderSize = renderSize

    // Export işlemi
    let outputURL = URL(fileURLWithPath: outputPath)
    if FileManager.default.fileExists(atPath: outputPath) {
        try? FileManager.default.removeItem(at: outputURL)
    }
    guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
        result(FlutterError(code: "EXPORT_ERROR", message: "Export başlatılamadı", details: nil))
        return
    }
    exporter.outputURL = outputURL
    exporter.outputFileType = .mp4
    exporter.shouldOptimizeForNetworkUse = true
    exporter.videoComposition = videoComposition

    exporter.exportAsynchronously {
        switch exporter.status {
        case .completed:
            result(outputPath)
        case .failed, .cancelled:
            result(FlutterError(code: "EXPORT_FAILED", message: exporter.error?.localizedDescription, details: nil))
        default:
            result(FlutterError(code: "EXPORT_UNKNOWN", message: "Bilinmeyen hata", details: nil))
        }
    }
  }
}
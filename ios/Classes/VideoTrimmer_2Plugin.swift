import Flutter
import UIKit
import AVFoundation

public class VideoTrimmer2Plugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_trimmer_2", binaryMessenger: registrar.messenger())
    let instance = VideoTrimmer2Plugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "trimVideo":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String,
            let startMs = args["startMs"] as? Int,
            let endMs = args["endMs"] as? Int else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let inputURL = URL(fileURLWithPath: path)
      let startTime = CMTime(value: Int64(startMs), timescale: 1000)
      let endTime = CMTime(value: Int64(endMs), timescale: 1000)
      
      DispatchQueue.global(qos: .background).async {
        do {
          let outputPath = try self.trimVideo(inputURL: inputURL, startTime: startTime, endTime: endTime)
          DispatchQueue.main.async {
            result(outputPath)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "TRIM_ERROR", message: error.localizedDescription, details: nil))
          }
        }
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func trimVideo(inputURL: URL, startTime: CMTime, endTime: CMTime) throws -> String {
    let asset = AVAsset(url: inputURL)
    let composition = AVMutableComposition()
    
    // Create output file path
    let outputPath = generateOutputPath()
    let outputURL = URL(fileURLWithPath: outputPath)
    
    // Setup video track
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      throw NSError(domain: "VideoTrimmer2PluginError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
    }
    
    // Create composition video track
    let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    // Insert time range from original video
    try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: startTime, end: endTime), of: videoTrack, at: .zero)
    
    // Handle audio track if available
    if let audioTrack = asset.tracks(withMediaType: .audio).first {
      let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: startTime, end: endTime), of: audioTrack, at: .zero)
    }
    
    // Create exporter
    guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
      throw NSError(domain: "VideoTrimmer2PluginError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
    }
    
    exporter.outputURL = outputURL
    exporter.outputFileType = .mp4
    exporter.shouldOptimizeForNetworkUse = true
    
    // Remove file if exists
    if FileManager.default.fileExists(atPath: outputPath) {
      try FileManager.default.removeItem(atPath: outputPath)
    }
    
    // Export the video
    let exportSemaphore = DispatchSemaphore(value: 0)
    
    exporter.exportAsynchronously {
      exportSemaphore.signal()
    }
    
    // Wait for export to complete
    exportSemaphore.wait()
    
    // Check export status
    if exporter.status == .completed {
      return outputPath
    } else {
      throw NSError(domain: "VideoTrimmer2PluginError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Export failed: \(exporter.error?.localizedDescription ?? "Unknown error")"])
    }
  }
  
  private func generateOutputPath() -> String {
    let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    let dirPath = paths[0].appendingPathComponent("trimmed_videos", isDirectory: true)
    
    // Create directory if needed
    if !FileManager.default.fileExists(atPath: dirPath.path) {
      try? FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
    }
    
    let uuid = UUID().uuidString
    let outputURL = dirPath.appendingPathComponent("trim_\(uuid).mp4")
    return outputURL.path
  }
}
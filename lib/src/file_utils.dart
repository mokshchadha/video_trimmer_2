import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Utility functions for file operations related to video trimming
class FileUtils {
  /// Generate a path for the output trimmed video file
  ///
  /// Creates a unique filename in the temporary directory
  static Future<String> generateOutputPath() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = path.join(tempDir.path, 'trimmed_video_$timestamp.mp4');
    return outputPath;
  }

  /// Extract the filename from a file path
  static String getFilename(String filePath) {
    return path.basename(filePath);
  }

  /// Check if a file is a valid video file based on its extension
  static bool isVideoFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.3gp', '.flv'].contains(extension);
  }
}

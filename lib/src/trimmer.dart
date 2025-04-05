import 'dart:async';
import 'dart:io';

import 'trimmer_platform_interface.dart';

/// Video trimmer class provides methods to trim video files
class Trimmer {
  final TrimmerPlatform _platform = TrimmerPlatform();

  /// Trims a video file between the specified start and end times
  ///
  /// [file] - The input video file to trim
  /// [startMs] - Start position in milliseconds
  /// [endMs] - End position in milliseconds
  ///
  /// Returns a [Future] that completes with the trimmed video [File]
  Future<File> trimVideo({
    required File file,
    required int startMs,
    required int endMs,
  }) async {
    // Validate input parameters
    if (!file.existsSync()) {
      throw ArgumentError('Input video file does not exist: ${file.path}');
    }

    if (startMs < 0) {
      throw ArgumentError('Start time cannot be negative: $startMs');
    }

    if (endMs <= startMs) {
      throw ArgumentError(
          'End time must be greater than start time: $endMs <= $startMs');
    }

    return _platform.trimVideo(file, startMs, endMs);
  }

  getPlatformVersion() {}
}

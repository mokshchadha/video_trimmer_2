import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Platform interface for video trimming functionality
class TrimmerPlatform {
  static const MethodChannel _channel = MethodChannel('video_trimmer_2');

  /// Trims a video file between the specified start and end times
  ///
  /// [file] - The input video file to trim
  /// [startMs] - Start position in milliseconds
  /// [endMs] - End position in milliseconds
  ///
  /// Returns a [Future] that completes with the trimmed video [File]
  Future<File> trimVideo(File file, int startMs, int endMs) async {
    final Map<String, dynamic> arguments = {
      'path': file.path,
      'startMs': startMs,
      'endMs': endMs,
    };

    final String? outputPath = await _channel.invokeMethod<String>(
      'trimVideo',
      arguments,
    );

    if (outputPath == null) {
      throw Exception('Failed to trim video: null output path');
    }

    return File(outputPath);
  }
}

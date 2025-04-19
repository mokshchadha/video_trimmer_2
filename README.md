# video_trimmer_2

A Flutter plugin to trim videos on Android and iOS.

## Features

- Trim videos on Android using MediaExtractor + MediaMuxer
- Trim videos on iOS using AVFoundation
- Simple API with Future-based result handling
- Works with any video file format supported by the respective platforms

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  video_trimmer_2: ^0.1.1
```

### Android Configuration

Add the following permissions to your Android Manifest (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS Configuration

Add the following keys to your `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>To access videos for trimming</string>
<key>NSCameraUsageDescription</key>
<string>To capture videos for trimming</string>
<key>NSMicrophoneUsageDescription</key>
<string>To capture audio for videos</string>
```

## Usage

Here's a simple example of how to use the video trimmer:

```dart
import 'dart:io';
import 'package:video_trimmer_2/video_trimmer_2.dart';

Future<void> trimMyVideo() async {
  final Trimmer trimmer = Trimmer();
  
  // Assuming you have a File instance of a video
  File inputVideo = File('/path/to/your/video.mp4');
  
  try {
    // Trim video from 2 seconds to 8 seconds
    File trimmedVideo = await trimmer.trimVideo(
      file: inputVideo,
      startMs: 2000,  // 2 seconds
      endMs: 8000,    // 8 seconds
    );
    
    print('Trimmed video saved to: ${trimmedVideo.path}');
  } catch (e) {
    print('Error trimming video: $e');
  }
}
```

## Example

Check out the example app in the `example` directory for a complete demo of video trimming with UI controls.

## Additional Utilities

The package includes some utility functions in the `FileUtils` class:

```dart
// Generate a unique path for output video
String outputPath = await FileUtils.generateOutputPath();

// Check if a file is a video file based on extension
bool isVideo = FileUtils.isVideoFile(File('/path/to/file.mp4'));

// Get just the filename from a path
String filename = FileUtils.getFilename('/path/to/video.mp4'); // Returns 'video.mp4'
```

## Issues and Feedback

Please file issues, bugs, or feature requests in the [issue tracker](https://github.com/yourusername/video_trimmer_2/issues).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

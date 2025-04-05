import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer_2/video_trimmer_2.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];
  File mockFile = File('test_video.mp4');

  setUp(() {
    // Setup mock handler for the MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('video_trimmer_2'),
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'trimVideo':
            return '/path/to/trimmed_video.mp4';
          default:
            return null;
        }
      },
    );

    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('video_trimmer_2'),
      null,
    );
  });

  test('trimVideo passes correct parameters to platform', () async {
    // Arrange
    final trimmer = Trimmer();
    final int startMs = 1000;
    final int endMs = 5000;

    // Act
    final File result = await trimmer.trimVideo(
      file: mockFile,
      startMs: startMs,
      endMs: endMs,
    );

    // Assert
    expect(log, hasLength(1));
    expect(log.first.method, 'trimVideo');
    expect(log.first.arguments['path'], mockFile.path);
    expect(log.first.arguments['startMs'], startMs);
    expect(log.first.arguments['endMs'], endMs);
    expect(result.path, '/path/to/trimmed_video.mp4');
  });

  test('trimVideo throws exception for negative start time', () async {
    // Arrange
    final trimmer = Trimmer();
    final int startMs = -100;
    final int endMs = 5000;

    // Act & Assert
    expect(
      () => trimmer.trimVideo(
        file: mockFile,
        startMs: startMs,
        endMs: endMs,
      ),
      throwsArgumentError,
    );
  });

  test('trimVideo throws exception when end time <= start time', () async {
    // Arrange
    final trimmer = Trimmer();
    final int startMs = 5000;
    final int endMs = 5000;

    // Act & Assert
    expect(
      () => trimmer.trimVideo(
        file: mockFile,
        startMs: startMs,
        endMs: endMs,
      ),
      throwsArgumentError,
    );
  });

  test('FileUtils.isVideoFile correctly identifies video files', () {
    // Arrange & Act & Assert
    expect(FileUtils.isVideoFile(File('video.mp4')), isTrue);
    expect(FileUtils.isVideoFile(File('video.mov')), isTrue);
    expect(FileUtils.isVideoFile(File('video.avi')), isTrue);
    expect(FileUtils.isVideoFile(File('video.mkv')), isTrue);
    expect(FileUtils.isVideoFile(File('image.jpg')), isFalse);
    expect(FileUtils.isVideoFile(File('document.pdf')), isFalse);
  });
}

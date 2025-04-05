import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer_2/video_trimmer_2_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelVideoTrimmer_2 platform = MethodChannelVideoTrimmer_2();
  const MethodChannel channel = MethodChannel('video_trimmer_2');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_trimmer_2_platform_interface.dart';

/// An implementation of [VideoTrimmer_2Platform] that uses method channels.
class MethodChannelVideoTrimmer_2 extends VideoTrimmer_2Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_trimmer_2');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

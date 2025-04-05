import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_trimmer_2_method_channel.dart';

abstract class VideoTrimmer_2Platform extends PlatformInterface {
  /// Constructs a VideoTrimmer_2Platform.
  VideoTrimmer_2Platform() : super(token: _token);

  static final Object _token = Object();

  static VideoTrimmer_2Platform _instance = MethodChannelVideoTrimmer_2();

  /// The default instance of [VideoTrimmer_2Platform] to use.
  ///
  /// Defaults to [MethodChannelVideoTrimmer_2].
  static VideoTrimmer_2Platform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoTrimmer_2Platform] when
  /// they register themselves.
  static set instance(VideoTrimmer_2Platform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'xebo_survey_sdk_method_channel.dart';

abstract class XeboSurveySdkPlatform extends PlatformInterface {
  /// Constructs a XeboSurveySdkPlatform.
  XeboSurveySdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static XeboSurveySdkPlatform _instance = MethodChannelXeboSurveySdk();

  /// The default instance of [XeboSurveySdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelXeboSurveySdk].
  static XeboSurveySdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [XeboSurveySdkPlatform] when
  /// they register themselves.
  static set instance(XeboSurveySdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

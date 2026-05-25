import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'xebo_survey_sdk_platform_interface.dart';

/// An implementation of [XeboSurveySdkPlatform] that uses method channels.
class MethodChannelXeboSurveySdk extends XeboSurveySdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('xebo_survey_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

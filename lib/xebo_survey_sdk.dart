
import 'xebo_survey_sdk_platform_interface.dart';

class XeboSurveySdk {
  Future<String?> getPlatformVersion() {
    return XeboSurveySdkPlatform.instance.getPlatformVersion();
  }
}

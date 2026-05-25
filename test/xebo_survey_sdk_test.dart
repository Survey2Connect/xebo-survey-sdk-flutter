import 'package:flutter_test/flutter_test.dart';
import 'package:xebo_survey_sdk/xebo_survey_sdk.dart';
import 'package:xebo_survey_sdk/xebo_survey_sdk_platform_interface.dart';
import 'package:xebo_survey_sdk/xebo_survey_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockXeboSurveySdkPlatform
    with MockPlatformInterfaceMixin
    implements XeboSurveySdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final XeboSurveySdkPlatform initialPlatform = XeboSurveySdkPlatform.instance;

  test('$MethodChannelXeboSurveySdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelXeboSurveySdk>());
  });

  test('getPlatformVersion', () async {
    XeboSurveySdk xeboSurveySdkPlugin = XeboSurveySdk();
    MockXeboSurveySdkPlatform fakePlatform = MockXeboSurveySdkPlatform();
    XeboSurveySdkPlatform.instance = fakePlatform;

    expect(await xeboSurveySdkPlugin.getPlatformVersion(), '42');
  });
}

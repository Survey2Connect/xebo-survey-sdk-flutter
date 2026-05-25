import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xebo_survey_sdk/xebo_survey_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelXeboSurveySdk platform = MethodChannelXeboSurveySdk();
  const MethodChannel channel = MethodChannel('xebo_survey_sdk');

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

import 'package:flutter_test/flutter_test.dart';
import 'package:xebo_survey_sdk/xebo_survey_sdk.dart';

void main() {
  test('XeboSurveyManager singleton is accessible', () {
    expect(XeboSurveyManager.instance, isNotNull);
  });
}

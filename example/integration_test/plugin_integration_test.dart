import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xebo_survey_sdk/xebo_survey_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('XeboSurveyManager singleton is accessible',
      (WidgetTester tester) async {
    expect(XeboSurveyManager.instance, isNotNull);
  });
}

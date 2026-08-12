import 'package:flutter/material.dart';
import 'package:xebo_survey_sdk/xebo_survey_sdk.dart';

// ─── Replace these with your real credentials ─────────────────────────────────
const _apiKey = '2882fe60026036fbba6d4f4285d26adb833fdbbdef18532f8aae72734f34e9d9';
const _collectorId = '2b08a2fc-cdc9-49cf-9b57-5679caeec6d8';
const _surveyId = 'd660ae06-8ab7-4154-89ce-3b09cdca5833';
const _zone = 'az4'; // e.g. az1, az2, az4

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure SDK on startup (pre-fetches survey in background)
  XeboSurveyManager.instance.configure(
    apiKey: _apiKey,
    collectorId: _collectorId,
    zone: _zone,
  );

  // Optional: set user identity
  XeboSurveyManager.instance.setUser(const XeboUserData(
    name: 'Test User',
    email: 'test@example.com',
    uniqueId: 'test-001',
  ));

  // Optional: customize theme
  configureTheme(const XeboThemeConfig(
    primaryColor: '#4F46E5',
    cornerRadius: 12,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xebo Survey SDK Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xebo Survey SDK'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.poll_outlined,
                  size: 80, color: Color(0xFF4F46E5)),
              const SizedBox(height: 24),
              const Text(
                'Xebo In-App Survey',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the button below to trigger a survey.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await XeboSurveyManager.instance
                        .fetchAndPresentSurvey(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Show Survey',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await XeboSurveyManager.instance.showInAppSurvey(
                      context: context,
                      surveyId: _surveyId,
                      collectorId: _collectorId,
                      zone: _zone,
                      onLoading: () => debugPrint('[Example] onLoading'),
                      onLoadFailed: (error) =>
                          debugPrint('[Example] onLoadFailed: $error'),
                      onCompleted: (response) =>
                          debugPrint('[Example] onCompleted: $response'),
                      onDismissed: () => debugPrint('[Example] onDismissed'),
                      onPartialResponse: (response) =>
                          debugPrint('[Example] onPartialResponse: $response'),
                      onSubmissionSucceeded: () =>
                          debugPrint('[Example] onSubmissionSucceeded'),
                      onSubmissionFailed: (error) =>
                          debugPrint('[Example] onSubmissionFailed: $error'),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Show In-App Survey (granular callbacks)',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Self-contained networking for the `showInAppSurvey` flow — deliberately independent of
// xebo_network_service.dart (which the pure-Dart fetchAndPresentSurvey flow uses) so the two
// entry points can't cross-contaminate each other's zone/token/api key, mirroring the native
// iOS SDK's own separation between XeboNativeSurveyManager and XeboInAppSurveyService.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/xebo_api_models.dart';
import '../models/xebo_models.dart';
import 'xebo_network_service.dart' show parseSurvey;

bool isValidUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

/// GET https://api.xebo.ai/api/v1/api-key/verify — zone-independent. Returns null (rather than
/// throwing) on any failure, matching the native SDK: verify failing isn't fatal, callers fall
/// back to the raw api key as an `x-api-key` header on subsequent requests.
Future<String?> inAppVerifyApiKey(String apiKey) async {
  try {
    final uri = Uri.parse('https://api.xebo.ai/api/v1/api-key/verify');
    final res = await http.get(uri, headers: {'x-api-key': apiKey});
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['access_token'] as String? ??
        (json['data'] as Map<String, dynamic>?)?['access_token'] as String?;
  } catch (_) {
    return null;
  }
}

Map<String, String> inAppAuthHeader(String? bearerToken, String apiKey) {
  return bearerToken != null
      ? {'Authorization': 'Bearer $bearerToken'}
      : {'x-api-key': apiKey};
}

/// GET https://{zone}-api.xebo.ai/v3/survey-management/surveys/{surveyId}/draft
/// No query params — this endpoint 400s (VALIDATION_ERROR) on unknown ones, so collectorId
/// goes in a header instead. No separate collector lookup — surveyId is used directly.
Future<XeboSurvey> fetchInAppSurveyDraft({
  required String zone,
  required String surveyId,
  required String collectorId,
  required Map<String, String> authHeader,
}) async {
  final uri = Uri.parse('https://$zone-api.xebo.ai/v3/survey-management/surveys/$surveyId/draft');
  final res = await http.get(uri, headers: {
    'Content-Type': 'application/json',
    'x-collector-id': collectorId,
    ...authHeader,
  });

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('[Xebo] fetchInAppSurveyDraft failed — HTTP ${res.statusCode}: ${res.body}');
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  if (json['data'] == null) {
    throw Exception('[Xebo] fetchInAppSurveyDraft failed — no data in response');
  }
  final surveyData = APISurveyData.fromJson(json['data'] as Map<String, dynamic>);
  return parseSurvey(surveyData);
}

/// GET https://{zone}-api.xebo.ai/v3/collectors/collect/{collectorId}
/// Resolves a collector's dashboard/database id into its uuid — the id create-response actually
/// validates collector_id against. Only called at submission time, and only when `collectorId`
/// isn't already uuid-shaped; falls back to the original id if resolution fails.
Future<String> resolveInAppCollectorUUID({
  required String zone,
  required String collectorId,
  required Map<String, String> authHeader,
}) async {
  if (isValidUuid(collectorId)) return collectorId;

  try {
    final uri = Uri.parse('https://$zone-api.xebo.ai/v3/collectors/collect/$collectorId');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json', ...authHeader});
    if (res.statusCode < 200 || res.statusCode >= 300) return collectorId;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final root = (json['data'] as Map<String, dynamic>?) ?? json;
    return root['uuid'] as String? ?? collectorId;
  } catch (_) {
    return collectorId;
  }
}

Map<String, dynamic> buildInAppResponsePayload({
  required String surveyId,
  required String collectorId,
  required List<XeboAnswer> answers,
}) {
  return {
    'surveyId': surveyId,
    'collectorId': collectorId,
    'questions': answers
        .where((a) => a.questionId != 'thank_you_auto')
        .map((a) => {
              'uuid': a.questionId,
              'answer': a.value.map((v) => v.toJson()).toList(),
            })
        .toList(),
  };
}

/// POST https://{zone}-feedback-api.xebo.ai/v3/survey-participation/{surveyId}/response/create-response
/// `mode: "sdk"` and `browser: "other"` intentionally — the backend validates browser against a
/// real-browser enum and 400s the whole submission for anything else. No start/end time or
/// quality flags — the in-app survey session doesn't track timing.
Future<bool> submitInAppSurveyResponse({
  required String zone,
  required String surveyId,
  required String collectorId,
  required Map<String, String> authHeader,
  required List<XeboAnswer> answers,
  required bool isIOS,
  required String osVersionRaw,
  XeboUserData? userData,
}) async {
  final uri = Uri.parse(
      'https://$zone-feedback-api.xebo.ai/v3/survey-participation/$surveyId/response/create-response');

  final customVariables = <String, String>{};
  if (userData != null) {
    void put(String key, String? value) {
      if (value != null && value.isNotEmpty) customVariables[key] = value;
    }

    put('fName', userData.name);
    put('email', userData.email);
    put('mobile', userData.phone);
    put('unique_id', userData.uniqueId);
    put('country', userData.country);
    put('city', userData.city);
    put('region', userData.region);
    userData.eData?.forEach((k, v) {
      if (k.isNotEmpty && v.isNotEmpty) customVariables[k] = v;
    });
  }

  final osVersion = osVersionRaw.replaceFirst(RegExp(r'^(ios|android)\s*', caseSensitive: false), '');
  final userAgent = isIOS
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS ${osVersion.replaceAll('.', '_')} like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
      : 'Mozilla/5.0 (Linux; Android $osVersion; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  final body = jsonEncode({
    'collector_id': collectorId,
    'responses': [
      {
        'response_status': 'complete',
        'mode': 'sdk',
        'userAgent': userAgent,
        if (customVariables.isNotEmpty) 'custom_variables': customVariables,
        'deviceInfo': {
          'type': 'mobile',
          'os': isIOS ? 'ios' : 'android',
          'browser': 'other',
        },
        'questions': answers
            .where((a) => a.questionId != 'thank_you_auto')
            .map((a) => {
                  'uuid': a.questionId,
                  'answer': a.value.map((v) => v.toJson()).toList(),
                })
            .toList(),
      }
    ],
  });

  final res = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      ...authHeader,
    },
    body: body,
  );

  return res.statusCode >= 200 && res.statusCode < 300;
}

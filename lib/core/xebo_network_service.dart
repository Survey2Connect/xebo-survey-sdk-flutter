import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/xebo_api_models.dart';
import '../models/xebo_models.dart';

// ─── URL helpers ──────────────────────────────────────────────────────────────

String buildBaseURL(String zone) => 'https://$zone-api.xebo.ai';
// UAT serves survey-participation on the main api host; other zones use -feedback-api.
String buildFeedbackBaseURL(String zone) => zone.startsWith('uat-')
    ? 'https://$zone-api.xebo.ai'
    : 'https://$zone-feedback-api.xebo.ai';
// UAT zones verify via pit-api; all other zones via the global api host.
String buildVerifyURL(String zone) {
  final host = zone.startsWith('uat-') ? 'pit-api.xebo.ai' : 'api.xebo.ai';
  return 'https://$host/api/v1/api-key/verify?zone=${Uri.encodeComponent(zone)}';
}

// ─── HTML stripping ───────────────────────────────────────────────────────────

String stripHTML(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  return raw
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();
}

// ─── Question type mapping ────────────────────────────────────────────────────

String _mapRatingStyle(String? apiType) {
  switch (apiType?.toLowerCase()) {
    case 'star':
    case 'stars':
      return 'star';
    case 'heart':
    case 'hearts':
      return 'heart';
    case 'circle':
    case 'circles':
      return 'circle';
    case 'tile':
    case 'tiles':
      return 'tile';
    case 'emoji':
    case 'emojis':
      return 'emoji';
    default:
      return 'star';
  }
}

XeboQuestionType _mapQuestionType(String apiType) {
  switch (apiType) {
    case 'single_choice':
      return XeboQuestionType.singleChoice;
    case 'multi_choice':
      return XeboQuestionType.multipleChoice;
    case 'dropdown':
      return XeboQuestionType.dropdown;
    case 'single_text':
      return XeboQuestionType.singleTextBox;
    case 'multi_text':
      return XeboQuestionType.multipleTextBox;
    case 'nps':
    case 'nps_pro':
      return XeboQuestionType.nps;
    case 'multi_nps':
      return XeboQuestionType.multiNps;
    case 'rating':
    case 'rating_pro':
      return XeboQuestionType.rating;
    case 'multi_rating':
      return XeboQuestionType.multiRating;
    default:
      return XeboQuestionType.singleChoice;
  }
}

// ─── Survey parsing ───────────────────────────────────────────────────────────

XeboSurvey parseSurvey(APISurveyData data) {
  // Collect all follow-up question IDs (from NPS Pro configScale)
  final followUpQuestionIds = <String>{};
  for (final block in data.blocks) {
    for (final q in block.questions) {
      for (final scale in q.settings?.configScale ?? []) {
        followUpQuestionIds.addAll(scale.qId);
      }
    }
  }

  final questions = <XeboQuestion>[];

  for (final block in data.blocks) {
    for (final q in block.questions) {
      if (followUpQuestionIds.contains(q.uuid)) continue;

      final type = _mapQuestionType(q.quesType);

      final rawOptions = q.options;
      List<dynamic> rowSource = [];
      if (rawOptions != null) {
        final row = rawOptions['row'];
        final items = rawOptions['items'];
        final choices = rawOptions['choices'];
        if (rawOptions is List) {
          rowSource = rawOptions as List<dynamic>;
        } else if (row is List) {
          rowSource = row;
        } else if (items is List) {
          rowSource = items;
        } else if (choices is List) {
          rowSource = choices;
        }
      }

      final rows = rowSource.map((r) {
        final rMap = r as Map<String, dynamic>;
        final id = rMap['uuid'] as String? ?? rMap['id'] as String? ?? '';
        return XeboChoice(
          id: id,
          text: stripHTML(rMap['text'] as String? ?? rMap['label'] as String? ?? rMap['value'] as String? ?? ''),
          value: id,
        );
      }).toList();

      List<dynamic> colSource = [];
      if (rawOptions != null) {
        final col = rawOptions['col'];
        final columns = rawOptions['columns'];
        if (col is List) colSource = col;
        else if (columns is List) colSource = columns;
      }

      final cols = colSource.map((c) {
        final cMap = c as Map<String, dynamic>;
        final id = cMap['uuid'] as String? ?? cMap['id'] as String? ?? '';
        return XeboChoice(
          id: id,
          text: stripHTML(cMap['text'] as String? ?? cMap['label'] as String? ?? ''),
          value: id,
        );
      }).toList();

      // Build conditional follow-ups for NPS Pro
      final conditionalFollowUps = <XeboConditionalFollowUp>[];
      for (final scale in q.settings?.configScale ?? []) {
        if (!scale.enabled) continue;
        final followUpQId = scale.qId.isNotEmpty ? scale.qId[0] : null;
        if (followUpQId == null) continue;

        APIQuestion? followUpApiQ;
        outer:
        for (final b in data.blocks) {
          for (final bq in b.questions) {
            if (bq.uuid == followUpQId) {
              followUpApiQ = bq;
              break outer;
            }
          }
        }

        final followUpOptionsRaw = followUpApiQ?.options;
        final followUpRowSource = followUpOptionsRaw?['row'] as List<dynamic>? ?? [];
        final followUpOptions = followUpRowSource.map((r) {
          final rMap = r as Map<String, dynamic>;
          final id = rMap['uuid'] as String? ?? '';
          return XeboChoice(
            id: id,
            text: stripHTML(rMap['text'] as String?),
            value: id,
          );
        }).toList();

        conditionalFollowUps.add(XeboConditionalFollowUp(
          minRating: scale.scaleMin,
          maxRating: scale.scaleMax,
          followUpQuestion: stripHTML(followUpApiQ?.title),
          followUpType: followUpApiQ != null
              ? _mapQuestionType(followUpApiQ.quesType)
              : XeboQuestionType.singleTextBox,
          followUpOptions: followUpOptions,
          questionId: followUpQId,
        ));
      }

      final npsSettings = q.settings?.nps;
      final ratingSettings = q.settings?.rating;

      questions.add(XeboQuestion(
        id: q.uuid,
        type: type,
        title: stripHTML(q.title),
        subtitle: q.helperText != null ? stripHTML(q.helperText) : null,
        placeholder: q.placeholder != null ? stripHTML(q.placeholder) : null,
        isRequired: q.required,
        options: rows.isNotEmpty ? rows : null,
        columns: cols.isNotEmpty ? cols : null,
        npsLabels: npsSettings != null
            ? XeboNPSLabels(
                lower: npsSettings['leftLabel'] as String?,
                upper: npsSettings['rightLabel'] as String?,
                detractorColor:
                    (npsSettings['colors'] as Map<String, dynamic>?)?['detractor']
                        as String?,
                passiveColor:
                    (npsSettings['colors'] as Map<String, dynamic>?)?['passive']
                        as String?,
                promoterColor:
                    (npsSettings['colors'] as Map<String, dynamic>?)?['promoter']
                        as String?,
              )
            : null,
        conditionalFollowUps:
            conditionalFollowUps.isNotEmpty ? conditionalFollowUps : null,
        ratingStyle: _mapRatingStyle(ratingSettings?['type'] as String?),
        showColLabels: ratingSettings?['colLabel'] as bool? ?? false,
        ratingColor: ratingSettings?['color'] as String?,
      ));
    }
  }

  // Append auto thank-you question
  final tyPage = data.thankYouPage;
  final tyEnabled = tyPage?['enabled'] as bool? ?? false;
  final tyContent = tyPage?['content'] as String?;
  final tyTitle =
      tyEnabled && tyContent != null && tyContent.isNotEmpty
          ? stripHTML(tyContent)
          : 'Thank You!';
  final tySubtitle =
      tyEnabled && tyContent != null && tyContent.isNotEmpty
          ? null
          : 'Your feedback is greatly appreciated.';

  questions.add(XeboQuestion(
    id: 'thank_you_auto',
    type: XeboQuestionType.thankYou,
    title: tyTitle,
    subtitle: tySubtitle,
    isRequired: false,
    redirectURL: tyPage?['links'] as String?,
  ));

  final introPageRaw = data.introPage;
  final thankYouPageRaw = data.thankYouPage;

  return XeboSurvey(
    id: data.uuid,
    name: data.displayTitle,
    projectId: data.projectId,
    questions: questions,
    introPage: introPageRaw != null
        ? XeboSurveyPage(
            enabled: introPageRaw['enabled'] as bool? ?? false,
            content: stripHTML(introPageRaw['content'] as String?),
            buttonText: introPageRaw['buttonText'] as String?,
          )
        : null,
    thankYouPage: thankYouPageRaw != null
        ? XeboSurveyPage(
            enabled: thankYouPageRaw['enabled'] as bool? ?? false,
            content: stripHTML(thankYouPageRaw['content'] as String?),
            links: thankYouPageRaw['links'] as String?,
          )
        : null,
  );
}

// ─── Step 0: Verify API key → bearer token ────────────────────────────────────

Future<String> verifyApiKey(String zone, String apiKey) async {
  final uri = Uri.parse(buildVerifyURL(zone));
  debugLog('[Xebo Step 0] Verifying API key — $uri');

  final res = await http.get(uri, headers: {'x-api-key': apiKey});
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  debugLog('[Xebo] Verify status: ${res.statusCode}');

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('[Xebo] verifyApiKey failed — HTTP ${res.statusCode}: ${res.body}');
  }

  final token = json['access_token'] as String? ??
      json['token'] as String? ??
      (json['data'] as Map<String, dynamic>?)?['token'] as String? ??
      json['bearerToken'] as String? ??
      (json['data'] as Map<String, dynamic>?)?['access_token'] as String?;

  if (token == null) {
    throw Exception('[Xebo] verifyApiKey — token not found in response');
  }

  debugLog('[Xebo] Bearer token obtained');
  return token;
}

// ─── Step 1: Fetch collector ──────────────────────────────────────────────────

class CollectorInfo {
  final String surveyId;
  final String uuid;
  final String mongoId;

  CollectorInfo({required this.surveyId, required this.uuid, required this.mongoId});
}

Future<CollectorInfo> fetchCollector(
    String baseURL, String collectorId, String bearerToken) async {
  final uri = Uri.parse('$baseURL/v3/collectors/collect/$collectorId');
  debugLog('[Xebo Step 1] Fetching collector — $uri');

  final res = await http.get(uri, headers: {'Authorization': 'Bearer $bearerToken'});
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final payload = (json['data'] as Map<String, dynamic>?) ?? json;

  if (res.statusCode < 200 || res.statusCode >= 300 || payload['surveyId'] == null) {
    throw Exception('[Xebo] fetchCollector failed — HTTP ${res.statusCode}: ${res.body}');
  }

  debugLog('[Xebo] Collector UUID: ${payload['uuid']}, surveyId: ${payload['surveyId']}');
  return CollectorInfo(
    surveyId: payload['surveyId'] as String,
    uuid: payload['uuid'] as String? ?? '',
    mongoId: payload['_id'] as String? ?? '',
  );
}

// ─── Step 2: Fetch survey ─────────────────────────────────────────────────────

Future<XeboSurvey> fetchSurvey(
    String baseURL, String surveyId, String bearerToken) async {
  final uri = Uri.parse('$baseURL/v3/survey-management/surveys/$surveyId');
  debugLog('[Xebo Step 2] Fetching survey — $uri');

  final res = await http.get(uri, headers: {'Authorization': 'Bearer $bearerToken'});
  final json = jsonDecode(res.body) as Map<String, dynamic>;

  if (res.statusCode < 200 || res.statusCode >= 300 || json['data'] == null) {
    throw Exception('[Xebo] fetchSurvey failed — HTTP ${res.statusCode}');
  }

  final surveyData = APISurveyData.fromJson(json['data'] as Map<String, dynamic>);
  debugLog('[Xebo] Survey parsed — ${surveyData.blocks.length} block(s)');
  return parseSurvey(surveyData);
}

// ─── Step 3: Submit response ──────────────────────────────────────────────────

Future<bool> submitResponse({
  required String feedbackBaseURL,
  required String surveyId,
  required String collectorUUID,
  required String bearerToken,
  required List<XeboAnswer> answers,
  XeboUserData? userData,
  String? platform,
  String? osVersion,
  String? startTime,
  String? endTime,
  XeboQualityFlags? qualityFlags,
}) async {
  final uri = Uri.parse(
      '$feedbackBaseURL/v3/survey-participation/$surveyId/response/create-response');

  final filteredAnswers = answers.where((a) => a.questionId != 'thank_you_auto').toList();

  final customVariables = <String, String>{};
  if (userData != null) {
    if (userData.name != null) customVariables['fName'] = userData.name!;
    if (userData.email != null) customVariables['email'] = userData.email!;
    if (userData.phone != null) customVariables['mobile'] = userData.phone!;
    if (userData.uniqueId != null) customVariables['unique_id'] = userData.uniqueId!;
    if (userData.country != null) customVariables['country'] = userData.country!;
    if (userData.city != null) customVariables['city'] = userData.city!;
    userData.eData?.forEach((k, v) => customVariables[k] = v);
  }

  final osVer = (osVersion ?? '').replaceAll(RegExp(r'^(ios|android)\s*', caseSensitive: false), '');
  final isIos = platform?.toLowerCase() == 'ios';
  final userAgent = isIos
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS ${osVer.replaceAll('.', '_')} like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
      : 'Mozilla/5.0 (Linux; Android $osVer; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  final timeTakenSecs = qualityFlags != null
      ? (qualityFlags.netTimeDuration * 60).round()
      : null;

  final responsePayload = <String, dynamic>{
    'response_status': 'complete',
    'mode': 'Flutter SDK',
    'userAgent': userAgent,
    if (startTime != null) 'start_time': startTime,
    if (endTime != null) 'end_time': endTime,
    if (timeTakenSecs != null) 'time_spent': timeTakenSecs,
    if (customVariables.isNotEmpty) 'custom_variables': customVariables,
    if (qualityFlags != null) 'qualityFlags': qualityFlags.toJson(),
    'deviceInfo': {
      'type': 'mobile',
      'os': isIos ? 'ios' : 'android',
      'browser': isIos ? 'safari' : 'chrome',
    },
    'geoLocation': {
      'type': 'point',
      'coordinates': [null, null],
      'country': userData?.country,
      'city': userData?.city,
      'region': userData?.region,
    },
    'questions': filteredAnswers
        .map((a) => {
              'uuid': a.questionId,
              'answer': a.value.map((v) => v.toJson()).toList(),
            })
        .toList(),
  };

  final body = jsonEncode({
    'collector_id': collectorUUID,
    'responses': [responsePayload],
  });

  debugLog('[Xebo Step 3] Submitting response — $uri');
  debugLog('[Xebo] ${filteredAnswers.length} answer(s)');

  final res = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $bearerToken',
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
    },
    body: body,
  );

  debugLog('[Xebo] Submit status: ${res.statusCode}');
  return res.statusCode >= 200 && res.statusCode < 300;
}

void debugLog(String message) {
  // ignore: avoid_print
  print(message);
}

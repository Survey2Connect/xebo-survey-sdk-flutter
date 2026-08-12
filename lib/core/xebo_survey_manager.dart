import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart' as xebo_theme;
import '../widgets/xebo_survey_sheet.dart';
import 'xebo_in_app_survey_service.dart';
import 'xebo_network_service.dart';
import 'xebo_offline_queue.dart';

String _generateUUID() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final rand = now ^ (now >> 16);
  return '${rand.toRadixString(16).padLeft(8, '0')}-'
      '${(rand >> 8 & 0xFFFF).toRadixString(16).padLeft(4, '0')}-'
      '4${(rand >> 4 & 0x0FFF).toRadixString(16).padLeft(3, '0')}-'
      '${(8 + (rand & 0x3) | 0x8).toRadixString(16)}${(rand & 0xFFFF).toRadixString(16).padLeft(3, '0')}-'
      '${now.toRadixString(16).padLeft(12, '0')}';
}

class XeboSurveyManager {
  static final XeboSurveyManager instance = XeboSurveyManager._();
  XeboSurveyManager._();

  // Config
  String _apiKey = '';
  String _collectorId = '';
  String _zone = '';
  String _baseURL = '';
  String _feedbackBaseURL = '';
  String _bearerToken = '';

  // State
  XeboSurvey? _survey;
  String _collectorUUID = '';

  // User
  XeboUserData? _userData;
  String _platform = '';
  String _osVersion = '';

  // Timing / quality
  final Map<String, double> _timePerQues = {};
  int _backTrackCount = 0;

  // Network monitoring
  StreamSubscription? _connectivitySub;
  bool _wasOffline = false;

  // ─── Configure ──────────────────────────────────────────────────────────────

  void configure({
    required String apiKey,
    required String collectorId,
    required String zone,
  }) {
    _apiKey = apiKey;
    _collectorId = collectorId;
    _zone = zone;
    _baseURL = buildBaseURL(zone);
    _feedbackBaseURL = buildFeedbackBaseURL(zone);

    _platform = Platform.isIOS ? 'ios' : 'android';
    _osVersion = '$_platform ${Platform.operatingSystemVersion}';

    _startNetworkMonitoring();
    _prefetchSurvey();
  }

  void configureTheme(XeboThemeConfig config) {
    xebo_theme.configureTheme(config);
  }

  // ─── User identity ───────────────────────────────────────────────────────────

  void setUser(XeboUserData data) => _userData = data;
  void clearUser() => _userData = null;

  // ─── Network monitoring ──────────────────────────────────────────────────────

  void _startNetworkMonitoring() {
    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (_wasOffline && isConnected) {
        debugLog('[Xebo] Network restored — flushing offline queue');
        _flushQueue();
      }
      _wasOffline = !isConnected;
    });
  }

  // ─── Pre-fetch ───────────────────────────────────────────────────────────────

  Future<void> _prefetchSurvey() async {
    try {
      debugLog('[Xebo] Pre-fetching survey in background...');
      _bearerToken = await verifyApiKey(_zone, _apiKey);
      final collector =
          await fetchCollector(_baseURL, _collectorId, _bearerToken);
      _collectorUUID = collector.uuid;
      final survey =
          await fetchSurvey(_baseURL, collector.surveyId, _bearerToken);
      _survey = survey;
      debugLog('[Xebo] Pre-fetch done — ${survey.questions.length} questions');
    } catch (e) {
      debugLog('[Xebo] Pre-fetch failed (will retry on present): $e');
    }
  }

  // ─── Present survey ──────────────────────────────────────────────────────────

  Future<void> fetchAndPresentSurvey(BuildContext context) async {
    try {
      if (_survey == null || _collectorUUID.isEmpty) {
        debugLog('[Xebo] Survey not cached — fetching now...');
        _bearerToken = await verifyApiKey(_zone, _apiKey);
        final collector =
            await fetchCollector(_baseURL, _collectorId, _bearerToken);
        _collectorUUID = collector.uuid;
        _survey = await fetchSurvey(_baseURL, collector.surveyId, _bearerToken);
      } else {
        debugLog('[Xebo] Survey cached — showing instantly');
      }

      if (!context.mounted) return;

      _timePerQues.clear();
      _backTrackCount = 0;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        builder: (_) => XeboSurveySheet(
          survey: _survey!,
          onSubmit: _onSessionSubmit,
          onQuestionTime: (qId, secs) => _timePerQues[qId] = secs,
          onDismiss: (_) {},
        ),
      );
    } catch (e) {
      debugLog('[Xebo] fetchAndPresentSurvey failed: $e');
    }
  }

  // ─── In-app survey (own verify → draft → render → submit, granular callbacks) ─
  //
  // Fully separate from fetchAndPresentSurvey above: its own local re-entrancy
  // flag, no shared state with `_survey`/`_collectorUUID`/`_bearerToken`, and its
  // own dedicated networking (xebo_in_app_survey_service.dart) rather than the
  // fetchCollector/fetchSurvey/submitResponse used there — this mirrors the real
  // native iOS `XeboSurvey.inAppSurvey(...)` flow, which:
  //   - fetches the survey *draft* directly by surveyId, with collectorId only as
  //     a header (no separate collector→surveyId lookup);
  //   - doesn't treat a failed key-verify as fatal — falls back to the raw api key;
  //   - resolves collectorId to its uuid only at submission time, only if needed;
  //   - fires onSurveyCompleted immediately on the last answer, submits in the
  //     background, and auto-dismisses ~2s later regardless of submission outcome;
  //   - fires onPartialResponse unconditionally on an early skip (even 0 answers).

  bool _inAppSurveyActive = false;

  /// Fetches and presents a survey with granular lifecycle callbacks mirroring
  /// the native SDK's own verify → draft → render → submit session. `xApiKey`
  /// defaults to the key passed to [configure] when empty.
  Future<void> showInAppSurvey({
    required BuildContext context,
    required String surveyId,
    required String collectorId,
    required String zone,
    String xApiKey = '',
    XeboUserData? userData,
    void Function()? onLoading,
    void Function(String error)? onLoadFailed,
    void Function(Map<String, dynamic> response)? onCompleted,
    void Function()? onDismissed,
    void Function(Map<String, dynamic> response)? onPartialResponse,
    void Function()? onSubmissionSucceeded,
    void Function(String error)? onSubmissionFailed,
  }) async {
    if (_inAppSurveyActive) {
      throw StateError('An in-app survey session is already active.');
    }
    _inAppSurveyActive = true;
    onLoading?.call();

    final effectiveApiKey = xApiKey.isEmpty ? _apiKey : xApiKey;
    final bearerToken = await inAppVerifyApiKey(effectiveApiKey);
    final authHeader = inAppAuthHeader(bearerToken, effectiveApiKey);

    XeboSurvey survey;
    try {
      survey = await fetchInAppSurveyDraft(
        zone: zone,
        surveyId: surveyId,
        collectorId: collectorId,
        authHeader: authHeader,
      );
    } catch (e) {
      _inAppSurveyActive = false;
      onLoadFailed?.call(e.toString());
      return;
    }

    if (!context.mounted) {
      _inAppSurveyActive = false;
      return;
    }

    var completed = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (sheetContext) => XeboSurveySheet(
        survey: survey,
        onSubmit: (answers, startTime, endTime) {
          completed = true;
          onCompleted?.call(buildInAppResponsePayload(
            surveyId: surveyId,
            collectorId: collectorId,
            answers: answers,
          ));

          // Submission runs in the background; the sheet auto-dismisses ~2s later
          // regardless of the outcome, matching XeboInAppSurveySession.complete().
          () async {
            final resolvedCollectorId = await resolveInAppCollectorUUID(
              zone: zone,
              collectorId: collectorId,
              authHeader: authHeader,
            );
            try {
              final ok = await submitInAppSurveyResponse(
                zone: zone,
                surveyId: surveyId,
                collectorId: resolvedCollectorId,
                authHeader: authHeader,
                answers: answers,
                isIOS: Platform.isIOS,
                osVersionRaw: _osVersion,
                userData: userData,
              );
              if (!ok) throw Exception('HTTP error');
              onSubmissionSucceeded?.call();
            } catch (e) {
              onSubmissionFailed?.call(e.toString());
            }
          }();

          Future.delayed(const Duration(seconds: 2), () {
            if (sheetContext.mounted && Navigator.of(sheetContext).canPop()) {
              Navigator.of(sheetContext).pop();
            }
          });
        },
        onQuestionTime: (_, __) {},
        onDismiss: (answersSoFar) {
          if (!completed) {
            onPartialResponse?.call(buildInAppResponsePayload(
              surveyId: surveyId,
              collectorId: collectorId,
              answers: answersSoFar,
            ));
          }
        },
      ),
    );

    _inAppSurveyActive = false;
    onDismissed?.call();
  }

  // ─── Submission ──────────────────────────────────────────────────────────────

  void _onSessionSubmit(
      List<XeboAnswer> answers, String startTime, String endTime) {
    _submitSession(answers, startTime, endTime);
  }

  Future<void> _submitSession(
      List<XeboAnswer> answers, String startTime, String endTime) async {
    final survey = _survey;
    if (survey == null) return;

    final qualityFlags = _buildQualityFlags(startTime);

    try {
      final ok = await submitResponse(
        feedbackBaseURL: _feedbackBaseURL,
        surveyId: survey.id,
        collectorUUID: _collectorUUID,
        bearerToken: _bearerToken,
        answers: answers,
        userData: _userData,
        platform: _platform,
        osVersion: _osVersion,
        startTime: startTime,
        endTime: endTime,
        qualityFlags: qualityFlags,
      );

      if (!ok) throw Exception('HTTP error');
      debugLog('[Xebo] Response submitted successfully');
    } catch (e) {
      debugLog('[Xebo] Submission failed — queuing offline: $e');
      await _enqueueOffline(answers, startTime, endTime, qualityFlags);
    }
  }

  XeboQualityFlags _buildQualityFlags(String startTimeIso) {
    final now = DateTime.now();
    final startEpoch =
        DateTime.parse(startTimeIso).millisecondsSinceEpoch;
    final totalMinutes = now.millisecondsSinceEpoch - startEpoch;
    final totalMins = totalMinutes / 60000.0;
    final curTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return XeboQualityFlags(
      timePerQues: Map.from(_timePerQues),
      totalTimeDuration: totalMins,
      netTimeDuration: totalMins,
      curTime: curTime,
      startTime: startEpoch,
      backTrackCount: _backTrackCount,
    );
  }

  Future<void> _enqueueOffline(
    List<XeboAnswer> answers,
    String startTime,
    String endTime,
    XeboQualityFlags qualityFlags,
  ) async {
    final survey = _survey;
    if (survey == null) return;

    final queued = XeboQueuedResponse(
      responseId: _generateUUID(),
      surveyId: survey.id,
      collectorUUID: _collectorUUID,
      status: 'complete',
      startTime: startTime,
      endTime: endTime,
      answers: List.from(answers),
      userData: _userData,
      platform: _platform,
      osVersion: _osVersion,
      qualityFlags: qualityFlags,
    );

    await XeboOfflineQueue.enqueue(queued);
  }

  // ─── Flush queue ─────────────────────────────────────────────────────────────

  Future<void> _flushQueue() async {
    final all = await XeboOfflineQueue.getAll();
    if (all.isEmpty) return;

    debugLog('[Xebo Offline] Flushing ${all.length} queued response(s)');
    final failed = <XeboQueuedResponse>[];

    for (final queued in all) {
      try {
        final ok = await submitResponse(
          feedbackBaseURL: _feedbackBaseURL,
          surveyId: queued.surveyId,
          collectorUUID: queued.collectorUUID,
          bearerToken: _bearerToken,
          answers: queued.answers,
          userData: queued.userData,
          platform: queued.platform,
          osVersion: queued.osVersion,
          startTime: queued.startTime,
          endTime: queued.endTime,
          qualityFlags: queued.qualityFlags,
        );
        if (!ok) throw Exception('HTTP error');
        debugLog('[Xebo Offline] Flushed: ${queued.responseId}');
      } catch (e) {
        debugLog('[Xebo Offline] Retry failed for ${queued.responseId}: $e');
        failed.add(queued);
      }
    }

    await XeboOfflineQueue.saveAll(failed);
    debugLog('[Xebo Offline] Flush complete — ${failed.length} still pending');
  }

  /// Manually flush the offline queue (call after a successful network check)
  Future<void> flushOfflineQueue() => _flushQueue();

  void dispose() {
    _connectivitySub?.cancel();
  }
}

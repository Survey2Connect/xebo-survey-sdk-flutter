// ─── Enums ────────────────────────────────────────────────────────────────────

enum XeboQuestionType {
  singleChoice,
  multipleChoice,
  dropdown,
  singleTextBox,
  multipleTextBox,
  nps,
  multiNps,
  rating,
  multiRating,
  thankYou,
}

// ─── Sub-models ───────────────────────────────────────────────────────────────

class XeboChoice {
  final String id;
  final String text;
  final String value;

  const XeboChoice({required this.id, required this.text, required this.value});

  factory XeboChoice.fromJson(Map<String, dynamic> json) {
    return XeboChoice(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'value': value};
}

class XeboNPSLabels {
  final String? lower;
  final String? upper;
  final String? detractorColor;
  final String? passiveColor;
  final String? promoterColor;

  const XeboNPSLabels({
    this.lower,
    this.upper,
    this.detractorColor,
    this.passiveColor,
    this.promoterColor,
  });
}

class XeboConditionalFollowUp {
  final int minRating;
  final int maxRating;
  final String followUpQuestion;
  final XeboQuestionType followUpType;
  final List<XeboChoice> followUpOptions;
  final String questionId;

  const XeboConditionalFollowUp({
    required this.minRating,
    required this.maxRating,
    required this.followUpQuestion,
    required this.followUpType,
    required this.followUpOptions,
    required this.questionId,
  });
}

// ─── Question ─────────────────────────────────────────────────────────────────

class XeboQuestion {
  final String id;
  final XeboQuestionType type;
  final String title;
  final String? subtitle;
  final String? placeholder;
  final bool isRequired;
  final List<XeboChoice>? options;
  final List<XeboChoice>? columns;
  final XeboNPSLabels? npsLabels;
  final String? followUpQuestion;
  final List<XeboConditionalFollowUp>? conditionalFollowUps;
  final String? redirectURL;
  final String ratingStyle;
  final bool showColLabels;
  final String? ratingColor;

  const XeboQuestion({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.placeholder,
    required this.isRequired,
    this.options,
    this.columns,
    this.npsLabels,
    this.followUpQuestion,
    this.conditionalFollowUps,
    this.redirectURL,
    this.ratingStyle = 'star',
    this.showColLabels = false,
    this.ratingColor,
  });
}

// ─── Survey Page ──────────────────────────────────────────────────────────────

class XeboSurveyPage {
  final bool enabled;
  final String? content;
  final String? buttonText;
  final String? links;

  const XeboSurveyPage({
    required this.enabled,
    this.content,
    this.buttonText,
    this.links,
  });
}

// ─── Survey ───────────────────────────────────────────────────────────────────

class XeboSurvey {
  final String id;
  final String name;
  final String? projectId;
  final List<XeboQuestion> questions;
  final XeboSurveyPage? introPage;
  final XeboSurveyPage? thankYouPage;

  const XeboSurvey({
    required this.id,
    required this.name,
    this.projectId,
    required this.questions,
    this.introPage,
    this.thankYouPage,
  });
}

// ─── Answers ──────────────────────────────────────────────────────────────────

class XeboAnswerValue {
  final String rowId;
  final String? colId;
  final String? text;

  const XeboAnswerValue({required this.rowId, this.colId, this.text});

  Map<String, dynamic> toJson() => {
        'row_id': rowId.isEmpty ? null : rowId,
        'col_id': colId,
        'text': text,
      };
}

class XeboAnswer {
  final String questionId;
  final List<XeboAnswerValue> value;

  const XeboAnswer({required this.questionId, required this.value});
}

// ─── User / eData ─────────────────────────────────────────────────────────────

class XeboUserData {
  final String? name;
  final String? email;
  final String? phone;
  final String? uniqueId;
  final String? country;
  final String? city;
  final String? region;
  final Map<String, String>? eData;

  const XeboUserData({
    this.name,
    this.email,
    this.phone,
    this.uniqueId,
    this.country,
    this.city,
    this.region,
    this.eData,
  });
}

// ─── Quality flags ────────────────────────────────────────────────────────────

class XeboQualityFlags {
  final Map<String, double> timePerQues;
  final double totalTimeDuration;
  final double netTimeDuration;
  final String curTime;
  final int startTime;
  final int backTrackCount;

  const XeboQualityFlags({
    required this.timePerQues,
    required this.totalTimeDuration,
    required this.netTimeDuration,
    required this.curTime,
    required this.startTime,
    required this.backTrackCount,
  });

  Map<String, dynamic> toJson() => {
        'data': {
          'timePerQues': timePerQues
              .map((k, v) => MapEntry(k, {'timeOnQues': v})),
          'survey': {
            'totalTimeDuration': totalTimeDuration,
            'netTimeDuration': netTimeDuration,
            'curTime': curTime,
            'startTime': startTime,
            'backTrackCount': backTrackCount,
          },
        },
        'straightLining': {'questionList': []},
      };
}

// ─── Config ───────────────────────────────────────────────────────────────────

class XeboConfig {
  final String apiKey;
  final String collectorId;
  final String zone;

  const XeboConfig({
    required this.apiKey,
    required this.collectorId,
    required this.zone,
  });
}

class XeboThemeConfig {
  final String? primaryColor;
  final String? backgroundColor;
  final String? textColor;
  final double? cornerRadius;
  final String? fontFamily;

  const XeboThemeConfig({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.cornerRadius,
    this.fontFamily,
  });
}

// ─── Offline queue entry ──────────────────────────────────────────────────────

class XeboQueuedResponse {
  final String responseId;
  final String surveyId;
  final String collectorUUID;
  final String status;
  final String startTime;
  final String endTime;
  final List<XeboAnswer> answers;
  final XeboUserData? userData;
  final String? platform;
  final String? osVersion;
  final XeboQualityFlags? qualityFlags;

  const XeboQueuedResponse({
    required this.responseId,
    required this.surveyId,
    required this.collectorUUID,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.answers,
    this.userData,
    this.platform,
    this.osVersion,
    this.qualityFlags,
  });

  Map<String, dynamic> toJson() => {
        'responseId': responseId,
        'surveyId': surveyId,
        'collectorUUID': collectorUUID,
        'status': status,
        'startTime': startTime,
        'endTime': endTime,
        'answers': answers
            .map((a) => {
                  'questionId': a.questionId,
                  'value': a.value.map((v) => v.toJson()).toList(),
                })
            .toList(),
        'userData': userData == null
            ? null
            : {
                'name': userData!.name,
                'email': userData!.email,
                'phone': userData!.phone,
                'uniqueId': userData!.uniqueId,
                'country': userData!.country,
                'city': userData!.city,
                'region': userData!.region,
                'eData': userData!.eData,
              },
        'platform': platform,
        'osVersion': osVersion,
        'qualityFlags': qualityFlags?.toJson(),
      };

  factory XeboQueuedResponse.fromJson(Map<String, dynamic> json) {
    final answersRaw = json['answers'] as List<dynamic>? ?? [];
    final userDataRaw = json['userData'] as Map<String, dynamic>?;
    final qfRaw = json['qualityFlags'] as Map<String, dynamic>?;
    final qfData = qfRaw?['data'] as Map<String, dynamic>?;
    final qfSurvey = qfData?['survey'] as Map<String, dynamic>?;
    final qfTimePerQues = qfData?['timePerQues'] as Map<String, dynamic>? ?? {};

    return XeboQueuedResponse(
      responseId: json['responseId'] as String? ?? '',
      surveyId: json['surveyId'] as String? ?? '',
      collectorUUID: json['collectorUUID'] as String? ?? '',
      status: json['status'] as String? ?? 'complete',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      answers: answersRaw.map((a) {
        final aMap = a as Map<String, dynamic>;
        final valRaw = aMap['value'] as List<dynamic>? ?? [];
        return XeboAnswer(
          questionId: aMap['questionId'] as String? ?? '',
          value: valRaw.map((v) {
            final vMap = v as Map<String, dynamic>;
            return XeboAnswerValue(
              rowId: vMap['row_id'] as String? ?? vMap['rowId'] as String? ?? '',
              colId: vMap['col_id'] as String? ?? vMap['colId'] as String?,
              text: vMap['text'] as String?,
            );
          }).toList(),
        );
      }).toList(),
      userData: userDataRaw == null
          ? null
          : XeboUserData(
              name: userDataRaw['name'] as String?,
              email: userDataRaw['email'] as String?,
              phone: userDataRaw['phone'] as String?,
              uniqueId: userDataRaw['uniqueId'] as String?,
              country: userDataRaw['country'] as String?,
              city: userDataRaw['city'] as String?,
              region: userDataRaw['region'] as String?,
              eData: (userDataRaw['eData'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v.toString())),
            ),
      platform: json['platform'] as String?,
      osVersion: json['osVersion'] as String?,
      qualityFlags: qfSurvey == null
          ? null
          : XeboQualityFlags(
              timePerQues: qfTimePerQues.map((k, v) {
                final vMap = v as Map<String, dynamic>;
                return MapEntry(k, (vMap['timeOnQues'] as num?)?.toDouble() ?? 0);
              }),
              totalTimeDuration:
                  (qfSurvey['totalTimeDuration'] as num?)?.toDouble() ?? 0,
              netTimeDuration:
                  (qfSurvey['netTimeDuration'] as num?)?.toDouble() ?? 0,
              curTime: qfSurvey['curTime'] as String? ?? '',
              startTime: (qfSurvey['startTime'] as num?)?.toInt() ?? 0,
              backTrackCount: (qfSurvey['backTrackCount'] as num?)?.toInt() ?? 0,
            ),
    );
  }
}

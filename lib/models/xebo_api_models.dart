// Raw API response shapes — mirror the exact JSON returned by the Xebo backend.

class APICollectorData {
  final String id;
  final String uuid;
  final String surveyId;

  APICollectorData({required this.id, required this.uuid, required this.surveyId});

  factory APICollectorData.fromJson(Map<String, dynamic> json) {
    return APICollectorData(
      id: json['_id'] as String? ?? '',
      uuid: json['uuid'] as String? ?? '',
      surveyId: json['surveyId'] as String? ?? '',
    );
  }
}

class APIOptionItem {
  final String uuid;
  final String text;

  APIOptionItem({required this.uuid, required this.text});

  factory APIOptionItem.fromJson(Map<String, dynamic> json) {
    return APIOptionItem(
      uuid: json['uuid'] as String? ?? json['id'] as String? ?? '',
      text: json['text'] as String? ?? json['label'] as String? ?? '',
    );
  }
}

class APIConfigScale {
  final String uuid;
  final int scaleMin;
  final int scaleMax;
  final bool enabled;
  final List<String> qId;

  APIConfigScale({
    required this.uuid,
    required this.scaleMin,
    required this.scaleMax,
    required this.enabled,
    required this.qId,
  });

  factory APIConfigScale.fromJson(Map<String, dynamic> json) {
    final scale = json['scale'] as Map<String, dynamic>? ?? {};
    final qIdRaw = json['qId'] as List<dynamic>? ?? [];
    return APIConfigScale(
      uuid: json['uuid'] as String? ?? '',
      scaleMin: (scale['min'] as num?)?.toInt() ?? 0,
      scaleMax: (scale['max'] as num?)?.toInt() ?? 10,
      enabled: json['enabled'] as bool? ?? true,
      qId: qIdRaw.map((e) => e.toString()).toList(),
    );
  }
}

class APIQuestionSettings {
  final Map<String, dynamic>? nps;
  final List<APIConfigScale> configScale;
  final Map<String, dynamic>? rating;

  APIQuestionSettings({this.nps, required this.configScale, this.rating});

  factory APIQuestionSettings.fromJson(Map<String, dynamic> json) {
    final scaleRaw = json['configScale'] as List<dynamic>? ?? [];
    return APIQuestionSettings(
      nps: json['nps'] as Map<String, dynamic>?,
      configScale: scaleRaw
          .map((e) => APIConfigScale.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: json['rating'] as Map<String, dynamic>?,
    );
  }
}

class APIQuestion {
  final String uuid;
  final String title;
  final String quesType;
  final String? helperText;
  final bool required;
  final Map<String, dynamic>? options;
  final APIQuestionSettings? settings;
  final String? placeholder;

  APIQuestion({
    required this.uuid,
    required this.title,
    required this.quesType,
    this.helperText,
    required this.required,
    this.options,
    this.settings,
    this.placeholder,
  });

  factory APIQuestion.fromJson(Map<String, dynamic> json) {
    final helperRaw = json['helperText'] as Map<String, dynamic>?;
    final requiredRaw = json['required'] as Map<String, dynamic>?;
    final placeholderRaw = json['placeholder'] as Map<String, dynamic>?;
    final settingsRaw = json['settings'] as Map<String, dynamic>?;
    return APIQuestion(
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      quesType: json['quesType'] as String? ?? '',
      helperText: helperRaw?['text'] as String?,
      required: requiredRaw?['enabled'] as bool? ?? false,
      options: json['options'] as Map<String, dynamic>?,
      settings: settingsRaw != null ? APIQuestionSettings.fromJson(settingsRaw) : null,
      placeholder: placeholderRaw?['text'] as String?,
    );
  }
}

class APIBlock {
  final List<APIQuestion> questions;

  APIBlock({required this.questions});

  factory APIBlock.fromJson(Map<String, dynamic> json) {
    final questionsRaw = json['questions'] as List<dynamic>? ?? [];
    return APIBlock(
      questions: questionsRaw.map((item) {
        final q = (item as Map<String, dynamic>)['question'] as Map<String, dynamic>;
        return APIQuestion.fromJson(q);
      }).toList(),
    );
  }
}

class APISurveyData {
  final String uuid;
  final String displayTitle;
  final String? projectId;
  final List<APIBlock> blocks;
  final Map<String, dynamic>? introPage;
  final Map<String, dynamic>? thankYouPage;

  APISurveyData({
    required this.uuid,
    required this.displayTitle,
    this.projectId,
    required this.blocks,
    this.introPage,
    this.thankYouPage,
  });

  factory APISurveyData.fromJson(Map<String, dynamic> json) {
    final blocksRaw = json['blocks'] as List<dynamic>? ?? [];
    return APISurveyData(
      uuid: json['uuid'] as String? ?? '',
      displayTitle: json['displayTitle'] as String? ?? '',
      projectId: json['projectId'] as String?,
      blocks: blocksRaw
          .map((b) => APIBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      introPage: json['introPage'] as Map<String, dynamic>?,
      thankYouPage: json['thankYouPage'] as Map<String, dynamic>?,
    );
  }
}

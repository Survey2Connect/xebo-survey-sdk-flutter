import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import 'xebo_intro_view.dart';
import 'xebo_thank_you_view.dart';
import 'xebo_single_choice_view.dart';
import 'xebo_multiple_choice_view.dart';
import 'xebo_dropdown_view.dart';
import 'xebo_text_box_view.dart';
import 'xebo_nps_view.dart';
import 'xebo_multi_nps_view.dart';
import 'xebo_rating_view.dart';
import 'xebo_multi_rating_view.dart';

enum _SurveyScreen { intro, question, thankYou }

class XeboSurveySheet extends StatefulWidget {
  final XeboSurvey survey;
  final void Function(List<XeboAnswer> answers, String startTime, String endTime) onSubmit;
  final void Function(String questionId, double secondsSpent) onQuestionTime;
  final VoidCallback onDismiss;
  final void Function(String url)? onRedirectURL;

  const XeboSurveySheet({
    super.key,
    required this.survey,
    required this.onSubmit,
    required this.onQuestionTime,
    required this.onDismiss,
    this.onRedirectURL,
  });

  @override
  State<XeboSurveySheet> createState() => _XeboSurveySheetState();
}

class _XeboSurveySheetState extends State<XeboSurveySheet> {
  late _SurveyScreen _screen;
  int _questionIndex = 0;
  final List<XeboAnswer> _answers = [];
  late DateTime _surveyStart;
  late DateTime _questionStart;

  @override
  void initState() {
    super.initState();
    _surveyStart = DateTime.now();
    _questionStart = DateTime.now();
    _screen = (widget.survey.introPage?.enabled == true)
        ? _SurveyScreen.intro
        : _SurveyScreen.question;
  }

  void _handleIntroStart() {
    setState(() {
      _screen = _SurveyScreen.question;
      _questionIndex = 0;
      _questionStart = DateTime.now();
    });
  }

  void _recordAnswer(XeboAnswer answer) {
    final idx = _answers.indexWhere((a) => a.questionId == answer.questionId);
    if (idx >= 0) {
      _answers[idx] = answer;
    } else {
      _answers.add(answer);
    }
  }

  void _handleAnswer(dynamic answer) {
    final now = DateTime.now();
    final currentQ = widget.survey.questions[_questionIndex];
    final secondsOnQuestion =
        now.difference(_questionStart).inMilliseconds / 1000.0;
    widget.onQuestionTime(currentQ.id, secondsOnQuestion);

    if (answer is List<XeboAnswer>) {
      for (final a in answer) {
        _recordAnswer(a);
      }
    } else if (answer is XeboAnswer) {
      _recordAnswer(answer);
    }

    final nextIndex = _questionIndex + 1;
    if (nextIndex < widget.survey.questions.length) {
      final nextQ = widget.survey.questions[nextIndex];
      if (nextQ.id == 'thank_you_auto') {
        final endTime = DateTime.now().toIso8601String();
        widget.onSubmit(_answers, _surveyStart.toIso8601String(), endTime);
        setState(() {
          _questionIndex = nextIndex;
          _screen = _SurveyScreen.thankYou;
        });
      } else {
        setState(() {
          _questionIndex = nextIndex;
          _questionStart = DateTime.now();
          _screen = _SurveyScreen.question;
        });
      }
    }
  }

  void _handleSkip() {
    widget.onDismiss();
    Navigator.of(context).pop();
  }

  Widget _buildContent() {
    final survey = widget.survey;

    if (_screen == _SurveyScreen.intro && survey.introPage != null) {
      return XeboIntroView(
        introPage: survey.introPage!,
        onStart: _handleIntroStart,
      );
    }

    if (_screen == _SurveyScreen.thankYou) {
      final tyQ = survey.questions.firstWhere((q) => q.id == 'thank_you_auto');
      return XeboThankYouView(
        question: tyQ,
        onDismiss: _handleSkip,
        onRedirectURL: widget.onRedirectURL,
      );
    }

    final question = survey.questions[_questionIndex];
    final lastRealIndex =
        survey.questions.indexWhere((q) => q.id == 'thank_you_auto') - 1;
    final isLast = _questionIndex == lastRealIndex;

    switch (question.type) {
      case XeboQuestionType.singleChoice:
        return XeboSingleChoiceView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      case XeboQuestionType.multipleChoice:
        return XeboMultipleChoiceView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      case XeboQuestionType.dropdown:
        return XeboDropdownView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      case XeboQuestionType.singleTextBox:
      case XeboQuestionType.multipleTextBox:
        return XeboTextBoxView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      case XeboQuestionType.nps:
        return XeboNPSView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      case XeboQuestionType.multiNps:
        return XeboMultiNPSView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      case XeboQuestionType.rating:
        return XeboRatingView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      case XeboQuestionType.multiRating:
        return XeboMultiRatingView(
          key: ValueKey(question.id),
          question: question,
          isLastQuestion: isLast,
          onAnswer: _handleAnswer,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();
    final mq = MediaQuery.of(context);
    final sh = mq.size.height;
    // home indicator / gesture bar height; fall back to 16 for non-notched devices
    final safeBottom = mq.padding.bottom > 0 ? mq.padding.bottom : 16.0;

    // Compute content area height (what the question widget itself gets).
    // The chrome above/below the content is: handle(18) + header(~40) + safeBottom.
    // We add that separately so content area is never compressed by it.
    final double contentHeight;
    if (_screen == _SurveyScreen.thankYou) {
      contentHeight = 320;
    } else if (_screen == _SurveyScreen.intro) {
      contentHeight = (sh * 0.38).clamp(240.0, 360.0);
    } else {
      contentHeight = (sh * 0.60).clamp(400.0, 540.0);
    }
    // chrome = handle(18) + header(40) = 58 px, plus safe area at bottom
    final sheetHeight = contentHeight + 58 + safeBottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, -4),
              )
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Header row with Skip / ✕
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _handleSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.textColor.withValues(
                            alpha: _screen == _SurveyScreen.thankYou
                                ? 0.7
                                : 0.6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        _screen == _SurveyScreen.thankYou ? '✕' : 'Skip',
                        style: TextStyle(
                          fontSize:
                              _screen == _SurveyScreen.thankYou ? 18 : 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: theme.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content — fills remaining space cleanly
              Expanded(child: _buildContent()),
              // Safe area spacer (home indicator / gesture bar)
              SizedBox(height: safeBottom),
            ],
          ),
        ),
      ),
    );
  }
}

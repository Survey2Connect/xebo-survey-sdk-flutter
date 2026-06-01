import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import '_shake_mixin.dart';
import '_nps_helpers.dart';

class XeboNPSView extends StatefulWidget {
  final XeboQuestion question;
  final bool isLastQuestion;
  final void Function(dynamic) onAnswer;

  const XeboNPSView({
    super.key,
    required this.question,
    required this.isLastQuestion,
    required this.onAnswer,
  });

  @override
  State<XeboNPSView> createState() => _XeboNPSViewState();
}

class _XeboNPSViewState extends State<XeboNPSView>
    with TickerProviderStateMixin, XeboShakeMixin {
  int? _selectedScore;
  String _followUpText = '';
  String? _followUpChoice;
  String _error = '';
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    initShake(this);
    _scaleControllers = List.generate(
      11,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      ),
    );
    _scaleAnimations = _scaleControllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.15).animate(
              CurvedAnimation(parent: c, curve: Curves.elasticOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _scaleControllers) c.dispose();
    disposeShake();
    super.dispose();
  }

  void _handleScorePress(int score) {
    setState(() {
      _selectedScore = score;
      _error = '';
      _followUpText = '';
      _followUpChoice = null;
    });
    _scaleControllers[score].forward().then((_) {
      _scaleControllers[score].reverse();
    });
  }

  XeboConditionalFollowUp? get _activeFollowUp {
    if (_selectedScore == null) return null;
    return (widget.question.conditionalFollowUps ?? []).firstWhere(
      (f) => _selectedScore! >= f.minRating && _selectedScore! <= f.maxRating,
      orElse: () => throw StateError(''),
    );
  }

  XeboConditionalFollowUp? get _safeActiveFollowUp {
    try {
      return _activeFollowUp;
    } catch (_) {
      return null;
    }
  }

  bool get _hasTextFollowUp =>
      widget.question.followUpQuestion != null && _safeActiveFollowUp == null;

  void _handleNext() {
    if (widget.question.isRequired && _selectedScore == null) {
      setState(() => _error = 'Please select a score.');
      triggerShake();
      return;
    }
    FocusScope.of(context).unfocus();
    final score = _selectedScore ?? 0;
    final colId = widget.question.columns != null && score < widget.question.columns!.length
        ? widget.question.columns![score].id
        : score.toString();
    final rowId = widget.question.options != null && widget.question.options!.isNotEmpty
        ? widget.question.options![0].id
        : score.toString();

    final activeFollowUp = _safeActiveFollowUp;
    if (activeFollowUp != null) {
      final answers = [
        XeboAnswer(
            questionId: widget.question.id,
            value: [XeboAnswerValue(rowId: rowId, colId: colId)]),
      ];
      if (_followUpChoice != null) {
        final selectedOption =
            activeFollowUp.followUpOptions.firstWhere((o) => o.id == _followUpChoice);
        answers.add(XeboAnswer(
          questionId: activeFollowUp.questionId,
          value: [XeboAnswerValue(rowId: _followUpChoice!, text: selectedOption.text)],
        ));
      } else if (_followUpText.trim().isNotEmpty) {
        answers.add(XeboAnswer(
          questionId: activeFollowUp.questionId,
          value: [XeboAnswerValue(rowId: activeFollowUp.questionId, text: _followUpText)],
        ));
      }
      widget.onAnswer(answers);
      return;
    }

    widget.onAnswer(XeboAnswer(
      questionId: widget.question.id,
      value: [
        XeboAnswerValue(
          rowId: rowId,
          colId: colId,
          text: _hasTextFollowUp ? _followUpText : null,
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();
    final activeFollowUp = _safeActiveFollowUp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.question.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                      fontFamily: theme.fontFamily,
                    ),
                  ),
                  if (widget.question.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.question.subtitle!,
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.textColor.withValues(alpha: 0.6),
                          fontFamily: theme.fontFamily),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // NPS scale row
                  Row(
                    children: List.generate(11, (i) {
                      final selected = _selectedScore == i;
                      final color = npsColor(i, widget.question.npsLabels);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: ScaleTransition(
                            scale: _scaleAnimations[i],
                            child: GestureDetector(
                              onTap: () => _handleScorePress(i),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.black
                                        : color,
                                    width: selected ? 2.5 : 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$i',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isColorDark(color)
                                        ? Colors.white
                                        : selected
                                            ? const Color(0xFF111111)
                                            : const Color(0xFF444444),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (widget.question.npsLabels?.lower != null ||
                      widget.question.npsLabels?.upper != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.question.npsLabels?.lower ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.textColor.withValues(alpha: 0.6),
                              fontFamily: theme.fontFamily),
                        ),
                        Text(
                          widget.question.npsLabels?.upper ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.textColor.withValues(alpha: 0.6),
                              fontFamily: theme.fontFamily),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Conditional follow-up (NPS Pro)
                  if (_selectedScore != null && activeFollowUp != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                        borderRadius:
                            BorderRadius.circular(theme.cornerRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            activeFollowUp.followUpQuestion,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                                fontFamily: theme.fontFamily),
                          ),
                          const SizedBox(height: 12),
                          if (activeFollowUp.followUpType ==
                                  XeboQuestionType.singleChoice &&
                              activeFollowUp.followUpOptions.isNotEmpty)
                            ...activeFollowUp.followUpOptions.map((opt) =>
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _followUpChoice = opt.id),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _followUpChoice == opt.id
                                            ? theme.primaryColor
                                            : const Color(0xFFE5E7EB),
                                        width: 1.5,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(opt.text,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: theme.textColor)),
                                  ),
                                ))
                          else
                            TextField(
                              onChanged: (v) =>
                                  setState(() => _followUpText = v),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Your comment...',
                                hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF)),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(theme.cornerRadius),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB), width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(theme.cornerRadius),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB), width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.all(10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  // Simple text follow-up
                  if (_selectedScore != null && _hasTextFollowUp) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                        borderRadius:
                            BorderRadius.circular(theme.cornerRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.question.followUpQuestion!,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                                fontFamily: theme.fontFamily),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            onChanged: (v) =>
                                setState(() => _followUpText = v),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Your comment...',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF9CA3AF)),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(theme.cornerRadius),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(theme.cornerRadius),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              children: [
                if (_error.isNotEmpty) ...[
                  Text(_error,
                      style: const TextStyle(
                          color: Color(0xFFEF4444), fontSize: 13)),
                  const SizedBox(height: 8),
                ],
                buildShakeWidget(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedScore == null ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            theme.primaryColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(theme.cornerRadius)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isLastQuestion ? 'Submit' : 'Next',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: theme.fontFamily),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

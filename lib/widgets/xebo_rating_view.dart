import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import '_shake_mixin.dart';
import '_nps_helpers.dart' show hexToNpsColor;

const _emojiMap = ['😡', '😕', '😐', '🙂', '😄'];

class XeboRatingView extends StatefulWidget {
  final XeboQuestion question;
  final bool isLastQuestion;
  final void Function(XeboAnswer) onAnswer;

  const XeboRatingView({
    super.key,
    required this.question,
    required this.isLastQuestion,
    required this.onAnswer,
  });

  @override
  State<XeboRatingView> createState() => _XeboRatingViewState();
}

class _XeboRatingViewState extends State<XeboRatingView>
    with SingleTickerProviderStateMixin, XeboShakeMixin {
  int? _selected;
  String _followUpText = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    initShake(this);
  }

  @override
  void dispose() {
    disposeShake();
    super.dispose();
  }

  void _handleSelect(int index) {
    setState(() {
      _selected = index;
      _error = '';
      _followUpText = '';
    });
  }

  void _handleNext() {
    if (widget.question.isRequired && _selected == null) {
      setState(() => _error = 'Please select a rating.');
      triggerShake();
      return;
    }
    FocusScope.of(context).unfocus();
    final idx = _selected ?? 0;
    final colId = widget.question.columns != null && idx < widget.question.columns!.length
        ? widget.question.columns![idx].id
        : idx.toString();
    final rowId = widget.question.options != null && widget.question.options!.isNotEmpty
        ? widget.question.options![0].id
        : 'rating';
    widget.onAnswer(XeboAnswer(
      questionId: widget.question.id,
      value: [
        XeboAnswerValue(
          rowId: rowId,
          colId: colId,
          text: _followUpText.isNotEmpty ? _followUpText : null,
        )
      ],
    ));
  }

  Widget _ratingIcon(int index, bool selected, bool filled) {
    final style = widget.question.ratingStyle;
    final rawColor = widget.question.ratingColor;
    Color activeColor = rawColor != null ? hexToNpsColor(rawColor) : const Color(0xFFF59E0B);
    const inactive = Color(0xFFE5E7EB);

    switch (style) {
      case 'heart':
        return Text(filled ? '♥' : '♡',
            style: TextStyle(fontSize: 34, color: filled ? activeColor : inactive));
      case 'circle':
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? activeColor : inactive,
          ),
        );
      case 'tile':
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: filled ? activeColor : inactive,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text('${index + 1}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : const Color(0xFF6B7280))),
        );
      case 'emoji':
        return Text(
          _emojiMap[index.clamp(0, _emojiMap.length - 1)],
          style: TextStyle(fontSize: 34, color: selected ? null : Colors.black.withValues(alpha: 0.35)),
        );
      default: // star
        return Text(filled ? '★' : '☆',
            style: TextStyle(fontSize: 34, color: filled ? activeColor : inactive));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();
    final style = widget.question.ratingStyle;
    final isCumulative = style == 'star' || style == 'heart';
    final totalSteps = widget.question.columns?.length ?? 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                    const SizedBox(height: 16),
                    Text(
                      widget.question.subtitle!,
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.textColor.withValues(alpha: 0.6),
                          fontFamily: theme.fontFamily),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(totalSteps, (i) {
                      final filled = isCumulative
                          ? (_selected != null && i <= _selected!)
                          : i == _selected;
                      return GestureDetector(
                        onTap: () => _handleSelect(i),
                        child: _ratingIcon(i, i == _selected, filled),
                      );
                    }),
                  ),
                  if (widget.question.showColLabels &&
                      widget.question.columns != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: widget.question.columns!
                          .map((col) => Expanded(
                                child: Text(
                                  col.text,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textColor.withValues(alpha: 0.6),
                                    fontFamily: theme.fontFamily,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_selected != null &&
                      widget.question.followUpQuestion != null) ...[
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
                                borderRadius: BorderRadius.circular(
                                    theme.cornerRadius),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    theme.cornerRadius),
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
                      onPressed: _selected == null ? null : _handleNext,
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


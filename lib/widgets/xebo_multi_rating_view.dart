import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import '_shake_mixin.dart';
import '_nps_helpers.dart' show hexToNpsColor;

class XeboMultiRatingView extends StatefulWidget {
  final XeboQuestion question;
  final bool isLastQuestion;
  final void Function(XeboAnswer) onAnswer;

  const XeboMultiRatingView({
    super.key,
    required this.question,
    required this.isLastQuestion,
    required this.onAnswer,
  });

  @override
  State<XeboMultiRatingView> createState() => _XeboMultiRatingViewState();
}

class _XeboMultiRatingViewState extends State<XeboMultiRatingView>
    with SingleTickerProviderStateMixin, XeboShakeMixin {
  final Map<String, int> _ratings = {};
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

  void _setRating(String rowId, int index) {
    setState(() {
      _ratings[rowId] = index;
      _error = '';
    });
  }

  void _handleNext() {
    final rows = widget.question.options ?? [];
    if (widget.question.isRequired &&
        rows.any((r) => !_ratings.containsKey(r.id))) {
      setState(() => _error = 'Please rate all items.');
      triggerShake();
      return;
    }
    widget.onAnswer(XeboAnswer(
      questionId: widget.question.id,
      value: rows
          .where((r) => _ratings.containsKey(r.id))
          .map((r) {
            final idx = _ratings[r.id]!;
            final colId = widget.question.columns != null &&
                    idx < widget.question.columns!.length
                ? widget.question.columns![idx].id
                : idx.toString();
            return XeboAnswerValue(rowId: r.id, colId: colId);
          })
          .toList(),
    ));
  }

  Widget _icon(String style, bool filled, int index, Color activeColor) {
    const inactive = Color(0xFFE5E7EB);
    switch (style) {
      case 'heart':
        return Text(filled ? '♥' : '♡',
            style: TextStyle(fontSize: 30, color: filled ? activeColor : inactive));
      case 'circle':
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: filled ? activeColor : inactive),
        );
      case 'tile':
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: filled ? activeColor : inactive,
              borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Text('${index + 1}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : const Color(0xFF6B7280))),
        );
      default: // star
        return Text(filled ? '★' : '☆',
            style: TextStyle(fontSize: 30, color: filled ? activeColor : inactive));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();
    final rows = widget.question.options ?? [];
    final totalSteps = widget.question.columns?.length ?? 5;
    final ratingStyle = widget.question.ratingStyle;
    final isCumulative = ratingStyle == 'star' || ratingStyle == 'heart';
    final rawColor = widget.question.ratingColor;
    final activeColor =
        rawColor != null ? hexToNpsColor(rawColor) : theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final row = rows[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        row.text,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.textColor,
                            fontFamily: theme.fontFamily),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(totalSteps, (j) {
                          final current = _ratings[row.id];
                          final filled = isCumulative
                              ? (current != null && j <= current)
                              : j == current;
                          return GestureDetector(
                            onTap: () => _setRating(row.id, j),
                            child: _icon(ratingStyle, filled, j, activeColor),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
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
    );
  }
}

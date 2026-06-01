import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import '_shake_mixin.dart';
import '_nps_helpers.dart';

class XeboMultiNPSView extends StatefulWidget {
  final XeboQuestion question;
  final bool isLastQuestion;
  final void Function(XeboAnswer) onAnswer;

  const XeboMultiNPSView({
    super.key,
    required this.question,
    required this.isLastQuestion,
    required this.onAnswer,
  });

  @override
  State<XeboMultiNPSView> createState() => _XeboMultiNPSViewState();
}

class _XeboMultiNPSViewState extends State<XeboMultiNPSView>
    with SingleTickerProviderStateMixin, XeboShakeMixin {
  final Map<String, int> _scores = {};
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

  void _setScore(String rowId, int score) {
    setState(() {
      _scores[rowId] = score;
      _error = '';
    });
  }

  void _handleNext() {
    final rows = widget.question.options ?? [];
    if (widget.question.isRequired &&
        rows.any((r) => !_scores.containsKey(r.id))) {
      setState(() => _error = 'Please rate all items.');
      triggerShake();
      return;
    }
    widget.onAnswer(XeboAnswer(
      questionId: widget.question.id,
      value: rows
          .where((r) => _scores.containsKey(r.id))
          .map((r) {
            final scoreIdx = _scores[r.id]!;
            final colId = widget.question.columns != null &&
                    scoreIdx < widget.question.columns!.length
                ? widget.question.columns![scoreIdx].id
                : scoreIdx.toString();
            return XeboAnswerValue(rowId: r.id, colId: colId);
          })
          .toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();
    final rows = widget.question.options ?? [];

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
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final row = rows[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
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
                        children: List.generate(11, (j) {
                          final selected = _scores[row.id] == j;
                          final color = npsColor(j, widget.question.npsLabels);
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: GestureDetector(
                                onTap: () => _setScore(row.id, j),
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color:
                                          selected ? Colors.black : color,
                                      width: selected ? 2.5 : 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$j',
                                    style: TextStyle(
                                      fontSize: 12,
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

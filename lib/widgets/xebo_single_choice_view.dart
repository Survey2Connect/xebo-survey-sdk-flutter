import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import '_shake_mixin.dart';

class XeboSingleChoiceView extends StatefulWidget {
  final XeboQuestion question;
  final bool isLastQuestion;
  final void Function(XeboAnswer) onAnswer;

  const XeboSingleChoiceView({
    super.key,
    required this.question,
    required this.isLastQuestion,
    required this.onAnswer,
  });

  @override
  State<XeboSingleChoiceView> createState() => _XeboSingleChoiceViewState();
}

class _XeboSingleChoiceViewState extends State<XeboSingleChoiceView>
    with SingleTickerProviderStateMixin, XeboShakeMixin {
  String? _selectedId;
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

  void _handleNext() {
    if (widget.question.isRequired && _selectedId == null) {
      setState(() => _error = 'Please select an option.');
      triggerShake();
      return;
    }
    if (_selectedId == null) {
      widget.onAnswer(XeboAnswer(questionId: widget.question.id, value: []));
      return;
    }
    final selectedText =
        widget.question.options?.firstWhere((o) => o.id == _selectedId).text;
    widget.onAnswer(XeboAnswer(
      questionId: widget.question.id,
      value: [XeboAnswerValue(rowId: _selectedId!, text: selectedText)],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();
    final options = widget.question.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                    fontFamily: theme.fontFamily,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Scrollable options list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: options.length,
            itemBuilder: (_, i) {
              final choice = options[i];
              final selected = _selectedId == choice.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedId = choice.id;
                  _error = '';
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? theme.primaryColor : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? theme.primaryColor : const Color(0xFF9CA3AF),
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.textColor,
                            fontFamily: theme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Error + button pinned at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error.isNotEmpty) ...[
                Text(_error,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                const SizedBox(height: 8),
              ],
              buildShakeWidget(
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.cornerRadius)),
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
            ],
          ),
        ),
      ],
    );
  }
}

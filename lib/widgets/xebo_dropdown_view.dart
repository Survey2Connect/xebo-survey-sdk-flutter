import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import '_shake_mixin.dart';

class XeboDropdownView extends StatefulWidget {
  final XeboQuestion question;
  final bool isLastQuestion;
  final void Function(XeboAnswer) onAnswer;

  const XeboDropdownView({
    super.key,
    required this.question,
    required this.isLastQuestion,
    required this.onAnswer,
  });

  @override
  State<XeboDropdownView> createState() => _XeboDropdownViewState();
}

class _XeboDropdownViewState extends State<XeboDropdownView>
    with SingleTickerProviderStateMixin, XeboShakeMixin {
  XeboChoice? _selectedChoice;
  bool _isOpen = false;
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

  void _handleSelect(XeboChoice choice) {
    setState(() {
      _selectedChoice = choice;
      _isOpen = false;
      _error = '';
    });
  }

  void _handleNext() {
    if (widget.question.isRequired && _selectedChoice == null) {
      setState(() => _error = 'Please select an option.');
      triggerShake();
      return;
    }
    widget.onAnswer(XeboAnswer(
      questionId: widget.question.id,
      value: _selectedChoice != null
          ? [XeboAnswerValue(rowId: _selectedChoice!.id, text: _selectedChoice!.text)]
          : [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();
    final options = widget.question.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scrollable content area
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
                // Trigger button
                buildShakeWidget(
                  child: GestureDetector(
                    onTap: () => setState(() => _isOpen = !_isOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isOpen ? theme.primaryColor : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(theme.cornerRadius),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedChoice?.text ??
                                  widget.question.placeholder ??
                                  'Select an option',
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedChoice != null
                                    ? theme.textColor
                                    : const Color(0xFF9CA3AF),
                                fontFamily: theme.fontFamily,
                              ),
                            ),
                          ),
                          Icon(
                            _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: theme.textColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isOpen) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.primaryColor, width: 1.5),
                      borderRadius: BorderRadius.circular(theme.cornerRadius),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(theme.cornerRadius - 1.5),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (_, i) {
                          final choice = options[i];
                          final isSelected = _selectedChoice?.id == choice.id;
                          return GestureDetector(
                            onTap: () => _handleSelect(choice),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primaryColor.withValues(alpha: 0.08)
                                    : null,
                                border: i < options.length - 1
                                    ? const Border(
                                        bottom: BorderSide(color: Color(0xFFF3F4F6)))
                                    : null,
                              ),
                              child: Text(
                                choice.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSelected ? theme.primaryColor : theme.textColor,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontFamily: theme.fontFamily,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
                const SizedBox(height: 6),
              ],
              ElevatedButton(
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
            ],
          ),
        ),
      ],
    );
  }
}

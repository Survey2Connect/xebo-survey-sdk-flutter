import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';
import '_shake_mixin.dart';

class XeboTextBoxView extends StatefulWidget {
  final XeboQuestion question;
  final bool isLastQuestion;
  final void Function(XeboAnswer) onAnswer;

  const XeboTextBoxView({
    super.key,
    required this.question,
    required this.isLastQuestion,
    required this.onAnswer,
  });

  @override
  State<XeboTextBoxView> createState() => _XeboTextBoxViewState();
}

class _XeboTextBoxViewState extends State<XeboTextBoxView>
    with SingleTickerProviderStateMixin, XeboShakeMixin {
  late List<XeboChoice> _fields;
  late Map<String, TextEditingController> _controllers;
  String _error = '';
  final _scrollController = ScrollController();

  bool get _isMulti => widget.question.type == XeboQuestionType.multipleTextBox;

  @override
  void initState() {
    super.initState();
    initShake(this);
    _fields = (widget.question.options != null && widget.question.options!.isNotEmpty)
        ? widget.question.options!
        : [XeboChoice(id: 'default', text: '', value: '')];
    _controllers = {
      for (final f in _fields) f.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _scrollController.dispose();
    disposeShake();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.question.isRequired) {
      final hasEmpty = _fields.any((f) => (_controllers[f.id]?.text.trim() ?? '').isEmpty);
      if (hasEmpty) {
        setState(() => _error = 'Please fill in all fields.');
        triggerShake();
        return;
      }
    }
    FocusScope.of(context).unfocus();
    widget.onAnswer(XeboAnswer(
      questionId: widget.question.id,
      value: _fields
          .where((f) => (_controllers[f.id]?.text.trim() ?? '').isNotEmpty)
          .map((f) => XeboAnswerValue(
                rowId: f.id,
                text: _controllers[f.id]!.text,
              ))
          .toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
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
                          fontFamily: theme.fontFamily),
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (int i = 0; i < _fields.length; i++) ...[
                    if (_isMulti && _fields[i].text.isNotEmpty) ...[
                      Text(
                        _fields[i].text,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.textColor,
                            fontFamily: theme.fontFamily),
                      ),
                      const SizedBox(height: 6),
                    ],
                    TextField(
                      controller: _controllers[_fields[i].id],
                      onChanged: (_) => setState(() => _error = ''),
                      onTap: () {
                        Future.delayed(const Duration(milliseconds: 150), () {
                          _scrollController.animateTo(
                            i * 80.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        });
                      },
                      maxLines: _isMulti ? 1 : 4,
                      minLines: 1,
                      textAlignVertical:
                          _isMulti ? TextAlignVertical.center : TextAlignVertical.top,
                      textInputAction: i == _fields.length - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: _isMulti
                            ? null
                            : (widget.question.placeholder ?? 'Type your answer here...'),
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(theme.cornerRadius),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(theme.cornerRadius),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(theme.cornerRadius),
                          borderSide: BorderSide(
                              color: theme.primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: TextStyle(
                          fontSize: 15,
                          color: theme.textColor,
                          fontFamily: theme.fontFamily),
                    ),
                    if (i < _fields.length - 1) const SizedBox(height: 14),
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
                      onPressed: _handleSubmit,
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
          ),
        ],
      ),
    );
  }
}

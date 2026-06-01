import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';

class XeboIntroView extends StatelessWidget {
  final XeboSurveyPage introPage;
  final VoidCallback onStart;

  const XeboIntroView({super.key, required this.introPage, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (introPage.content != null && introPage.content!.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    introPage.content!,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.625,
                      color: theme.textColor,
                      fontFamily: theme.fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildButton(theme),
        ],
      ),
    );
  }

  Widget _buildButton(XeboTheme theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: Text(
          introPage.buttonText ?? "Let's get started",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: theme.fontFamily,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/xebo_models.dart';
import '../theme/xebo_theme.dart';

class XeboThankYouView extends StatefulWidget {
  final XeboQuestion question;
  final VoidCallback onDismiss;
  final void Function(String url)? onRedirectURL;

  const XeboThankYouView({
    super.key,
    required this.question,
    required this.onDismiss,
    this.onRedirectURL,
  });

  @override
  State<XeboThankYouView> createState() => _XeboThankYouViewState();
}

class _XeboThankYouViewState extends State<XeboThankYouView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    if (widget.question.redirectURL != null) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        widget.onRedirectURL?.call(widget.question.redirectURL!);
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTheme();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                widget.question.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  fontFamily: theme.fontFamily,
                ),
              ),
              if (widget.question.subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.question.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textColor.withValues(alpha: 0.7),
                    height: 1.47,
                    fontFamily: theme.fontFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

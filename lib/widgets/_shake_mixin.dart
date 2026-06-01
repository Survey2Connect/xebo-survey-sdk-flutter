import 'package:flutter/material.dart';

mixin XeboShakeMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  void initShake(TickerProvider vsync) {
    _shakeController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 240),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  void disposeShake() {
    _shakeController.dispose();
  }

  void triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  Widget buildShakeWidget({required Widget child}) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (_, __) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: child,
      ),
    );
  }
}

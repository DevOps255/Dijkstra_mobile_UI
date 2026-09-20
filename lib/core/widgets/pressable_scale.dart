import 'package:flutter/material.dart';

/// Enveloppe n'importe quel widget d'une réponse tactile immédiate.
///
/// Principe n°1 du skill Apple Design : le retour visuel doit
/// apparaître au `pointer-down`, jamais attendre le relâchement —
/// sinon l'interaction "se sent morte". `GestureDetector.onTapDown`
/// déclenche le rétrécissement instantanément ; `onTapUp`/`onTapCancel`
/// le relâchent avec le même ressort, jamais une courbe figée.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _setPressed(false);
              widget.onTap!.call();
            },
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

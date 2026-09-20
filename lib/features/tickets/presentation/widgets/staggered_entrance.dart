import 'package:flutter/material.dart';

/// Fait apparaître [child] en fondu + léger déplacement vertical,
/// avec un délai proportionnel à [index] — les éléments d'une liste
/// entrent en cascade plutôt que tous d'un coup. Délai volontairement
/// court (40ms/élément, dans la fourchette 30-80ms recommandée) :
/// au-delà, l'interface se sent lente plutôt qu'élégante.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = curved;
    _offset = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved);

    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

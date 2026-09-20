import 'package:flutter/material.dart';

import 'app_spring.dart';

/// Route de navigation animée par un ressort critically-damped plutôt
///
/// Différence concrète avec `MaterialPageRoute` : une `Curve` a une
/// durée fixe et une trajectoire figée à l'avance. Un `SpringSimulation`
/// a un comportement qui dépend de son état courant  en gros! le ressort
/// repart toujours de sa valeur de présentation actuelle.
class SpringPageRoute<T> extends PageRouteBuilder<T> {
  SpringPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final bool reduceMotion =
                MediaQuery.of(context).disableAnimations;

            if (reduceMotion) {
              return FadeTransition(opacity: animation, child: child);
            }

            final curved = CurvedAnimation(
              parent: animation,
              curve: const SpringCurve(),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

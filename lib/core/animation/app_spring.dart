import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Traduction Flutter des paramètres de ressort Apple (WWDC 2018,
/// *Designing Fluid Interfaces*) : `damping` (contrôle le rebond) et
/// `response` (vitesse d'approche de la cible), plutôt que le triplet
/// physique brut masse/raideur/amortissement.
///
/// - `damping = 1.0`  critically damped, aucun rebond, réglage par
///   défaut de toute l'UI non gestuelle (transitions d'écran, fondus).
/// - `damping < 1.0` → sous-amorti, léger rebond — réservé aux
///   interactions qui portaient déjà une vélocité physique (un swipe
///   relâché), jamais à un élément qui apparaît seul.
abstract final class AppSpring {
  /// Ressort par défaut de tout le projet  transitions d'écran,
  /// apparitions de cartes, boutons. Aucun rebond, doux et direct.
  static SpringDescription critical({double response = 0.38}) {
    return _fromDampingResponse(damping: 1.0, response: response);
  }

  /// Ressort à léger rebond — réservé aux éléments qui prolongent un
  /// geste (ex: un swipe relâché, un drag de bottom sheet).
  static SpringDescription momentum({double response = 0.35}) {
    return _fromDampingResponse(damping: 0.8, response: response);
  }

  static SpringDescription _fromDampingResponse({
    required double damping,
    required double response,
    double mass = 1.0,
  }) {
    final double stiffness = (4 * 3.14159265 * 3.14159265 * mass) /
        (response * response);
    final double dampingCoefficient =
        4 * 3.14159265 * damping * mass / response;

    return SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: dampingCoefficient,
    );
  }

  const AppSpring._();
}

/// Simulation prête à l'emploi pour piloter un `AnimationController`
/// avec `controller.animateWith(...)`.
///
/// Point Apple critique n°3 (interruptibilité) : quand on relance
/// cette simulation, on part TOUJOURS de `controller.value` (valeur
/// de présentation actuelle), jamais d'une valeur logique cible —
/// c'est ce qui rend l'animation reprenable sans saut visuel si
/// l'utilisateur interagit à nouveau pendant la transition.
SpringSimulation buildSpringSimulation({
  required SpringDescription spring,
  required double start,
  required double end,
  double velocity = 0,
}) {
  return SpringSimulation(spring, start, end, velocity);
}

/// Approxime la trajectoire d'un ressort critically-damped sous
/// forme de `Curve` standard Flutter — pour rester compatible avec
/// `CurvedAnimation` / `AnimatedSwitcher` tout en conservant le
/// "settle" caractéristique d'un ressort plutôt qu'un easing
/// cubique générique. Réutilisée par `SpringPageRoute` et par tout
/// `AnimatedSwitcher` interne (ex: le flux d'authentification).
class SpringCurve extends Curve {
  const SpringCurve({this.response = 0.38});

  final double response;

  @override
  double transform(double t) {
    final simulation = buildSpringSimulation(
      spring: AppSpring.critical(response: response),
      start: 0,
      end: 1,
    );

    final double sampledTime = t * (response + 0.04);
    return simulation.x(sampledTime).clamp(0.0, 1.0);
  }
}

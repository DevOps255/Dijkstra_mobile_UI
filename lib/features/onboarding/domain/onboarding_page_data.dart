import 'package:equatable/equatable.dart';

/// ici c'est le contenu textuel d'une slide d'onboarding.
///
///  il reste volontairement simple (pas de génération freezed) : ce
/// modèle est purement statique, et il défini une fois en local,
///
class OnboardingPageData extends Equatable {
  const OnboardingPageData({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  List<Object?> get props => [title, description];
}

/// Contenu des trois écrans d'onboarding Dijkstra.
final class OnboardingContent {
  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Votre bus,\nen temps réel',
      description:
          'Suivez la position exacte de votre bus sur la carte du campus '
          'et sachez précisément quand il arrive à votre arrêt.',
    ),
    OnboardingPageData(
      title: 'Un ticket,\nzéro contact',
      description:
          'Rechargez votre portefeuille depuis votre Mobile Money et '
          'achetez vos tickets en une seule seconde, sans réseau requis.',
    ),
    OnboardingPageData(
      title: 'Montez en\ntoute confiance',
      description:
          'Chaque trajet est sécurisé et vérifié. Votre place est garantie '
          'du premier jour de cours jusqu\'au dernier.',
    ),
  ];

  const OnboardingContent._();
}

/// Identité de l'application — nom de travail en attendant le nom
/// définitif. Un seul endroit à modifier : `appName` ci-dessous.
/// Référencé par `main.dart` (titre système), le wordmark de
/// l'en-tête d'accueil, et `pubspec.yaml` (nom du package — celui-là
/// nécessite un renommage manuel séparé si le nom technique du
/// package doit changer aussi, mais le nom AFFICHÉ ne dépend que
/// de cette constante).
abstract final class AppInfo {
  static const String appName = 'Bus Campus';

  const AppInfo._();
}

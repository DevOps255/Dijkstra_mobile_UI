import 'dart:io';

import 'package:flutter/services.dart';

/// Empêche les captures et enregistrements d'écran sur l'ensemble de
/// l'application — implémenté via `MethodChannel` plutôt qu'un
/// package tiers.
///
/// Historique : la première version utilisait le package
/// `screen_protector`, qui applique le Kotlin Gradle Plugin à
/// l'ancienne manière (pré "Built-in Kotlin support" de Flutter) —
/// incompatible avec les toolchains Gradle/AGP récents, cause de
/// l'échec `cannot find symbol ScreenProtectorPlugin`. Cette version
/// réutilise exactement le canal et les méthodes déjà documentés en
/// L39B (`bus.campus/security`, `enableSecureScreen`,
/// `disableSecureScreen`) — code Kotlin déjà en ta possession, à
/// coller dans `MainActivity.kt` (voir `SECURITY_NATIVE_SETUP.md`).
///
/// - **Android** : `FLAG_SECURE` posé sur la fenêtre racine —
///   capture d'écran et enregistrement retournent un écran noir,
///   comportement identique à WhatsApp ou Microsoft Authenticator.
/// - **iOS** : Apple n'expose aucune API bloquant la capture
///   d'écran (limitation de plateforme, pas de ce projet — déjà
///   documenté en L39B). `disable()`/`enable()` sont des no-op sur
///   iOS tant que la détection de capture n'est pas implémentée
///   nativement — voir la note dans `SECURITY_NATIVE_SETUP.md`.
abstract final class ScreenshotProtection {
  static const MethodChannel _channel = MethodChannel('bus.campus/security');

  static Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } on PlatformException {
      // Canal natif absent (MainActivity.kt pas encore modifié) —
      // dégradation silencieuse plutôt que crash au démarrage.
      // Voir SECURITY_NATIVE_SETUP.md pour l'activer réellement.
    } on MissingPluginException {
      // Même cas — le channel handler natif n'existe pas encore.
    }
  }

  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } on PlatformException {
      // no-op
    } on MissingPluginException {
      // no-op
    }
  }

  const ScreenshotProtection._();
}

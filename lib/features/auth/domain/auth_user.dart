import 'package:equatable/equatable.dart';

/// Représentation locale de l'utilisateur authentifié.
///
/// Écrit à la main plutôt que généré via `freezed`/`json_serializable`
/// — la surface de DTOs est encore petite à ce stade du projet, et la
/// dernière introduction de packages de génération non encore
/// utilisés a cassé le build. Ce modèle migrera vers `freezed` quand
/// le nombre de DTOs justifiera le coût de génération (voir README).
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isVerified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final bool isVerified;

  @override
  List<Object?> get props => [id, email, fullName, isVerified];
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../data/auth_repository.dart';
import '../data/mail_app_launcher.dart';
import '../data/verification_deep_link_service.dart';
import '../domain/auth_exception.dart';

enum AuthStep {
  emailEntry,
  confirmEmail,
  loginPassword, // utilisateur déjà inscrit et vérifié
  fullName, // inscription qui est l'étape 1
  createPassword, // inscription l'eétape 2
  checkYourEmail, // en attente du clic sur le lien
  welcome, // animation  de bienvenue
}

class AuthFlowState {
  const AuthFlowState({
    required this.step,
    required this.email,
    required this.fullName,
    required this.isLoading,
    this.errorMessage,
    this.infoMessage,
  });

  factory AuthFlowState.initial() => const AuthFlowState(
        step: AuthStep.emailEntry,
        email: '',
        fullName: '',
        isLoading: false,
      );

  final AuthStep step;
  final String email;
  final String fullName;
  final bool isLoading;
  final String? errorMessage;

  /// Message de confirmation neutre (ex: "Email renvoyé.") distinct
  /// de [errorMessage] pour ne pas afficher un bandeau d'erreur rouge
  /// sur une action qui a réussi.
  final String? infoMessage;

  AuthFlowState copyWith({
    AuthStep? step,
    String? email,
    String? fullName,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthFlowState(
      step: step ?? this.step,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

/// Fenêtre de rétention du mot de passe en attente de confirmation
/// email (inscription fraîche uniquement  voir la note en fin de
/// fichier)  passé ce délai, le mot de passe en mémoire est purgé.
const Duration _pendingPasswordWindow = Duration(minutes: 10);

class AuthFlowController extends Notifier<AuthFlowState> {
  late final AuthRepository _repository;
  late final VerificationDeepLinkService _deepLinkService;
  late final MailAppLauncher _mailLauncher;

  /// Jamais exposé dans [AuthFlowState] car un mot de passe ne doit
  /// jamais transiter par un état observable/loggable par des devtools
  /// Riverpod. Existence strictement bornée dans le temps et effacée
  /// explicitement dès qu'elle n'est plus nécessaire.
  String? _pendingPassword;
  Timer? _pendingPasswordTimer;

  bool _isExistingUser = false;
  bool _isExistingVerified = false;

  @override
  AuthFlowState build() {
    _repository = getIt<AuthRepository>();
    _deepLinkService = getIt<VerificationDeepLinkService>();
    _mailLauncher = getIt<MailAppLauncher>();

    ref.onDispose(() {
      _clearPendingPassword();
      _deepLinkService.stopListening();
    });

    return AuthFlowState.initial();
  }

  Future<void> submitEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (!_isValidEmail(normalized)) {
      state = state.copyWith(
        errorMessage: 'Entrez une adresse email valide.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);

    try {
      final result = await _repository.checkEmailExists(normalized);
      _isExistingUser = result.exists;
      _isExistingVerified = result.isVerified;
      state = state.copyWith(
        email: normalized,
        step: AuthStep.confirmEmail,
        isLoading: false,
      );
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.publicMessage,
      );
    }
  }

  /// Branche à TROIS voies c'est le correctif de la faille de
  /// contournement de vérification email :
  /// - nouveau compte              -> saisie du nom (inscription)
  /// - compte existant, vérifié    -> mot de passe (connexion normale)
  /// - compte existant, NON vérifié -> reprise de la vérification,
  ///   
  void confirmEmailAndProceed() {
    if (!_isExistingUser) {
      state = state.copyWith(step: AuthStep.fullName, clearError: true);
      return;
    }

    if (_isExistingVerified) {
      state = state.copyWith(step: AuthStep.loginPassword, clearError: true);
      return;
    }

    // Compte existant mais pas vérifié  on ne connaît pas son
    // mot de passe dans cette session, donc pas d'auto-login possible
    // après clic sur le lien. On mène simplement l'utilisateur vers
    // l'écran mot de passe une fois la vérification confirmée.
    _deepLinkService.startListening(onVerified: _handleResumedVerification);
    state = state.copyWith(step: AuthStep.checkYourEmail, clearError: true);
  }

  void editEmail() {
    state = state.copyWith(step: AuthStep.emailEntry, clearError: true);
  }

  void submitFullName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.length < 2) {
      state = state.copyWith(errorMessage: 'Entrez votre nom complet.');
      return;
    }
    state = state.copyWith(
      fullName: trimmed,
      step: AuthStep.createPassword,
      clearError: true,
    );
  }

  int _failedLoginAttempts = 0;
  DateTime? _loginLockedUntil;

  static const int _maxLocalLoginAttempts = 5;
  static const Duration _localLockoutDuration = Duration(minutes: 2);

  Future<void> submitLoginPassword(String password) async {
    final lockedUntil = _loginLockedUntil;
    if (lockedUntil != null) {
      if (DateTime.now().isBefore(lockedUntil)) {
        final remaining = lockedUntil.difference(DateTime.now()).inSeconds;
        state = state.copyWith(
          errorMessage:
              'Trop de tentatives. Réessayez dans ${remaining}s.',
        );
        return;
      }
      // Le délai est passé on réinitialise
      _loginLockedUntil = null;
      _failedLoginAttempts = 0;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.login(email: state.email, password: password);
      _failedLoginAttempts = 0;
      state = state.copyWith(isLoading: false, step: AuthStep.welcome);
    } on AuthException catch (error) {
      _failedLoginAttempts++;

      if (_failedLoginAttempts >= _maxLocalLoginAttempts) {
        _loginLockedUntil = DateTime.now().add(_localLockoutDuration);
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Trop de tentatives. Réessayez dans '
              '${_localLockoutDuration.inMinutes} minute(s).',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: error.publicMessage,
      );
    }
  }

  Future<void> submitSignupPassword(String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.register(
        email: state.email,
        fullName: state.fullName,
        password: password,
      );

      _pendingPassword = password;
      _pendingPasswordTimer?.cancel();
      _pendingPasswordTimer = Timer(_pendingPasswordWindow, () {
        _clearPendingPassword();
      });

      _deepLinkService.startListening(onVerified: _handleFreshSignupVerification);

      state = state.copyWith(isLoading: false, step: AuthStep.checkYourEmail);
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.publicMessage,
      );
    }
  }

  /// Bouton "Je n'ai pas reçu l'email" 
  Future<void> resendVerificationEmail() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      await _repository.resendVerificationEmail(state.email);
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Un nouvel email de confirmation a été envoyé.',
      );
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.publicMessage,
      );
    }
  }

  Future<bool> openMailApp() => _mailLauncher.openMailApp();

  /// Deep link reçu pendant une nouvelle inscription  comme le mot de passe
  /// est encore en mémoire, on peut connecter directement.
  Future<void> _handleFreshSignupVerification() async {
    final password = _pendingPassword;
    if (password == null) {
      state = state.copyWith(
        errorMessage:
            'Le délai de confirmation a expiré. Reprenez l\'inscription.',
        step: AuthStep.emailEntry,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.login(email: state.email, password: password);
      _clearPendingPassword();
      state = state.copyWith(isLoading: false, step: AuthStep.welcome);
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.publicMessage,
      );
    }
  }

  /// Deep link reçu en REPRISE d'un compte existant non vérifié 
  ///  on demande le mot de passe maintenant
  /// que le compte est confirmé vérifié.
  void _handleResumedVerification() {
    _isExistingVerified = true;
    state = state.copyWith(
      step: AuthStep.loginPassword,
      clearError: true,
      infoMessage: 'Email confirmé — entrez votre mot de passe.',
    );
  }

  void _clearPendingPassword() {
    _pendingPassword = null;
    _pendingPasswordTimer?.cancel();
    _pendingPasswordTimer = null;
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }
}

final authFlowControllerProvider =
    NotifierProvider<AuthFlowController, AuthFlowState>(
  AuthFlowController.new,
);


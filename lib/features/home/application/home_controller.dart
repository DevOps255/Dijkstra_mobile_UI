import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/current_user_profile.dart';
import '../../auth/data/auth_repository.dart';
import '../data/notifications_repository.dart';
import '../data/trips_repository.dart';
import '../../wallet/data/wallet_repository.dart';
import '../../wallet/domain/wallet_exception.dart';
import '../domain/campus_route.dart';
import '../domain/scheduled_departure.dart';
import '../../wallet/domain/wallet_balance.dart';

class HomeState {
  const HomeState({
    required this.direction,
    required this.selectedDate,
    required this.boardingStop,
    required this.departures,
    required this.walletBalance,
    required this.unreadNotifications,
    required this.isLoadingDepartures,
    this.currentUser,
    this.recommendationMessage,
  });

  factory HomeState.initial() {
    final today = DateTime.now();
    return HomeState(
      direction: TripDirection.aller,
      selectedDate: DateTime(today.year, today.month, today.day),
      boardingStop: CampusRoute.allerStops.first,
      departures: const [],
      walletBalance: WalletBalance.zero(),
      unreadNotifications: 0,
      isLoadingDepartures: true,
    );
  }

  final TripDirection direction;
  final DateTime selectedDate;
  final CampusStop boardingStop;
  final List<ScheduledDeparture> departures;
  final WalletBalance walletBalance;
  final int unreadNotifications;
  final bool isLoadingDepartures;
  final CurrentUserProfile? currentUser;
  final String? recommendationMessage;

  HomeState copyWith({
    TripDirection? direction,
    DateTime? selectedDate,
    CampusStop? boardingStop,
    List<ScheduledDeparture>? departures,
    WalletBalance? walletBalance,
    int? unreadNotifications,
    bool? isLoadingDepartures,
    CurrentUserProfile? currentUser,
    String? recommendationMessage,
    bool clearRecommendation = false,
  }) {
    return HomeState(
      direction: direction ?? this.direction,
      selectedDate: selectedDate ?? this.selectedDate,
      boardingStop: boardingStop ?? this.boardingStop,
      departures: departures ?? this.departures,
      walletBalance: walletBalance ?? this.walletBalance,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      isLoadingDepartures: isLoadingDepartures ?? this.isLoadingDepartures,
      currentUser: currentUser ?? this.currentUser,
      recommendationMessage: clearRecommendation
          ? null
          : (recommendationMessage ?? this.recommendationMessage),
    );
  }
}

class HomeController extends Notifier<HomeState> {
  late final WalletRepository _walletRepository;
  late final NotificationsRepository _notificationsRepository;
  late final TripsRepository _tripsRepository;
  late final AuthRepository _authRepository;

  /// Compteur de génération — incrémenté à chaque appel de
  /// `_loadDepartures()`. Une réponse réseau dont le compteur ne
  /// correspond plus à la génération courante à son retour est une
  /// réponse PÉRIMÉE (une action plus récente a eu lieu entre-temps)
  /// et doit être silencieusement ignorée — sinon elle écraserait
  /// l'état à jour avec des données obsolètes. C'est la cause exacte
  /// du bug "la direction retombe sur Campus Nord → Sud" : sans ce
  /// garde-fou, une réponse lente d'un ancien changement de direction
  /// pouvait arriver APRÈS une réponse plus récente et la remplacer.
  int _departuresRequestGeneration = 0;

  @override
  HomeState build() {
    _walletRepository = getIt<WalletRepository>();
    _notificationsRepository = getIt<NotificationsRepository>();
    _tripsRepository = getIt<TripsRepository>();
    _authRepository = getIt<AuthRepository>();

    Future.microtask(_loadAll);

    return HomeState.initial();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadWallet(),
      _loadNotifications(),
      _loadDepartures(),
    ]);
  }

  Future<void> _loadCurrentUser() async {
    final profile = await _authRepository.getCurrentUser();
    if (profile != null) {
      state = state.copyWith(currentUser: profile);
    }
  }

  Future<void> _loadWallet() async {
    try {
      final balance = await _walletRepository.fetchBalance();
      state = state.copyWith(walletBalance: balance);
    } on WalletException {
      // Degradation silencieuse deja voulue a l'origine.
    }
  }

  Future<void> _loadNotifications() async {
    final result = await _notificationsRepository.fetch();
    state = state.copyWith(unreadNotifications: result.unreadCount);
  }

  Future<void> refreshWallet() => _loadWallet();
  Future<void> refreshNotifications() => _loadNotifications();

  Future<void> setDirection(TripDirection direction) async {
    if (direction == state.direction) return;
    final stops = CampusRoute.stopsFor(direction);
    state = state.copyWith(
      direction: direction,
      boardingStop: stops.first,
      clearRecommendation: true,
    );
    await _loadDepartures();
  }

  Future<void> setBoardingStop(CampusStop stop) async {
    state = state.copyWith(boardingStop: stop, clearRecommendation: true);
    await _loadDepartures();
  }

  Future<void> setSelectedDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, clearRecommendation: true);
    await _loadDepartures();
  }

  void dismissRecommendation() {
    state = state.copyWith(clearRecommendation: true);
  }

  /// Évalue si le départ choisi mérite une recommandation
  /// informative — jamais bloquante, juste un conseil.
  ///
  /// Règle : pour l'Aller, embarquer à Campus Sud après 6h30 laisse
  /// moins de marge de confort — recommandation d'anticiper.
  void evaluateRecommendation(String selectedTime) {
    final isCampusSudBoarding = state.boardingStop.id == 'campus_sud';
    final isAller = state.direction == TripDirection.aller;

    if (!isAller || !isCampusSudBoarding) {
      state = state.copyWith(clearRecommendation: true);
      return;
    }

    final parts = selectedTime.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = int.tryParse(parts.last) ?? 0;
    final totalMinutes = hour * 60 + minute;
    const thresholdMinutes = 6 * 60 + 30;

    if (totalMinutes > thresholdMinutes) {
      state = state.copyWith(
        recommendationMessage:
            'Les étudiants du Campus Sud partent généralement avant '
            '6h30 pour plus de confort. Ce départ reste disponible '
            'si cet horaire vous convient mieux.',
      );
    } else {
      state = state.copyWith(clearRecommendation: true);
    }
  }

  Future<void> _loadDepartures() async {
    final int requestGeneration = ++_departuresRequestGeneration;

    state = state.copyWith(isLoadingDepartures: true);

    // Figés AVANT l'attente réseau — jamais relus depuis `state`
    // après l'`await`, où ils pourraient déjà avoir changé si
    // l'utilisateur a tapé sur un autre bouton entre-temps.
    final TripDirection requestDirection = state.direction;
    final CampusStop requestBoardingStop = state.boardingStop;
    final DateTime requestDate = state.selectedDate;

    final directionKey =
        requestDirection == TripDirection.aller ? 'aller' : 'retour';

    final liveTrips = await _tripsRepository.fetchLiveTrips(
      date: requestDate,
      direction: directionKey,
    );

    // Une action plus récente a démarré une nouvelle requête pendant
    // qu'on attendait celle-ci — on abandonne silencieusement ce
    // résultat périmé plutôt que d'écraser l'état à jour.
    if (requestGeneration != _departuresRequestGeneration) return;

    final times = CampusSchedule.departuresFor(requestDirection);
    final destination = CampusRoute.destinationFor(requestDirection);

    final departures = times.map((time) {
      final isPalaisOnly = requestBoardingStop.id == 'palais_congres';
      // L'arrêt Palais des Congrès n'est desservi qu'au tout premier
      // départ de la journée (règle explicite).
      if (isPalaisOnly && time != times.first) {
        return null;
      }

      var departure = ScheduledDeparture(
        time: time,
        direction: requestDirection,
        boardingStop: requestBoardingStop,
        destinationLabel: destination,
        fareFcfa: 150, // L34B — tarif fixe du ticket Bus Campus
        isPalaisCongresOnly: isPalaisOnly,
      );

      final live = liveTrips[time];
      if (live != null) {
        departure = departure.copyWithLiveData(
          tripId: live.tripId,
          availableSeats: live.availableSeats,
        );
      }

      return departure;
    }).whereType<ScheduledDeparture>().toList();

    if (requestGeneration != _departuresRequestGeneration) return;

    state = state.copyWith(
      departures: departures,
      isLoadingDepartures: false,
    );
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

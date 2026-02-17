import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../quiz/data/models/question_model.dart';
import '../models/pvp_match_model.dart';
import '../models/pvp_round_model.dart';
import '../repositories/pvp_repository.dart';

class PvPProvider extends ChangeNotifier {
  final PvPRepository _pvpRepository;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  // === État du jeu ===
  PvPMatchModel? currentMatch;
  PvPRoundModel? currentRound;
  List<QuestionModel> currentQuestions = [];
  int currentQuestionIndex = 0;
  List<PvPAnswerModel> myAnswers = [];
  bool isMyTurn = false;
  int timeSpent = 0;
  String? errorMessage;
  bool isLoading = false;
  int consecutiveWrong = 0;
  bool roundSubmitted = false;

  // === État de la recherche ===
  bool isSearchingMatch = false;
  bool isInQueue = false;
  int searchDuration = 0;

  // === État des notifications ===
  // Type 1a: Match trouvé, c'est à moi de jouer → countdown + auto-nav
  bool matchFound = false;
  // Type 1b: Match trouvé, c'est à l'adversaire de jouer → countdown + auto-nav
  bool matchFoundWaiting = false;
  int matchFoundCountdown = 5;
  String? foundMatchId;
  String? opponentUsername;
  // Type 2: C'est ton tour → bouton pour aller au match
  bool yourTurnNotification = false;
  int? notificationRoundNumber;
  // Type 3: Match terminé → résultat
  bool matchCompletedNotification = false;
  bool? matchCompletedDidWin;

  // === État interne ===
  bool isOnGamePage = false;
  bool _previousIsMyTurn = false;
  bool _processingMatchFound = false; // Guard contre les appels concurrents
  bool _backgroundCheckRunning = false; // Guard pour le polling
  bool _isSubmittingRound = false; // Guard contre les doubles soumissions
  Timer? _matchFoundTimer;
  Timer? _notificationAutoDismissTimer;
  StreamSubscription<PvPMatchModel?>? _matchSubscription;
  Timer? _searchTimer;
  Timer? _searchDurationTimer;
  Timer? _backgroundCheckTimer; // Polling global en arrière-plan
  final Set<String> _knownMatchIds = {}; // Matchs qu'on a déjà vus (pour notif completed)

  PvPProvider({
    PvPRepository? pvpRepository,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  })  : _pvpRepository = pvpRepository ?? PvPRepository(),
        _authRepository = authRepository ?? AuthRepository(),
        _profileRepository = profileRepository ?? ProfileRepository();

  String? get currentUserId => _authRepository.getCurrentUserId();
  bool get isPlayer1 => currentMatch?.player1Id == currentUserId;

  int get myTotalScore {
    if (currentMatch == null || currentUserId == null) return 0;
    return currentMatch!.getPlayerScore(currentUserId!);
  }

  int get opponentTotalScore {
    if (currentMatch == null || currentUserId == null) return 0;
    final opponentId = currentMatch!.getOpponentId(currentUserId!);
    if (opponentId == null) return 0;
    return currentMatch!.getPlayerScore(opponentId);
  }

  int get myRoundScore {
    int total = 0;
    for (final answer in myAnswers) {
      total += answer.points;
    }
    return total < 0 ? 0 : total;
  }

  bool get hasAnsweredAllQuestions =>
      roundSubmitted ||
      (currentQuestions.isNotEmpty && myAnswers.length >= currentQuestions.length);

  QuestionModel? get currentQuestion {
    if (currentQuestionIndex >= currentQuestions.length) return null;
    return currentQuestions[currentQuestionIndex];
  }

  bool get isMyThemeChoice {
    if (currentMatch == null || currentUserId == null) return false;
    return currentMatch!.isPlayerChoosingTheme(currentUserId!);
  }

  /// Indique si une notification quelconque est active
  bool get hasActiveNotification =>
      matchFound || matchFoundWaiting || yourTurnNotification || matchCompletedNotification;

  // =========================================================================
  // POLLING GLOBAL EN ARRIÈRE-PLAN
  // =========================================================================

  /// Démarre le polling global. Appelé une fois au login/init.
  /// Vérifie toutes les 5 secondes : queue + matchs actifs.
  void startBackgroundChecks() {
    _backgroundCheckTimer?.cancel();
    _backgroundCheckRunning = false; // Reset le guard au redémarrage
    _processingMatchFound = false; // Reset au cas où bloqué
    _backgroundCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _backgroundCheck();
    });
    // Ré-établir le watcher si on a un match actif (retour au foreground sur mobile)
    if (currentMatch != null) {
      _knownMatchIds.add(currentMatch!.id);
      if (currentMatch!.isInProgress) {
        _watchMatch(currentMatch!.id);
      }
    }
    // Charger les IDs des matchs connus au démarrage (pour détecter les complétions)
    _initKnownMatches();
    // Vérification immédiate au démarrage
    _backgroundCheck();
  }

  Future<void> _initKnownMatches() async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      final matches = await _pvpRepository.getActiveMatches(userId);
      for (final m in matches) {
        _knownMatchIds.add(m.id);
      }
    } catch (_) {}
  }

  void stopBackgroundChecks() {
    _backgroundCheckTimer?.cancel();
    _backgroundCheckRunning = false;
  }

  /// Appelé quand l'app passe en arrière-plan (paused).
  /// Si un quiz est en cours et le joueur n'a pas fini, auto-soumet ses réponses.
  void autoSubmitIfInProgress() {
    if (currentRound != null && !roundSubmitted && isMyTurn && myAnswers.isNotEmpty) {
      debugPrint('[PvP] autoSubmitIfInProgress - submitting ${myAnswers.length} answers before app pause');
      finishRound();
    }
  }

  Future<void> _backgroundCheck() async {
    final userId = currentUserId;
    if (userId == null) return;
    // Ne pas vérifier si on est en plein jeu ou en recherche active
    // ou si le countdown matchFound est en cours (auto-teleport)
    if (isOnGamePage || isSearchingMatch || matchFound) return;
    // Guard contre les appels concurrents (Timer.periodic n'attend pas la fin de l'async)
    if (_backgroundCheckRunning || _processingMatchFound) return;
    _backgroundCheckRunning = true;

    try {
      // 1. Vérifier les matchs actifs (inclut tous les matchs non-completed)
      final activeMatches = await _pvpRepository.getActiveMatches(userId);

      // 2. Vérifier aussi les matchs complétés récemment pour la notification de fin
      final allMatches = await _pvpRepository.getMyMatches(userId, limit: 5);
      for (final match in allMatches) {
        if (match.isCompleted && match.id != currentMatch?.id && !matchCompletedNotification) {
          // Match complété qu'on ne suit pas encore → notification
          // Seulement si on avait ce match en cours ou si c'est récent
          if (_knownMatchIds.contains(match.id)) {
            debugPrint('[PvP] _backgroundCheck - match ${match.id} completed!');
            currentMatch = match;
            matchCompletedNotification = true;
            matchCompletedDidWin = match.winnerId == null ? null : match.winnerId == userId;
            await _ensureOpponentUsername(match, userId);
            notifyListeners();
            _startAutoDismissTimer();
            return;
          }
        }
      }

      // 3. Pas de match actif → vérifier la queue
      if (activeMatches.isEmpty && currentMatch == null) {
        final queueResult = await _pvpRepository.checkQueueStatus(userId);
        if (queueResult['matchFound'] == true && queueResult['matchId'] != null) {
          debugPrint('[PvP] _backgroundCheck - match found from queue (no active matches)');
          foundMatchId = queueResult['matchId'] as String;
          // On ne vient PAS d'une recherche active → c'est un match existant, pas "Match Trouvé"
          // Charger le match et montrer la bonne notification
          await loadMatch(foundMatchId!, preservePreviousTurn: true);
          foundMatchId = null;
          if (currentMatch != null) {
            _knownMatchIds.add(currentMatch!.id);
            await _ensureOpponentUsername(currentMatch!, userId);
            if (isMyTurn || isMyThemeChoice) {
              yourTurnNotification = true;
              notificationRoundNumber = currentMatch!.currentRound;
              notifyListeners();
              _startAutoDismissTimer();
            }
          }
          return;
        }
        return;
      }

      // 4. Parcourir les matchs actifs
      for (final match in activeMatches) {
        _knownMatchIds.add(match.id);
        final myTurn = match.isPlayerTurn(userId) || match.isPlayerChoosingTheme(userId);

        if (myTurn) {
          debugPrint('[PvP] _backgroundCheck - it is my turn in match ${match.id}, status=${match.status}');
          // Charger le match et démarrer le watcher si pas déjà fait
          if (currentMatch?.id != match.id) {
            currentMatch = match;
            _updateIsMyTurn();
            _previousIsMyTurn = true;
            _watchMatch(match.id);
          } else {
            currentMatch = match;
            _updateIsMyTurn();
          }
          await _ensureOpponentUsername(match, userId);
          // Déclencher la notification seulement si pas déjà affichée
          if (!yourTurnNotification) {
            matchFoundWaiting = false;
            yourTurnNotification = true;
            notificationRoundNumber = match.currentRound;
            notifyListeners();
            _startAutoDismissTimer();
          }
          return;
        }
      }

      // 5. Pas notre tour mais on a un match actif → garder le watcher actif
      if (activeMatches.isNotEmpty) {
        final match = activeMatches.first;
        if (currentMatch?.id != match.id) {
          currentMatch = match;
          _updateIsMyTurn();
          _previousIsMyTurn = isMyTurn || isMyThemeChoice;
          _watchMatch(match.id);
          notifyListeners();
        } else {
          currentMatch = match;
          _updateIsMyTurn();
          _previousIsMyTurn = isMyTurn || isMyThemeChoice;
        }
      }
    } catch (e) {
      debugPrint('[PvP] _backgroundCheck error: $e');
    } finally {
      _backgroundCheckRunning = false;
    }
  }

  Future<void> _ensureOpponentUsername(PvPMatchModel match, String userId) async {
    if (opponentUsername != null) return;
    final opponentId = match.getOpponentId(userId);
    if (opponentId != null) {
      opponentUsername = await _pvpRepository.getUsername(opponentId);
    }
  }

  // =========================================================================
  // PAGE DE JEU - flag pour supprimer les notifications quand on est dessus
  // =========================================================================

  void setOnGamePage(bool value) {
    isOnGamePage = value;
    if (value) {
      // On entre sur la page de jeu → dismiss toutes les notifications
      final hadNotification = yourTurnNotification || matchFoundWaiting || matchCompletedNotification;
      yourTurnNotification = false;
      matchFoundWaiting = false;
      matchCompletedNotification = false;
      matchCompletedDidWin = null;
      notificationRoundNumber = null;
      _matchFoundTimer?.cancel();
      if (hadNotification) notifyListeners();
    }
  }

  // =========================================================================
  // MATCHMAKING
  // =========================================================================

  Future<void> joinMatchmaking() async {
    final userId = currentUserId;
    if (userId == null) {
      errorMessage = 'User not logged in';
      notifyListeners();
      return;
    }

    try {
      isSearchingMatch = true;
      isInQueue = false;
      searchDuration = 0;
      errorMessage = null;
      notifyListeners();

      final stats = await _pvpRepository.getPlayerPvPStats(userId);
      final rating = stats['rating'] as int;
      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      debugPrint('[PvP] joinMatchmaking - calling RPC');
      final result = await _pvpRepository.joinMatchmaking(userId, rating, language);
      debugPrint('[PvP] joinMatchmaking - result: $result');

      if (result['matchFound'] == true && result['matchId'] != null) {
        foundMatchId = result['matchId'];
        debugPrint('[PvP] joinMatchmaking - match found! matchId=$foundMatchId');
        await _onMatchFound();
      } else {
        debugPrint('[PvP] joinMatchmaking - no match, entering queue');
        isInQueue = true;
        _startSearchTimer();
        _startSearchDurationTimer();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[PvP] ERROR joinMatchmaking: $e');
      errorMessage = 'Error joining matchmaking: $e';
      isSearchingMatch = false;
      isInQueue = false;
      notifyListeners();
    }
  }

  void _startSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkForMatch();
    });
  }

  void _startSearchDurationTimer() {
    _searchDurationTimer?.cancel();
    _searchDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      searchDuration++;
      notifyListeners();
    });
  }

  void _stopSearchTimers() {
    _searchTimer?.cancel();
    _searchDurationTimer?.cancel();
  }

  Future<void> _checkForMatch() async {
    final userId = currentUserId;
    if (userId == null) return;
    // Guard contre les appels concurrents (Timer.periodic n'attend pas l'async)
    if (_processingMatchFound) return;

    try {
      final status = await _pvpRepository.checkQueueStatus(userId);

      if (status['matchFound'] == true && status['matchId'] != null) {
        _stopSearchTimers();
        foundMatchId = status['matchId'] as String;
        debugPrint('[PvP] _checkForMatch - match found! matchId=$foundMatchId');
        await _onMatchFound();
        return;
      }

      if (status['inQueue'] == true) {
        final stats = await _pvpRepository.getPlayerPvPStats(userId);
        final rating = stats['rating'] as int;
        final userStats = await _authRepository.getUserStats();
        final language = userStats?.preferredLanguage ?? 'en';
        final result = await _pvpRepository.joinMatchmaking(userId, rating, language);

        if (result['matchFound'] == true && result['matchId'] != null) {
          _stopSearchTimers();
          foundMatchId = result['matchId'];
          debugPrint('[PvP] _checkForMatch - match found via join! matchId=$foundMatchId');
          await _onMatchFound();
        }
      } else {
        debugPrint('[PvP] _checkForMatch - not in queue anymore, stopping');
        _stopSearchTimers();
        isSearchingMatch = false;
        isInQueue = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking for match: $e');
    }
  }

  // =========================================================================
  // MATCH FOUND
  // =========================================================================

  /// Match trouvé depuis une RECHERCHE ACTIVE (joinMatchmaking / _checkForMatch).
  /// Affiche la notification "Match Trouvé" avec countdown + auto-nav.
  Future<void> _onMatchFound() async {
    // Guard contre les appels concurrents (Timer.periodic + réseau lent sur mobile)
    if (_processingMatchFound) return;
    _processingMatchFound = true;

    _stopSearchTimers();
    isInQueue = false;
    isSearchingMatch = false;
    // Notifier immédiatement pour que l'UI masque le popup de recherche
    notifyListeners();

    try {
      if (foundMatchId != null) {
        await loadMatch(foundMatchId!, preservePreviousTurn: true);
        if (currentMatch != null && currentUserId != null) {
          _knownMatchIds.add(currentMatch!.id);
          await _ensureOpponentUsername(currentMatch!, currentUserId!);
        }
        foundMatchId = null;
      }

      if (currentMatch == null) {
        debugPrint('[PvP] _onMatchFound - match not loaded, aborting');
        return;
      }

      if (isMyTurn || isMyThemeChoice) {
        // C'est à moi de jouer → countdown 5s puis auto-nav
        _previousIsMyTurn = true;
        matchFound = true;
        matchFoundCountdown = 5;
        debugPrint('[PvP] _onMatchFound - showing matchFound countdown (my turn)');
        notifyListeners();
        _startMatchFoundCountdown();
      } else {
        // L'adversaire joue → notification "Match Trouvé - En attente"
        _previousIsMyTurn = false;
        matchFoundWaiting = true;
        debugPrint('[PvP] _onMatchFound - showing matchFoundWaiting (opponent turn)');
        notifyListeners();
        _startAutoDismissTimer();
      }
    } catch (e) {
      debugPrint('[PvP] Error in _onMatchFound: $e');
    } finally {
      _processingMatchFound = false;
    }
  }

  void _startMatchFoundCountdown() {
    _matchFoundTimer?.cancel();
    _matchFoundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      matchFoundCountdown--;
      notifyListeners();
      if (matchFoundCountdown <= 0) {
        timer.cancel();
        // Ne pas clear les flags ici - l'overlay gère la navigation
        // et appelle dismissNotification() au moment de naviguer
      }
    });
  }

  void dismissNotification() {
    matchFound = false;
    matchFoundWaiting = false;
    yourTurnNotification = false;
    matchCompletedNotification = false;
    matchCompletedDidWin = null;
    notificationRoundNumber = null;
    _matchFoundTimer?.cancel();
    _notificationAutoDismissTimer?.cancel();
    notifyListeners();
  }

  /// Démarre un timer de 15s pour auto-dismiss les notifications
  /// (toutes sauf matchFound qui a son propre countdown + auto-teleport)
  void _startAutoDismissTimer() {
    _notificationAutoDismissTimer?.cancel();
    _notificationAutoDismissTimer = Timer(const Duration(seconds: 15), () {
      if (matchFoundWaiting || yourTurnNotification || matchCompletedNotification) {
        matchFoundWaiting = false;
        yourTurnNotification = false;
        matchCompletedNotification = false;
        matchCompletedDidWin = null;
        notificationRoundNumber = null;
        notifyListeners();
      }
    });
  }

  void dismissMatchFound() => dismissNotification();

  Future<void> leaveMatchmaking() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      _stopSearchTimers();
      await _pvpRepository.leaveMatchmaking(userId);
      isSearchingMatch = false;
      isInQueue = false;
      searchDuration = 0;
      matchFound = false;
      foundMatchId = null;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error leaving matchmaking: $e';
      notifyListeners();
    }
  }

  // =========================================================================
  // MATCH LOADING & WATCHING
  // =========================================================================

  int get _avgRating {
    if (currentMatch == null) return 1000;
    final r1 = currentMatch!.player1RatingBefore;
    final r2 = currentMatch!.player2RatingBefore ?? r1;
    return ((r1 + r2) / 2).round();
  }

  Future<void> loadMatch(String matchId, {bool preservePreviousTurn = false}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      debugPrint('[PvP] loadMatch($matchId)');
      currentMatch = await _pvpRepository.getMatch(matchId);
      if (currentMatch == null) {
        debugPrint('[PvP] loadMatch - match not found');
        errorMessage = 'Match not found';
        isLoading = false;
        notifyListeners();
        return;
      }

      _knownMatchIds.add(currentMatch!.id);
      debugPrint('[PvP] loadMatch - status=${currentMatch!.status}, round=${currentMatch!.currentRound}');

      _updateIsMyTurn();
      // Ne pas écraser _previousIsMyTurn si appelé depuis _onMatchFound
      // (qui le définit correctement pour que le watcher détecte les transitions)
      if (!preservePreviousTurn) {
        _previousIsMyTurn = isMyTurn || isMyThemeChoice;
      }

      if (!currentMatch!.isChoosingTheme) {
        await loadRound(currentMatch!.currentRound);
      }

      _watchMatch(matchId);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[PvP] ERROR loadMatch: $e');
      errorMessage = 'Error loading match: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  void _updateIsMyTurn() {
    if (currentMatch == null || currentUserId == null) {
      isMyTurn = false;
      return;
    }
    isMyTurn = currentMatch!.isPlayerTurn(currentUserId!) ||
               currentMatch!.isPlayerChoosingTheme(currentUserId!);
  }

  void _watchMatch(String matchId) {
    _matchSubscription?.cancel();
    _matchSubscription = _pvpRepository.watchMatch(matchId).listen(
      (match) async {
        if (match == null) return;

        final previousStatus = currentMatch?.status;
        final previousMatchRound = currentMatch?.currentRound;
        final wasMyTurn = _previousIsMyTurn;
        currentMatch = match;
        _updateIsMyTurn();

        debugPrint('[PvP] _watchMatch - status=${match.status}, round=${match.currentRound}, wasMyTurn=$wasMyTurn, isMyTurn=$isMyTurn');

        // Match terminé
        if (previousStatus != PvPMatchStatus.completed &&
            match.status == PvPMatchStatus.completed) {
          debugPrint('[PvP] _watchMatch - match completed!');
          matchCompletedNotification = true;
          matchCompletedDidWin = match.winnerId == null
              ? null
              : match.winnerId == currentUserId;
          if (currentUserId != null) {
            await _ensureOpponentUsername(match, currentUserId!);
          }
          notifyListeners();
          _startAutoDismissTimer();
          return;
        }

        // C'est devenu mon tour (et ça ne l'était pas avant)
        // Notification SEULEMENT si PAS sur la page de jeu
        if (!wasMyTurn && (isMyTurn || isMyThemeChoice) && !matchFound && !isOnGamePage) {
          debugPrint('[PvP] _watchMatch - it became my turn! round=${match.currentRound}');
          // Dismiss matchFoundWaiting si actif (le match a avancé, on passe à "C'est ton tour")
          matchFoundWaiting = false;
          yourTurnNotification = true;
          notificationRoundNumber = match.currentRound;
          if (currentUserId != null) {
            await _ensureOpponentUsername(match, currentUserId!);
          }
          _startAutoDismissTimer();
        }
        _previousIsMyTurn = isMyTurn || isMyThemeChoice;

        // Si statut changé de choosingTheme → playerTurn, charger le round
        final wasChoosingTheme = previousStatus == PvPMatchStatus.player1ChoosingTheme ||
            previousStatus == PvPMatchStatus.player2ChoosingTheme;
        final isNowPlaying = match.status == PvPMatchStatus.player1Turn ||
            match.status == PvPMatchStatus.player2Turn;

        if (wasChoosingTheme && isNowPlaying) {
          await loadRound(match.currentRound);
        }

        final roundChanged = previousMatchRound != null &&
            previousMatchRound != match.currentRound;

        if (roundChanged && hasAnsweredAllQuestions) {
          currentRound = await _pvpRepository.getRound(matchId, previousMatchRound);
        } else if (!match.isChoosingTheme && currentRound == null && isMyTurn) {
          await loadRound(match.currentRound);
        } else if (currentRound != null &&
            currentRound!.roundNumber == match.currentRound) {
          currentRound = await _pvpRepository.getRound(matchId, match.currentRound);
        }

        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error watching match: $e');
      },
    );
  }

  // =========================================================================
  // THEME SELECTION
  // =========================================================================

  Future<void> selectTheme(String themeId) async {
    if (currentMatch == null || currentUserId == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      final questions = await _pvpRepository.getQuestionsByTheme(themeId, language, 100, avgRating: _avgRating);
      currentQuestions = questions;

      final questionIds = questions.map((q) => q.id).toList();

      // Vérifier si le round existe déjà (peut arriver si submitRound a été appelé 2 fois)
      final existingRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentMatch!.currentRound,
      );
      if (existingRound == null) {
        await _pvpRepository.createRound(
          currentMatch!.id,
          currentMatch!.currentRound,
          questionIds,
          themeId: themeId,
        );
      }

      final newStatus = currentMatch!.currentRound == 1
          ? 'player1_turn'
          : 'player2_turn';
      await _pvpRepository.updateMatchStatus(currentMatch!.id, newStatus);

      currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
      currentRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentMatch!.currentRound,
      );

      myAnswers = [];
      currentQuestionIndex = 0;
      timeSpent = 0;
      roundSubmitted = false;
      consecutiveWrong = 0;

      _updateIsMyTurn();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[PvP] ERROR selectTheme: $e');
      errorMessage = 'Error selecting theme: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // ROUND MANAGEMENT
  // =========================================================================

  Future<void> loadRound(int roundNumber) async {
    if (currentMatch == null) return;

    if (currentMatch!.isChoosingTheme) {
      debugPrint('[PvP] loadRound($roundNumber) - skipped, choosing theme phase');
      return;
    }

    try {
      debugPrint('[PvP] loadRound($roundNumber) - isMyTurn=$isMyTurn');
      currentRound = await _pvpRepository.getRound(currentMatch!.id, roundNumber);

      myAnswers = [];
      currentQuestionIndex = 0;
      timeSpent = 0;
      roundSubmitted = false;
      consecutiveWrong = 0;

      if (currentRound == null) {
        if (isMyTurn && roundNumber == 3) {
          await _startRoundWithRandomTheme();
        } else if (isMyTurn) {
          await startRound();
        } else {
          debugPrint('[PvP] loadRound - round null and not my turn, waiting');
        }
      } else {
        await _loadQuestionsFromRound();
      }

      debugPrint('[PvP] loadRound done - ${currentQuestions.length} questions loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('[PvP] ERROR loadRound: $e');
      errorMessage = 'Error loading round: $e';
      notifyListeners();
    }
  }

  Future<void> _startRoundWithRandomTheme() async {
    if (currentMatch == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      final round1 = await _pvpRepository.getRound(currentMatch!.id, 1);
      final round2 = await _pvpRepository.getRound(currentMatch!.id, 2);
      final excludeThemes = [
        if (round1?.themeId != null) round1!.themeId!,
        if (round2?.themeId != null) round2!.themeId!,
      ];

      final randomThemeId = await _pvpRepository.getRandomTheme(language, excludeThemes);

      List<QuestionModel> questions;
      if (randomThemeId != null) {
        questions = await _pvpRepository.getQuestionsByTheme(randomThemeId, language, 100, avgRating: _avgRating);
      } else {
        questions = await _pvpRepository.getQuestionsForRound(language, 100);
      }

      currentQuestions = questions;
      final questionIds = questions.map((q) => q.id).toList();

      await _pvpRepository.createRound(
        currentMatch!.id,
        3,
        questionIds,
        themeId: randomThemeId,
      );

      currentRound = await _pvpRepository.getRound(currentMatch!.id, 3);

      myAnswers = [];
      currentQuestionIndex = 0;
      timeSpent = 0;
      roundSubmitted = false;
      consecutiveWrong = 0;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[PvP] ERROR _startRoundWithRandomTheme: $e');
      errorMessage = 'Error starting round 3: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadQuestionsFromRound() async {
    if (currentRound == null || currentRound!.questionIds.isEmpty) return;

    final userStats = await _authRepository.getUserStats();
    final language = userStats?.preferredLanguage ?? 'en';
    final questionIds = currentRound!.questionIds;

    final fetchedQuestions = await _pvpRepository.getQuestionsByIds(
      questionIds,
      language,
    );

    // Réordonner pour correspondre à l'ordre exact de questionIds
    final questionsMap = {for (final q in fetchedQuestions) q.id: q};
    currentQuestions = questionIds
        .where((id) => questionsMap.containsKey(id))
        .map((id) => questionsMap[id]!)
        .toList();
  }

  Future<void> startRound() async {
    if (currentMatch == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      final existingRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentMatch!.currentRound,
      );

      List<QuestionModel> questions;
      String? themeId = existingRound?.themeId;

      if (themeId != null) {
        questions = await _pvpRepository.getQuestionsByTheme(themeId, language, 100, avgRating: _avgRating);
      } else {
        questions = await _pvpRepository.getQuestionsForRound(language, 100);
      }

      currentQuestions = questions;
      final questionIds = currentQuestions.map((q) => q.id).toList();

      await _pvpRepository.createRound(
        currentMatch!.id,
        currentMatch!.currentRound,
        questionIds,
        themeId: themeId,
      );

      currentRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentMatch!.currentRound,
      );

      myAnswers = [];
      currentQuestionIndex = 0;
      timeSpent = 0;
      roundSubmitted = false;
      consecutiveWrong = 0;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[PvP] ERROR startRound: $e');
      errorMessage = 'Error starting round: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // ANSWERING & SUBMITTING
  // =========================================================================

  void selectAnswer(
    String questionId,
    String answerId,
    bool isCorrect,
    String difficulty,
  ) {
    int points = 0;
    if (isCorrect) {
      switch (difficulty.toLowerCase()) {
        case 'easy':
          points = 1;
          break;
        case 'medium':
          points = 2;
          break;
        case 'hard':
          points = 3;
          break;
        default:
          points = 1;
      }
      consecutiveWrong = 0;
    } else {
      consecutiveWrong++;
      points = myRoundScore > 0 ? -1 : 0;
    }

    final answer = PvPAnswerModel(
      questionId: questionId,
      answerId: answerId,
      isCorrect: isCorrect,
      difficulty: difficulty,
      points: points,
      timeSpent: timeSpent,
    );

    myAnswers.add(answer);
    currentQuestionIndex++;
    notifyListeners();

    if (hasAnsweredAllQuestions) {
      submitRound();
    }
  }

  void skipQuestion() {
    if (currentQuestion == null) return;

    final answer = PvPAnswerModel(
      questionId: currentQuestion!.id,
      answerId: '',
      isCorrect: false,
      difficulty: currentQuestion!.difficulty,
      points: 0,
      timeSpent: timeSpent,
    );

    myAnswers.add(answer);
    currentQuestionIndex++;
    notifyListeners();

    if (hasAnsweredAllQuestions) {
      submitRound();
    }
  }

  void finishRound() {
    if (roundSubmitted) return;
    roundSubmitted = true;
    notifyListeners();
    // Si un submit est déjà en cours (ex: dernière réponse a déclenché submitRound),
    // on ne relance pas - le round sera soumis avec les réponses actuelles
    if (!_isSubmittingRound) {
      submitRound();
    }
  }

  void updateTimeSpent(int seconds) {
    timeSpent = seconds;
  }

  Future<void> submitRound() async {
    if (currentMatch == null || currentRound == null || currentUserId == null) {
      return;
    }
    // Guard contre les appels concurrents (selectAnswer + finishRound/timer)
    if (_isSubmittingRound) return;
    _isSubmittingRound = true;

    try {
      isLoading = true;
      notifyListeners();

      final score = myRoundScore;

      await _pvpRepository.submitRoundAnswers(
        currentMatch!.id,
        currentRound!.roundNumber,
        currentUserId!,
        myAnswers,
        score,
      );

      try {
        await _profileRepository.updateStreak(currentUserId!);
      } catch (e) {
        debugPrint('[PvP] Error updating streak: $e');
      }

      currentRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentRound!.roundNumber,
      );

      currentMatch = await _pvpRepository.getMatch(currentMatch!.id);

      if (currentRound!.isRoundCompleted) {
        final roundNumber = currentRound!.roundNumber;
        if (roundNumber >= 3) {
          await completeMatch();
        } else if (roundNumber == 1) {
          debugPrint('[PvP] submitRound - round 1 complete → player2_choosing_theme');
          await _pvpRepository.updateMatchStatusAndRound(
            currentMatch!.id,
            'player2_choosing_theme',
            2,
          );
          currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
        } else if (roundNumber == 2) {
          debugPrint('[PvP] submitRound - round 2 complete → player1_turn round 3');
          await _pvpRepository.updateMatchStatusAndRound(
            currentMatch!.id,
            'player1_turn',
            3,
          );
          currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
        }
      } else {
        final newStatus = isPlayer1 ? 'player2_turn' : 'player1_turn';
        debugPrint('[PvP] submitRound - switching turn to $newStatus');
        await _pvpRepository.updateMatchStatus(currentMatch!.id, newStatus);
        currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
      }

      _updateIsMyTurn();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error submitting round: $e';
      isLoading = false;
      notifyListeners();
    } finally {
      _isSubmittingRound = false;
    }
  }

  Future<void> completeMatch() async {
    if (currentMatch == null) return;

    try {
      await _pvpRepository.completeMatch(currentMatch!.id);
      currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error completing match: $e';
      notifyListeners();
    }
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  bool? get didWin {
    if (currentMatch == null ||
        currentMatch!.status != PvPMatchStatus.completed ||
        currentUserId == null) {
      return null;
    }
    if (currentMatch!.winnerId == null) return null;
    return currentMatch!.winnerId == currentUserId;
  }

  int? get myRatingChange {
    if (currentMatch == null || currentUserId == null) return null;
    return currentMatch!.getPlayerRatingChange(currentUserId!);
  }

  Future<List<String>> getUsedThemeIds() async {
    if (currentMatch == null) return [];
    try {
      final rounds = await _pvpRepository.getRounds(currentMatch!.id);
      return rounds
          .where((r) => r.themeId != null)
          .map((r) => r.themeId!)
          .toList();
    } catch (e) {
      debugPrint('[PvP] Error getting used theme ids: $e');
      return [];
    }
  }

  Future<List<PvPMatchModel>> getMatchHistory({int limit = 20}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      return await _pvpRepository.getMyMatches(userId, limit: limit);
    } catch (e) {
      debugPrint('Error getting match history: $e');
      return [];
    }
  }

  Future<List<PvPMatchModel>> getActiveMatches() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      return await _pvpRepository.getActiveMatches(userId);
    } catch (e) {
      debugPrint('Error getting active matches: $e');
      return [];
    }
  }

  // =========================================================================
  // RESET & DISPOSE
  // =========================================================================

  void reset() {
    _matchSubscription?.cancel();
    _stopSearchTimers();
    _matchFoundTimer?.cancel();
    _notificationAutoDismissTimer?.cancel();

    currentMatch = null;
    currentRound = null;
    currentQuestions = [];
    currentQuestionIndex = 0;
    myAnswers = [];
    roundSubmitted = false;
    consecutiveWrong = 0;
    isSearchingMatch = false;
    isInQueue = false;
    isMyTurn = false;
    timeSpent = 0;
    searchDuration = 0;
    errorMessage = null;
    isLoading = false;
    matchFound = false;
    matchFoundWaiting = false;
    foundMatchId = null;
    opponentUsername = null;
    yourTurnNotification = false;
    matchCompletedNotification = false;
    matchCompletedDidWin = null;
    notificationRoundNumber = null;
    _previousIsMyTurn = false;
    _processingMatchFound = false;
    _isSubmittingRound = false;
    isOnGamePage = false;
    _knownMatchIds.clear();

    // NE PAS arrêter le background timer : il doit continuer à tourner
    notifyListeners();
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _stopSearchTimers();
    _backgroundCheckTimer?.cancel();
    _matchFoundTimer?.cancel();
    _notificationAutoDismissTimer?.cancel();
    super.dispose();
  }
}

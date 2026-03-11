import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../quiz/data/models/question_model.dart';
import '../models/pvp_match_model.dart';
import '../models/pvp_round_model.dart';
import '../repositories/pvp_repository.dart';

class PvPProvider extends ChangeNotifier {
  bool _disposed = false;

  /// Calls notifyListeners() only if the provider has not yet been disposed.
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  final PvPRepository _pvpRepository;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  // === Game state ===
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

  // === Search state ===
  bool isSearchingMatch = false;
  bool isInQueue = false;
  int searchDuration = 0;

  // === Notification state ===
  // Type 1a: Match found, it's my turn to play → countdown + auto-nav
  bool matchFound = false;
  // Type 1b: Match found, it's the opponent's turn to play → countdown + auto-nav
  bool matchFoundWaiting = false;
  int matchFoundCountdown = 5;
  String? foundMatchId;
  String? opponentUsername;
  String? opponentLanguage;
  // Type 2: It's your turn → button to go to the match
  bool yourTurnNotification = false;
  int? notificationRoundNumber;
  // Type 3: Match over → result
  bool matchCompletedNotification = false;
  bool? matchCompletedDidWin;

  // === Internal state ===
  bool isOnGamePage = false;
  bool _previousIsMyTurn = false;
  bool _processingMatchFound = false; // Guard against concurrent calls
  bool _backgroundCheckRunning = false; // Guard for polling
  bool _isSubmittingRound = false; // Guard against double submissions
  Timer? _matchFoundTimer;
  Timer? _notificationAutoDismissTimer;
  StreamSubscription<PvPMatchModel?>? _matchSubscription;
  Timer? _searchTimer;
  Timer? _searchDurationTimer;
  Timer? _backgroundCheckTimer; // Global background polling
  final Set<String> _knownMatchIds = {}; // Matches we have already seen
  final Set<String> _notifiedCompletedMatchIds = {}; // Matches whose completion we have already notified
  final Set<String> _dismissedTurnNotifications = {}; // Turns already dismissed by the user

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
  // GLOBAL BACKGROUND POLLING
  // =========================================================================

  /// Starts global polling. Called once at login/init.
  /// Checks every 5 seconds: queue + active matches.
  void startBackgroundChecks() {
    _backgroundCheckTimer?.cancel();
    _backgroundCheckRunning = false; // Reset the guard on restart
    _processingMatchFound = false; // Reset in case it was stuck
    _backgroundCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _backgroundCheck();
    });
    // Re-establish the watcher if we have an active match (returning to foreground on mobile)
    if (currentMatch != null) {
      _knownMatchIds.add(currentMatch!.id);
      if (currentMatch!.isInProgress) {
        _watchMatch(currentMatch!.id);
      }
    }
    // Load known match IDs at startup (to detect completions)
    _initKnownMatches();
    // Immediate check at startup
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

  /// Called when the app goes to the background (paused).
  /// If a quiz is in progress and the player hasn't finished, auto-submits their answers.
  void autoSubmitIfInProgress() {
    if (currentRound != null && !roundSubmitted && isMyTurn && myAnswers.isNotEmpty) {
      finishRound();
    }
  }

  Future<void> _backgroundCheck() async {
    final userId = currentUserId;
    if (userId == null) return;
    if (isOnGamePage || isSearchingMatch || matchFound) return;
    if (_backgroundCheckRunning || _processingMatchFound) return;
    _backgroundCheckRunning = true;

    try {
      // ── 1. Check if the current match has become "completed" ──
      if (currentMatch != null && !currentMatch!.isCompleted) {
        final freshMatch = await _pvpRepository.getMatch(currentMatch!.id);
        if (freshMatch != null && freshMatch.isCompleted &&
            !_notifiedCompletedMatchIds.contains(freshMatch.id) &&
            !matchCompletedNotification) {
          _notifiedCompletedMatchIds.add(freshMatch.id);
          currentMatch = freshMatch;
          matchCompletedNotification = true;
          matchCompletedDidWin = freshMatch.winnerId == null ? null : freshMatch.winnerId == userId;
          await _ensureOpponentInfo(freshMatch, userId);
          _safeNotify();
          _startAutoDismissTimer();
          return;
        }
      }

      // ── 2. Retrieve all active matches ──
      final activeMatches = await _pvpRepository.getActiveMatches(userId);

      // ── 3. Check known matches that have become "completed" ──
      if (_knownMatchIds.isNotEmpty && !matchCompletedNotification) {
        for (final knownId in _knownMatchIds.toList()) {
          // Skip if already notified or if it's an active match
          if (_notifiedCompletedMatchIds.contains(knownId)) continue;
          if (activeMatches.any((m) => m.id == knownId)) continue;
          // This match is no longer active → it may be completed
          final completedMatch = await _pvpRepository.getMatch(knownId);
          if (completedMatch != null && completedMatch.isCompleted) {
            _notifiedCompletedMatchIds.add(knownId);
            currentMatch = completedMatch;
            matchCompletedNotification = true;
            matchCompletedDidWin = completedMatch.winnerId == null ? null : completedMatch.winnerId == userId;
            await _ensureOpponentInfo(completedMatch, userId);
            _safeNotify();
            _startAutoDismissTimer();
            return;
          }
        }
      }

      // ── 4. Iterate over active matches: is it my turn? ──
      for (final match in activeMatches) {
        _knownMatchIds.add(match.id);
        final myTurn = match.isPlayerTurn(userId) || match.isPlayerChoosingTheme(userId);

        if (myTurn) {
          final isNewMatch = currentMatch?.id != match.id;
          currentMatch = match;
          _updateIsMyTurn();
          if (isNewMatch) {
            _previousIsMyTurn = true;
          }
          // Always restart the watcher (can die silently on Chrome/mobile)
          _watchMatch(match.id);
          await _ensureOpponentInfo(match, userId);
          final notifKey = '${match.id}_${match.currentRound}';
          if (!yourTurnNotification && !_dismissedTurnNotifications.contains(notifKey)) {
            matchFoundWaiting = false;
            yourTurnNotification = true;
            notificationRoundNumber = match.currentRound;
            _safeNotify();
            _startAutoDismissTimer();
          }
          return;
        }
      }

      // ── 5. Not our turn → make sure the watcher is active ──
      if (activeMatches.isNotEmpty) {
        final match = activeMatches.first;
        final isNewMatch = currentMatch?.id != match.id;
        currentMatch = match;
        _updateIsMyTurn();
        _previousIsMyTurn = isMyTurn || isMyThemeChoice;
        // Always restart the watcher to compensate for silent disconnections
        _watchMatch(match.id);
        if (isNewMatch) _safeNotify();
      }

      // ── 6. No active or current match → check the queue ──
      if (activeMatches.isEmpty && currentMatch == null) {
        final queueResult = await _pvpRepository.checkQueueStatus(userId);
        if (queueResult['matchFound'] == true && queueResult['matchId'] != null) {
          foundMatchId = queueResult['matchId'] as String;
          await loadMatch(foundMatchId!, preservePreviousTurn: true);
          foundMatchId = null;
          if (currentMatch != null) {
            _knownMatchIds.add(currentMatch!.id);
            await _ensureOpponentInfo(currentMatch!, userId);
            if (isMyTurn || isMyThemeChoice) {
              final notifKey = '${currentMatch!.id}_${currentMatch!.currentRound}';
              if (!_dismissedTurnNotifications.contains(notifKey)) {
                yourTurnNotification = true;
                notificationRoundNumber = currentMatch!.currentRound;
                _safeNotify();
                _startAutoDismissTimer();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PvP] _backgroundCheck error: $e');
    } finally {
      _backgroundCheckRunning = false;
    }
  }

  /// Sends a push notification to the opponent (fire-and-forget).
  /// [notificationType]: 'match_found' | 'your_turn' | 'match_over'
  /// The content is generated server-side based on the recipient's language.
  void _notifyOpponent(String notificationType) {
    final userId = currentUserId;
    if (userId == null || currentMatch == null) return;
    final opponentId = currentMatch!.getOpponentId(userId);
    if (opponentId == null) return;
    _pvpRepository.sendPvPNotification(opponentId, notificationType).catchError((_) {});
  }

  Future<void> _ensureOpponentInfo(PvPMatchModel match, String userId) async {
    if (opponentUsername != null && opponentLanguage != null) return;
    final opponentId = match.getOpponentId(userId);
    if (opponentId != null) {
      final info = await _pvpRepository.getOpponentInfo(opponentId);
      opponentUsername = info['username'];
      opponentLanguage = info['language'] ?? 'en';
    }
  }

  // =========================================================================
  // GAME PAGE - flag to suppress notifications when on this page
  // =========================================================================

  void setOnGamePage(bool value) {
    isOnGamePage = value;
    if (value) {
      // Entering the game page → dismiss all notifications
      final hadNotification = yourTurnNotification || matchFoundWaiting || matchCompletedNotification;
      yourTurnNotification = false;
      matchFoundWaiting = false;
      matchCompletedNotification = false;
      matchCompletedDidWin = null;
      notificationRoundNumber = null;
      _matchFoundTimer?.cancel();
      if (hadNotification) _safeNotify();
    }
  }

  // =========================================================================
  // MATCHMAKING
  // =========================================================================

  Future<void> joinMatchmaking() async {
    final userId = currentUserId;
    if (userId == null) {
      errorMessage = 'User not logged in';
      _safeNotify();
      return;
    }

    try {
      isSearchingMatch = true;
      isInQueue = false;
      searchDuration = 0;
      errorMessage = null;
      _safeNotify();

      final stats = await _pvpRepository.getPlayerPvPStats(userId);
      final rating = stats['rating'] as int;
      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      final result = await _pvpRepository.joinMatchmaking(userId, rating, language);

      if (result['matchFound'] == true && result['matchId'] != null) {
        foundMatchId = result['matchId'];
        await _onMatchFound();
      } else {
        isInQueue = true;
        _startSearchTimer();
        _startSearchDurationTimer();
      }

      _safeNotify();
    } catch (e) {
      debugPrint('[PvP] ERROR joinMatchmaking: $e');
      errorMessage = 'Unable to join matchmaking. Please try again.';
      isSearchingMatch = false;
      isInQueue = false;
      _safeNotify();
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
      _safeNotify();
    });
  }

  void _stopSearchTimers() {
    _searchTimer?.cancel();
    _searchDurationTimer?.cancel();
  }

  Future<void> _checkForMatch() async {
    final userId = currentUserId;
    if (userId == null) return;
    // Guard against concurrent calls (Timer.periodic doesn't wait for async)
    if (_processingMatchFound) return;

    try {
      final status = await _pvpRepository.checkQueueStatus(userId);

      if (status['matchFound'] == true && status['matchId'] != null) {
        _stopSearchTimers();
        foundMatchId = status['matchId'] as String;
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
          await _onMatchFound();
        }
      } else {
        _stopSearchTimers();
        isSearchingMatch = false;
        isInQueue = false;
        _safeNotify();
      }
    } catch (e) {
      debugPrint('Error checking for match: $e');
    }
  }

  // =========================================================================
  // MATCH FOUND
  // =========================================================================

  /// Match found from an ACTIVE SEARCH (joinMatchmaking / _checkForMatch).
  /// Shows the "Match Found" notification with countdown + auto-nav.
  Future<void> _onMatchFound() async {
    // Guard against concurrent calls (Timer.periodic + slow network on mobile)
    if (_processingMatchFound) return;
    _processingMatchFound = true;

    _stopSearchTimers();
    isInQueue = false;
    isSearchingMatch = false;
    // Notify immediately so the UI hides the search popup
    _safeNotify();

    try {
      if (foundMatchId != null) {
        await loadMatch(foundMatchId!, preservePreviousTurn: true);
        if (currentMatch != null && currentUserId != null) {
          _knownMatchIds.add(currentMatch!.id);
          await _ensureOpponentInfo(currentMatch!, currentUserId!);
        }
        foundMatchId = null;
      }

      if (currentMatch == null) {
        return;
      }

      _notifyOpponent('match_found');

      if (isMyTurn || isMyThemeChoice) {
        // It's my turn to play → 5s countdown then auto-nav
        _previousIsMyTurn = true;
        matchFound = true;
        matchFoundCountdown = 5;
        _safeNotify();
        _startMatchFoundCountdown();
      } else {
        // The opponent plays → "Match Found - Waiting" notification
        _previousIsMyTurn = false;
        matchFoundWaiting = true;
        _safeNotify();
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
      _safeNotify();
      if (matchFoundCountdown <= 0) {
        timer.cancel();
        // Do not clear the flags here - the overlay manages navigation
        // and calls dismissNotification() when navigating
      }
    });
  }

  void dismissNotification() {
    if (yourTurnNotification && currentMatch != null && notificationRoundNumber != null) {
      _dismissedTurnNotifications.add('${currentMatch!.id}_$notificationRoundNumber');
    }
    matchFound = false;
    matchFoundWaiting = false;
    yourTurnNotification = false;
    matchCompletedNotification = false;
    matchCompletedDidWin = null;
    notificationRoundNumber = null;
    _matchFoundTimer?.cancel();
    _notificationAutoDismissTimer?.cancel();
    _safeNotify();
  }

  /// Starts a 15s timer to auto-dismiss notifications
  /// (all except matchFound which has its own countdown + auto-teleport)
  void _startAutoDismissTimer() {
    _notificationAutoDismissTimer?.cancel();
    _notificationAutoDismissTimer = Timer(const Duration(seconds: 15), () {
      if (matchFoundWaiting || yourTurnNotification || matchCompletedNotification) {
        if (yourTurnNotification && currentMatch != null && notificationRoundNumber != null) {
          _dismissedTurnNotifications.add('${currentMatch!.id}_$notificationRoundNumber');
        }
        matchFoundWaiting = false;
        yourTurnNotification = false;
        matchCompletedNotification = false;
        matchCompletedDidWin = null;
        notificationRoundNumber = null;
        _safeNotify();
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
      _safeNotify();
    } catch (e) {
      errorMessage = 'Unable to leave matchmaking. Please try again.';
      _safeNotify();
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
    // Ne pas recharger si on est en plein quiz (submitRound en cours)
    if (_isSubmittingRound) {
      return;
    }
    try {
      isLoading = true;
      errorMessage = null;
      _safeNotify();

      currentMatch = await _pvpRepository.getMatch(matchId);
      if (currentMatch == null) {
        errorMessage = 'Match not found';
        isLoading = false;
        _safeNotify();
        return;
      }

      _knownMatchIds.add(currentMatch!.id);
      _updateIsMyTurn();
      // Do not overwrite _previousIsMyTurn if called from _onMatchFound
      // (which sets it correctly so the watcher can detect transitions)
      if (!preservePreviousTurn) {
        _previousIsMyTurn = isMyTurn || isMyThemeChoice;
      }

      if (!currentMatch!.isChoosingTheme) {
        await loadRound(currentMatch!.currentRound);
      }

      _watchMatch(matchId);

      isLoading = false;
      _safeNotify();
    } catch (e) {
      debugPrint('[PvP] ERROR loadMatch: $e');
      errorMessage = 'Unable to load match. Please try again.';
      isLoading = false;
      _safeNotify();
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
        // Do not interfere while a submitRound is in progress
        // (submitRound manages its own status transitions)
        if (_isSubmittingRound) return;

        final previousStatus = currentMatch?.status;
        final previousMatchRound = currentMatch?.currentRound;
        final wasMyTurn = _previousIsMyTurn;
        currentMatch = match;
        _updateIsMyTurn();

        // Match over
        if (previousStatus != PvPMatchStatus.completed &&
            match.status == PvPMatchStatus.completed) {
          _notifiedCompletedMatchIds.add(match.id);
          matchCompletedNotification = true;
          matchCompletedDidWin = match.winnerId == null
              ? null
              : match.winnerId == currentUserId;
          if (currentUserId != null) {
            await _ensureOpponentInfo(match, currentUserId!);
          }
          _safeNotify();
          _startAutoDismissTimer();
          return;
        }

        // It has become my turn (and it wasn't before)
        // Notification SEULEMENT si PAS sur la page de jeu
        if (!wasMyTurn && (isMyTurn || isMyThemeChoice) && !matchFound && !isOnGamePage) {
          final notifKey = '${match.id}_${match.currentRound}';
          if (!_dismissedTurnNotifications.contains(notifKey)) {
            matchFoundWaiting = false;
            yourTurnNotification = true;
            notificationRoundNumber = match.currentRound;
            if (currentUserId != null) {
              await _ensureOpponentInfo(match, currentUserId!);
            }
            _startAutoDismissTimer();
          }
        }
        _previousIsMyTurn = isMyTurn || isMyThemeChoice;

        // If status changed from choosingTheme → playerTurn, load the round
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

        _safeNotify();
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
      _safeNotify();

      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      final questions = await _pvpRepository.getQuestionsByTheme(themeId, language, 100, avgRating: _avgRating);
      currentQuestions = questions;

      final questionIds = questions.map((q) => q.id).toList();

      // Check if the round already exists (can happen if submitRound was called twice)
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
      _safeNotify();
    } catch (e) {
      debugPrint('[PvP] ERROR selectTheme: $e');
      errorMessage = 'Unable to select theme. Please try again.';
      isLoading = false;
      _safeNotify();
    }
  }

  // =========================================================================
  // ROUND MANAGEMENT
  // =========================================================================

  Future<void> loadRound(int roundNumber) async {
    if (currentMatch == null) return;

    if (currentMatch!.isChoosingTheme) {
      return;
    }

    try {
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
        }
      } else {
        await _loadQuestionsFromRound();
      }

      _safeNotify();
    } catch (e) {
      debugPrint('[PvP] ERROR loadRound: $e');
      errorMessage = 'Unable to load round. Please try again.';
      _safeNotify();
    }
  }

  Future<void> _startRoundWithRandomTheme() async {
    if (currentMatch == null) return;

    try {
      isLoading = true;
      _safeNotify();

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
      _safeNotify();
    } catch (e) {
      debugPrint('[PvP] ERROR _startRoundWithRandomTheme: $e');
      errorMessage = 'Unable to start round. Please try again.';
      isLoading = false;
      _safeNotify();
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

    // Reorder to match the exact order of questionIds
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
      _safeNotify();

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
      _safeNotify();
    } catch (e) {
      debugPrint('[PvP] ERROR startRound: $e');
      errorMessage = 'Unable to start round. Please try again.';
      isLoading = false;
      _safeNotify();
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
    _safeNotify();

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
    _safeNotify();

    if (hasAnsweredAllQuestions) {
      submitRound();
    }
  }

  void finishRound() {
    if (roundSubmitted) return;
    roundSubmitted = true;
    _safeNotify();
    // If a submit is already in progress (e.g. last answer triggered submitRound),
    // do not re-trigger - the round will be submitted with the current answers
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
    // Guard against concurrent calls (selectAnswer + finishRound/timer)
    if (_isSubmittingRound) return;
    _isSubmittingRound = true;

    try {
      isLoading = true;
      _safeNotify();

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

      final submittedRoundNumber = currentRound!.roundNumber;
      currentRound = await _pvpRepository.getRound(
        currentMatch!.id,
        submittedRoundNumber,
      );

      // Verify our submission was recorded. If not, the RPC failed silently.
      final myCompletionRecorded = isPlayer1
          ? (currentRound?.isPlayer1Completed ?? false)
          : (currentRound?.isPlayer2Completed ?? false);

      if (!myCompletionRecorded) {
        errorMessage = 'Submission failed. Please try again.';
        isLoading = false;
        _safeNotify();
        return;
      }

      currentMatch = await _pvpRepository.getMatch(currentMatch!.id);

      if (currentRound!.isRoundCompleted) {
        final roundNumber = currentRound!.roundNumber;
        if (roundNumber >= 3) {
          await completeMatch();
        } else if (roundNumber == 1) {
          await _pvpRepository.updateMatchStatusAndRound(
            currentMatch!.id,
            'player2_choosing_theme',
            2,
          );
          currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
        } else if (roundNumber == 2) {
          await _pvpRepository.updateMatchStatusAndRound(
            currentMatch!.id,
            'player1_turn',
            3,
          );
          currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
        }
      } else {
        // Round not yet complete: it's now the other player's turn
        final newStatus = isPlayer1 ? 'player2_turn' : 'player1_turn';
        await _pvpRepository.updateMatchStatus(currentMatch!.id, newStatus);
        currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
        _notifyOpponent('your_turn');
      }

      _updateIsMyTurn();
      isLoading = false;
      _safeNotify();
    } catch (e) {
      errorMessage = 'Unable to submit round. Please try again.';
      isLoading = false;
      _safeNotify();
    } finally {
      _isSubmittingRound = false;
    }
  }

  Future<void> completeMatch() async {
    if (currentMatch == null) return;

    try {
      await _pvpRepository.completeMatch(currentMatch!.id);
      currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
      _notifyOpponent('match_over');
      _safeNotify();
    } catch (e) {
      errorMessage = 'Unable to complete match. Please try again.';
      _safeNotify();
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
    opponentLanguage = null;
    yourTurnNotification = false;
    matchCompletedNotification = false;
    matchCompletedDidWin = null;
    notificationRoundNumber = null;
    _previousIsMyTurn = false;
    _processingMatchFound = false;
    _isSubmittingRound = false;
    isOnGamePage = false;
    _knownMatchIds.clear();
    _notifiedCompletedMatchIds.clear();
    _dismissedTurnNotifications.clear();

    // DO NOT stop the background timer: it must keep running
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _matchSubscription?.cancel();
    _stopSearchTimers();
    _backgroundCheckTimer?.cancel();
    _matchFoundTimer?.cancel();
    _notificationAutoDismissTimer?.cancel();
    super.dispose();
  }
}

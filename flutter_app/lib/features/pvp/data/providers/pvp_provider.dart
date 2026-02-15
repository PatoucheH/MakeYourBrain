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

  // État
  PvPMatchModel? currentMatch;
  PvPRoundModel? currentRound;
  List<QuestionModel> currentQuestions = [];
  int currentQuestionIndex = 0;
  List<PvPAnswerModel> myAnswers = [];
  bool isSearchingMatch = false;
  bool isInQueue = false;
  bool isMyTurn = false;
  int timeSpent = 0;
  int searchDuration = 0;
  String? errorMessage;
  bool isLoading = false;

  // États pour les notifications
  bool matchFound = false;          // Match trouvé avec countdown → auto-nav (joueur qui commence)
  bool matchFoundWaiting = false;   // Match trouvé mais c'est l'adversaire qui commence
  int matchFoundCountdown = 5;
  String? foundMatchId;
  String? opponentUsername;
  bool yourTurnNotification = false; // C'est votre tour → bouton pour aller au match
  int? notificationRoundNumber;       // Numéro du round pour la notif "your turn"
  bool matchCompletedNotification = false; // Match terminé
  bool? matchCompletedDidWin;        // Résultat du match terminé
  Timer? _matchFoundTimer;
  bool _previousIsMyTurn = false;     // Pour détecter les changements de tour

  // Streams
  StreamSubscription<PvPMatchModel?>? _matchSubscription;
  Timer? _searchTimer;
  Timer? _searchDurationTimer;

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

  int consecutiveWrong = 0;

  int get myRoundScore {
    int total = 0;
    for (final answer in myAnswers) {
      total += answer.points;
    }
    return total < 0 ? 0 : total;
  }

  bool roundSubmitted = false;

  bool get hasAnsweredAllQuestions =>
      roundSubmitted ||
      (currentQuestions.isNotEmpty && myAnswers.length >= currentQuestions.length);

  QuestionModel? get currentQuestion {
    if (currentQuestionIndex >= currentQuestions.length) return null;
    return currentQuestions[currentQuestionIndex];
  }

  /// Vérifie si le joueur doit choisir un thème
  bool get isMyThemeChoice {
    if (currentMatch == null || currentUserId == null) return false;
    return currentMatch!.isPlayerChoosingTheme(currentUserId!);
  }

  /// Vérifie le statut de la queue et des matchs actifs au retour dans l'app
  Future<void> checkQueueStatusOnResume() async {
    final userId = currentUserId;
    if (userId == null) return;
    // Ne pas vérifier si on est déjà en recherche active
    if (isSearchingMatch || matchFound || matchFoundWaiting) return;

    try {
      // 1. Vérifier la queue de matchmaking
      if (currentMatch == null) {
        final result = await _pvpRepository.checkQueueStatus(userId);

        if (result['matchFound'] == true && result['matchId'] != null) {
          foundMatchId = result['matchId'] as String;
          _onMatchFound();
          return;
        } else if (result['inQueue'] == true) {
          isSearchingMatch = true;
          isInQueue = true;
          searchDuration = (result['timeInQueue'] as int?) ?? 0;
          _startSearchTimer();
          _startSearchDurationTimer();
          notifyListeners();
          return;
        }
      }

      // 2. Vérifier les matchs actifs pour détecter si c'est notre tour
      await checkActiveMatchesForTurn();
    } catch (e) {
      debugPrint('Error checking queue status: $e');
    }
  }

  /// Vérifie les matchs actifs et notifie si c'est le tour du joueur
  Future<void> checkActiveMatchesForTurn() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final activeMatches = await _pvpRepository.getActiveMatches(userId);
      if (activeMatches.isEmpty) return;

      for (final match in activeMatches) {
        final isMyTurn = match.isPlayerTurn(userId) || match.isPlayerChoosingTheme(userId);
        if (isMyTurn) {
          debugPrint('[PvP] checkActiveMatchesForTurn - found active match ${match.id} where it is my turn');

          // Charger le match et démarrer le watcher si pas déjà fait
          if (currentMatch?.id != match.id) {
            currentMatch = match;
            _updateIsMyTurn();
            _previousIsMyTurn = true; // On sait déjà que c'est notre tour
            _watchMatch(match.id);
          }

          // Récupérer le username de l'adversaire
          if (opponentUsername == null) {
            final opponentId = match.getOpponentId(userId);
            if (opponentId != null) {
              opponentUsername = await _pvpRepository.getUsername(opponentId);
            }
          }

          // Déclencher la notification "your turn"
          yourTurnNotification = true;
          notificationRoundNumber = match.currentRound;
          notifyListeners();
          return; // Notifier pour le premier match trouvé
        }
      }

      // Si on a un match en cours mais pas notre tour, quand même garder le watcher actif
      if (currentMatch == null && activeMatches.isNotEmpty) {
        final match = activeMatches.first;
        currentMatch = match;
        _updateIsMyTurn();
        _previousIsMyTurn = isMyTurn || isMyThemeChoice;
        _watchMatch(match.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PvP] Error checking active matches for turn: $e');
    }
  }

  /// Rejoint la file d'attente de matchmaking
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

      // Récupérer les stats du joueur
      final stats = await _pvpRepository.getPlayerPvPStats(userId);
      final rating = stats['rating'] as int;

      // Récupérer la langue préférée
      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      // Rejoindre la file d'attente
      debugPrint('[PvP] joinMatchmaking - calling RPC with userId=$userId, rating=$rating, language=$language');
      final result = await _pvpRepository.joinMatchmaking(userId, rating, language);
      debugPrint('[PvP] joinMatchmaking - result: $result');

      if (result['matchFound'] == true && result['matchId'] != null) {
        // Match trouvé immédiatement - démarrer le countdown
        foundMatchId = result['matchId'];
        debugPrint('[PvP] joinMatchmaking - match found! matchId=$foundMatchId');
        _onMatchFound();
      } else {
        // En attente d'un adversaire, on poll régulièrement
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
    // Ne pas chercher si un match est déjà en cours
    if (currentMatch != null && currentMatch!.isInProgress) {
      _stopSearchTimers();
      return;
    }

    try {
      // D'abord vérifier si un match a été trouvé (par l'autre joueur)
      final status = await _pvpRepository.checkQueueStatus(userId);

      if (status['matchFound'] == true && status['matchId'] != null) {
        _stopSearchTimers();
        foundMatchId = status['matchId'] as String;
        debugPrint('[PvP] _checkForMatch - match found via checkQueueStatus! matchId=$foundMatchId');
        _onMatchFound();
        return;
      }

      // Si toujours dans la queue, tenter de matcher avec quelqu'un
      if (status['inQueue'] == true) {
        final stats = await _pvpRepository.getPlayerPvPStats(userId);
        final rating = stats['rating'] as int;
        final userStats = await _authRepository.getUserStats();
        final language = userStats?.preferredLanguage ?? 'en';

        final result = await _pvpRepository.joinMatchmaking(userId, rating, language);

        if (result['matchFound'] == true && result['matchId'] != null) {
          _stopSearchTimers();
          foundMatchId = result['matchId'];
          debugPrint('[PvP] _checkForMatch - match found via joinMatchmaking! matchId=$foundMatchId');
          _onMatchFound();
        }
      } else {
        // Plus dans la queue et pas de match → arrêter le polling
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

  /// Match trouvé : charger le match, récupérer le username adversaire
  /// Si c'est à moi de commencer → countdown 5s + auto-navigation
  /// Sinon → notification silencieuse (attendre mon tour via watcher)
  Future<void> _onMatchFound() async {
    _stopSearchTimers();
    isInQueue = false;
    isSearchingMatch = false;

    try {
      if (foundMatchId != null) {
        await loadMatch(foundMatchId!);
        // Récupérer le username de l'adversaire
        if (currentMatch != null && currentUserId != null) {
          final opponentId = currentMatch!.getOpponentId(currentUserId!);
          if (opponentId != null) {
            opponentUsername = await _pvpRepository.getUsername(opponentId);
          }
        }
        foundMatchId = null;
      }
    } catch (e) {
      debugPrint('[PvP] Error in _onMatchFound: $e');
    }

    // Initialiser le tracking de tour pour le watcher
    _previousIsMyTurn = isMyTurn || isMyThemeChoice;

    // Si c'est à moi de commencer → countdown 5s + auto-navigation
    if (isMyTurn || isMyThemeChoice) {
      matchFound = true;
      matchFoundCountdown = 5;
      notifyListeners();
      _matchFoundTimer?.cancel();
      _matchFoundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        matchFoundCountdown--;
        notifyListeners();
        if (matchFoundCountdown <= 0) {
          timer.cancel();
          matchFound = false;
          notifyListeners();
        }
      });
    } else {
      // Pas à mon tour → notifier que le match est trouvé mais l'adversaire joue en premier
      matchFoundWaiting = true;
      notifyListeners();
      // Auto-dismiss après 5 secondes
      Timer(const Duration(seconds: 5), () {
        if (matchFoundWaiting) {
          matchFoundWaiting = false;
          notifyListeners();
        }
      });
    }
  }

  /// Ferme une notification (appelé aussi par dismissMatchFound pour compatibilité)
  void dismissNotification() {
    matchFound = false;
    matchFoundWaiting = false;
    yourTurnNotification = false;
    matchCompletedNotification = false;
    matchCompletedDidWin = null;
    notificationRoundNumber = null;
    _matchFoundTimer?.cancel();
    notifyListeners();
  }

  /// Alias pour compatibilité
  void dismissMatchFound() => dismissNotification();

  /// Quitte la file d'attente de matchmaking
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

  /// Calcule le rating moyen des deux joueurs
  int get _avgRating {
    if (currentMatch == null) return 1000;
    final r1 = currentMatch!.player1RatingBefore;
    final r2 = currentMatch!.player2RatingBefore ?? r1;
    return ((r1 + r2) / 2).round();
  }

  /// Sélectionne un thème pour le round actuel
  Future<void> selectTheme(String themeId) async {
    if (currentMatch == null || currentUserId == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      // Générer les questions pour ce thème avec difficulté basée sur le rating moyen
      final questions = await _pvpRepository.getQuestionsByTheme(themeId, language, 100, avgRating: _avgRating);
      currentQuestions = questions;
      if (questions.isNotEmpty) {
        final q = questions.first;
        debugPrint('[PvP] selectTheme - first question: id=${q.id}, answers=${q.answers.length}, correctAnswers=${q.answers.where((a) => a.isCorrect).length}');
      }

      final questionIds = questions.map((q) => q.id).toList();

      // Créer le round avec le thème et les questions
      await _pvpRepository.createRound(
        currentMatch!.id,
        currentMatch!.currentRound,
        questionIds,
        themeId: themeId,
      );

      // Mettre à jour le statut du match vers playerX_turn
      // (le backend pvp_create_round ne change pas le status, on le fait ici)
      final newStatus = currentMatch!.currentRound == 1
          ? 'player1_turn'
          : 'player2_turn';
      await _pvpRepository.updateMatchStatus(currentMatch!.id, newStatus);

      // Recharger le match et le round
      currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
      currentRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentMatch!.currentRound,
      );

      // Réinitialiser l'état de jeu
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

  /// Charge un match et s'abonne aux changements
  Future<void> loadMatch(String matchId) async {
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

      debugPrint('[PvP] loadMatch - status=${currentMatch!.status}, currentRound=${currentMatch!.currentRound}, player1=${currentMatch!.player1Id}, player2=${currentMatch!.player2Id}');

      // Déterminer si c'est notre tour
      _updateIsMyTurn();
      _previousIsMyTurn = isMyTurn || isMyThemeChoice;
      debugPrint('[PvP] loadMatch - isMyTurn=$isMyTurn, isMyThemeChoice=$isMyThemeChoice, _previousIsMyTurn=$_previousIsMyTurn, currentUserId=$currentUserId');

      // Si c'est un état de choix de thème, ne pas charger le round
      if (!currentMatch!.isChoosingTheme) {
        await loadRound(currentMatch!.currentRound);
      }

      // S'abonner aux changements du match
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
        if (match != null) {
          final previousMatchRound = currentMatch?.currentRound;
          final previousStatus = currentMatch?.status;
          final wasMyTurn = _previousIsMyTurn;
          currentMatch = match;
          _updateIsMyTurn();

          debugPrint('[PvP] _watchMatch - status=${match.status}, round=${match.currentRound}, wasMyTurn=$wasMyTurn, isMyTurn=$isMyTurn, isMyThemeChoice=$isMyThemeChoice');

          // Détecter si le match vient de se terminer
          if (previousStatus != PvPMatchStatus.completed &&
              match.status == PvPMatchStatus.completed) {
            debugPrint('[PvP] _watchMatch - match completed!');
            matchCompletedNotification = true;
            if (match.winnerId == null) {
              matchCompletedDidWin = null; // draw
            } else {
              matchCompletedDidWin = match.winnerId == currentUserId;
            }
            // Récupérer le username adversaire si pas encore fait
            if (opponentUsername == null && currentUserId != null) {
              final opponentId = match.getOpponentId(currentUserId!);
              if (opponentId != null) {
                opponentUsername = await _pvpRepository.getUsername(opponentId);
              }
            }
            notifyListeners();
            return;
          }

          // Détecter si c'est devenu mon tour (et ça ne l'était pas avant)
          if (!wasMyTurn && (isMyTurn || isMyThemeChoice) && !matchFound) {
            debugPrint('[PvP] _watchMatch - it became my turn! round=${match.currentRound}');
            yourTurnNotification = true;
            notificationRoundNumber = match.currentRound;
            // Récupérer le username adversaire si pas encore fait
            if (opponentUsername == null && currentUserId != null) {
              final opponentId = match.getOpponentId(currentUserId!);
              if (opponentId != null) {
                opponentUsername = await _pvpRepository.getUsername(opponentId);
              }
            }
          }
          _previousIsMyTurn = isMyTurn || isMyThemeChoice;

          // Si le statut a changé de choosingTheme à playerTurn, charger le round
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
        }
      },
      onError: (e) {
        debugPrint('Error watching match: $e');
      },
    );
  }

  /// Charge un round spécifique
  Future<void> loadRound(int roundNumber) async {
    if (currentMatch == null) return;

    // Ne pas charger de round si on est en phase de choix de thème
    if (currentMatch!.isChoosingTheme) {
      debugPrint('[PvP] loadRound($roundNumber) - skipped, choosing theme phase');
      return;
    }

    try {
      debugPrint('[PvP] loadRound($roundNumber) - isMyTurn=$isMyTurn');
      currentRound = await _pvpRepository.getRound(currentMatch!.id, roundNumber);
      debugPrint('[PvP] loadRound - round=${currentRound != null ? 'found (${currentRound!.questionIds.length} questionIds, theme=${currentRound!.themeId})' : 'null'}');

      // Réinitialiser les réponses locales pour ce round
      myAnswers = [];
      currentQuestionIndex = 0;
      timeSpent = 0;
      roundSubmitted = false;
      consecutiveWrong = 0;

      if (currentRound == null) {
        // Round 3 : thème aléatoire, le premier joueur le crée
        if (isMyTurn && roundNumber == 3) {
          debugPrint('[PvP] loadRound - round 3, creating with random theme');
          await _startRoundWithRandomTheme();
        } else if (isMyTurn) {
          debugPrint('[PvP] loadRound - creating new round (startRound)');
          await startRound();
        } else {
          debugPrint('[PvP] loadRound - round null and not my turn, waiting');
        }
      } else {
        // Round existant, charger les questions
        debugPrint('[PvP] loadRound - loading questions from existing round');
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

  /// Crée le round 3 avec un thème aléatoire
  Future<void> _startRoundWithRandomTheme() async {
    if (currentMatch == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      // Récupérer les thèmes des rounds 1 et 2
      final round1 = await _pvpRepository.getRound(currentMatch!.id, 1);
      final round2 = await _pvpRepository.getRound(currentMatch!.id, 2);
      final excludeThemes = [
        if (round1?.themeId != null) round1!.themeId!,
        if (round2?.themeId != null) round2!.themeId!,
      ];

      // Choisir un thème aléatoire différent
      final randomThemeId = await _pvpRepository.getRandomTheme(language, excludeThemes);

      List<QuestionModel> questions;
      if (randomThemeId != null) {
        questions = await _pvpRepository.getQuestionsByTheme(randomThemeId, language, 100, avgRating: _avgRating);
      } else {
        // Fallback : questions aléatoires tous thèmes
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
    if (currentRound == null || currentRound!.questionIds.isEmpty) {
      debugPrint('[PvP] _loadQuestionsFromRound - skipped (round=${currentRound == null ? 'null' : 'empty questionIds'})');
      return;
    }

    final userStats = await _authRepository.getUserStats();
    final language = userStats?.preferredLanguage ?? 'en';
    final questionIds = currentRound!.questionIds;
    debugPrint('[PvP] _loadQuestionsFromRound - fetching ${questionIds.length} questions (lang=$language)');

    final fetchedQuestions = await _pvpRepository.getQuestionsByIds(
      questionIds,
      language,
    );

    // Réordonner les questions pour correspondre à l'ordre exact de questionIds
    // (le SQL ne garantit pas l'ordre) → les deux joueurs auront les mêmes questions dans le même ordre
    final questionsMap = {for (final q in fetchedQuestions) q.id: q};
    currentQuestions = questionIds
        .where((id) => questionsMap.containsKey(id))
        .map((id) => questionsMap[id]!)
        .toList();
  }

  /// Démarre un nouveau round (génère les questions)
  Future<void> startRound() async {
    if (currentMatch == null) return;

    try {
      isLoading = true;
      notifyListeners();

      debugPrint('[PvP] startRound - generating questions');
      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      // Vérifier si un round existe déjà avec un thème
      final existingRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentMatch!.currentRound,
      );

      List<QuestionModel> questions;
      String? themeId = existingRound?.themeId;

      if (themeId != null) {
        // Le thème a été choisi, récupérer les questions pour ce thème
        questions = await _pvpRepository.getQuestionsByTheme(themeId, language, 100, avgRating: _avgRating);
      } else {
        // Pas de thème (fallback ou ancien système)
        questions = await _pvpRepository.getQuestionsForRound(language, 100);
      }

      currentQuestions = questions;
      debugPrint('[PvP] startRound - got ${currentQuestions.length} questions (theme=$themeId)');

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

  /// Sélectionne une réponse pour la question actuelle
  void selectAnswer(
    String questionId,
    String answerId,
    bool isCorrect,
    String difficulty,
  ) {
    debugPrint('[PvP] selectAnswer - questionId=$questionId, answerId=$answerId, isCorrect=$isCorrect, difficulty=$difficulty');
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
      // Ne pas descendre en dessous de 0
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

  /// Passe à la question suivante sans répondre (timeout)
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

  /// Termine le round (temps écoulé)
  void finishRound() {
    if (roundSubmitted) return;
    roundSubmitted = true;
    notifyListeners();
    submitRound();
  }

  /// Met à jour le temps écoulé
  void updateTimeSpent(int seconds) {
    timeSpent = seconds;
  }

  /// Soumet les réponses du round
  Future<void> submitRound() async {
    if (currentMatch == null || currentRound == null || currentUserId == null) {
      return;
    }

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

      // Mettre à jour la streak (le PvP compte comme activité)
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
          // Dernier round terminé → compléter le match
          await completeMatch();
        } else if (roundNumber == 1) {
          // Round 1 terminé → Player 2 choisit le thème du round 2
          debugPrint('[PvP] submitRound - round 1 complete, transitioning to player2_choosing_theme');
          await _pvpRepository.updateMatchStatusAndRound(
            currentMatch!.id,
            'player2_choosing_theme',
            2,
          );
          currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
        } else if (roundNumber == 2) {
          // Round 2 terminé → Round 3 avec thème aléatoire, player1 joue en premier
          debugPrint('[PvP] submitRound - round 2 complete, transitioning to player1_turn for round 3');
          await _pvpRepository.updateMatchStatusAndRound(
            currentMatch!.id,
            'player1_turn',
            3,
          );
          currentMatch = await _pvpRepository.getMatch(currentMatch!.id);
        }
      } else {
        // Round pas encore complété : basculer le tour vers l'autre joueur
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
    }
  }

  /// Termine le match et calcule le gagnant
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

  /// Vérifie si le joueur actuel a gagné
  bool? get didWin {
    if (currentMatch == null ||
        currentMatch!.status != PvPMatchStatus.completed ||
        currentUserId == null) {
      return null;
    }

    if (currentMatch!.winnerId == null) {
      return null;
    }

    return currentMatch!.winnerId == currentUserId;
  }

  /// Retourne le changement de rating du joueur actuel
  int? get myRatingChange {
    if (currentMatch == null || currentUserId == null) return null;
    return currentMatch!.getPlayerRatingChange(currentUserId!);
  }

  /// Remet tous les états à zéro
  void reset() {
    _matchSubscription?.cancel();
    _stopSearchTimers();

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
    _matchFoundTimer?.cancel();

    notifyListeners();
  }

  /// Récupère l'historique des matchs
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

  /// Récupère les thèmes déjà utilisés dans les rounds précédents du match en cours
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

  /// Récupère les matchs actifs
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

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _stopSearchTimers();
    super.dispose();
  }
}

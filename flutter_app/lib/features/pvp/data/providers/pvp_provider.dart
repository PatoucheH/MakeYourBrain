import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../quiz/data/models/question_model.dart';
import '../models/pvp_match_model.dart';
import '../models/pvp_round_model.dart';
import '../repositories/pvp_repository.dart';

class PvPProvider extends ChangeNotifier {
  final PvPRepository _pvpRepository;
  final AuthRepository _authRepository;

  // État
  PvPMatchModel? currentMatch;
  PvPRoundModel? currentRound;
  List<QuestionModel> currentQuestions = [];
  int currentQuestionIndex = 0;
  List<PvPAnswerModel> myAnswers = [];
  bool isSearchingMatch = false;
  bool isInQueue = false; // Indique si on est bien dans la file d'attente
  bool isMyTurn = false;
  int timeSpent = 0;
  int searchDuration = 0; // Temps de recherche en secondes
  String? errorMessage;
  bool isLoading = false;

  // États pour le matchmaking avec popup
  bool matchFound = false;
  int matchFoundCountdown = 5; // Compte à rebours avant de lancer le match
  String? foundMatchId; // ID du match trouvé
  bool isReadyToPlay = false; // Indique que le match est prêt à être joué

  // Streams
  StreamSubscription<PvPMatchModel?>? _matchSubscription;
  Timer? _searchTimer;
  Timer? _searchDurationTimer;
  Timer? _matchFoundTimer;

  PvPProvider({
    PvPRepository? pvpRepository,
    AuthRepository? authRepository,
  })  : _pvpRepository = pvpRepository ?? PvPRepository(),
        _authRepository = authRepository ?? AuthRepository();

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
      final result = await _pvpRepository.joinMatchmaking(userId, rating, language);

      if (result['matchFound'] == true && result['matchId'] != null) {
        // Match trouvé immédiatement - démarrer le countdown
        foundMatchId = result['matchId'];
        _startMatchFoundCountdown();
      } else {
        // En attente d'un adversaire, on poll régulièrement
        isInQueue = true;
        _startSearchTimer();
        _startSearchDurationTimer();
      }

      notifyListeners();
    } catch (e) {
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
    searchDuration = 0;
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

    try {
      // Vérifier si on a été matché
      final activeMatches = await _pvpRepository.getActiveMatches(userId);
      final waitingMatch = activeMatches.where((m) =>
        m.status != PvPMatchStatus.waiting || m.player2Id != null
      ).firstOrNull;

      if (waitingMatch != null) {
        _stopSearchTimers();
        foundMatchId = waitingMatch.id;
        _startMatchFoundCountdown();
      }
    } catch (e) {
      print('Error checking for match: $e');
    }
  }

  /// Démarre le compte à rebours quand un match est trouvé
  void _startMatchFoundCountdown() {
    matchFound = true;
    matchFoundCountdown = 5;
    isInQueue = false;
    isReadyToPlay = false;
    notifyListeners();

    _matchFoundTimer?.cancel();
    _matchFoundTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      matchFoundCountdown--;
      notifyListeners();

      if (matchFoundCountdown <= 0) {
        timer.cancel();
        // Charger le match et signaler que c'est prêt
        if (foundMatchId != null) {
          await loadMatch(foundMatchId!);
          foundMatchId = null;
        }
        isSearchingMatch = false;
        matchFound = false;
        isReadyToPlay = true; // Le match est prêt à être joué
        notifyListeners();
      }
    });
  }

  /// Réinitialise l'état isReadyToPlay après la navigation
  void clearReadyToPlay() {
    isReadyToPlay = false;
  }

  /// Quitte la file d'attente de matchmaking
  Future<void> leaveMatchmaking() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      _stopSearchTimers();
      _matchFoundTimer?.cancel();
      await _pvpRepository.leaveMatchmaking(userId);
      isSearchingMatch = false;
      isInQueue = false;
      searchDuration = 0;
      matchFound = false;
      matchFoundCountdown = 5;
      foundMatchId = null;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error leaving matchmaking: $e';
      notifyListeners();
    }
  }

  /// Charge un match et s'abonne aux changements
  Future<void> loadMatch(String matchId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      print('[PvP] loadMatch($matchId)');
      currentMatch = await _pvpRepository.getMatch(matchId);
      if (currentMatch == null) {
        print('[PvP] loadMatch - match not found');
        errorMessage = 'Match not found';
        isLoading = false;
        notifyListeners();
        return;
      }

      print('[PvP] loadMatch - status=${currentMatch!.status}, currentRound=${currentMatch!.currentRound}, player1=${currentMatch!.player1Id}, player2=${currentMatch!.player2Id}');

      // Déterminer si c'est notre tour
      _updateIsMyTurn();
      print('[PvP] loadMatch - isMyTurn=$isMyTurn, currentUserId=$currentUserId');

      // Charger le round actuel
      await loadRound(currentMatch!.currentRound);

      // S'abonner aux changements du match
      _watchMatch(matchId);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[PvP] ERROR loadMatch: $e');
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
    isMyTurn = currentMatch!.isPlayerTurn(currentUserId!);
  }

  void _watchMatch(String matchId) {
    _matchSubscription?.cancel();
    _matchSubscription = _pvpRepository.watchMatch(matchId).listen(
      (match) async {
        if (match != null) {
          final previousMatchRound = currentMatch?.currentRound;
          currentMatch = match;
          _updateIsMyTurn();

          final roundChanged = previousMatchRound != null &&
              previousMatchRound != match.currentRound;

          if (roundChanged && hasAnsweredAllQuestions) {
            // Le backend a avancé le round pendant qu'on attendait l'adversaire.
            // Recharger NOTRE round (celui qu'on vient de jouer) pour voir les résultats.
            // La transition vers le round suivant sera gérée par l'UI après affichage des résultats.
            currentRound = await _pvpRepository.getRound(matchId, previousMatchRound);
          } else if (currentRound == null && isMyTurn) {
            // C'est devenu notre tour et le round n'est pas chargé
            await loadRound(match.currentRound);
          } else if (currentRound != null &&
              currentRound!.roundNumber == match.currentRound) {
            // Même round - rafraîchir pour voir les données de l'adversaire
            currentRound = await _pvpRepository.getRound(matchId, match.currentRound);
          }

          notifyListeners();
        }
      },
      onError: (e) {
        print('Error watching match: $e');
      },
    );
  }

  /// Charge un round spécifique
  Future<void> loadRound(int roundNumber) async {
    if (currentMatch == null) return;

    try {
      print('[PvP] loadRound($roundNumber) - isMyTurn=$isMyTurn');
      currentRound = await _pvpRepository.getRound(currentMatch!.id, roundNumber);
      print('[PvP] loadRound - round=${currentRound != null ? 'found (${currentRound!.questionIds.length} questionIds)' : 'null'}');

      // Réinitialiser les réponses locales pour ce round
      myAnswers = [];
      currentQuestionIndex = 0;
      timeSpent = 0;
      roundSubmitted = false;
      consecutiveWrong = 0;

      if (currentRound == null) {
        // Nouveau round, le premier joueur doit le créer
        if (isMyTurn) {
          print('[PvP] loadRound - creating new round (startRound)');
          await startRound();
        } else {
          print('[PvP] loadRound - round null and not my turn, waiting');
        }
      } else {
        // Round existant, charger les questions
        print('[PvP] loadRound - loading questions from existing round');
        await _loadQuestionsFromRound();
      }

      print('[PvP] loadRound done - ${currentQuestions.length} questions loaded');
      notifyListeners();
    } catch (e) {
      print('[PvP] ERROR loadRound: $e');
      errorMessage = 'Error loading round: $e';
      notifyListeners();
    }
  }

  Future<void> _loadQuestionsFromRound() async {
    if (currentRound == null || currentRound!.questionIds.isEmpty) {
      print('[PvP] _loadQuestionsFromRound - skipped (round=${currentRound == null ? 'null' : 'empty questionIds'})');
      return;
    }

    final userStats = await _authRepository.getUserStats();
    final language = userStats?.preferredLanguage ?? 'en';
    print('[PvP] _loadQuestionsFromRound - fetching ${currentRound!.questionIds.length} questions (lang=$language)');

    currentQuestions = await _pvpRepository.getQuestionsByIds(
      currentRound!.questionIds,
      language,
    );
  }

  /// Démarre un nouveau round (génère les questions)
  Future<void> startRound() async {
    if (currentMatch == null) return;

    try {
      isLoading = true;
      notifyListeners();

      print('[PvP] startRound - generating questions');
      final userStats = await _authRepository.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      // Générer un large pool de questions
      currentQuestions = await _pvpRepository.getQuestionsForRound(language, 150);
      print('[PvP] startRound - got ${currentQuestions.length} questions');

      // Extraire les IDs des questions
      final questionIds = currentQuestions.map((q) => q.id).toList();

      // Créer le round dans la base de données
      final roundId = await _pvpRepository.createRound(
        currentMatch!.id,
        currentMatch!.currentRound,
        questionIds,
      );

      // Recharger le round
      currentRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentMatch!.currentRound,
      );

      // Réinitialiser l'état
      myAnswers = [];
      currentQuestionIndex = 0;
      timeSpent = 0;
      roundSubmitted = false;
      consecutiveWrong = 0;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[PvP] ERROR startRound: $e');
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
    int points = 0;
    if (isCorrect) {
      // Points selon la difficulté
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
      points = -1;
    }

    // Ajouter la réponse
    final answer = PvPAnswerModel(
      questionId: questionId,
      answerId: answerId,
      isCorrect: isCorrect,
      difficulty: difficulty,
      points: points,
      timeSpent: timeSpent,
    );

    myAnswers.add(answer);

    // Passer à la question suivante
    currentQuestionIndex++;

    notifyListeners();

    // Vérifier si toutes les questions ont été répondues
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

  /// Termine le round (temps écoulé) — soumet les réponses données sans skip
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

      // Calculer le score total
      final score = myRoundScore;

      // Soumettre les réponses
      await _pvpRepository.submitRoundAnswers(
        currentMatch!.id,
        currentRound!.roundNumber,
        currentUserId!,
        myAnswers,
        score,
      );

      // Recharger le round pour voir si l'adversaire a aussi joué
      currentRound = await _pvpRepository.getRound(
        currentMatch!.id,
        currentRound!.roundNumber,
      );

      // Recharger le match pour voir les mises à jour
      currentMatch = await _pvpRepository.getMatch(currentMatch!.id);

      // Vérifier si le match est terminé
      if (currentRound!.isRoundCompleted && currentMatch!.currentRound >= 3) {
        // Dernier round terminé, compléter le match
        await completeMatch();
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

      // Recharger le match pour obtenir les résultats finaux
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
      return null; // Égalité
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
    _matchFoundTimer?.cancel();

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
    matchFoundCountdown = 5;
    foundMatchId = null;
    isReadyToPlay = false;

    notifyListeners();
  }

  /// Récupère l'historique des matchs
  Future<List<PvPMatchModel>> getMatchHistory({int limit = 20}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      return await _pvpRepository.getMyMatches(userId, limit: limit);
    } catch (e) {
      print('Error getting match history: $e');
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
      print('Error getting active matches: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _stopSearchTimers();
    _matchFoundTimer?.cancel();
    super.dispose();
  }
}

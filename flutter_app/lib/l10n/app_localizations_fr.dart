// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Make Your Brain';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get dontHaveAccount => 'Pas de compte ? S\'inscrire';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get registrationSuccessful =>
      'Inscription réussie ! Vérifiez vos emails.';

  @override
  String get registrationFailed => 'Échec de l\'inscription';

  @override
  String get pleaseFillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get welcome => 'Bienvenue sur Make Your Brain !';

  @override
  String get startQuiz => 'Commencer le Quiz';

  @override
  String get selectTheme => 'Sélectionner un Thème';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Déconnexion';

  @override
  String get statistics => 'Statistiques';

  @override
  String get currentStreak => 'Série Actuelle';

  @override
  String get bestStreak => 'Meilleure';

  @override
  String get days => 'jours';

  @override
  String get questions => 'Questions';

  @override
  String get accuracy => 'précision';

  @override
  String get progressByTheme => 'Progression par Thème';

  @override
  String get noProgressYet => 'Aucune progression. Commencez un quiz !';

  @override
  String get level => 'Niveau';

  @override
  String get xp => 'XP';

  @override
  String get correct => 'correctes';

  @override
  String get preferredLanguage => 'Langue Préférée';

  @override
  String get languageUpdated => 'Langue mise à jour !';

  @override
  String get errorLoadingProfile => 'Erreur de chargement du profil';

  @override
  String get errorLoadingThemes => 'Erreur de chargement des thèmes';

  @override
  String get errorLoadingQuestions => 'Erreur de chargement des questions';

  @override
  String get quizCompleted => 'Quiz Terminé ! 🎉';

  @override
  String get yourScore => 'Votre score';

  @override
  String get backToThemes => 'Retour aux Thèmes';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get noQuestionsAvailable => 'Aucune question disponible pour ce thème';

  @override
  String get explanation => '💡 Explication :';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get selected => 'Sélectionné';

  @override
  String get myFavoriteThemes => 'Mes Thèmes Favoris';

  @override
  String get addTheme => 'Ajouter un Thème';

  @override
  String get allThemes => 'Tous les Thèmes';

  @override
  String get noFavoriteThemes => 'Aucun thème favori !';

  @override
  String get tapAddTheme => 'Appuyez sur \"Ajouter un Thème\" pour commencer';

  @override
  String get aboutThisTheme => 'À propos de ce thème';

  @override
  String get moreFeaturesComingSoon =>
      '🚀 Plus de fonctionnalités bientôt !\nClassement, Défi Chrono, Mode Versus...';

  @override
  String get removeFromFavorites => 'Retirer des favoris ?';

  @override
  String removeFavoriteConfirm(Object themeName) {
    return 'Retirer $themeName de vos thèmes favoris ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Retirer';

  @override
  String get allThemesInFavorites =>
      'Vous avez déjà tous les thèmes en favoris ! 🎉';

  @override
  String get manageFavoriteThemes => 'Gérer les Thèmes Favoris';

  @override
  String get noFavoriteThemesProfile => 'Aucun thème favori pour le moment.';

  @override
  String get correctAnswer => '✅ Correct !';

  @override
  String get incorrectAnswer => '❌ Incorrect';

  @override
  String get continueButton => 'Continuer →';

  @override
  String get leaderboard => 'Classement';

  @override
  String get viewLeaderboard => 'Voir le Classement';

  @override
  String get global => 'Mondial';

  @override
  String get thisWeek => 'Cette Semaine';

  @override
  String get yourGlobalRank => 'Votre Rang Mondial';

  @override
  String get yourWeeklyRank => 'Votre Rang Hebdo';

  @override
  String get yourThemeRank => 'Votre Rang';

  @override
  String get points => 'pts';

  @override
  String get loadingAdd => 'Chargement d\'une pub....';

  @override
  String get winLifes => '+2 Vies ! Continuez à jouer';

  @override
  String get noLife => 'Plus de vie !';

  @override
  String get needLifes => 'Vous avez besoin de vie pour jouer';

  @override
  String get nextLife => 'Prochaine vie dans :';

  @override
  String get orWatchAdd => 'Ou regarder une pub pour gagner 2 vies';

  @override
  String get close => 'fermer';

  @override
  String get watchAdd => 'Regarder une pub(+2 ❤️)';

  @override
  String get getMoreLifes => 'Avoir plus de vies';

  @override
  String get currentLife => 'Vie actuelle';

  @override
  String get timedQuiz => 'Quiz Chronométré';

  @override
  String get chooseYourTime => 'Choisissez votre temps';

  @override
  String get timesUp => 'Temps écoulé !';

  @override
  String get seconds30 => '30 secondes';

  @override
  String get seconds45 => '45 secondes';

  @override
  String get seconds60 => '1 minute';

  @override
  String get timedQuizDescription =>
      'Ce mode utilise 1 vie pour participer. Les erreurs ne font pas perdre de vies.';

  @override
  String get timeBonus => 'Bonus Temps';

  @override
  String get questionsAnswered => 'Questions répondues';

  @override
  String themesSelected(int count) {
    return '$count thèmes sélectionnés';
  }

  @override
  String get maxThemesReached => 'Maximum 3 thèmes autorisés';

  @override
  String get maxThemesMessage =>
      'Vous ne pouvez avoir que 3 thèmes favoris. Supprimez-en un pour en ajouter un autre.';

  @override
  String get pvpArena => 'Arène PvP';

  @override
  String get rating => 'Classement';

  @override
  String get wins => 'Victoires';

  @override
  String get losses => 'Défaites';

  @override
  String get draws => 'Nuls';

  @override
  String get winRate => 'Taux de victoire';

  @override
  String get findMatch => 'Trouver un Match';

  @override
  String get searchingMatch => 'Recherche...';

  @override
  String get matchHistory => 'Historique des Matchs';

  @override
  String get noMatchesYet => 'Aucun match pour le moment';

  @override
  String get startFirstMatch =>
      'Lancez votre premier match pour voir votre historique';

  @override
  String get victory => 'Victoire';

  @override
  String get defeat => 'Défaite';

  @override
  String get draw => 'Nul';

  @override
  String get cancelled => 'Annulé';

  @override
  String get inProgress => 'En cours';

  @override
  String get score => 'Score';

  @override
  String get waitingForOpponent => 'En attente de l\'adversaire...';

  @override
  String get opponentFinished => 'L\'adversaire a terminé !';

  @override
  String roundComplete(int round) {
    return 'Round $round Terminé !';
  }

  @override
  String get nextRoundStarting => 'Prochain round...';

  @override
  String get finalResultsComing => 'Résultats finaux...';

  @override
  String get backToMenu => 'Retour au Menu';

  @override
  String get you => 'Vous';

  @override
  String get opponent => 'Adversaire';

  @override
  String get searchingOpponent => 'Recherche d\'un adversaire...';

  @override
  String get round => 'Round';

  @override
  String get pvpRating => 'Classement PvP';

  @override
  String get waitingForPlayer => 'En attente d\'un autre joueur...';

  @override
  String get noPlayerFoundYet =>
      'Aucun joueur trouvé pour le moment.\nContinuez à patienter...';

  @override
  String get searchTakingLong =>
      'La recherche prend du temps.\nPeu de joueurs sont en ligne actuellement.';

  @override
  String get matchFound => 'Match trouvé !';

  @override
  String matchStartingIn(int seconds) {
    return 'Début dans ${seconds}s...';
  }

  @override
  String get opponentsTurn => 'Tour de l\'adversaire';

  @override
  String get yourTurn => 'Votre tour';

  @override
  String get waitingOpponentTurn => 'En attente du tour de l\'adversaire...';

  @override
  String get activeMatches => 'Matchs en cours';

  @override
  String get resumeMatch => 'Reprendre';

  @override
  String get username => 'Pseudo';

  @override
  String get usernameAvailable => 'Pseudo disponible !';

  @override
  String get usernameNotAvailable => 'Ce pseudo n\'est pas disponible';

  @override
  String get usernameTaken => 'Ce pseudo est déjà pris';

  @override
  String get usernameInvalid => 'Pseudo invalide';

  @override
  String get usernameMinLength => 'Minimum 3 caractères';

  @override
  String get usernameMaxLength => 'Maximum 20 caractères';

  @override
  String get usernameAllowedChars => 'Lettres, chiffres et _ uniquement';

  @override
  String get changeUsername => 'Changer de pseudo';

  @override
  String get currentUsername => 'Pseudo actuel';

  @override
  String get newUsername => 'Nouveau pseudo';

  @override
  String get usernameUpdated => 'Pseudo mis à jour !';

  @override
  String get usernameUpdateFailed => 'Échec de la mise à jour du pseudo';
}

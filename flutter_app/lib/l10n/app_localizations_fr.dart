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
}

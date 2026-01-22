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
  String get accuracy => 'Précision';

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
}

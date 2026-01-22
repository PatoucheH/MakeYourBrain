// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Make Your Brain';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get registrationSuccessful =>
      'Registration successful! Please check your email.';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get welcome => 'Welcome to Make Your Brain!';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get selectTheme => 'Select a Theme';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get statistics => 'Statistics';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get bestStreak => 'Best';

  @override
  String get days => 'days';

  @override
  String get questions => 'Questions';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get progressByTheme => 'Progress by Theme';

  @override
  String get noProgressYet => 'No progress yet. Start a quiz!';

  @override
  String get level => 'Level';

  @override
  String get xp => 'XP';

  @override
  String get correct => 'correct';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get languageUpdated => 'Language updated!';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get errorLoadingThemes => 'Error loading themes';

  @override
  String get errorLoadingQuestions => 'Error loading questions';

  @override
  String get quizCompleted => 'Quiz Completed! 🎉';

  @override
  String get yourScore => 'Your score';

  @override
  String get backToThemes => 'Back to Themes';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noQuestionsAvailable => 'No questions available for this theme';

  @override
  String get explanation => '💡 Explanation:';

  @override
  String get createAccount => 'Create Account';

  @override
  String get selected => 'Selected';
}

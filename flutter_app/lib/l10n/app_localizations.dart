import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Make Your Brain'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please check your email.'**
  String get registrationSuccessful;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Make Your Brain!'**
  String get welcome;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuiz;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select a Theme'**
  String get selectTheme;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get bestStreak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'accuracy'**
  String get accuracy;

  /// No description provided for @progressByTheme.
  ///
  /// In en, this message translates to:
  /// **'Progress by Theme'**
  String get progressByTheme;

  /// No description provided for @noProgressYet.
  ///
  /// In en, this message translates to:
  /// **'No progress yet. Start a quiz!'**
  String get noProgressYet;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'correct'**
  String get correct;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated!'**
  String get languageUpdated;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @errorLoadingThemes.
  ///
  /// In en, this message translates to:
  /// **'Error loading themes'**
  String get errorLoadingThemes;

  /// No description provided for @errorLoadingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Error loading questions'**
  String get errorLoadingQuestions;

  /// No description provided for @quizCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quiz Completed! 🎉'**
  String get quizCompleted;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get yourScore;

  /// No description provided for @backToThemes.
  ///
  /// In en, this message translates to:
  /// **'Back to Themes'**
  String get backToThemes;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No questions available for this theme'**
  String get noQuestionsAvailable;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'💡 Explanation:'**
  String get explanation;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @myFavoriteThemes.
  ///
  /// In en, this message translates to:
  /// **'My Favorite Themes'**
  String get myFavoriteThemes;

  /// No description provided for @addTheme.
  ///
  /// In en, this message translates to:
  /// **'Add Theme'**
  String get addTheme;

  /// No description provided for @allThemes.
  ///
  /// In en, this message translates to:
  /// **'All Themes'**
  String get allThemes;

  /// No description provided for @noFavoriteThemes.
  ///
  /// In en, this message translates to:
  /// **'No favorite themes yet!'**
  String get noFavoriteThemes;

  /// No description provided for @tapAddTheme.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Theme\" to get started'**
  String get tapAddTheme;

  /// No description provided for @aboutThisTheme.
  ///
  /// In en, this message translates to:
  /// **'About this theme'**
  String get aboutThisTheme;

  /// No description provided for @moreFeaturesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'🚀 More features coming soon!\nLeaderboard, Time Challenge, Versus Mode...'**
  String get moreFeaturesComingSoon;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites?'**
  String get removeFromFavorites;

  /// No description provided for @removeFavoriteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {themeName} from your favorite themes?'**
  String removeFavoriteConfirm(Object themeName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @allThemesInFavorites.
  ///
  /// In en, this message translates to:
  /// **'You already have all themes in your favorites! 🎉'**
  String get allThemesInFavorites;

  /// No description provided for @manageFavoriteThemes.
  ///
  /// In en, this message translates to:
  /// **'Manage Favorite Themes'**
  String get manageFavoriteThemes;

  /// No description provided for @noFavoriteThemesProfile.
  ///
  /// In en, this message translates to:
  /// **'No favorite themes yet.'**
  String get noFavoriteThemesProfile;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'✅ Correct!'**
  String get correctAnswer;

  /// No description provided for @incorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'❌ Incorrect'**
  String get incorrectAnswer;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get continueButton;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @viewLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'View Leaderboard'**
  String get viewLeaderboard;

  /// No description provided for @global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get global;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @yourGlobalRank.
  ///
  /// In en, this message translates to:
  /// **'Your Global Rank'**
  String get yourGlobalRank;

  /// No description provided for @yourWeeklyRank.
  ///
  /// In en, this message translates to:
  /// **'Your Weekly Rank'**
  String get yourWeeklyRank;

  /// No description provided for @yourThemeRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourThemeRank;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points;

  /// No description provided for @loadingAdd.
  ///
  /// In en, this message translates to:
  /// **'Loading add ....'**
  String get loadingAdd;

  /// No description provided for @winLifes.
  ///
  /// In en, this message translates to:
  /// **'+2 Lives! Keep playing!'**
  String get winLifes;

  /// No description provided for @noLife.
  ///
  /// In en, this message translates to:
  /// **'No Lives Left!'**
  String get noLife;

  /// No description provided for @needLifes.
  ///
  /// In en, this message translates to:
  /// **'You need lives to play.'**
  String get needLifes;

  /// No description provided for @nextLife.
  ///
  /// In en, this message translates to:
  /// **'Next life in:'**
  String get nextLife;

  /// No description provided for @orWatchAdd.
  ///
  /// In en, this message translates to:
  /// **'Or watch an add to get +2 lives instantly!'**
  String get orWatchAdd;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get close;

  /// No description provided for @watchAdd.
  ///
  /// In en, this message translates to:
  /// **'Watch Add (+2 ❤️)'**
  String get watchAdd;

  /// No description provided for @getMoreLifes.
  ///
  /// In en, this message translates to:
  /// **'Get more lifes'**
  String get getMoreLifes;

  /// No description provided for @currentLife.
  ///
  /// In en, this message translates to:
  /// **'Current life'**
  String get currentLife;

  /// No description provided for @timedQuiz.
  ///
  /// In en, this message translates to:
  /// **'Timed Quiz'**
  String get timedQuiz;

  /// No description provided for @chooseYourTime.
  ///
  /// In en, this message translates to:
  /// **'Choose your time'**
  String get chooseYourTime;

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timesUp;

  /// No description provided for @seconds30.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get seconds30;

  /// No description provided for @seconds45.
  ///
  /// In en, this message translates to:
  /// **'45 seconds'**
  String get seconds45;

  /// No description provided for @seconds60.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get seconds60;

  /// No description provided for @timedQuizDescription.
  ///
  /// In en, this message translates to:
  /// **'This mode uses 1 life to participate. Mistakes don\'t cost extra lives.'**
  String get timedQuizDescription;

  /// No description provided for @timeBonus.
  ///
  /// In en, this message translates to:
  /// **'Time Bonus'**
  String get timeBonus;

  /// No description provided for @questionsAnswered.
  ///
  /// In en, this message translates to:
  /// **'Questions answered'**
  String get questionsAnswered;

  /// No description provided for @themesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} themes selected'**
  String themesSelected(int count);

  /// No description provided for @maxThemesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 themes allowed'**
  String get maxThemesReached;

  /// No description provided for @maxThemesMessage.
  ///
  /// In en, this message translates to:
  /// **'You can only have 3 favorite themes. Remove one to add another.'**
  String get maxThemesMessage;

  /// No description provided for @pvpArena.
  ///
  /// In en, this message translates to:
  /// **'PvP Arena'**
  String get pvpArena;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// No description provided for @draws.
  ///
  /// In en, this message translates to:
  /// **'Draws'**
  String get draws;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// No description provided for @findMatch.
  ///
  /// In en, this message translates to:
  /// **'Find Match'**
  String get findMatch;

  /// No description provided for @searchingMatch.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingMatch;

  /// No description provided for @matchHistory.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get matchHistory;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// No description provided for @startFirstMatch.
  ///
  /// In en, this message translates to:
  /// **'Start your first match to see your history'**
  String get startFirstMatch;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get defeat;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @waitingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent...'**
  String get waitingForOpponent;

  /// No description provided for @opponentFinished.
  ///
  /// In en, this message translates to:
  /// **'Opponent finished!'**
  String get opponentFinished;

  /// No description provided for @roundComplete.
  ///
  /// In en, this message translates to:
  /// **'Round {round} Complete!'**
  String roundComplete(int round);

  /// No description provided for @nextRoundStarting.
  ///
  /// In en, this message translates to:
  /// **'Next round starting...'**
  String get nextRoundStarting;

  /// No description provided for @finalResultsComing.
  ///
  /// In en, this message translates to:
  /// **'Final results coming...'**
  String get finalResultsComing;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get backToMenu;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @searchingOpponent.
  ///
  /// In en, this message translates to:
  /// **'Searching for opponent...'**
  String get searchingOpponent;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @pvpRating.
  ///
  /// In en, this message translates to:
  /// **'PvP Rating'**
  String get pvpRating;

  /// No description provided for @waitingForPlayer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for another player...'**
  String get waitingForPlayer;

  /// No description provided for @noPlayerFoundYet.
  ///
  /// In en, this message translates to:
  /// **'No player found yet.\nKeep waiting...'**
  String get noPlayerFoundYet;

  /// No description provided for @searchTakingLong.
  ///
  /// In en, this message translates to:
  /// **'Search is taking a while.\nFew players are online right now.'**
  String get searchTakingLong;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username available!'**
  String get usernameAvailable;

  /// No description provided for @usernameNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This username is not available'**
  String get usernameNotAvailable;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get usernameTaken;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid username'**
  String get usernameInvalid;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 characters'**
  String get usernameMinLength;

  /// No description provided for @usernameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum 20 characters'**
  String get usernameMaxLength;

  /// No description provided for @usernameAllowedChars.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers and _ only'**
  String get usernameAllowedChars;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get changeUsername;

  /// No description provided for @currentUsername.
  ///
  /// In en, this message translates to:
  /// **'Current username'**
  String get currentUsername;

  /// No description provided for @newUsername.
  ///
  /// In en, this message translates to:
  /// **'New username'**
  String get newUsername;

  /// No description provided for @usernameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Username updated!'**
  String get usernameUpdated;

  /// No description provided for @usernameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update username'**
  String get usernameUpdateFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

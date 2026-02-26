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
  String get accuracy => 'accuracy';

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

  @override
  String get myFavoriteThemes => 'My Favorite Themes';

  @override
  String get addTheme => 'Add Theme';

  @override
  String get allThemes => 'All Themes';

  @override
  String get noFavoriteThemes => 'No favorite themes yet!';

  @override
  String get tapAddTheme => 'Tap \"Add Theme\" to get started';

  @override
  String get aboutThisTheme => 'About this theme';

  @override
  String get moreFeaturesComingSoon =>
      'More features coming soon!\nLeaderboard, Time Challenge, Versus Mode...';

  @override
  String get removeFromFavorites => 'Remove from favorites?';

  @override
  String removeFavoriteConfirm(Object themeName) {
    return 'Remove $themeName from your favorite themes?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get allThemesInFavorites =>
      'You already have all themes in your favorites! 🎉';

  @override
  String get manageFavoriteThemes => 'Manage Favorite Themes';

  @override
  String get noFavoriteThemesProfile => 'No favorite themes yet.';

  @override
  String get correctAnswer => '✅ Correct!';

  @override
  String get incorrectAnswer => '❌ Incorrect';

  @override
  String get continueButton => 'Continue →';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get viewLeaderboard => 'View Leaderboard';

  @override
  String get global => 'Global';

  @override
  String get thisWeek => 'This Week';

  @override
  String get yourGlobalRank => 'Your Global Rank';

  @override
  String get yourWeeklyRank => 'Your Weekly Rank';

  @override
  String get yourThemeRank => 'Your Rank';

  @override
  String get points => 'pts';

  @override
  String get loadingAdd => 'Loading add ....';

  @override
  String get winLifes => '+2 Lives! Keep playing!';

  @override
  String get noLife => 'No Lives Left!';

  @override
  String get needLifes => 'You need lives to play.';

  @override
  String get nextLife => 'Next life in:';

  @override
  String get orWatchAdd => 'Or watch an add to get +2 lives instantly!';

  @override
  String get close => 'close';

  @override
  String get watchAdd => 'Watch Add (+2 ❤️)';

  @override
  String get getMoreLifes => 'Get more lifes';

  @override
  String get currentLife => 'Current life';

  @override
  String get timedQuiz => 'Timed Quiz';

  @override
  String get chooseYourTime => 'Choose your time';

  @override
  String get timesUp => 'Time\'s up!';

  @override
  String get seconds30 => '30 seconds';

  @override
  String get seconds45 => '45 seconds';

  @override
  String get seconds60 => '1 minute';

  @override
  String get timedQuizDescription =>
      'This mode uses 1 life to participate. Mistakes don\'t cost extra lives.';

  @override
  String get timeBonus => 'Time Bonus';

  @override
  String get questionsAnswered => 'Questions answered';

  @override
  String themesSelected(int count) {
    return '$count themes selected';
  }

  @override
  String get maxThemesReached => 'Maximum 3 themes allowed';

  @override
  String get maxThemesMessage =>
      'You can only have 3 favorite themes. Remove one to add another.';

  @override
  String get pvpArena => 'PvP Arena';

  @override
  String get rating => 'Rating';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get draws => 'Draws';

  @override
  String get winRate => 'Win Rate';

  @override
  String get findMatch => 'Find Match';

  @override
  String get searchingMatch => 'Searching...';

  @override
  String get matchHistory => 'Match History';

  @override
  String get noMatchesYet => 'No matches yet';

  @override
  String get startFirstMatch => 'Start your first match to see your history';

  @override
  String get victory => 'Victory';

  @override
  String get defeat => 'Defeat';

  @override
  String get draw => 'Draw';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get inProgress => 'In Progress';

  @override
  String get score => 'Score';

  @override
  String get waitingForOpponent => 'Waiting for opponent...';

  @override
  String get opponentFinished => 'Opponent finished!';

  @override
  String roundComplete(int round) {
    return 'Round $round Complete!';
  }

  @override
  String get nextRoundStarting => 'Next round starting...';

  @override
  String get finalResultsComing => 'Final results coming...';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get you => 'You';

  @override
  String get opponent => 'Opponent';

  @override
  String get searchingOpponent => 'Searching for opponent...';

  @override
  String get round => 'Round';

  @override
  String get pvpRating => 'PvP Rating';

  @override
  String get waitingForPlayer => 'Waiting for another player...';

  @override
  String get noPlayerFoundYet => 'No player found yet.\nKeep waiting...';

  @override
  String get searchTakingLong =>
      'Search is taking a while.\nFew players are online right now.';

  @override
  String get matchFound => 'Match found!';

  @override
  String matchStartingIn(int seconds) {
    return 'Starting in ${seconds}s...';
  }

  @override
  String yourTurnAgainst(String opponent) {
    return 'It\'s your turn against $opponent!';
  }

  @override
  String get tapToPlay => 'Tap to play';

  @override
  String get opponentsTurn => 'Opponent\'s turn';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get waitingOpponentTurn => 'Waiting for opponent to play...';

  @override
  String get activeMatches => 'Active Matches';

  @override
  String get resumeMatch => 'Resume';

  @override
  String get username => 'Username';

  @override
  String get usernameAvailable => 'Username available!';

  @override
  String get usernameNotAvailable => 'This username is not available';

  @override
  String get usernameTaken => 'This username is already taken';

  @override
  String get usernameInvalid => 'Invalid username';

  @override
  String get usernameMinLength => 'Minimum 3 characters';

  @override
  String get usernameMaxLength => 'Maximum 20 characters';

  @override
  String get usernameAllowedChars => 'Letters, numbers and _ only';

  @override
  String get changeUsername => 'Change username';

  @override
  String get currentUsername => 'Current username';

  @override
  String get newUsername => 'New username';

  @override
  String get usernameUpdated => 'Username updated!';

  @override
  String get usernameUpdateFailed => 'Failed to update username';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get searchUsers => 'Search users';

  @override
  String get searchByUsernameOrEmail => 'Search by username or email';

  @override
  String get noFollowersYet => 'No followers yet';

  @override
  String get noFollowingYet => 'Not following anyone yet';

  @override
  String get followingLeaderboard => 'Following';

  @override
  String get userNotFound => 'No users found';

  @override
  String get profileSummary => 'Profile';

  @override
  String get followSuccess => 'You are now following this user';

  @override
  String get unfollowSuccess => 'You unfollowed this user';

  @override
  String get cannotFollowYourself => 'You cannot follow yourself';

  @override
  String get social => 'Social';

  @override
  String get viewAll => 'View all';

  @override
  String selectThemeForRound(int round) {
    return 'Select Theme for Round $round';
  }

  @override
  String get yourFavoriteThemes => 'Your Favorite Themes';

  @override
  String get allThemesAvailable => 'All Themes';

  @override
  String get waitingForThemeSelection =>
      'Waiting for opponent to choose theme...';

  @override
  String get randomTheme => 'Random Theme';

  @override
  String get chooseTheme => 'Choose a theme for this round';

  @override
  String get betaTitle => 'Beta Version';

  @override
  String get betaMessage =>
      'This app is still in Beta. Some bugs may appear.\n\nThank you for your patience! If you encounter any issue, please report it to:';

  @override
  String get betaEmail => 'hugo.patou@hotmail.com';

  @override
  String get thanks => 'Thank you!';

  @override
  String get understood => 'Got it!';

  @override
  String get matchFoundWaiting => 'Match found! Opponent plays first.';

  @override
  String roundAgainst(int round, String opponent) {
    return 'Round $round vs $opponent';
  }

  @override
  String get goToMatch => 'Go to match';

  @override
  String matchEndedAgainst(String opponent) {
    return 'Match ended vs $opponent';
  }

  @override
  String get youWon => 'You won!';

  @override
  String get youLost => 'You lost!';

  @override
  String get matchDrew => 'It\'s a draw!';

  @override
  String get seeResults => 'See results';

  @override
  String get loadMore => 'Load more';

  @override
  String get home => 'Home';

  @override
  String get loadingQuestions => 'Loading questions...';

  @override
  String get back => 'Back';

  @override
  String get dailyQuiz => 'Daily Quiz';

  @override
  String get todaysConcept => 'Today\'s concept';

  @override
  String get xpTriple => 'XP x3';

  @override
  String get noLivesNeeded => 'No lives needed';

  @override
  String get dailyQuizCompleted => 'Already completed!';

  @override
  String get startDailyQuiz => 'Start Quiz';

  @override
  String get dailyQuizInfo =>
      'The daily quiz earns you 3x more XP in this theme! No lives are needed and mistakes don\'t cost lives.';

  @override
  String get noDailyQuiz => 'Come back tomorrow for a new concept!';
}

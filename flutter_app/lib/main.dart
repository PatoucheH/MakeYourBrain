import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'shared/services/supabase_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/quiz/presentation/pages/home_page.dart';
import 'features/quiz/presentation/pages/theme_preferences_page.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/quiz/data/repositories/theme_preferences_repository.dart';
import 'core/providers/language_provider.dart';
import 'core/theme/app_colors.dart';
import 'l10n/app_localizations.dart';
import 'features/lives/data/providers/lives_provider.dart';
import 'features/pvp/data/providers/pvp_provider.dart';
import 'features/pvp/presentation/widgets/matchmaking_overlay.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => LivesProvider()),
        ChangeNotifierProvider(create: (context) => PvPProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Make Your Brain',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.brainPurple,
              primary: AppColors.brainPurple,
              secondary: AppColors.brainLightPurple,
              surface: AppColors.backgroundLight,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.backgroundLight,

            // AppBar Theme
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.brainPurple,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                color: AppColors.brainPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: const IconThemeData(
                color: AppColors.brainPurple,
              ),
            ),

            // Card Theme
            cardTheme: CardThemeData(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadowColor: AppColors.brainPurple.withValues(alpha:0.1),
            ),

            // Elevated Button Theme
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brainPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Text Button Theme
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brainPurple,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Outlined Button Theme
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brainPurple,
                side: const BorderSide(color: AppColors.brainPurple, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Input Decoration Theme
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.brainPurple.withValues(alpha:0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.brainPurple.withValues(alpha:0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.brainPurple, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha:0.7)),
            ),

            // Chip Theme
            chipTheme: ChipThemeData(
              backgroundColor: AppColors.brainPurpleLight,
              labelStyle: const TextStyle(
                color: AppColors.brainPurple,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            // Dialog Theme
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titleTextStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Snackbar Theme
            snackBarTheme: SnackBarThemeData(
              backgroundColor: AppColors.brainPurple,
              contentTextStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              behavior: SnackBarBehavior.floating,
            ),

            // Progress Indicator Theme
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: AppColors.brainPurple,
              linearTrackColor: AppColors.brainPurpleLight,
            ),

            // Divider Theme
            dividerTheme: DividerThemeData(
              color: AppColors.brainPurple.withValues(alpha:0.1),
              thickness: 1,
            ),
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
          ],
          locale: Locale(languageProvider.currentLanguage),
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                const MatchmakingOverlay(),
              ],
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Vérifier le statut de la queue PvP au retour dans l'app
      context.read<PvPProvider>().checkQueueStatusOnResume();
    }
  }

  Future<void> _initialize() async {
    await context.read<LanguageProvider>().initialize();
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    return const AuthChecker();
  }
}

// Splash Screen avec le branding
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animé
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.cardShadow,
                ),
                child: Image.asset(
                  'assets/branding/logo/brainly_logo.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Make Your Brain',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brainPurple,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brainPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final _authRepo = AuthRepository();
  final _prefsRepo = ThemePreferencesRepository();
  bool _isChecking = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _checkAuthAndOnboarding();
  }

  Future<void> _checkAuthAndOnboarding() async {
    if (!_authRepo.isLoggedIn()) {
      setState(() {
        _destination = const LoginPage();
        _isChecking = false;
      });
      return;
    }

    try {
      final userId = _authRepo.getCurrentUserId()!;
      final hasCompletedOnboarding = await _prefsRepo.hasCompletedOnboarding(userId);

      setState(() {
        _destination = hasCompletedOnboarding
            ? const HomePage()
            : const ThemePreferencesPage();
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _destination = const ThemePreferencesPage();
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SplashScreen();
    }

    return _destination ?? const LoginPage();
  }
}

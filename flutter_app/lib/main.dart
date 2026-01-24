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
import '../l10n/app_localizations.dart';
import 'features/lives/data/providers/lives_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => LivesProvider()),
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
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

class _AuthGateState extends State<AuthGate> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await context.read<LanguageProvider>().initialize();
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const AuthChecker();
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

    // User connecté, vérifier si onboarding fait
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _destination ?? const LoginPage();
  }
}
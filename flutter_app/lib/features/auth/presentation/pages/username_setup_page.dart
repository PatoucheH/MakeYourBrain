import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../quiz/data/repositories/theme_preferences_repository.dart';
import '../../../quiz/presentation/pages/home_page.dart';
import '../../../quiz/presentation/pages/theme_preferences_page.dart';

class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({super.key});

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final _authRepo = AuthRepository();
  final _prefsRepo = ThemePreferencesRepository();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
      });
      return;
    }

    final normalized = username.toLowerCase().trim();
    final l10n = AppLocalizations.of(context)!;

    if (normalized.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = l10n.usernameMinLength;
      });
      return;
    }

    if (normalized.length > 20) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = l10n.usernameMaxLength;
      });
      return;
    }

    final validPattern = RegExp(r'^[a-z0-9_]+$');
    if (!validPattern.hasMatch(normalized)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = l10n.usernameAllowedChars;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await _authRepo.isUsernameAvailable(normalized);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingUsername = false;
          _usernameError = isAvailable ? null : l10n.usernameTaken;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameError = l10n.usernameCheckFailed;
        });
      }
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;

    if (_isUsernameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_usernameError ?? l10n.usernameNotAvailable)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authRepo.updateUsername(_usernameController.text.trim());
      if (!mounted) return;

      if (success) {
        final userId = _authRepo.getCurrentUserId();
        if (userId == null) return;
        final hasCompletedOnboarding = await _prefsRepo.hasCompletedOnboarding(userId);
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => hasCompletedOnboarding
                ? const HomePage()
                : const ThemePreferencesPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.usernameUpdateFailed)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.usernameUpdateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.backgroundGradientOf(context),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // Mascot
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardColorOf(context),
                        shape: BoxShape.circle,
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Image.asset(
                        'assets/branding/mascot/brainly_thinking.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person_outline,
                          size: 80,
                          color: AppColors.brainPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.brainPurple, AppColors.brainLightPurple],
                      ).createShader(bounds),
                      child: Text(
                        l10n.chooseYourUsername,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.chooseYourUsernameHint,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardColorOf(context),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildUsernameField(l10n),
                          const SizedBox(height: 24),

                          // Confirm button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppColors.primaryGradient,
                              boxShadow: AppColors.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: (_isLoading || _isUsernameAvailable != true)
                                  ? null
                                  : _confirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      l10n.confirmUsername,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField(AppLocalizations l10n) {
    Widget? suffixIcon;
    Color? borderColor;

    if (_isCheckingUsername) {
      suffixIcon = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_isUsernameAvailable == true) {
      suffixIcon = const Icon(Icons.check_circle, color: AppColors.success);
      borderColor = AppColors.success;
    } else if (_isUsernameAvailable == false) {
      suffixIcon = const Icon(Icons.cancel, color: AppColors.error);
      borderColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _usernameController,
          style: TextStyle(fontSize: 16),
          onChanged: _checkUsername,
          decoration: InputDecoration(
            labelText: l10n.username,
            hintText: 'ex: brain_master42',
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.brainPurple),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.brainPurpleLight.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: borderColor != null
                  ? BorderSide(color: borderColor, width: 2)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.brainPurple,
                width: 2,
              ),
            ),
          ),
        ),
        if (_usernameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              _usernameError!,
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        if (_isUsernameAvailable == true)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              l10n.usernameAvailable,
              style: TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

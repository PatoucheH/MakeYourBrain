import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../main.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _repository = AuthRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  Timer? _oauthTimer;
  StreamSubscription? _oauthSubscription;

  void _resetOAuthState() {
    _oauthTimer?.cancel();
    _oauthSubscription?.cancel();
    _oauthTimer = null;
    _oauthSubscription = null;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseFillAllFields)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repository.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthChecker()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Future<void> _loginWithFacebook() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final success = await _repository.signInWithFacebook();
  //     if (!success) {
  //       if (mounted) {
  //         setState(() => _isLoading = false);
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Could not open Facebook login')),
  //         );
  //       }
  //       return;
  //     }
  //     final subscription = _repository.authStateChanges.listen((state) {
  //       if (state.event == AuthChangeEvent.signedIn && mounted) {
  //         Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (context) => const HomePage()),
  //         );
  //       }
  //     });
  //     await Future.delayed(const Duration(seconds: 60));
  //     subscription.cancel();
  //     if (mounted && !_repository.isLoggedIn()) {
  //       setState(() => _isLoading = false);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Login timeout. Please try again.')),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Facebook login error: $e')),
  //       );
  //     }
  //   }
  // }

  Future<void> _startOAuthFlow(Future<bool> Function() signIn, String failMessage) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final success = await signIn();

      if (!success) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failMessage)),
          );
        }
        return;
      }

      // Listen for successful sign-in via deep link.
      // Navigate to AuthChecker (not HomePage directly) so onboarding is checked.
      _oauthSubscription = _repository.authStateChanges.listen((state) {
        if (state.event == AuthChangeEvent.signedIn && mounted) {
          _oauthTimer?.cancel();
          _oauthSubscription?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthChecker()),
          );
        }
      });

      // Reset after 30s if no deep link received.
      _oauthTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && !_repository.isLoggedIn()) {
          _resetOAuthState();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.loginTimeout)),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginFailed)),
        );
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    await _startOAuthFlow(
      _repository.signInWithGoogle,
      l10n.couldNotOpenGoogleLogin,
    );
  }

  Future<void> _loginWithApple() async {
    final l10n = AppLocalizations.of(context)!;
    await _startOAuthFlow(
      _repository.signInWithApple,
      l10n.couldNotOpenAppleLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.06),

                  // Logo and mascot
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Image.asset(
                      'assets/branding/mascot/brainly_happy.png',
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.brainPurple, AppColors.brainLightPurple],
                    ).createShader(bounds),
                    child: Text(
                      l10n.appName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcome,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.05),

                  // Sign-in card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Google button
                        _buildSocialButton(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          icon: Icons.g_mobiledata,
                          label: l10n.continueWithGoogle,
                          color: const Color(0xFF4285F4),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 12),

                        // Apple button
                        _buildSocialButton(
                          onPressed: _isLoading ? null : _loginWithApple,
                          icon: Icons.apple,
                          label: l10n.continueWithApple,
                          color: const Color(0xFF000000),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.brainPurple.withValues(alpha:0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                l10n.orDivider,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.brainPurple.withValues(alpha:0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: l10n.email,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: l10n.password,
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: AppColors.primaryGradient,
                            boxShadow: AppColors.buttonShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
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
                                    l10n.login,
                                    style: const TextStyle(
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
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.dontHaveAccountPrefix} ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.register,
                            style: const TextStyle(
                              color: AppColors.brainPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.brainPurple),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.brainPurpleLight.withValues(alpha:0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brainPurple, width: 2),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            // Icon on the left
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, size: 24),
            // Text centered in the remaining space
            Expanded(
              child: Center(
                child: Text(
                  isLoading ? AppLocalizations.of(context)!.connecting : label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // Mirror of the icon to balance the optical centering
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oauthTimer?.cancel();
    _oauthSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

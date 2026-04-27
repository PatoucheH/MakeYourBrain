import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
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

  Future<void> _showForgotPasswordDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        repository: _repository,
      ),
    );

    if (!mounted) return;
    if (sent == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.resetPasswordSent),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
      // Navigation handled globally by AuthGate via authStateChanges listener
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginFailed)),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startOAuthFlow(
    Future<bool> Function() signIn,
    String failMessage,
  ) async {
    setState(() => _isLoading = true);
    try {
      final success = await signIn();
      // Always reset loading after the OAuth browser opens (or fails to open).
      // On iOS, signInWithOAuth returns true as soon as the browser launches —
      // it does NOT wait for the user to complete or cancel.
      // If auth completes, AuthGate handles navigation via authStateChanges.
      // If the user cancels, loading is reset immediately — no infinite spinner.
      if (mounted) setState(() => _isLoading = false);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginFailed)),
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
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradientOf(context),
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
                      color: AppColors.cardColorOf(context),
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
                      style: TextStyle(
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
                      color: AppColors.textSecondaryOf(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.05),

                  // Sign-in card
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
                                      AppColors.brainPurple.withValues(alpha: 0.3),
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
                                  color: AppColors.textSecondaryOf(context),
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
                                      AppColors.brainPurple.withValues(alpha: 0.3),
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
                              color: AppColors.textSecondaryOf(context),
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.forgotPassword,
                              style: TextStyle(
                                color: AppColors.brainPurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

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
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.dontHaveAccountPrefix} ',
                        style: TextStyle(color: AppColors.textSecondaryOf(context)),
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
                            style: TextStyle(
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
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.brainPurple),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.brainPurpleLight.withValues(alpha: 0.3),
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
            Expanded(
              child: Center(
                child: Text(
                  isLoading ? AppLocalizations.of(context)!.connecting : label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final AuthRepository repository;

  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.repository,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.resetPasswordTitle,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brainPurple),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.resetPasswordHint,
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.brainPurple),
              filled: true,
              fillColor: AppColors.brainPurpleLight.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
        ),
        ElevatedButton(
          onPressed: _isSending
              ? null
              : () async {
                  if (_emailController.text.trim().isEmpty) return;
                  setState(() => _isSending = true);
                  try {
                    await widget.repository.resetPassword(_emailController.text.trim());
                    if (context.mounted) Navigator.of(context).pop(true);
                  } catch (e) {
                    if (mounted) setState(() => _isSending = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brainPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(l10n.send),
        ),
      ],
    );
  }
}

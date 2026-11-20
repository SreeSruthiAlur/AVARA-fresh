import 'package:avara_astrology_trial/screens/main_navigation_scaffold.dart';
import 'package:avara_astrology_trial/screens/register_screen.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/auth_service.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:avara_astrology_trial/widgets/global_voice_assistant_modal.dart';
import 'package:avara_astrology_trial/widgets/language_selector_sheet.dart';
import 'package:avara_astrology_trial/widgets/voice_input_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AVARA Login screen.
///
/// Features voice input attachments on email and password fields,
/// visual language switcher (English, Telugu, Tanglish), and
/// a "Continue as Guest" one-tap voice access mode for non-typists.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    VoiceService.instance.onLoginAsGuestRequest = _continueAsGuest;
    VoiceService.instance.onOpenScreenRequest = (screen) {
      if (!mounted) return;
      if (screen == 'register') {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
        );
      } else {
        _continueAsGuest();
      }
    };
    VoiceService.instance.onAskAstrologyRequest = (question) {
      if (!mounted) return;
      _continueAsGuest();
      Future.delayed(const Duration(milliseconds: 300), () {
        VoiceService.instance.onAskAstrologyRequest?.call(question);
      });
    };
  }

  @override
  void dispose() {
    if (VoiceService.instance.onLoginAsGuestRequest == _continueAsGuest) {
      VoiceService.instance.onLoginAsGuestRequest = null;
    }
    VoiceService.instance.onOpenScreenRequest = null;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      _navigateHome(user);
    } on AvaraApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsGuest() {
    final apiKey = dotenv.get('GROQ_API_KEY',
        fallback: dotenv.get('GEMINI_API_KEY', fallback: ''));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MainNavigationScaffold(
          apiKey: apiKey,
          userName: 'Guest User',
        ),
      ),
      (_) => false,
    );
  }

  void _navigateHome(AuthUser user) {
    final apiKey = dotenv.get('GROQ_API_KEY',
        fallback: dotenv.get('GEMINI_API_KEY', fallback: ''));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MainNavigationScaffold(
          apiKey: apiKey,
          userName: user.fullName.isNotEmpty ? user.fullName : user.username,
        ),
      ),
      (_) => false, // remove every prior route
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Voice Assistant in header
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: AppColors.blue),
            tooltip: 'Voice Assistant / మాట్లాడండి',
            onPressed: () => GlobalVoiceAssistantModal.show(context),
          ),
          // Quick Language Switcher Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              avatar: const Icon(Icons.language_rounded, size: 16, color: AppColors.blue),
              label: Text(
                AppLanguageService.instance.currentLanguage.shortLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              backgroundColor: AppColors.lightBlue,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => LanguageSelectorSheet.show(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GlobalVoiceAssistantModal.show(context),
        icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
        label: const Text(
          'Speak / మాట్లాడండి',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.blue,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildForm(context),
                  const SizedBox(height: 20),
                  _buildLoginButton(context),
                  const SizedBox(height: 12),
                  _buildGuestButton(context),
                  const SizedBox(height: 20),
                  _buildRegisterLink(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AVARA brand mark
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.lavender,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in with your email or use your voice to enter',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field with Voice Input
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com (or tap mic to speak)',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.secondaryText),
              suffixIcon: VoiceInputButton(
                controller: _emailController,
                tooltip: 'Speak your email',
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field with Voice Input and Visibility Toggle
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Your password (or tap mic to speak)',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondaryText),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VoiceInputButton(
                    controller: _passwordController,
                    tooltip: 'Speak your password',
                  ),
                  IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.secondaryText,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  ),
                ],
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text('Login'),
      ),
    );
  }

  Widget _buildGuestButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _continueAsGuest,
        icon: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 22),
        label: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue without typing (Guest)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              'అతిథిగా ప్రవేశించండి (నో టైపింగ్)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F9D58),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.secondaryText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            'Sign up',
            style: TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

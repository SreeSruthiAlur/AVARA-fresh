import 'package:avara_astrology_trial/screens/main_navigation_scaffold.dart';
import 'package:avara_astrology_trial/screens/register_screen.dart';
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/auth_service.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/survey_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:avara_astrology_trial/widgets/language_selector_sheet.dart';
import 'package:avara_astrology_trial/widgets/survey_modal.dart';
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
    SurveyService.instance.loadSurveyState();
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
    if (!SurveyService.instance.isCompleted) {
      SurveyModal.show(
        context,
        onCompleted: () => _proceedHome('Guest User'),
      );
      return;
    }
    _proceedHome('Guest User');
  }

  void _navigateHome(AuthUser user) {
    final name = user.fullName.isNotEmpty ? user.fullName : user.username;
    if (!SurveyService.instance.isCompleted) {
      SurveyModal.show(
        context,
        onCompleted: () => _proceedHome(name),
      );
      return;
    }
    _proceedHome(name);
  }

  void _proceedHome(String userName) {
    final apiKey = dotenv.get('GROQ_API_KEY',
        fallback: dotenv.get('GEMINI_API_KEY', fallback: ''));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MainNavigationScaffold(
          apiKey: apiKey,
          userName: userName,
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLanguageService.instance,
        AgeProfileService.instance,
      ]),
      builder: (context, _) {
        final ageService = AgeProfileService.instance;
        final ageGroup = ageService.ageGroup;
        final ageTheme = ageService.activeTheme;
        final tr = AppLanguageService.instance.tr;

        final bgColor = switch (ageGroup) {
          AgeGroup.youth => const Color(0xFFFAF9FF),
          AgeGroup.adult => const Color(0xFFF8FAFC),
          AgeGroup.senior => const Color(0xFFFFFDF5),
        };

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            actions: [
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
                      const SizedBox(height: 20),
                      _buildAgeQuickEntry(context),
                      const SizedBox(height: 24),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AVARA creative glowing brand mark
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF2E71DB), Color(0xFF00CEC9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 5),
              Text(
                tr('vedic_wisdom_tag'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00B894).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub_rounded, size: 14, color: Color(0xFF00B894)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  tr('five_pillars_connected'),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B894),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr('welcome_title'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('welcome_subtitle'),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }

  Widget _buildAgeQuickEntry(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    final lang = AppLanguageService.instance.currentLanguage;

    final youthLabel = switch (lang) {
      AppLanguage.telugu => '⚡ యువత\n(<22)',
      AppLanguage.tanglish => '⚡ Youth\n(<22)',
      AppLanguage.malayalam => '⚡ യുവാക്കൾ\n(<22)',
      AppLanguage.manglish => '⚡ Youth\n(<22)',
      AppLanguage.english => '⚡ Youth\n(<22)',
    };
    final adultLabel = switch (lang) {
      AppLanguage.telugu => '💼 పెద్దలు\n(22-45)',
      AppLanguage.tanglish => '💼 Adult\n(22-45)',
      AppLanguage.malayalam => '💼 മുതിർന്നവർ\n(22-45)',
      AppLanguage.manglish => '💼 Adult\n(22-45)',
      AppLanguage.english => '💼 Adult\n(22-45)',
    };
    final seniorLabel = switch (lang) {
      AppLanguage.telugu => '🌸 సీనియర్స్\n(45+)',
      AppLanguage.tanglish => '🌸 Senior\n(45+)',
      AppLanguage.malayalam => '🌸 മുതിർന്നവർ\n(45+)',
      AppLanguage.manglish => '🌸 Senior\n(45+)',
      AppLanguage.english => '🌸 Senior\n(45+)',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_rounded, color: Color(0xFF6C5CE7), size: 18),
              const SizedBox(width: 8),
              Text(
                tr('explore_by_age'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr('age_cohort_hint'),
            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAgeChip(
                context,
                title: youthLabel,
                group: AgeGroup.youth,
                color: const Color(0xFF6C5CE7),
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(width: 8),
              _buildAgeChip(
                context,
                title: adultLabel,
                group: AgeGroup.adult,
                color: const Color(0xFF1E3A8A),
                icon: Icons.self_improvement_rounded,
              ),
              const SizedBox(width: 8),
              _buildAgeChip(
                context,
                title: seniorLabel,
                group: AgeGroup.senior,
                color: const Color(0xFFB45309),
                icon: Icons.spa_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeChip(
    BuildContext context, {
    required String title,
    required AgeGroup group,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          await AgeProfileService.instance.setAgeGroup(group);
          if (!mounted) return;
          SurveyModal.show(
            context,
            onCompleted: () => _proceedHome('Guest (${group.name})'),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: tr('login_email'),
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.secondaryText),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field with Visibility Toggle
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: tr('login_password'),
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondaryText),
              suffixIcon: IconButton(
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
    final tr = AppLanguageService.instance.tr;
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
            : Text(tr('login_btn')),
      ),
    );
  }

  Widget _buildGuestButton(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    final lang = AppLanguageService.instance.currentLanguage;
    final guestSub = switch (lang) {
      AppLanguage.telugu => 'అతిథిగా ప్రవేశించండి (నో టైపింగ్)',
      AppLanguage.tanglish => 'Guest ga proceed avvandi (No typing)',
      AppLanguage.malayalam => 'അതിഥിയായി തുടരുക (ടൈപ്പിംഗ് ഇല്ലാതെ)',
      AppLanguage.manglish => 'Guest aayi continue cheyyoo',
      AppLanguage.english => 'Instant access with customized experience',
    };

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _continueAsGuest,
        icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
        label: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('login_guest_btn'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            Text(
              guestSub,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
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
    final tr = AppLanguageService.instance.tr;
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
        ),
        child: Text(
          tr('login_no_account'),
          style: const TextStyle(
            color: AppColors.blue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

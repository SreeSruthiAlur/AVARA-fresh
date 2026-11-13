import 'package:avara_astrology_trial/screens/main_navigation_scaffold.dart';
import 'package:avara_astrology_trial/services/auth_service.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AVARA Register screen.
///
/// Collects a display name, email address, and password, then calls
/// [AuthService.register]. On success navigates to [MainNavigationScaffold],
/// clearing the route stack — registration is treated as an implicit login.
///
/// Mirrors the error-handling pattern of [LoginScreen]: [AvaraApiException]
/// messages appear in a [SnackBar]; other errors show a generic retry prompt.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      final user = await AuthService.instance.register(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
      (_) => false,
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
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.deepNavy),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 36),
                  _buildForm(context),
                  const SizedBox(height: 24),
                  _buildSignUpButton(context),
                  const SizedBox(height: 20),
                  _buildLoginLink(context),
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
        Text('Create account',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Join AVARA — your space for reflection, clarity, and a better you.',
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
          // Name
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Sruthi',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppColors.secondaryText),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2) return 'Enter your full name';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Username
          TextFormField(
            controller: _usernameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'sruthi_avara',
              prefixIcon:
                  Icon(Icons.alternate_email, color: AppColors.secondaryText),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.trim().length < 3) return 'Username must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppColors.secondaryText),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'At least 8 characters',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.secondaryText),
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
              if (v.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Confirm password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.secondaryText),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.secondaryText,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                tooltip:
                    _obscureConfirm ? 'Show password' : 'Hide password',
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
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
            : const Text('Sign Up'),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.secondaryText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text(
            'Login',
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

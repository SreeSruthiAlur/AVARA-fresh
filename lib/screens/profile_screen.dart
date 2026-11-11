import 'package:avara_astrology_trial/screens/login_screen.dart';
import 'package:avara_astrology_trial/services/auth_service.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// A single entry in the profile menu list.
class _ProfileMenuItem {
  const _ProfileMenuItem({required this.label, required this.subtitle});
  final String label;
  final String subtitle;
}

/// AVARA Profile screen — "10 — Profile" Figma design.
///
/// All user data ([userName], [userSubtitle]) is dynamic; nothing is
/// hardcoded. The avatar renders the first letter of [userName] in a lavender
/// [CircleAvatar] matching the Figma design.
///
/// The "Log out" button calls [AuthService.logout] directly and navigates to
/// [LoginScreen], clearing the full route stack so the user cannot navigate
/// back with the system back button.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    this.userSubtitle = '',
    // kept for backward compatibility; if provided it overrides the default
    // AuthService-based logout. Prefer leaving it null in new call-sites.
    this.onLogout,
  });

  /// User display name — shown as the avatar letter and headline text.
  final String userName;

  /// Optional one-line subtitle shown below the name (e.g. "3rd Year CSE · Bengaluru").
  final String userSubtitle;

  /// Optional override for the logout action. When `null` (the default) the
  /// screen handles logout via [AuthService] and navigates to [LoginScreen].
  final VoidCallback? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  // Live birth details fetched from GET /profile/me in initState.
  String? _birthDate;
  String? _birthPlace;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------------------------------------------------------------------------
  // Profile fetch
  // ---------------------------------------------------------------------------

  Future<void> _loadProfile() async {
    try {
      final data = await AvaraApiClient.instance.get('/profile/me')
          as Map<String, dynamic>?;
      if (data == null || !mounted) return;
      setState(() {
        _birthDate = data['birth_date']?.toString();
        _birthPlace = data['birth_place']?.toString();
        _profileLoaded = true;
      });
    } catch (_) {
      // Best-effort — if the backend is unreachable the screen still renders
      // with the fallback "Tap to add" subtitle.
      if (mounted) setState(() => _profileLoaded = true);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> _handleLogout() async {
    // If a custom callback was injected, defer to it.
    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await AuthService.instance.logout();
    } catch (_) {
      // logout() is already best-effort internally; nothing to re-throw.
    }
    if (!mounted) return;

    // Replace the entire stack so the user lands on LoginScreen and cannot
    // navigate back into the authenticated area with the system back button.
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static const List<_ProfileMenuItem> _menuItems = [
    _ProfileMenuItem(
      label: 'Personal Information',
      subtitle: 'Birth details and preferences',
    ),
    _ProfileMenuItem(
      label: 'Birth Details',
      subtitle: 'Used for astrology features',
    ),
    _ProfileMenuItem(
      label: 'Preferences',
      subtitle: 'Language, notifications',
    ),
    _ProfileMenuItem(
      label: 'Consultation History',
      subtitle: 'Past conversations',
    ),
    _ProfileMenuItem(
      label: 'My Data',
      subtitle: 'Manage your information',
    ),
    _ProfileMenuItem(
      label: 'Help & Support',
      subtitle: 'FAQs and contact',
    ),
    _ProfileMenuItem(
      label: 'Privacy & Security',
      subtitle: 'Your data and privacy',
    ),
  ];

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
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildMenuSection(context),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — avatar, name, subtitle, edit button
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        children: [
          _buildAvatar(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (widget.userSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.userSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText),
                  ),
                ],
                const SizedBox(height: 10),
                _EditProfileButton(
                  onTap: () {
                    // TODO: navigate to edit profile flow
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final initial = widget.userName.trim().isNotEmpty
        ? widget.userName.trim()[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.lavender,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.deepNavy,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Menu items
  // ---------------------------------------------------------------------------

  Widget _buildMenuSection(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _menuItems.length; i++) ...[
            _buildMenuItem(context, _menuItems[i]),
            if (i < _menuItems.length - 1)
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _ProfileMenuItem item) {
    // The "Birth Details" tile displays live data fetched from the backend.
    final subtitle = item.label == 'Birth Details'
        ? _birthDetailsSubtitle()
        : item.subtitle;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        item.label,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.secondaryText),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.secondaryText,
        size: 20,
      ),
      onTap: () {
        // TODO: navigate to each settings sub-screen
      },
    );
  }

  /// Returns a human-readable subtitle for the "Birth Details" tile.
  ///
  /// Shows the fetched date and place when available; falls back gracefully
  /// while loading or when the user hasn't set their details yet.
  String _birthDetailsSubtitle() {
    if (!_profileLoaded) return 'Loading…';
    final hasDate = _birthDate != null && _birthDate!.isNotEmpty;
    final hasPlace = _birthPlace != null && _birthPlace!.isNotEmpty;
    if (!hasDate && !hasPlace) return 'Tap to add birth details';
    if (hasDate && hasPlace) return '$_birthDate · $_birthPlace';
    if (hasDate) return _birthDate!;
    return _birthPlace!;
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: _isLoggingOut ? null : _handleLogout,
      icon: _isLoggingOut
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD32F2F),
              ),
            )
          : const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFD32F2F)),
      label: const Text(
        'Log out',
        style: TextStyle(
          color: Color(0xFFD32F2F),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small "Edit Profile" pill button
// ---------------------------------------------------------------------------

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.lavender,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

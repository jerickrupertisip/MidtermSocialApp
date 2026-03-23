import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Supabase client ────────────────────────────────────────────────────────
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // ── Form controllers ───────────────────────────────────────────────────────
  final TextEditingController _usernameInputController =
      TextEditingController();
  final TextEditingController _emailInputController = TextEditingController();
  final TextEditingController _newPasswordInputController =
      TextEditingController();

  // ── Displayed profile state ────────────────────────────────────────────────
  String _displayedUsername = "";
  String? _profileAvatarUrl;
  String _rawBirthdate = "";
  int _computedAge = 0;

  bool _isSavingProfile = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchAndPopulateUserData();
  }

  @override
  void dispose() {
    _usernameInputController.dispose();
    _emailInputController.dispose();
    _newPasswordInputController.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  void _fetchAndPopulateUserData() {
    final User? currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) return;

    final Map<String, dynamic> userMetadata = currentUser.userMetadata ?? {};

    setState(() {
      _displayedUsername = userMetadata["username"] ?? "Unknown";
      _profileAvatarUrl = userMetadata["avatar_url"];
      _rawBirthdate = userMetadata["birthdate"] ?? "";
      _computedAge = _calculateAgeFromBirthdate(_rawBirthdate);

      _usernameInputController.text = _displayedUsername;
      _emailInputController.text = currentUser.email ?? "";
    });
  }

  // ── Business logic ─────────────────────────────────────────────────────────

  int _calculateAgeFromBirthdate(String birthdateString) {
    if (birthdateString.isEmpty) return 0;

    try {
      final DateTime birthdate = DateTime.parse(birthdateString);
      final DateTime today = DateTime.now();
      int age = today.year - birthdate.year;

      final bool birthdayNotYetOccurredThisYear =
          today.month < birthdate.month ||
          (today.month == birthdate.month && today.day < birthdate.day);

      if (birthdayNotYetOccurredThisYear) age--;
      return age;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() => _isSavingProfile = true);

    try {
      final String trimmedUsername = _usernameInputController.text.trim();
      final String trimmedEmail = _emailInputController.text.trim();
      final String trimmedNewPassword = _newPasswordInputController.text.trim();

      final String? currentUserEmail = _supabaseClient.auth.currentUser?.email;
      final bool emailHasChanged =
          trimmedEmail.isNotEmpty && trimmedEmail != currentUserEmail;

      await _supabaseClient.auth.updateUser(
        UserAttributes(
          data: {"username": trimmedUsername},
          email: emailHasChanged ? trimmedEmail : null,
          password: trimmedNewPassword.isNotEmpty ? trimmedNewPassword : null,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        _fetchAndPopulateUserData();
      }
    } on AuthException catch (authError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authError.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _signOutCurrentUser() async {
    await _supabaseClient.auth.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _ProfileHeaderRow(
                displayedUsername: _displayedUsername,
                profileAvatarUrl: _profileAvatarUrl,
              ),
              const Spacer(),
              _ProfileEditFields(
                usernameController: _usernameInputController,
                emailController: _emailInputController,
                newPasswordController: _newPasswordInputController,
              ),
              const SizedBox(height: 24),
              _SaveChangesButton(
                isSaving: _isSavingProfile,
                onPressed: _saveProfileChanges,
              ),
              const Spacer(),
              _ProfileFooterRow(
                computedAge: _computedAge,
                onSignOut: _signOutCurrentUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _ProfileHeaderRow extends StatelessWidget {
  const _ProfileHeaderRow({
    required this.displayedUsername,
    required this.profileAvatarUrl,
  });

  final String displayedUsername;
  final String? profileAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          displayedUsername,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        _UserAvatarCircle(avatarUrl: profileAvatarUrl),
      ],
    );
  }
}

class _UserAvatarCircle extends StatelessWidget {
  const _UserAvatarCircle({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null ? const Text("pfp") : null,
    );
  }
}

class _ProfileEditFields extends StatelessWidget {
  const _ProfileEditFields({
    required this.usernameController,
    required this.emailController,
    required this.newPasswordController,
  });

  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController newPasswordController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: "Change Username"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Email Address"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "New Password"),
        ),
      ],
    );
  }
}

class _SaveChangesButton extends StatelessWidget {
  const _SaveChangesButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      child: isSaving
          ? const CircularProgressIndicator()
          : const Text("Save Changes"),
    );
  }
}

class _ProfileFooterRow extends StatelessWidget {
  const _ProfileFooterRow({required this.computedAge, required this.onSignOut});

  final int computedAge;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Age: $computedAge", style: const TextStyle(fontSize: 18)),
        _SignOutButton(onPressed: onSignOut),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
    );
  }
}

import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:uniso_social_media_app/screens/auth/sign_up_screen.dart";
import "package:uniso_social_media_app/components/form_fields/email_field.dart";
import "package:uniso_social_media_app/components/form_fields/password_field.dart";
import "package:uniso_social_media_app/services/supabase.dart";

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _SignInScreenState extends State<SignInScreen> {
  // Form
  final GlobalKey<FormState> _signInFormKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailInputController = TextEditingController();
  final TextEditingController _passwordInputController =
      TextEditingController();

  // UI state
  bool _rememberPasswordChecked = false;
  bool _passwordObscured = true;
  bool _signInRequestInProgress = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _emailInputController.dispose();
    _passwordInputController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Business logic
  // ---------------------------------------------------------------------------

  Future<void> _submitSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() => _signInRequestInProgress = true);

    try {
      await SupabaseService.signIn(
        emailAddress: _emailInputController.text.trim(),
        password: _passwordInputController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (authError) {
      _showErrorSnackBar(authError.message);
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      setState(() => _signInRequestInProgress = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _passwordObscured = !_passwordObscured);
  }

  void _toggleRememberPassword(bool? checked) {
    setState(() => _rememberPasswordChecked = checked ?? false);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTransparentAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _signInFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AppBranding(),
                    const SizedBox(height: 48),
                    EmailField(controller: _emailInputController),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordInputController,
                      isObscured: _passwordObscured,
                      onToggleVisibility: _togglePasswordVisibility,
                    ),
                    const SizedBox(height: 8),
                    _RememberPasswordRow(
                      isChecked: _rememberPasswordChecked,
                      onChanged: _toggleRememberPassword,
                    ),
                    const SizedBox(height: 24),
                    _SignInButton(
                      isLoading: _signInRequestInProgress,
                      onPressed: _submitSignIn,
                    ),
                    const SizedBox(height: 16),
                    _NavigateToSignUpButton(onPressed: _navigateToSignUp),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildTransparentAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: "Exit to Home",
        onPressed: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Displays the app name and tagline at the top of the sign-in form.
class _AppBranding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          "Uni-So",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Connect with your community",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

/// Checkbox row that lets the user opt into remembering their password.
class _RememberPasswordRow extends StatelessWidget {
  const _RememberPasswordRow({
    required this.isChecked,
    required this.onChanged,
  });

  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: isChecked, onChanged: onChanged),
        const Text("Remember password"),
      ],
    );
  }
}

/// Primary call-to-action button that triggers sign-in. Shows a loading
/// spinner while the authentication request is in progress.
class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text("Sign In"),
    );
  }
}

/// Text button that navigates users without an account to the sign-up screen.
class _NavigateToSignUpButton extends StatelessWidget {
  const _NavigateToSignUpButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text("Don't have an account? Sign Up"),
    );
  }
}

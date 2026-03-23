import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:intl/intl.dart";

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _username = "";
  String? _avatarUrl;
  String _birthdate = "";
  int _age = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      setState(() {
        _username = metadata["username"] ?? "Unknown";
        _avatarUrl = metadata["avatar_url"];
        _birthdate = metadata["birthdate"] ?? "";
        _usernameController.text = _username;
        _emailController.text = user.email ?? "";
        _age = _calculateAge(_birthdate);
      });
    }
  }

  int _calculateAge(String birthdateStr) {
    if (birthdateStr.isEmpty) return 0;
    try {
      final birthdate = DateTime.parse(birthdateStr);
      final today = DateTime.now();
      int age = today.year - birthdate.year;
      if (today.month < birthdate.month || (today.month == birthdate.month && today.day < birthdate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final newUsername = _usernameController.text.trim();
      final newEmail = _emailController.text.trim();
      final newPassword = _passwordController.text.trim();

      // Update metadata (username)
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {"username": newUsername},
          email: newEmail.isNotEmpty && newEmail != _supabase.auth.currentUser?.email ? newEmail : null,
          password: newPassword.isNotEmpty ? newPassword : null,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        _loadUserData();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

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
              // Top row: Username and Profile Pic
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _username,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null ? const Text("pfp") : null,
                  ),
                ],
              ),
              const Spacer(),
              // Middle section: Edit fields
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Change Username"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email Address"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading ? const CircularProgressIndicator() : const Text("Save Changes"),
              ),
              const Spacer(),
              // Bottom row: Age and Sign Out
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Age: $_age",
                    style: const TextStyle(fontSize: 18),
                  ),
                  ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

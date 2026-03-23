import "package:flutter/material.dart";

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.isObscured,
    required this.onToggleVisibility,
  });

  final TextEditingController controller;
  final bool isObscured;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleVisibility,
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (enteredPassword) {
        if (enteredPassword == null || enteredPassword.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
    );
  }
}

import "package:flutter/material.dart";

/// Username input field with presence validation.
class UsernameField extends StatelessWidget {
  const UsernameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: "Username",
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
      validator: (enteredUsername) {
        if (enteredUsername == null || enteredUsername.isEmpty) {
          return "Please enter your username";
        } else if (enteredUsername.length <= 1) {
          return "Your username needs to be 2 characters or longer";
        }
        return null;
      },
    );
  }
}

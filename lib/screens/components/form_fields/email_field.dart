import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: "Email Address",
        hintText: "Enter your email address",
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      validator: (enteredEmail) {
        if (enteredEmail == null ||
            enteredEmail.isEmpty ||
            !enteredEmail.contains("@")) {
          return "Please enter a valid email address";
        }
        return null;
      },
    );
  }
}

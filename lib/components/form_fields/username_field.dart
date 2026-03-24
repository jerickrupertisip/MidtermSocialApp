import "package:flutter/material.dart";
import "package:form_builder_validators/form_builder_validators.dart";

/// Username input field with presence validation.
class UsernameField extends StatelessWidget {
  const UsernameField({
    super.key,
    required this.errorText,
    required this.controller,
  });

  final String? errorText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Username",
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
        errorText: errorText,
      ),
      validator: FormBuilderValidators.username(
        allowUnderscore: true,
        allowDots: true,
        allowDash: true,
      ),
    );
  }
}

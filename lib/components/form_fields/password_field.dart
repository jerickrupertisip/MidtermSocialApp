import "package:flutter/material.dart";
import "package:form_builder_validators/form_builder_validators.dart";

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
      validator: FormBuilderValidators.password(
        minLength: 6,
        minNumberCount: 0,
        minUppercaseCount: 0,
        minLowercaseCount: 0,
        minSpecialCharCount: 0,
      ),
    );
  }
}

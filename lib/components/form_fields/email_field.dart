import 'package:flutter/material.dart';
import "package:form_builder_validators/form_builder_validators.dart";

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
      validator: FormBuilderValidators.email(),
    );
  }
}

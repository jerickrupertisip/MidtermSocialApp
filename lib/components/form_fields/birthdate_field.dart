import "package:flutter/material.dart";

class BirthdateField extends StatelessWidget {
  const BirthdateField({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: const InputDecoration(
        labelText: "Birthdate",
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
        hintText: "YYYY-MM-DD",
      ),
      validator: (selectedBirthdate) {
        if (selectedBirthdate == null || selectedBirthdate.isEmpty) {
          return "Please select your birthdate";
        }
        return null;
      },
    );
  }
}

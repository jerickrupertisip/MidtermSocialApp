import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

void debugLog(BuildContext context, String message) {
  if (!kDebugMode) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(content: Text(message)));
  debugPrint(message);
}

String getInitials(String name) {
  if (name.isEmpty) return "";

  List<String> nameParts = name.trim().split(" ");

  if (nameParts.length > 1) {
    // Returns first letter of first name and first letter of last name
    return (nameParts.first[0] + nameParts.last[0]).toUpperCase();
  } else {
    // Returns first letter of a single name
    return nameParts.first[0].toUpperCase();
  }
}

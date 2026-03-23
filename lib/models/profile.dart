import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String username;
  final String? avatarUrl;

  Profile({required this.id, required this.username, required this.avatarUrl});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json["id"],
      username: json["username"],
      avatarUrl: json["avatar_url"],
    );
  }

  factory Profile.fromUser(User user) {
    return Profile(
      id: user.id,
      username: user.userMetadata?["username"],
      avatarUrl: user.userMetadata?["avatar_url"],
    );
  }

  static List<Profile> fromList(List<Map<String, dynamic>> messages) {
    return messages.map((element) => Profile.fromJson(element)).toList();
  }
}

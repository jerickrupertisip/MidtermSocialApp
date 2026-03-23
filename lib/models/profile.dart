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
}

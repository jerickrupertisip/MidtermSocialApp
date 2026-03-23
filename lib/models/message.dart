import "package:uniso_social_media_app/models/profile.dart";

class Message {
  final String content;
  final DateTime createdAt;
  final Profile sentBy;

  Message({
    required this.content,
    required this.createdAt,
    required this.sentBy,
  });

  factory Message.fromMap(Map<String, dynamic> message) {
    return Message(
      content: message["content"],
      createdAt: DateTime.parse(message["created_at"]),
      sentBy: Profile(
        id: message["user_id"],
        username: message["username"],
        avatarUrl: message["avatar_url"],
      ),
    );
  }

  factory Message.fromMapWithProfile(
    Map<String, dynamic> message,
    Profile profile,
  ) {
    return Message(
      content: message["content"],
      createdAt: DateTime.parse(message["created_at"]),
      sentBy: profile,
    );
  }

  static List<Message> fromList(List<Map<String, dynamic>> messages) {
    return messages.map((element) => Message.fromMap(element)).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      "content": content,
      "created_at": createdAt.toIso8601String(),
      "user_id": sentBy.id,
      "username": sentBy.username,
      "avatar_url": sentBy.avatarUrl,
    };
  }
}

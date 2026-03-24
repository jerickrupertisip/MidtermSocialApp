import "package:flutter/cupertino.dart";
import "package:uniso_social_media_app/models/profile.dart";

enum MessageType { message, media }

class Message {
  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final DateTime createdAt;
  final Profile sentBy;

  Message({
    required this.type,
    required this.content,
    required this.mediaUrl,
    required this.createdAt,
    required this.sentBy,
  });

  factory Message.fromMap(Map<String, dynamic> map, {Profile? profile}) {
    debugPrint(map.toString());
    // 1. Centralized Type Mapping
    final type = switch (map["type"]) {
      "message" => MessageType.message,
      "media" => MessageType.media,
      _ => throw ArgumentError("Invalid message type: ${map["type"]}"),
    };

    return Message(
      type: type,
      content: map["content"] as String?,
      mediaUrl: map["media_url"] as String?,
      createdAt: DateTime.parse(map["created_at"] as String),
      // 2. Conditional Profile Logic
      // If a profile is passed in, use it; otherwise, build it from the map.
      sentBy:
          profile ??
          Profile(
            id: map["user_id"] as String,
            username: map["username"] as String,
            avatarUrl: map["avatar_url"] as String?,
          ),
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

class Post {
  final String id;
  final String mediaUrl;
  final String createdAt;
  final String unionId;
  final String unionName;
  final String authorName;
  final String avatarUrl;

  Post({
    required this.id,
    required this.mediaUrl,
    required this.createdAt,
    required this.unionId,
    required this.unionName,
    required this.authorName,
    required this.avatarUrl,
  });

  factory Post.fromMap(Map<String, dynamic> message) {
    return Post(
      id: message["id"],
      mediaUrl: message["media_url"],
      createdAt: message["created_at"],
      unionId: message["union_id"],
      unionName: message["union_name"],
      authorName: message["author_name"],
      avatarUrl: message["avatar_url"] ?? "",
    );
  }

  static List<Post> fromList(List<Map<String, dynamic>> messages) {
    return messages.map((element) => Post.fromMap(element)).toList();
  }
}

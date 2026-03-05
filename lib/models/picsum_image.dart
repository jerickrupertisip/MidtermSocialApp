class PicsumImage {
  final String id;
  final String author;
  final String downloadUrl;
  final int width;
  final int height;

  PicsumImage({
    required this.id,
    required this.author,
    required this.downloadUrl,
    required this.width,
    required this.height,
  });

  factory PicsumImage.fromJson(Map<String, dynamic> json) {
    return PicsumImage(
      id: json["id"],
      author: json["author"],
      downloadUrl: json["download_url"],
      width: json["width"] as int,
      height: json["height"] as int,
    );
  }
}

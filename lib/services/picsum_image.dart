import "dart:convert";
import "package:http/http.dart" as http;
import "package:uniso_social_media_app/models/picsum_image.dart";

Future<List<PicsumImage>> fetchImages(int page, {int? limit = 4}) async {
  final response = await http.get(
    Uri.parse("https://picsum.photos/v2/list?page=$page&limit=$limit"),
  );

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => PicsumImage.fromJson(item)).toList();
  } else {
    throw Exception("Failed to load images");
  }
}

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class CloudinaryService {
  // TODO: Thay đổi thông tin này
  final String cloudName = "dnjz2p5eb"; // Thay bằng cloud name của bạn
  final String uploadPreset = "vocab_ai"; // Thay bằng upload preset của bạn

  Future<String> uploadImage(File file) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody) as Map<String, dynamic>;
        final String imageUrl = data['secure_url'];
        return imageUrl;
      } else {
        throw Exception("Upload failed: ${response.statusCode} - $resBody");
      }
    } catch (e) {
      throw Exception("Error uploading image: $e");
    }
  }
}
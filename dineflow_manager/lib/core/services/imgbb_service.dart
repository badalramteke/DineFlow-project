import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String _apiKey = "ce7a09686c6751a7ead28921dbf08527";
  static const String _apiUrl = "https://api.imgbb.com/1/upload";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.fields['key'] = _apiKey;
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = json.decode(responseString);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data']['url'];
      } else {
        print("ImgBB Upload Failed: ${jsonResponse['error']['message']}");
        return null;
      }
    } catch (e) {
      print("Error uploading to ImgBB: $e");
      return null;
    }
  }
}

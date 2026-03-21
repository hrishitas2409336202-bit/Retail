import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const String apiKey = 'AIzaSyD4EFTlvtM5l7Zj12ivSkNLMfK-tNI92wg';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('AVAILABLE MODELS:');
      for (var model in data['models']) {
        print('- ${model['name']} (supports: ${model['supportedGenerationMethods']})');
      }
    } else {
      print('FAILED TO LIST MODELS: ${response.statusCode}');
      print('BODY: ${response.body}');
    }
  } catch (e) {
    print('ERROR: $e');
  }
}

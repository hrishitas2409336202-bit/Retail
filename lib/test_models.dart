import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const apiKey = 'AIzaSyD4EFTlvtM5l7Zj12ivSkNLMfK-tNI92wg';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  final response = await http.get(url);
  final body = jsonDecode(response.body);
  if (body['models'] != null) {
     for (var model in body['models']) {
       print(model['name']);
     }
  } else {
     print(response.body);
  }
}


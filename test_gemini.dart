import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const String apiKey = 'AIzaSyD4EFTlvtM5l7Zj12ivSkNLMfK-tNI92wg';
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  final prompt = 'Identify barcode 7622300699710 and return JSON: {"name": "...", "price": 0.0, "category": "..."}. Return ONLY JSON.';

  try {
    final response = await model.generateContent([Content.text(prompt)]);
    print('RESPONSE: ${response.text}');
  } catch (e) {
    print('ERROR: $e');
  }
}

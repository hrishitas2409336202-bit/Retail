import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main() async {
  const apiKey = 'AIzaSyD4EFTlvtM5l7Zj12ivSkNLMfK-tNI92wg';
  try {
    final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
    final response = await model.generateContent([
      Content.text('Identify this product from barcode: "8901595862726". Just say the product name if you know it or say Unknown.')
    ]);
    print('SUCCESS: \${response.text}');
  } catch (e) {
    print('ERROR: $e');
  }
}


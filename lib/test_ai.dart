import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main() async {
  print('Starting AI test...');
  const apiKey = 'AIzaSyD4EFTlvtM5l7Zj12ivSkNLMfK-tNI92wg';
  try {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final response = await model.generateContent([
      Content.text('Identify this product from barcode: "8901595862726". Just say the product name if you know it or say Unknown.')
    ]);
    print('1.5-FLASH Response: \${response.text}');
  } catch (e) {
    print('1.5-FLASH Error: $e');
  }

  try {
    final model2 = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final response2 = await model2.generateContent([
      Content.text('Identify this product from barcode: "8901595862726". Just say the product name if you know it or say Unknown.')
    ]);
    print('PRO Response: \${response2.text}');
  } catch (e) {
    print('PRO Error: $e');
  }
}


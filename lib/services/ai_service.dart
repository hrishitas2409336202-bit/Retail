import 'package:openfoodfacts/openfoodfacts.dart' as off;
import '../models/product.dart' as model;
import '../models/sale.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // ── Local Knowledge Base ─────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _localKB = {
    '7622300699710': {
      'name': 'Cadbury Dairy Milk Silk 150g',
      'price': 175.0,
      'category': 'Snacks & Packaged Foods',
      'unit': '150g',
      'emoji': '🍫',
      'description': 'Premium smooth and creamy milk chocolate.',
      'shelf': 'S5',
      'imageUrl': 'https://images.unsplash.com/photo-1614088685112-0a860dbbfbe9?auto=format&fit=crop&q=80&w=200',
    },
    '8901030653063': {
      'name': 'Dove Soap 100g',
      'price': 72.0,
      'category': 'Personal Care',
      'unit': '100g',
      'emoji': '🧼',
      'description': 'Moisturizing beauty bathing bar.',
      'shelf': 'S8',
    },
    '5000159461122': {
      'name': 'Mars Chocolate Bar 51g',
      'price': 50.0,
      'category': 'Snacks & Packaged Foods',
      'unit': '51g',
      'emoji': '🍫',
      'description': 'Classic caramel and nougat chocolate bar.',
      'shelf': 'S5',
    },
    '05449000000996': {
      'name': 'Coca-Cola 500ml',
      'price': 40.0,
      'category': 'Beverages',
      'unit': '500ml',
      'emoji': '🥤',
      'description': 'Crisp and refreshing carbonated drink.',
      'shelf': 'S6',
    },
    '5000159414548': {
      'name': 'Snickers Bar 50g',
      'price': 50.0,
      'category': 'Snacks & Packaged Foods',
      'unit': '50g',
      'emoji': '🍫',
      'description': 'Hungry? Grab a Snickers with peanuts and caramel.',
      'shelf': 'S5',
    },
    '8901030025914': {
      'name': 'Lifebuoy Hand Wash 200ml',
      'price': 99.0,
      'category': 'Personal Care',
      'unit': '200ml',
      'emoji': '🧼',
      'description': 'Effective protection against 99.9% germs.',
      'shelf': 'S8',
    },
    '8901030704949': {
      'name': 'Pepsodent Germi Check 150g',
      'price': 110.0,
      'category': 'Personal Care',
      'unit': '150g',
      'emoji': '🦷',
      'description': '12-hour germ protection toothpaste.',
      'shelf': 'S8',
    },
    '8901595862726': {
      'name': "Ching's Secret Dark Soy Sauce 200g",
      'price': 60.0,
      'category': 'Sauces & Condiments',
      'unit': '200g',
      'emoji': '🥫',
      'description': 'Essential ingredient for Chinese cooking.',
      'shelf': 'S9',
      'mfgDate': '2023-11-01',
      'expires': '2025-11-01',
    },
  };

  static String _getEmojiForCategory(String? categories) {
    if (categories == null) return '📦';
    final cats = categories.toLowerCase();
    if (cats.contains('beverage') || cats.contains('drink') || cats.contains('soda')) return '🥤';
    if (cats.contains('chocolate') || cats.contains('candy') || cats.contains('sweet')) return '🍫';
    if (cats.contains('snack') || cats.contains('chip') || cats.contains('cookie')) return '🍪';
    if (cats.contains('sauce') || cats.contains('condiment')) return '🥫';
    if (cats.contains('fruit')) return '🍎';
    if (cats.contains('vegetable')) return '🥦';
    if (cats.contains('dairy') || cats.contains('milk') || cats.contains('cheese')) return '🧀';
    if (cats.contains('bread') || cats.contains('bakery')) return '🍞';
    if (cats.contains('meat') || cats.contains('fish')) return '🍗';
    if (cats.contains('frozen')) return '❄️';
    if (cats.contains('personal care') || cats.contains('soap') || cats.contains('shampoo')) return '🧼';
    return '📦';
  }

  static Future<Map<String, dynamic>?> getProductFromBarcode(String barcode) async {
    if (_localKB.containsKey(barcode)) return Map<String, dynamic>.from(_localKB[barcode]!);
    try {
      final off.ProductQueryConfiguration configuration = off.ProductQueryConfiguration(
        barcode,
        language: off.OpenFoodFactsLanguage.ENGLISH,
        fields: [off.ProductField.ALL],
        version: off.ProductQueryVersion.v3,
      );
      final off.ProductResultV3 result = await off.OpenFoodAPIClient.getProductV3(configuration);
      if (result.status == off.ProductResultV3.statusSuccess && result.product != null) {
        final product = result.product!;
        final rawName = product.productName ?? '';
        if (rawName.isEmpty) return null;
        return {
          'name': rawName,
          'price': 0.0,
          'category': product.categories ?? 'General Merchandise',
          'unit': product.quantity ?? 'Unit',
          'emoji': _getEmojiForCategory(product.categories),
          'description': product.ingredientsText ?? 'No description available.',
          'shelf': 'S1',
          'imageUrl': product.imageFrontUrl ?? '',
          'mfgDate': null,
          'expires': null,
        };
      }
    } catch (e) {}
    return null;
  }

  // ── GitHub Models AI Integration ─────────────────────────────────────────
  static Future<String> getAIAdvice(
    String query,
    String storeName,
    List<model.Product> inventory,
    List<Sale> sales,
    String language,
    List<Map<String, String>> history,
    String token,
  ) async {
    if (token.isEmpty) {
      return generateRuleBasedResponse(query, inventory, sales, history);
    }

    final contextInfo = _buildStoreContext(storeName, inventory, sales, language);
    
    final List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content': '''You are "RetailIQ Advisor", a brilliant AI retail consultant for $storeName.
Your goal is to provide actionable, data-driven advice based on the provided store data.
Current Language: $language (Reply in this language if possible, otherwise English).

STORE DATA:
$contextInfo

INSTRUCTIONS:
1. Be concise, professional, and helpful.
2. Use emojis to make the chat friendly.
3. If asked about stock, refer to specific quantities.
4. If asked about revenue, give today's totals.
5. If the data doesn't contain the answer, say you are still gathering that information.
6. Format your response clearly with bold text for product names or numbers.'''
      }
    ];

    for (var m in history.reversed.take(5).toList().reversed) {
      messages.add({
        'role': m['role'] == 'user' ? 'user' : 'assistant',
        'content': m['text'] ?? '',
      });
    }

    messages.add({'role': 'user', 'content': query});

    try {
      final response = await http.post(
        Uri.parse('https://models.inference.ai.azure.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'messages': messages,
          'model': 'gpt-4o',
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        return "Sorry, I'm having trouble connecting to my brain right now (Error: ${response.statusCode}). Let's try again in a moment! 🧠💤";
      }
    } catch (e) {
      return "I encountered a technical glitch while thinking. Please check your internet connection! 🌐";
    }
  }

  static String _buildStoreContext(String storeName, List<model.Product> inventory, List<Sale> sales, String lang) {
    final now = DateTime.now();
    
    // 1. Basic Metrics
    final todaySales = sales.where((s) => s.date.day == now.day && s.date.month == now.month && s.date.year == now.year).toList();
    final revenue = todaySales.fold(0.0, (a, b) => a + b.total);
    final totalInventoryValue = inventory.fold(0.0, (sum, p) => sum + (p.stock * p.price));

    // 2. Inventory Breakdown
    final lowStock = inventory.where((p) => p.stock <= p.threshold).toList();
    final outOfStock = inventory.where((p) => p.stock == 0).length;
    final Map<String, int> categories = {};
    for (var p in inventory) categories[p.category] = (categories[p.category] ?? 0) + 1;

    // 3. Performance (Last 7 Days)
    final Map<String, double> dailyPerf = {};
    for (int i = 0; i < 7; i++) {
       final day = now.subtract(Duration(days: i));
       final dayTotal = sales.where((s) => s.date.day == day.day && s.date.month == day.month && s.date.year == day.year)
                             .fold(0.0, (a, b) => a + b.total);
       dailyPerf["${day.day}/${day.month}"] = dayTotal;
    }

    // 4. Products expiring in next 30 days
    final expiringSoon = inventory.where((p) => p.expires != null && p.expires!.isNotEmpty).take(5).toList();

    return '''
- Store Name: $storeName
- REVENUE TODAY: $revenue
- TOTAL BILLS: ${todaySales.length}
- TOTAL INVENTORY VALUE: $totalInventoryValue
- CATEGORIES: ${categories.entries.map((e) => "${e.key}(${e.value})").join(", ")}
- LOW STOCK ALERT: ${lowStock.length} items (${lowStock.take(5).map((p) => "${p.name}: ${p.stock}").join(", ")}...)
- OUT OF STOCK: $outOfStock items
- TOP SELLING TODAY: ${_getTopSellingNames(todaySales, inventory)}
- PERFORMANCE (Last 7 Days): ${dailyPerf.entries.map((e) => "${e.key}: ${e.value}").join(" | ")}
- EXPIRY SNAPSHOT: ${expiringSoon.map((p) => "${p.name}(Exp: ${p.expires})").join(", ")}
''';
  }

  static String _getTopSellingNames(List<Sale> sales, List<model.Product> inventory) {
    final Map<String, int> counts = {};
    for (var s in sales) for (var i in s.items) counts[i.name] = (counts[i.name] ?? 0) + i.qty;
    final sorted = counts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => "${e.key} (${e.value} units)").join(", ");
  }

  static String generateRuleBasedResponse(
    String query,
    List<model.Product> inventory,
    List<Sale> sales, [
    List<Map<String, String>>? history,
  ]) {
    query = query.toLowerCase().trim();
    if (query.contains('revenue') || query.contains('sale')) {
      final total = sales.where((s) => s.date.day == DateTime.now().day).fold(0.0, (a, b) => a + b.total);
      return "Today's revenue is ${total.toInt()}. 💰";
    }
    return "I'm analyzing your store data. Ask me about stock levels or revenue! 😊";
  }
}

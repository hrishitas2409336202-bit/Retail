import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/product.dart' as model;
import '../models/sale.dart';

class AIService {
  // ── GitHub AI Brain Configuration ─────────────────────────────────────────
  // Replace with your GitHub Token (settings -> Developer -> Personal access tokens)
  static String githubToken = ''; // USER can set this or I'll provide a placeholder
  static const String githubEndpoint = 'https://models.inference.ai.azure.com/chat/completions';
  static const String githubModel = 'gpt-4o'; // Powerful model for retail analysis

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

  // ── Emoji mapping ────────────────────────────────────────────────────────
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

  // ── OpenFoodFacts Lookup ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProductFromBarcode(String barcode) async {
    // 1. Check local knowledge base first
    if (_localKB.containsKey(barcode)) return Map<String, dynamic>.from(_localKB[barcode]!);

    // 2. Query OpenFoodFacts
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
    } catch (e) {
      // silently fail, caller shows manual entry
    }
    return null;
  }

  // ── Rule-based AI Advisor ────────────────────────────────────────────────
  static String generateRuleBasedResponse(
    String query,
    List<model.Product> inventory,
    List<Sale> sales, [
    List<Map<String, String>>? history,
  ]) {
    query = query.toLowerCase().trim();

    String? prevTopic;
    if (history != null && history.isNotEmpty) {
      try {
        final lastAI = history.lastWhere((m) => m['role'] == 'ai');
        final lastText = lastAI['text']!.toLowerCase();
        if (lastText.contains('stock') || lastText.contains('restock')) prevTopic = 'stock';
        else if (lastText.contains('expir') || lastText.contains('fresh')) prevTopic = 'expiry';
        else if (lastText.contains('revenue') || lastText.contains('sale')) prevTopic = 'revenue';
      } catch (_) {}
    }

    final isGreeting = RegExp(r'\b(hi|hello|hey|morning|evening)\b').hasMatch(query);
    final hasBusinessKeyword = RegExp(r'\b(stock|restock|expir|date|sale|revenue|top|others|more|detail)\b').hasMatch(query);

    if (isGreeting && !hasBusinessKeyword) {
      final hour = DateTime.now().hour;
      final timeGreeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
      return "$timeGreeting! I've been reviewing your store data. We have some products moving fast today — what would you like me to look into first? 😊";
    }

    if (RegExp(r'\b(stock|stok|restock|restok|empty|fill|low|inventory)\b').hasMatch(query) ||
        ((query.contains('other') || query.contains('more')) && prevTopic == 'stock')) {
      final lowStock = inventory.where((p) => p.stock <= p.threshold).toList();
      if (lowStock.isEmpty) return "Everything is well-stocked right now. I'll keep an eye out for you! ✅";
      if (query.contains('other') || query.contains('more') || query.contains('list')) {
        final slice = lowStock.length > 3 ? lowStock.sublist(0, 3) : lowStock;
        final lines = slice.map((p) => "• **${p.name}** (${p.stock} left)").join("\n");
        return "Here are the items needing attention:\n$lines\n\nShould I help you draft purchase orders? 📦";
      }
      final p = lowStock.first;
      return "**${p.name}** is down to just ${p.stock} units. We should restock before the next rush! 📦";
    }

    if (RegExp(r'\b(expir|date|spoil|old|fresh)\b').hasMatch(query) ||
        ((query.contains('other') || query.contains('more')) && prevTopic == 'expiry')) {
      final expiring = inventory.where((p) => p.expires != null && (p.expires!.contains('day') || p.expires!.contains('hour'))).toList();
      if (expiring.isEmpty) return "Everything looks fresh! No expiry risks found today. ✨";
      final p = expiring.first;
      return "**${p.name}** is approaching its expiry. Consider creating a clearance promotion today! ⏰";
    }

    if (RegExp(r'\b(top|best|popular|trend|sell|most)\b').hasMatch(query)) {
      final Map<String, int> demand = {};
      for (var sale in sales) {
        for (var item in sale.items) {
          demand[item.name] = (demand[item.name] ?? 0) + item.qty;
        }
      }
      final sorted = demand.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.isEmpty) return "Waiting for the first few sales of the day to identify trends. 📈";
      return "**${sorted.first.key}** is the star of the show today! It's moving faster than anything else. 🏆";
    }

    if (RegExp(r'\b(revenue|money|sale|cash|today|profit|income)\b').hasMatch(query)) {
      final today = DateTime.now();
      final todaySales = sales.where((s) => s.date.day == today.day && s.date.month == today.month);
      double total = todaySales.fold(0, (a, b) => a + b.total);
      if (total == 0) return "No revenue recorded yet today, but the day is young! 🚀";
      return "We've reached **${total.toInt()}** in revenue today across ${todaySales.length} bills. Great progress! 💰";
    }
    // ── Fuzzy Product Search Fallback ──────────────────────────────────────
    // If we haven't matched a broad category, look for specific product names
    final queryWords = query.split(RegExp(r'\s+'));
    for (var p in inventory) {
      final nameLower = p.name.toLowerCase();
      // Check if product name is in query or if any word in query matches product name
      bool match = query.contains(nameLower) || nameLower.contains(query);
      if (!match) {
        for (var word in queryWords) {
          if (word.length > 3 && (nameLower.contains(word) || word.contains(nameLower))) {
            match = true; break;
          }
        }
      }
      
      if (match) {
        return "I found **${p.name}** in the records. You currently have **${p.stock}** units in stock. The selling price is **₹${p.price.toInt()}**. Is there anything else about this product you'd like to know? 🧐";
      }
    }

    return "I'm analyzing your store data. Ask me about stock levels, expiry dates, top sellers, or today's revenue! 😊";
  }

  // ── Smart AI Brain (GitHub Models) ───────────────────────────────────────
  static Future<String> getAIAdvice(
    String query,
    String context, // Summary data from AppState
    List<model.Product> inventory,
    List<Sale> sales,
    String language,
    List<Map<String, String>> history,
  ) async {
    // If no token, fall back to rule-based instantly
    if (githubToken.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      return generateRuleBasedResponse(query, inventory, sales, history);
    }

    try {
      // 1. Construct System Context with Actual Data
      final lowStock = inventory.where((p) => p.stock <= p.threshold).toList();
      final today = DateTime.now();
      final todaySales = sales.where((s) => s.date.day == today.day && s.date.month == today.month);
      final revenue = todaySales.fold(0.0, (a, b) => a + b.total);
      
      final Map<String, int> demand = {};
      for (var s in sales) for (var i in s.items) demand[i.name] = (demand[i.name] ?? 0) + i.qty;
      final sortedDemand = demand.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
      final topSellers = sortedDemand.take(5).map((e) => "• ${e.key}: ${e.value} sold").join("\n");

      // Build the FULL Inventory Summary
      final fullInventorySummary = inventory.map((p) => 
        "• ${p.emoji} ${p.name} | Stock: ${p.stock} | Price: ₹${p.price.toInt()} | Cat: ${p.category}"
      ).join("\n");

      final systemPrompt = """
You are RetailIQ Advisor, a professional retail business analyst AI.
You have access to the FULL records of the store inventory and performance metrics.

[GENERAL CONTEXT]
- Store Name: RetailIQ Demo
- Total Revenue Today: ₹${revenue.toInt()} (${todaySales.length} bills processed)
- Current Language: $language

[TOP PERFORMING PRODUCTS]
$topSellers

[LOW STOCK ALERTS]
${lowStock.isEmpty ? "All items healthy." : lowStock.map((p) => "• ${p.name} (${p.stock} left)").join("\n")}

[FULL INVENTORY RECORDS]
$fullInventorySummary

ROLE: Provide precise, data-driven, strategic advice. 
When asked about specific products, refer to the [FULL INVENTORY RECORDS].
If asked about performance, refer to [TOP PERFORMING PRODUCTS].
Always be professional, use bold for emphasis, and use emojis like 📦, 💰, 📈, 🚨 appropriately.
""";

      // 2. Map History to API format
      final messages = [
        {"role": "system", "content": systemPrompt},
        ...history.map((m) => {
          "role": m['role'] == 'ai' ? 'assistant' : 'user',
          "content": m['text'] ?? ""
        }),
        {"role": "user", "content": query}
      ];

      // 3. API Call to GitHub Models
      final response = await http.post(
        Uri.parse(githubEndpoint),
        headers: {
          'Authorization': 'Bearer ${githubToken.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": githubModel,
          "messages": messages,
          "temperature": 0.5,
          "max_tokens": 800,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['choices'][0]['message']['content']?.trim() ?? "I analyzed the data but couldn't form a response.";
      } else {
        debugPrint("AI_BRAIN_ERROR: Status ${response.statusCode}");
        debugPrint("AI_BRAIN_BODY: ${response.body}");
        return generateRuleBasedResponse(query, inventory, sales, history);
      }
    } catch (e) {
      debugPrint("AI_BRAIN_EXCEPTION: $e");
      return generateRuleBasedResponse(query, inventory, sales, history);
    }
  }
}


import 'dart:math';
import '../models/product.dart';

class AIResponseFormatter {
  static final Random _random = Random();

  static String pick(List<String> options) => options[_random.nextInt(options.length)];

  static String getGreeting() {
    return pick([
      "Hi! I've been analyzing your store activity. Here are some things you should know. 👋",
      "Hello! I just checked today’s store performance. Here are a few insights for you. 📊",
      "Hey! I ran a quick analysis on your inventory and sales. Here's what I found. 🧐",
      "Good to see you! I've got some updates on how the store is doing. 🏪",
    ]);
  }

  static String formatStockAlert(Product p, double daysRemaining) {
    final name = p.name;
    final days = daysRemaining.toStringAsFixed(1);
    
    return pick([
      "Heads up! $name might run out in about $days days. You may want to restock soon. 📦",
      "$name seems to be selling quickly. At this rate, it could run out in around $days days. 📈",
      "You might want to plan a restock for $name soon — current stock may last about $days days. ⏳",
      "I noticed $name is moving fast! We've only got about $days days of stock left. 🛒",
    ]);
  }

  static String formatExpiryAlert(Product p) {
    return pick([
      "I noticed that ${p.name} is expiring in ${p.expires}. You might want to offer a discount to move it faster. ⚠",
      "Heads up, ${p.name} is nearing its expiry date (${p.expires}). Should we run a promotion? 🏷️",
      "We've got some ${p.name} expiring in ${p.expires}. Let's try to clear it soon! 🕒",
    ]);
  }

  static String formatRiskAlert(Product p, String level) {
    if (level == 'High') {
      return pick([
        "I'm a bit concerned about ${p.name}. It's high risk due to low stock or near expiry. 🛡️",
        "Critical alert for ${p.name}! It needs your immediate attention. 🆘",
      ]);
    }
    return "${p.name} is showing some mid-level risk. Keep an eye on it! 🧐";
  }

  static String formatTopSellers(List<String> top3) {
    final items = top3.join(", ");
    return pick([
      "Right now, $items are your top performers! They are really popular today. 🏆",
      "It looks like $items are the big hits right now. Great choice having them in stock! 🌟",
      "The clear winners today are $items. They are moving faster than anything else. 🚀",
    ]);
  }

  static String formatRevenue(double total, int count) {
    return pick([
      "We've brought in ₹${total.toInt()} so far from $count transactions. Not a bad start! 💰",
      "Today's total revenue is ₹${total.toInt()} across $count bills. Business is moving! 📈",
    ]);
  }
}


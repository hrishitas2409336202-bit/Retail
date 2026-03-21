import 'dart:convert';
import 'package:flutter/foundation.dart';

class SaleItem {
  final String id;
  final String name;
  final int qty;
  final double price;

  SaleItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'qty': qty,
    'price': price,
  };

  factory SaleItem.fromJson(Map<dynamic, dynamic> json) => SaleItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    qty: (json['qty'] ?? 0) as int,
    price: (json['price'] ?? 0.0).toDouble(),
  );
}

class Sale {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double total;
  final String paymentMethod;
  final double amountReceived;
  final double changeReturned;

  Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    this.paymentMethod = 'Cash',
    this.amountReceived = 0.0,
    this.changeReturned = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'total': total,
    'paymentMethod': paymentMethod,
    'amountReceived': amountReceived,
    'changeReturned': changeReturned,
  };

  factory Sale.fromJson(Map<dynamic, dynamic> json) => Sale(
    id: json['id']?.toString() ?? '',
    date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
    items: json['items'] != null 
        ? (json['items'] as List).map((i) => SaleItem.fromJson(i as Map)).toList()
        : [],
    total: (json['total'] ?? 0.0).toDouble(),
    paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
    amountReceived: (json['amountReceived'] ?? 0.0).toDouble(),
    changeReturned: (json['changeReturned'] ?? 0.0).toDouble(),
  );

  /// Generates a Hardened, Sanitized URL for secure verification.
  /// Format: https://rq.link/v?d=<Base64>
  String toCompactCode() {
    try {
      // Sanitize names to avoid breaking the decoder delimiters (| : ;)
      final sanitizedItems = items.map((i) {
        final cleanName = i.name.replaceAll(RegExp(r'[|:;]'), ' ');
        return "${i.qty}x$cleanName:${i.price.toInt()}";
      }).join(';');
      
      final rawData = "V4|$id|$paymentMethod|${total.toInt()}|${date.millisecondsSinceEpoch}|$sanitizedItems";
      final bytes = utf8.encode(rawData);
      final encoded = base64Url.encode(bytes); // Use URL-safe mapping
      
      return "https://rq.link/v?d=$encoded";
    } catch (e) {
      debugPrint("QR Encoding Error: $e");
      return "VERIFY:$id"; // Ultra-safe fallback
    }
  }

  /// Reconstructs a Sale object from any supported QR format.
  static Sale? fromCompactCode(String code) {
    try {
      String rawData = '';
      
      if (code.contains("rq.link/v?d=")) {
        final uri = Uri.parse(code);
        final d = uri.queryParameters['d'] ?? '';
        final bytes = base64Url.decode(d);
        rawData = utf8.decode(bytes);
      } else if (code.startsWith("RIQ:")) {
        final encoded = code.substring(4);
        final bytes = base64.decode(encoded);
        rawData = utf8.decode(bytes);
      } else if (code.startsWith("RCV2|")) {
        rawData = code.substring(5);
      } else if (code.contains("verify?d=")) {
        final uri = Uri.parse(code);
        rawData = uri.queryParameters['d'] ?? '';
      } else {
        return null;
      }

      if (rawData.isEmpty) return null;
      final parts = rawData.split('|');
      
      // Handle V4, V3 (prefixed) vs V2 (unprefixed)
      int startIdx = (rawData.startsWith("V4|") || rawData.startsWith("V3|")) ? 1 : 0;
      if (parts.length < startIdx + 5) return null;

      final saleId = parts[startIdx];
      final method = parts[startIdx + 1];
      final totalAmount = double.tryParse(parts[startIdx + 2]) ?? 0.0;
      final saleDate = DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[startIdx + 3]) ?? 0);
      final itemsPart = parts[startIdx + 4];
      
      final saleItems = itemsPart.split(';').map((it) {
        final subParts = it.split(':');
        if (subParts.length < 2) return SaleItem(id: '?', name: 'Unknown', qty: 1, price: 0);
        
        final meta = subParts[0]; // "1xMilk"
        final price = double.tryParse(subParts[1]) ?? 0.0;
        
        final qtyParts = meta.split('x');
        final qty = int.tryParse(qtyParts[0]) ?? 1;
        final name = qtyParts.sublist(1).join('x'); 
        
        return SaleItem(id: '?', name: name, qty: qty, price: price);
      }).toList();

      return Sale(
        id: saleId,
        date: saleDate,
        items: saleItems,
        total: totalAmount,
        paymentMethod: method,
      );
    } catch (e) {
      debugPrint("QR Decoding Error: $e");
      return null;
    }
  }
}


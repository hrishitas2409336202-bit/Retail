import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/notification_service.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/supplier.dart';
import '../models/promotion.dart';
import '../services/ai_response_formatter.dart';
import 'dart:math' as math;

enum UserRole { admin, staff }

class AppState extends ChangeNotifier {
  late Box _inventoryBox;
  late Box _salesBox;
  late Box _suppliersBox;
  late Box _settingsBox;
  late Box _promotionsBox;
  late Box _pendingOrdersBox;
  late Box _loyaltyBox;
  late Box _eventsBox;

  List<Product> _inventory = [];
  List<Sale> _sales = [];
  List<Supplier> _suppliers = [];
  List<Promotion> _activePromotions = [];
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _loyaltyUsers = [];
  UserRole? _currentRole;
  ThemeMode _themeMode = ThemeMode.dark;
  String _currentLanguage = 'English'; // Default
  String _storeName = 'My Smart Retail';
  int _globalThreshold = 20;
  String _currency = '₹';
  double _taxRate = 18.0; // Default 18% GST
  String _upiId = 'retail.iq@upi'; // Default UPI VPA
  String _upiName = 'Store Owner'; // Default Account Name
  Map<String, dynamic> _ownerProfile = {
    'name': 'Store Owner',
    'email': 'owner@retailiq.com',
    'phone': '+91 9112692049'
  };
  Map<String, dynamic> _staffProfile = {
    'name': 'Store Staff',
    'email': 'staff@retailiq.com',
    'phone': '+91 9112692049'
  };
  
  // Activity Feed
  final List<String> _events = [
    "System initialized successfully.",
    "Inventory ready for testing.",
  ];

  // Offline Sync State
  bool _isOnline = true;
  int _unsyncedCount = 0;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  int get unsyncedCount => _unsyncedCount;
  bool get isSyncing => _isSyncing;
  List<Product> get inventory => _inventory;
  List<Sale> get sales => _sales;
  List<Supplier> get suppliers => _suppliers;
  List<Promotion> get activePromotions => _activePromotions;
  List<Map<String, dynamic>> get loyaltyUsers => _loyaltyUsers;
  UserRole? get currentRole => _currentRole;
  ThemeMode get themeMode => _themeMode;
  String get currentLanguage => _currentLanguage;
  String get storeName => _storeName;
  int get globalThreshold => _globalThreshold;
  String get currency => _currency;
  double get taxRate => _taxRate;
  String get upiId => _upiId;
  String get upiName => _upiName;
  Map<String, dynamic> get ownerProfile => _ownerProfile;
  Map<String, dynamic> get staffProfile => _staffProfile;
  List<String> get events => _events.reversed.toList(); // Newest first
  
  // -- Staff Dashboard Metrics --
  double get todayRevenue {
    final now = DateTime.now();
    return _sales.where((s) {
      return s.date.day == now.day && s.date.month == now.month && s.date.year == now.year;
    }).fold(0.0, (sum, s) => sum + s.total);
  }

  int get todayBillsCount {
    final now = DateTime.now();
    return _sales.where((s) {
      return s.date.day == now.day && s.date.month == now.month && s.date.year == now.year;
    }).length;
  }

  int get todayItemsSold {
    final now = DateTime.now();
    return _sales.where((s) {
      return s.date.day == now.day && s.date.month == now.month && s.date.year == now.year;
    }).fold(0, (sum, s) => sum + s.items.fold(0, (iSum, i) => iSum + i.qty));
  }

  List<Product> get lowStockProducts => _inventory.where((p) => p.stock <= p.threshold).toList();

  int get lowStockCount => _inventory.where((p) => p.stock <= p.threshold).length;

  List<Map<String, dynamic>> getTopSellingProducts(int limit) {
    final now = DateTime.now();
    final Map<String, int> counts = {};
    
    // Filter today's sales
    final todaySales = _sales.where((s) {
      return s.date.day == now.day && s.date.month == now.month && s.date.year == now.year;
    });

    for (var sale in todaySales) {
      for (var item in sale.items) {
        counts[item.name] = (counts[item.name] ?? 0) + item.qty;
      }
    }

    final sortedList = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedList.take(limit).map((e) {
      // Safer lookup with a null-safe fallback
      final product = _inventory.any((p) => p.name == e.key)
          ? _inventory.firstWhere((p) => p.name == e.key)
          : null;
          
      return {
        'name': e.key,
        'quantity': e.value,
        'emoji': product?.emoji ?? '📦',
        'totalValue': e.value * (product?.price ?? 0.0),
      };
    }).toList();
  }
  
  /// Real count: products that are out of stock need urgent attention
  int get pendingSupportCount => _inventory.where((p) => p.stock == 0).length;


  /// ── Risk Radar: Multi-factor product risk analysis ──
  List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TKT-001',
      'subject': 'Barcode scanner not responding',
      'category': 'Technical',
      'status': 'Open',
      'date': '15 Mar, 10:32 AM',
      'priority': 'High',
      'desc': 'The scanner doesn\'t beep when scanning milk packets.',
    },
    {
      'id': 'TKT-002',
      'subject': 'Stock count mismatch in Dairy section',
      'category': 'Inventory',
      'status': 'In Progress',
      'date': '14 Mar, 3:45 PM',
      'priority': 'Medium',
      'desc': 'System says 5 items left, but shelf is empty.',
    },
    {
      'id': 'TKT-003',
      'subject': 'UPI payment failed for customer',
      'category': 'Billing Issue',
      'status': 'Resolved',
      'date': '13 Mar, 11:10 AM',
      'priority': 'Low',
      'desc': 'Payment debited from customer but not shown in app.',
    },
  ];

  List<Map<String, dynamic>> get tickets => _tickets;

  int get activeTicketsCount => _tickets.where((t) => 
    t['status'] != 'Resolved' && t['status'] != 'Completed').length;

  void addTicket(Map<String, dynamic> ticket) {
    _tickets.insert(0, ticket);
    notifyListeners();
  }

  void updateTicketStatus(String ticketId, String status) {
    final index = _tickets.indexWhere((t) => t['id'] == ticketId);
    if (index != -1) {
      _tickets[index]['status'] = status;
      notifyListeners();
    }
  }

  void updateTicketPriority(String ticketId, String priority) {
    final index = _tickets.indexWhere((t) => t['id'] == ticketId);
    if (index != -1) {
      _tickets[index]['priority'] = priority;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getRiskRadar() {
    final now = DateTime.now();
    final last7Days = _sales.where((s) => now.difference(s.date).inDays <= 7).toList();
    final Map<String, int> salesCounts = {};
    for (var s in last7Days) for (var item in s.items) {
      salesCounts[item.name] = (salesCounts[item.name] ?? 0) + item.qty;
    }

    final results = <Map<String, dynamic>>[];
    for (var p in _inventory) {
      double riskScore = 0;
      // Factor 1: Low stock ratio
      if (p.threshold > 0) {
        final ratio = p.stock / p.threshold;
        if (ratio <= 0) riskScore += 60;
        else if (ratio < 1) riskScore += 50;
        else if (ratio < 1.5) riskScore += 25;
      }
      // Factor 2: Expiry risk
      if (p.expires != null && p.expires!.isNotEmpty) {
        if (p.expires!.contains('1 day') || p.expires!.contains('2 day')) riskScore += 30;
        else if (p.expires!.contains('day') || p.expires!.contains('hour')) riskScore += 15;
      }
      // Factor 3: Slow moving
      final sold = salesCounts[p.name] ?? 0;
      if (sold == 0 && p.stock > 50) riskScore += 20;
      else if (sold < 3) riskScore += 10;

      final level = riskScore >= 50 ? 'High' : riskScore >= 20 ? 'Medium' : 'Healthy';
      results.add({'product': p, 'score': riskScore, 'level': level});
    }
    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return results;
  }

  /// ── Generate Purchase Order Recommendations ──
  List<Map<String, dynamic>> generatePurchaseOrders() {
    final List<Map<String, dynamic>> orders = [];
    for (var p in _inventory) {
      if (p.stock <= p.threshold) {
        // Skip if an order is already pending for this product
        if (_pendingOrders.any((o) => o['productId'] == p.id && o['status'] == 'Pending')) continue;

        int recommended = (p.threshold * 2) - p.stock;
        if (recommended <= 0) recommended = 10; // Default min restock
        
        orders.add({
          'product': p,
          'recommended': recommended,
          'estCost': recommended * p.price * 0.7, // 30% margin assumption
          'priority': p.stock <= (p.threshold / 2) ? 'Urgent' : 'Low',
        });
      }
    }
    return orders;
  }



  String? _lastScanResult;
  String? get lastScanResult => _lastScanResult;

  void updateLastScan(String result) {
    _lastScanResult = result;
    addEvent("Staff scanned code: $result");
    notifyListeners();
  }

  Sale? getSaleById(String id) {
    try {
      return _sales.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Looks up a product by barcode string first, then falls back to product ID.
  /// Called by the scanner screen after every successful scan.
  Product? findProductById(String code) {
    // 1. Match by barcode field (most common case when scanning a real product)
    try {
      return _inventory.firstWhere(
        (p) => p.barcode != null && p.barcode!.trim() == code.trim(),
      );
    } catch (_) {}
    // 2. Fallback: match by product id
    try {
      return _inventory.firstWhere((p) => p.id == code);
    } catch (_) {}
    return null;
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _settingsBox.put('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  // ── Google Cloud Translate API Configuration ──────────────────────────────
  // To enable live translation, set your Google Cloud Translate API key below.
  // Get a key from: https://console.cloud.google.com/apis/credentials
  // Enable: Cloud Translation API.
  // Leave empty to use pre-baked translations only.
  static const String _googleTranslateApiKey = 'AIzaSyClON9XMXUtFFUUs85RYffXTajMs4VErlQ'; // Set your API key here
  static const String _translateEndpoint =
      'https://translation.googleapis.com/language/translate/v2';

  // Map language display names to Google Translate target codes
  static const Map<String, String> _langCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Marathi': 'mr',
  };

  /// Translate arbitrary text via Google Cloud Translate API.
  /// Returns the original text if the API key is not set or the call fails.
  Future<String> translateDynamic(String text) async {
    if (_currentLanguage == 'English') return text;
    if (_googleTranslateApiKey.isEmpty) return text;

    final targetCode = _langCodes[_currentLanguage] ?? 'en';
    try {
      final uri = Uri.parse('$_translateEndpoint?key=$_googleTranslateApiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'target': targetCode,
          'format': 'text',
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['translations'][0]['translatedText'] as String? ?? text;
      }
    } catch (_) {
      // Silently fall back to the original text
    }
    return text;
  }

  void setLanguage(String lang) async {
    _currentLanguage = lang;
    await _settingsBox.put('language', lang);
    notifyListeners();
    addEvent("Language changed to $lang");
  }

  String tr(String key) {
    // Basic pre-baked translations for critical UI
    final maps = {
      'English': {
        'store_command_center': 'Store Command Center',
        'Command Center Actions': 'Command Center Actions',
        'Promotions': 'Promotions',
        'Loyalty Hub': 'Loyalty Hub',
        'Risk Report': 'Risk Report',
        'Analytics': 'Analytics',
        'AI Insight': 'AI Insight',
        'Suppliers': 'Suppliers',
        'login_title': 'RetailIQ',
        'login_subtitle': 'Smart Inventory & Decisions',
        'role_select': 'Choose your role to continue',
        'admin_role': 'Store Owner / Admin',
        'admin_desc': 'Manage inventory, view AI insights',
        'staff_role': 'Store Staff / Cashier',
        'staff_desc': 'Billing, scanning and stock check',
        'logout': 'Logout',
        'inventory': 'Inventory',
        'billing': 'Billing',
        'history': 'History',
        'settings': 'Settings',
        'search_hint': 'Search items...',
        'add_to_cart': 'Add to Cart',
        'checkout': 'Checkout',
        'stock': 'Stock',
        'daily_revenue': 'Today\'s Revenue',
        'total_transactions': 'Total Transactions',
        'low_stock_items': 'Low Stock Items',
        'Vegetables & Fruits': 'Vegetables & Fruits',
        'Atta, Rice & Dal': 'Atta, Rice & Dal',
        'Oil, Ghee & Masala': 'Oil, Ghee & Masala',
        'Dairy, Bread & Eggs': 'Dairy, Bread & Eggs',
        'Bakery & Biscuits': 'Bakery & Biscuits',
        'Dry Fruits & Cereals': 'Dry Fruits & Cereals',
        'Chicken, Meat & Fish': 'Chicken, Meat & Fish',
        'Kitchenware & Appliances': 'Kitchenware & Appliances',
        'Chips & Namkeen': 'Chips & Namkeen',
        'Sweets & Chocolates': 'Sweets & Chocolates',
        'Drinks & Juices': 'Drinks & Juices',
        'Tea, Coffee & Milk Drinks': 'Tea, Coffee & Milk Drinks',
        'Instant Foods': 'Instant Foods',
        'Ice Creams & Frozen Foods': 'Ice Creams & Frozen Foods',
        'Ice Cream & Frozen Food': 'Ice Cream & Frozen Food',
        'Snacks & Packaged Foods': 'Snacks & Packaged Foods',
        'Beverages': 'Beverages',
        'Cleaning & Household': 'Cleaning & Household',
        'Personal Care': 'Personal Care',
        'Manage your stock and products': 'Manage your stock and products',
        'Search items, codes, or shelf...': 'Search items, codes, or shelf...',
        'Add Product': 'Add Product',
        'Update Stock': 'Update Stock',
        'Items': 'Items',
        'Browse': 'Browse',
        'Browse Category': 'Browse Category',
        'Total Items': 'Total Items',
        'in stock': 'in stock',
        'LOW STOCK < 20': 'LOW STOCK < 20',
        'LOW STOCK': 'LOW STOCK',
        'No products found': 'No products found',
        'items selected': 'items selected',
        'Revenue': 'Revenue',
        'Transactions': 'Transactions',
        'Avg Bill Value': 'Avg Bill Value',
        'Low Stock': 'Low Stock',
        'of ₹500 target': 'of ₹500 target',
        'AI Business Advisor': 'AI Business Advisor',
        'ai_analysis_loading': 'I\'m analyzing your inventory trends. Tap for a full report.',
        'Inventory Risk Radar': 'Inventory Risk Radar',
        'Products below restock threshold': 'Products below restock threshold',
        'All products are well stocked!': 'All products are well stocked!',
        'OUT': 'OUT',
        'LOW': 'LOW',
        'CRITICAL': 'CRITICAL',
        'Out': 'Out',
        'Low': 'Low',
        'Critical': 'Critical',
        'Clear filter': 'Clear filter',
        'show all': 'show all',
        'No products in this category': 'No products in this category',
        'Welcome back': 'Welcome back',
        'bills today': 'bills today',
        'AI Scanner': 'AI Scanner',
        'OpenFood Powered': 'OpenFood Powered',
        'products': 'products',
        'support': 'Support',
        'Get help': 'Get help',
        'Low Stock Alerts': 'Low Stock Alerts',
        'ITEMS': 'ITEMS',
        'Out of Stock!': 'Out of Stock!',
        'left': 'left',
        'Bills History': 'Bills History',
        'total transactions': 'total transactions',
        'Top Selling Today': 'Top Selling Today',
        'units sold': 'units sold',
        'NEW BILL': 'NEW BILL',
        'Master Inventory': 'Master Inventory',
        'Search master inventory...': 'Search master inventory...',
        'Add Master Product': 'Add Master Product',
        'Stock: ': 'Stock: ',
        'Edit details': 'Edit details',
        'Delete product': 'Delete product',
        'Delete Product?': 'Delete Product?',
        'delete_confirm_msg': 'Are you sure you want to remove this product from the master database?',
        'Cancel': 'Cancel',
        'Add': 'Add',
        'Update': 'Update',
        'Delete': 'Delete',
        'Sold': 'Sold',
        'Sales Leaderboard': 'Sales Leaderboard',
        'Profile': 'Profile',
        'Language': 'Language',
        'Today Sales': 'Today Sales',
        'Revenue': 'Revenue',
        'Tickets': 'Tickets',
        'Personal Information': 'Personal Information',
        'Full Name': 'Full Name',
        'Email': 'Email',
        'Phone': 'Phone',
        'Work Information': 'Work Information',
        'Store': 'Store',
        'Role': 'Role',
        'Shift': 'Shift',
        'Employee ID': 'Employee ID',
        'Account': 'Account',
        'logout_subtitle': 'Sign out of this session',
      },
      'Hindi': {
        'store_command_center': 'स्टोर कमांड सेंटर',
        'Command Center Actions': 'कमांड सेंटर कार्य',
        'Promotions': 'प्रचार (Promotions)',
        'Loyalty Hub': 'लॉयल्टी हब',
        'Risk Report': 'जोखिम रिपोर्ट',
        'Analytics': 'एनालिटिक्स',
        'AI Insight': 'AI अंतर्दृष्टि',
        'Suppliers': 'आपूर्तिकर्ता',
        'login_title': 'रिटेलआईक्यू',
        'login_subtitle': 'स्मार्ट इन्वेंटरी और निर्णय',
        'role_select': 'जारी रखने के लिए अपनी भूमिका चुनें',
        'admin_role': 'स्टोर मालिक / एडमिन',
        'admin_desc': 'इन्वेंट्री प्रबंधित करें, AI अंतर्दृष्टि देखें',
        'staff_role': 'स्टोर कर्मचारी / कैशियर',
        'staff_desc': 'बिलिंग, स्कैनिंग और स्टॉक जांच',
        'logout': 'लॉग आउट',
        'inventory': 'इन्वेंटरी',
        'billing': 'बिलिंग',
        'history': 'इतिहास',
        'settings': 'सेटिंग्स',
        'search_hint': 'सामान खोजें...',
        'add_to_cart': 'कार्ट में जोड़ें',
        'checkout': 'चेकआउट',
        'stock': 'स्टॉक',
        'daily_revenue': 'आज का राजस्व',
        'total_transactions': 'कुल लेनदेन',
        'low_stock_items': 'कम स्टॉक वाली वस्तुएं',
        'Vegetables & Fruits': 'सब्जियां और फल',
        'Atta, Rice & Dal': 'आटा, चावल और दाल',
        'Oil, Ghee & Masala': 'तेल, घी और मसाला',
        'Dairy, Bread & Eggs': 'डेयरी, ब्रेड और अंडे',
        'Bakery & Biscuits': 'बेकरी और बिस्कुट',
        'Dry Fruits & Cereals': 'सूखे मेवे और अनाज',
        'Chicken, Meat & Fish': 'चिकन, मांस और मछली',
        'Kitchenware & Appliances': 'बर्तन और उपकरण',
        'Chips & Namkeen': 'चिप्स और नमकीन',
        'Sweets & Chocolates': 'मिठाई और चॉकलेट',
        'Drinks & Juices': 'ड्रिंक्स और जूस',
        'Tea, Coffee & Milk Drinks': 'चाय, कॉफी और दूध',
        'Instant Foods': 'इंस्टेंट फूड्स',
        'Ice Creams & Frozen Foods': 'आइसक्रीम और फ्रोजन फूड',
        'Ice Cream & Frozen Food': 'आइसक्रीम और फ्रोजन फूड',
        'Snacks & Packaged Foods': 'स्नैक्स और डिब्बाबंद खाद्य पदार्थ',
        'Beverages': 'पेय पदार्थ',
        'Cleaning & Household': 'सफाई और घरेलू सामान',
        'Personal Care': 'व्यक्तिगत देखभाल',
        'Manage your stock and products': 'स्टॉक और उत्पादों का प्रबंधन करें',
        'Search items, codes, or shelf...': 'सामान, कोड या शेल्फ खोजें...',
        'Add Product': 'उत्पाद जोड़ें',
        'Update Stock': 'स्टॉक अद्यतन करें',
        'Items': 'सामान',
        'Browse': 'ब्राउज़ करें',
        'Browse Category': 'श्रेणी ब्राउज़ करें',
        'Total Items': 'कुल सामान',
        'in stock': 'स्टॉक में',
        'LOW STOCK < 20': 'स्टॉक कम < 20',
        'LOW STOCK': 'स्टॉक कम',
        'No products found': 'मद नहीं मिली',
        'items selected': 'सामान चुने गए',
        'Revenue': 'राजस्व',
        'Transactions': 'लेनदेन',
        'Avg Bill Value': 'औसत बिल',
        'Low Stock': 'कम स्टॉक',
        'of ₹500 target': '₹500 लक्ष्य का',
        'AI Business Advisor': 'AI बिजनेस सलाहकार',
        'ai_analysis_loading': 'मैं आपके इन्वेंट्री रुझानों का विश्लेषण कर रहा हूँ। पूरी रिपोर्ट के लिए टैप करें।',
        'Inventory Risk Radar': 'इन्वेंटरी रिस्क रडार',
        'Products below restock threshold': 'पुनर्प्राप्ति सीमा से नीचे उत्पाद',
        'All products are well stocked!': 'सभी उत्पादों का स्टॉक अच्छा है!',
        'OUT': 'खत्म',
        'LOW': 'कम',
        'CRITICAL': 'गंभीर',
        'Out': 'खत्म',
        'Low': 'कम',
        'Critical': 'गंभीर',
        'Clear filter': 'फ़िल्टर हटाएं',
        'show all': 'सभी दिखाएं',
        'No products in this category': 'इस श्रेणी में कोई उत्पाद नहीं है',
        'Welcome back': 'स्वागत है',
        'bills today': 'आज के बिल',
        'AI Scanner': 'AI स्कैनर',
        'OpenFood Powered': 'OpenFood द्वारा संचालित',
        'products': 'उत्पाद',
        'support': 'सहायता',
        'Get help': 'सहायता लें',
        'Low Stock Alerts': 'कम स्टॉक अलर्ट',
        'ITEMS': 'सामान',
        'Out of Stock!': 'स्टॉक खत्म!',
        'left': 'बाकी',
        'Bills History': 'बिल इतिहास',
        'total transactions': 'कुल लेनदेन',
        'Top Selling Today': 'आज की सबसे ज्यादा बिक्री',
        'units sold': 'यूनिट बिकीं',
        'NEW BILL': 'नया बिल',
        'Master Inventory': 'मास्टर इन्वेंटरी',
        'Search master inventory...': 'मास्टर इन्वेंटरी खोजें...',
        'Add Master Product': 'मास्टर उत्पाद जोड़ें',
        'Stock: ': 'स्टॉक: ',
        'Edit details': 'विवरण संपादित करें',
        'Delete product': 'उत्पाद हटाएं',
        'Delete Product?': 'उत्पाद हटाएं?',
        'delete_confirm_msg': 'क्या आप वाकई इस उत्पाद को मास्टर डेटाबेस से हटाना चाहते हैं?',
        'Cancel': 'रद्द करें',
        'Add': 'जोड़ें',
        'Update': 'अपडेट करें',
        'Delete': 'हटाएं',
        'Sold': 'बिका',
        'Sales Leaderboard': 'बिक्री लीडरबोर्ड',
        'Profile': 'प्रोफ़ाइल',
        'Language': 'भाषा',
        'Today Sales': 'आज की बिक्री',
        'Revenue': 'राजस्व',
        'Tickets': 'टिकट',
        'Personal Information': 'व्यक्तिगत जानकारी',
        'Full Name': 'पूरा नाम',
        'Email': 'ईमेल',
        'Phone': 'फोन',
        'Work Information': 'कार्य संबंधी जानकारी',
        'Store': 'स्टोर',
        'Role': 'भूमिका',
        'Shift': 'शिफ्ट',
        'Employee ID': 'कर्मचारी आईडी',
        'Account': 'खाता',
        'logout_subtitle': 'इस सत्र से लॉग आउट करें',
      },
      'Marathi': {
        'store_command_center': 'स्टोअर कमांड सेंटर',
        'Command Center Actions': 'कमांड सेंटर क्रिया',
        'Promotions': 'प्रमोशन्स',
        'Loyalty Hub': 'लॉयल्टी हब',
        'Risk Report': 'धोका अहवाल',
        'Analytics': 'अॅनालिटिक्स',
        'AI Insight': 'AI इनसाइट',
        'Suppliers': 'पुरवठादार',
        'login_title': 'रिटेल-आय-क्यू',
        'login_subtitle': 'स्मार्ट इन्व्हेंटरी आणि निर्णय',
        'role_select': 'सुरू ठेवण्यासाठी तुमची भूमिका निवडा',
        'admin_role': 'स्टोअर मालक / प्रशासक',
        'admin_desc': 'इन्व्हेंटरी व्यवस्थापित करा, AI अंतर्दृष्टी पहा',
        'staff_role': 'स्टोअर कर्मचारी / कॅशियर',
        'staff_desc': 'बिलिंग, स्कॅनिंग आणि स्टॉक चेक',
        'logout': 'लॉग आउट',
        'inventory': 'इन्व्हेंटरी',
        'billing': 'बिलिंग',
        'history': 'इतिहास',
        'settings': 'सेटिंग्ज',
        'search_hint': 'वस्तू शोधा...',
        'add_to_cart': 'कार्टमध्ये जोडा',
        'checkout': 'चेकआउट',
        'stock': 'स्टॉक',
        'daily_revenue': 'आजचा महसूल',
        'total_transactions': 'एकूण व्यवहार',
        'low_stock_items': 'कमी स्टॉक वस्तू',
        'Vegetables & Fruits': 'भाज्या आणि फळे',
        'Atta, Rice & Dal': 'पीठ, तांदूळ आणि डाळ',
        'Oil, Ghee & Masala': 'तेल, तूप आणि मसाला',
        'Dairy, Bread & Eggs': 'डेअरी, ब्रेड आणि अंडी',
        'Bakery & Biscuits': 'बेकरी आणि बिस्किटे',
        'Dry Fruits & Cereals': 'सुकामेवा आणि तृणधान्ये',
        'Chicken, Meat & Fish': 'चिकन, मांस आणि मासे',
        'Kitchenware & Appliances': 'भांडी आणि उपकरणे',
        'Chips & Namkeen': 'चिप्स आणि नमकीन',
        'Sweets & Chocolates': 'मिठाई आणि चॉकोलेट',
        'Drinks & Juices': 'पेये आणि ज्यूस',
        'Tea, Coffee & Milk Drinks': 'चहा, कॉफी आणि दूध',
        'Instant Foods': 'इन्स्टंट फूड्स',
        'Ice Creams & Frozen Foods': 'आईस्क्रीम आणि फ्रोझन फूड',
        'Ice Cream & Frozen Food': 'आईस्क्रीम आणि फ्रोझन फूड',
        'Snacks & Packaged Foods': 'स्नॅक्स आणि पॅकेज्ड पदार्थ',
        'Beverages': 'पेये',
        'Cleaning & Household': 'स्वच्छता आणि घरगुती वस्तू',
        'Personal Care': 'वैयक्तिक निगा',
        'Manage your stock and products': 'स्टॉक आणि उत्पादने व्यवस्थापित करा',
        'Search items, codes, or shelf...': 'वस्तू, कोड किंवा शेल्फ शोधा...',
        'Add Product': 'उत्पादन जोडा',
        'Update Stock': 'स्टॉक अपडेट करा',
        'Items': 'वस्तू',
        'Browse': 'ब्राउझ करा',
        'Browse Category': 'श्रेणी ब्राउझ करा',
        'Total Items': 'एकूण वस्तू',
        'in stock': 'स्टॉकमध्ये',
        'LOW STOCK < 20': 'स्टॉक कमी < 20',
        'LOW STOCK': 'स्टॉक कमी',
        'No products found': 'वस्तू सापडली नाही',
        'items selected': 'वस्तू निवडल्या',
        'Revenue': 'महसूल',
        'Transactions': 'व्यवहार',
        'Avg Bill Value': 'सरासरी बिल',
        'Low Stock': 'कमी स्टॉक',
        'of ₹500 target': '₹500 लक्ष्याचे',
        'AI Business Advisor': 'AI बिजनेस सल्लागार',
        'ai_analysis_loading': 'मी तुमच्या इन्व्हेंटरी ट्रेंडचे विश्लेषण करत आहे. पूर्ण अहवालासाठी टॅप करा.',
        'Inventory Risk Radar': 'इन्व्हेंटरी रिस्क रडार',
        'Products below restock threshold': 'पुनर्प्राप्ती मर्यादेपेक्षा कमी उत्पादने',
        'All products are well stocked!': 'सर्व उत्पादनांचा स्टॉक चांगला आहे!',
        'OUT': 'संपले',
        'LOW': 'कमी',
        'CRITICAL': 'गंभीर',
        'Out': 'संपले',
        'Low': 'कमी',
        'Critical': 'गंभीर',
        'Clear filter': 'फिल्टर काढा',
        'show all': 'सर्व दाखवा',
        'No products in this category': 'या श्रेणीमध्ये कोणतेही उत्पादन नाही',
        'Welcome back': 'पुन्हा स्वागत आहे',
        'bills today': 'आजची बिले',
        'AI Scanner': 'AI स्कॅनर',
        'OpenFood Powered': 'OpenFood द्वारे संचालित',
        'products': 'उत्पादने',
        'support': 'मदत',
        'Get help': 'मदत घ्या',
        'Low Stock Alerts': 'कमी स्टॉक अलर्ट',
        'ITEMS': 'वस्तू',
        'Out of Stock!': 'स्टॉक संपला!',
        'left': 'बाकी',
        'Bills History': 'बिल इतिहास',
        'total transactions': 'एकूण व्यवहार',
        'Top Selling Today': 'आजची सर्वाधिक विक्री',
        'units sold': 'यूनिट विकले',
        'NEW BILL': 'नवीन बिल',
        'Master Inventory': 'मास्टर इन्व्हेंटरी',
        'Search master inventory...': 'मास्टर इन्व्हेंटरी शोधा...',
        'Add Master Product': 'मास्टर उत्पादन जोडा',
        'Stock: ': 'स्टॉक: ',
        'Edit details': 'तपशील संपादित करा',
        'Delete product': 'उत्पादन काढा',
        'Delete Product?': 'उत्पादन काढायचे?',
        'delete_confirm_msg': 'तुम्ही खात्रीने हे उत्पादन मास्टर डेटाबेसमधून काढू इच्छिता?',
        'Cancel': 'रद्द करा',
        'Add': 'जोडा',
        'Update': 'अपडेट करा',
        'Delete': 'काढा',
        'Sold': 'विकले',
        'Sales Leaderboard': 'विक्री लीडरबोर्ड',
        'Profile': 'प्रोफाइल',
        'Language': 'भाषा',
        'Today Sales': 'आजची विक्री',
        'Revenue': 'महसूल',
        'Tickets': 'तिकीट',
        'Personal Information': 'वैयक्तिक माहिती',
        'Full Name': 'पूर्ण नाव',
        'Email': 'ईमेल',
        'Phone': 'फोन',
        'Work Information': 'कामाची माहिती',
        'Store': 'स्टोअर',
        'Role': 'भूमिका',
        'Shift': 'शिफ्ट',
        'Employee ID': 'कर्मचारी आयडी',
        'Account': 'खाते',
        'logout_subtitle': 'या सत्रातून बाहेर पडा',
      }
    };

    return maps[_currentLanguage]?[key] ?? key;
  }

  void addEvent(String msg) {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    _events.add("[$h:$m] $msg");
    if (_events.length > 50) _events.removeAt(0);
    _eventsBox.clear();
    _eventsBox.addAll(_events);
    notifyListeners();
  }

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      _inventoryBox = await Hive.openBox('inventory');
      _salesBox = await Hive.openBox('sales');
      _suppliersBox = await Hive.openBox('suppliers');
      _settingsBox = await Hive.openBox('settings');
      _promotionsBox = await Hive.openBox('promotions');
      _pendingOrdersBox = await Hive.openBox('pending_orders');
      _eventsBox = await Hive.openBox('events');

      // Only seed data if empty
      if (_inventoryBox.isEmpty) {
        await _seedData();
      }
      if (_suppliersBox.isEmpty) {
        await _seedSuppliers();
      }
      
      _loadData();
      _loadEvents();
      await _fixExistingContacts();

      _loadPromotions();
      _loyaltyBox = await Hive.openBox('loyalty');
      if (_loyaltyBox.isEmpty) {
        await _seedLoyalty();
      } else {
        _loadLoyalty();
      }

      final savedRole = _settingsBox.get('role');
      if (savedRole != null) {
        _currentRole = savedRole == 'admin' ? UserRole.admin : UserRole.staff;
      }

      final savedTheme = _settingsBox.get('theme_mode');
      if (savedTheme != null) {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }

      _currentLanguage = _settingsBox.get('language', defaultValue: 'English');

      _unsyncedCount = _settingsBox.get('unsynced_count', defaultValue: 0);
      _storeName = _settingsBox.get('store_name', defaultValue: 'My Smart Retail');
      _globalThreshold = _settingsBox.get('global_threshold', defaultValue: 10);
      _currency = _settingsBox.get('currency', defaultValue: '₹');
      _taxRate = _settingsBox.get('tax_rate', defaultValue: 18.0);
    _upiId = _settingsBox.get('upi_id', defaultValue: 'retail.iq@upi');
    _upiName = _settingsBox.get('upi_name', defaultValue: 'Store Owner');
      _ownerProfile = Map<String, dynamic>.from(_settingsBox.get('owner_profile', defaultValue: _ownerProfile));
      _staffProfile = Map<String, dynamic>.from(_settingsBox.get('staff_profile', defaultValue: _staffProfile));
      
      notifyListeners();
    } catch (e, stack) {
      print("APP STATE INIT ERROR: $e");
      print("STACK: $stack");
    }
  }

  Future<void> _seedData() async {
    final initialInventory = [
      {"id": "PRD001", "name": "Fresh Apples", "category": "Vegetables & Fruits", "price": 180.0, "stock": 30, "threshold": 20, "emoji": "🍎", "shelf": "S1", "unit": "1 kg", "description": "Fresh and crisp red apples.", "imageUrl": "https://images.unsplash.com/photo-1560806887-1e4cd0b6caa6?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD002", "name": "Organic Bananas", "category": "Vegetables & Fruits", "price": 60.0, "stock": 45, "threshold": 20, "emoji": "🍌", "shelf": "S1", "unit": "1 dozen", "description": "Naturally ripened sweet bananas.", "imageUrl": "https://images.unsplash.com/photo-1571501470233-a332a6cb82e4?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD003", "name": "Hass Avocado", "category": "Vegetables & Fruits", "price": 240.0, "stock": 60, "threshold": 20, "emoji": "🥑", "shelf": "S1", "unit": "2 pcs", "description": "Creamy and ready-to-eat avocados.", "imageUrl": "https://images.unsplash.com/photo-1519162808019-7de1683fa2ad?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD004", "name": "Hybrid Tomatoes", "category": "Vegetables & Fruits", "price": 40.0, "stock": 52, "threshold": 20, "emoji": "🍅", "shelf": "S1", "unit": "1 kg", "description": "Firm and juicy red tomatoes.", "imageUrl": "https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD005", "name": "Fresh Spinach Bunch", "category": "Vegetables & Fruits", "price": 30.0, "stock": 70, "threshold": 20, "emoji": "🥬", "shelf": "S1", "unit": "1 bunch", "description": "Green and leafy farm spinach.", "imageUrl": "https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD006", "name": "Red Bell Pepper", "category": "Vegetables & Fruits", "price": 120.0, "stock": 78, "threshold": 20, "emoji": "🫑", "shelf": "S1", "unit": "1 kg", "description": "Sweet and crunchy bell peppers.", "imageUrl": "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD007", "name": "Green Grapes Seedless", "category": "Vegetables & Fruits", "price": 150.0, "stock": 63, "threshold": 20, "emoji": "🍇", "shelf": "S1", "unit": "500 g", "description": "Sweet seedless green grapes.", "imageUrl": "https://images.unsplash.com/photo-1596363505729-41941ba9e1cd?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD008", "name": "Pomegranates", "category": "Vegetables & Fruits", "price": 200.0, "stock": 94, "threshold": 20, "emoji": "🍎", "shelf": "S1", "unit": "1 kg", "description": "Juicy and rich pomegranates.", "imageUrl": "https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD009", "name": "Organic Carrots", "category": "Vegetables & Fruits", "price": 70.0, "stock": 7, "threshold": 20, "emoji": "🥕", "shelf": "S1", "unit": "1 kg", "description": "Crunchy orange carrots.", "imageUrl": "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD010", "name": "Sweet Corn", "category": "Vegetables & Fruits", "price": 45.0, "stock": 86, "threshold": 20, "emoji": "🌽", "shelf": "S1", "unit": "2 pcs", "description": "Fresh yellow sweet corn.", "imageUrl": "https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD011", "name": "Potatoes", "category": "Vegetables & Fruits", "price": 35.0, "stock": 99, "threshold": 20, "emoji": "🥔", "shelf": "S1", "unit": "1 kg", "description": "Multi-purpose cooking potatoes.", "imageUrl": "https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD012", "name": "Green Beans", "category": "Vegetables & Fruits", "price": 80.0, "stock": 86, "threshold": 20, "emoji": "🥒", "shelf": "S1", "unit": "1 kg", "description": "Fresh crunchy green string beans.", "imageUrl": "https://images.unsplash.com/photo-1562923696-2775aab518fb?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD013", "name": "Onions", "category": "Vegetables & Fruits", "price": 40.0, "stock": 8, "threshold": 20, "emoji": "🧅", "shelf": "S1", "unit": "1 kg", "description": "Essential red cooking onions.", "imageUrl": "https://images.unsplash.com/photo-1620574387735-3624d75b2dbc?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD014", "name": "Aashirvaad Atta", "category": "Atta, Rice & Dal", "price": 485.0, "stock": 78, "threshold": 20, "emoji": "🌾", "shelf": "S2", "unit": "10 kg", "description": "Premium whole wheat chakki atta.", "imageUrl": "https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD015", "name": "Kohinoor Basmati Rice", "category": "Atta, Rice & Dal", "price": 520.0, "stock": 10, "threshold": 20, "emoji": "🍚", "shelf": "S2", "unit": "5 kg", "description": "Long-grain royal basmati rice.", "imageUrl": "https://images.unsplash.com/photo-1536304929831-2fb0c69d0340?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD016", "name": "Toor Dal unpolished", "category": "Atta, Rice & Dal", "price": 165.0, "stock": 66, "threshold": 20, "emoji": "🥣", "shelf": "S2", "unit": "1 kg", "description": "Protein-rich premium toor dal.", "imageUrl": "https://images.unsplash.com/photo-1585994235474-9f82de897745?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD017", "name": "Moong Dal", "category": "Atta, Rice & Dal", "price": 140.0, "stock": 77, "threshold": 20, "emoji": "🥣", "shelf": "S2", "unit": "1 kg", "description": "Organic cleaned yellow moong dal.", "imageUrl": "https://images.unsplash.com/photo-1561081622-b5e197d15fc3?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD018", "name": "Sona Masuri Rice", "category": "Atta, Rice & Dal", "price": 650.0, "stock": 10, "threshold": 20, "emoji": "🍚", "shelf": "S2", "unit": "10 kg", "description": "Everyday usage premium sona masuri.", "imageUrl": "https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD019", "name": "Chana Dal", "category": "Atta, Rice & Dal", "price": 110.0, "stock": 65, "threshold": 20, "emoji": "🥣", "shelf": "S2", "unit": "1 kg", "description": "High quality protein chana dal.", "imageUrl": "https://images.unsplash.com/photo-1585994235474-9f82de897745?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD020", "name": "Kabuli Chana", "category": "Atta, Rice & Dal", "price": 180.0, "stock": 48, "threshold": 20, "emoji": "🥣", "shelf": "S2", "unit": "1 kg", "description": "Large white chickpeas.", "imageUrl": "https://images.unsplash.com/photo-1561081622-b5e197d15fc3?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD021", "name": "Fortune Besan", "category": "Atta, Rice & Dal", "price": 95.0, "stock": 59, "threshold": 20, "emoji": "🌾", "shelf": "S2", "unit": "1 kg", "description": "Finely grounded gram flour.", "imageUrl": "https://images.unsplash.com/photo-1627485937980-221c88ce04ea?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD022", "name": "Madhur Sugar", "category": "Atta, Rice & Dal", "price": 45.0, "stock": 37, "threshold": 20, "emoji": "🍬", "shelf": "S2", "unit": "1 kg", "description": "Pure and hygienic fine sugar.", "imageUrl": "https://images.unsplash.com/photo-1622485493026-6a2c2df9e578?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD023", "name": "Tata Salt", "category": "Atta, Rice & Dal", "price": 28.0, "stock": 9, "threshold": 20, "emoji": "🧂", "shelf": "S2", "unit": "1 kg", "description": "Iodized quality table salt.", "imageUrl": "https://images.unsplash.com/photo-1518110925485-5ce82d8c3656?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD024", "name": "Urad Dal White", "category": "Atta, Rice & Dal", "price": 150.0, "stock": 46, "threshold": 20, "emoji": "🥣", "shelf": "S2", "unit": "1 kg", "description": "Split and skinned white urad.", "imageUrl": "https://images.unsplash.com/photo-1585994235474-9f82de897745?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD025", "name": "Rajma Chitra", "category": "Atta, Rice & Dal", "price": 160.0, "stock": 8, "threshold": 20, "emoji": "🥣", "shelf": "S2", "unit": "1 kg", "description": "Speckled kidney beans for thick gravy.", "imageUrl": "https://images.unsplash.com/photo-1561081622-b5e197d15fc3?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD026", "name": "Idli Rice", "category": "Atta, Rice & Dal", "price": 85.0, "stock": 22, "threshold": 20, "emoji": "🍚", "shelf": "S2", "unit": "1 kg", "description": "Round grained rice specially for Idli batter.", "imageUrl": "https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD027", "name": "Fortune Sunflower Oil", "category": "Oil, Ghee & Masala", "price": 165.0, "stock": 63, "threshold": 20, "emoji": "🌻", "shelf": "S3", "unit": "1 Litre", "description": "Light and healthy sunflower oil for daily cooking.", "imageUrl": "https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD028", "name": "Amul Pure Ghee", "category": "Oil, Ghee & Masala", "price": 310.0, "stock": 56, "threshold": 20, "emoji": "🧈", "shelf": "S3", "unit": "500 ml", "description": "Rich, premium pure cow ghee.", "imageUrl": "https://plus.unsplash.com/premium_photo-1694707172082-9366115fb6de?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD029", "name": "Everest Turmeric Powder", "category": "Oil, Ghee & Masala", "price": 35.0, "stock": 10, "threshold": 20, "emoji": "🌶️", "shelf": "S3", "unit": "100 g", "description": "High quality yellow turmeric powder.", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD030", "name": "Catch Red Chili Powder", "category": "Oil, Ghee & Masala", "price": 45.0, "stock": 51, "threshold": 20, "emoji": "🌶️", "shelf": "S3", "unit": "100 g", "description": "Spicy red chilli powder.", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD031", "name": "Saffola Gold Oil", "category": "Oil, Ghee & Masala", "price": 195.0, "stock": 64, "threshold": 20, "emoji": "🌻", "shelf": "S3", "unit": "1 Litre", "description": "Pro-health blended edible oil.", "imageUrl": "https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD032", "name": "Everest Garam Masala", "category": "Oil, Ghee & Masala", "price": 65.0, "stock": 7, "threshold": 20, "emoji": "🌶️", "shelf": "S3", "unit": "50 g", "description": "Authentic blend of Indian spices.", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD033", "name": "Patanjali Mustard Oil", "category": "Oil, Ghee & Masala", "price": 180.0, "stock": 22, "threshold": 20, "emoji": "🌻", "shelf": "S3", "unit": "1 Litre", "description": "Kachi Ghani pure mustard oil.", "imageUrl": "https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD034", "name": "Cumin Seeds (Jeera)", "category": "Oil, Ghee & Masala", "price": 85.0, "stock": 59, "threshold": 20, "emoji": "🌿", "shelf": "S3", "unit": "100 g", "description": "Aromatic unroasted cumin seeds.", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD035", "name": "Black Pepper Whole", "category": "Oil, Ghee & Masala", "price": 120.0, "stock": 82, "threshold": 20, "emoji": "🌿", "shelf": "S3", "unit": "50 g", "description": "Strong premium black peppercorns.", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD036", "name": "Coriander Powder", "category": "Oil, Ghee & Masala", "price": 40.0, "stock": 13, "threshold": 20, "emoji": "🌿", "shelf": "S3", "unit": "100 g", "description": "Freshly ground coriander powder.", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD037", "name": "Gowardhan Ghee", "category": "Oil, Ghee & Masala", "price": 580.0, "stock": 83, "threshold": 20, "emoji": "🧈", "shelf": "S3", "unit": "1 Litre", "description": "Rich aroma Desi ghee.", "imageUrl": "https://plus.unsplash.com/premium_photo-1694707172082-9366115fb6de?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD038", "name": "MDH Chana Masala", "category": "Oil, Ghee & Masala", "price": 75.0, "stock": 6, "threshold": 20, "emoji": "🌶️", "shelf": "S3", "unit": "100 g", "description": "Special spice mix for Chana.", "imageUrl": "https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD039", "name": "Virgin Olive Oil", "category": "Oil, Ghee & Masala", "price": 850.0, "stock": 32, "threshold": 20, "emoji": "🫒", "shelf": "S3", "unit": "500 ml", "description": "Cold-pressed extra virgin olive oil.", "imageUrl": "https://images.unsplash.com/photo-1474979266404-7eaacbacf849?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD040", "name": "Amul Taaza Milk", "category": "Dairy, Bread & Eggs", "price": 58.0, "stock": 5, "threshold": 20, "emoji": "🥛", "shelf": "S4", "unit": "1 Litre", "description": "Fresh toned milk tetra pack.", "imageUrl": "https://images.unsplash.com/photo-1550583724-125581f779ed?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD041", "name": "Britannia Brown Bread", "category": "Dairy, Bread & Eggs", "price": 45.0, "stock": 62, "threshold": 20, "emoji": "🍞", "shelf": "S4", "unit": "1 packet", "description": "Whole wheat healthy brown bread.", "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD042", "name": "Farm Fresh Eggs", "category": "Dairy, Bread & Eggs", "price": 84.0, "stock": 72, "threshold": 20, "emoji": "🥚", "shelf": "S4", "unit": "1 Dozen", "description": "High protein fresh white eggs.", "imageUrl": "https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD043", "name": "Amul Butter", "category": "Dairy, Bread & Eggs", "price": 56.0, "stock": 93, "threshold": 20, "emoji": "🧈", "shelf": "S4", "unit": "100 g", "description": "Delicious pasteurized butter.", "imageUrl": "https://images.unsplash.com/photo-1588195538326-c5b1e9f6f5b4?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD044", "name": "Mother Dairy Paneer", "category": "Dairy, Bread & Eggs", "price": 90.0, "stock": 13, "threshold": 20, "emoji": "🧀", "shelf": "S4", "unit": "200 g", "description": "Fresh and soft malai paneer.", "imageUrl": "https://images.unsplash.com/photo-1631387227447-fd9b85c1dbcf?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD045", "name": "Nestle Dahi", "category": "Dairy, Bread & Eggs", "price": 40.0, "stock": 37, "threshold": 20, "emoji": "🥛", "shelf": "S4", "unit": "400 g", "description": "Thick and tasty set curd.", "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD046", "name": "Garlic Bread Loaf", "category": "Dairy, Bread & Eggs", "price": 65.0, "stock": 17, "threshold": 20, "emoji": "🍞", "shelf": "S4", "unit": "250 g", "description": "Freshly baked garlic bread loaf.", "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD047", "name": "Nutrela Soya Milk", "category": "Dairy, Bread & Eggs", "price": 140.0, "stock": 20, "threshold": 20, "emoji": "🥛", "shelf": "S4", "unit": "1 Litre", "description": "Plain organic vegan soya milk.", "imageUrl": "https://images.unsplash.com/photo-1550583724-125581f779ed?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD048", "name": "Epigamia Greek Yogurt", "category": "Dairy, Bread & Eggs", "price": 55.0, "stock": 20, "threshold": 20, "emoji": "🥛", "shelf": "S4", "unit": "100 g", "description": "High protein natural greek yogurt.", "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD049", "name": "Amul Cheese Slices", "category": "Dairy, Bread & Eggs", "price": 160.0, "stock": 72, "threshold": 20, "emoji": "🧀", "shelf": "S4", "unit": "10 slices", "description": "Processed cheese slices.", "imageUrl": "https://images.unsplash.com/photo-1550583724-125581f779ed?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD050", "name": "White Sandwich Bread", "category": "Dairy, Bread & Eggs", "price": 40.0, "stock": 5, "threshold": 20, "emoji": "🍞", "shelf": "S4", "unit": "1 packet", "description": "Soft and fluffy white bread slice.", "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD051", "name": "Pizza Base", "category": "Dairy, Bread & Eggs", "price": 35.0, "stock": 20, "threshold": 20, "emoji": "🍕", "shelf": "S4", "unit": "2 pcs", "description": "Ready to bake pizza bases.", "imageUrl": "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD052", "name": "Parle-G Biscuits", "category": "Snacks & Packaged Foods", "price": 65.0, "stock": 5, "threshold": 20, "emoji": "🍪", "shelf": "S5", "unit": "800 g", "description": "Original glucose biscuits.", "imageUrl": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD053", "name": "Oreo Chocolate Cookies", "category": "Snacks & Packaged Foods", "price": 35.0, "stock": 29, "threshold": 20, "emoji": "🍪", "shelf": "S5", "unit": "120 g", "description": "Classic sandwich cookies.", "imageUrl": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD054", "name": "Maggi 2-Minute Noodles", "category": "Snacks & Packaged Foods", "price": 144.0, "stock": 32, "threshold": 20, "emoji": "🍜", "shelf": "S5", "unit": "12 pack", "description": "The famous instant masala noodles.", "imageUrl": "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD055", "name": "Lays Magic Masala", "category": "Snacks & Packaged Foods", "price": 20.0, "stock": 78, "threshold": 20, "emoji": "🍟", "shelf": "S5", "unit": "50 g", "description": "Crispy spicy potato chips.", "imageUrl": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD056", "name": "Haldiram Aloo Bhujia", "category": "Snacks & Packaged Foods", "price": 105.0, "stock": 95, "threshold": 20, "emoji": "🥨", "shelf": "S5", "unit": "400 g", "description": "Spicy potato and besan noodles.", "imageUrl": "https://images.unsplash.com/photo-1621303837174-89787a7d4729?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD057", "name": "Pringles Sour Cream", "category": "Snacks & Packaged Foods", "price": 110.0, "stock": 33, "threshold": 20, "emoji": "🍟", "shelf": "S5", "unit": "110 g", "description": "Sour cream and onion stacked chips.", "imageUrl": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD058", "name": "Knorr Tomato Soup", "category": "Snacks & Packaged Foods", "price": 55.0, "stock": 58, "threshold": 20, "emoji": "🥣", "shelf": "S5", "unit": "4 serves", "description": "Instant thick tomato soup powder.", "imageUrl": "https://images.unsplash.com/photo-1574484284002-952d92456975?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD059", "name": "Nutella Hazelnut Spread", "category": "Snacks & Packaged Foods", "price": 350.0, "stock": 95, "threshold": 20, "emoji": "🍫", "shelf": "S5", "unit": "350 g", "description": "Delicious cocoa hazelnut spread.", "imageUrl": "https://images.unsplash.com/photo-1582293041079-7814c2f12063?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD060", "name": "Kissan Mixed Fruit Jam", "category": "Snacks & Packaged Foods", "price": 120.0, "stock": 66, "threshold": 20, "emoji": "🍓", "shelf": "S5", "unit": "500 g", "description": "Sweet fruit jam for breakfast.", "imageUrl": "https://images.unsplash.com/photo-1582293041079-7814c2f12063?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD061", "name": "Kellogg's Corn Flakes", "category": "Snacks & Packaged Foods", "price": 190.0, "stock": 87, "threshold": 20, "emoji": "🥣", "shelf": "S5", "unit": "500 g", "description": "Crunchy original corn flakes.", "imageUrl": "https://images.unsplash.com/photo-1521483756775-addabfc80dec?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD062", "name": "Quaker Oats", "category": "Snacks & Packaged Foods", "price": 160.0, "stock": 34, "threshold": 20, "emoji": "🥣", "shelf": "S5", "unit": "1 kg", "description": "Healthy whole grain oats.", "imageUrl": "https://images.unsplash.com/photo-1517673132405-a56a62b18caf?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD063", "name": "Dairy Milk Silk", "category": "Snacks & Packaged Foods", "price": 175.0, "stock": 65, "threshold": 20, "emoji": "🍫", "shelf": "S5", "unit": "150 g", "description": "Premium smooth milk chocolate.", "imageUrl": "https://images.unsplash.com/photo-1614088685112-0a860dbbfbe9?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD064", "name": "Ferrero Rocher", "category": "Snacks & Packaged Foods", "price": 890.0, "stock": 73, "threshold": 20, "emoji": "💎", "shelf": "S5", "unit": "16 pcs", "description": "Crisp hazelnut and milk chocolate.", "imageUrl": "https://images.unsplash.com/photo-1548844877-38e4a9042b31?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD065", "name": "Sunfeast Dark Fantasy", "category": "Snacks & Packaged Foods", "price": 90.0, "stock": 40, "threshold": 20, "emoji": "🍪", "shelf": "S5", "unit": "75 g", "description": "Choco-filled delicious cookies.", "imageUrl": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD066", "name": "Coca-Cola", "category": "Beverages", "price": 95.0, "stock": 82, "threshold": 20, "emoji": "🥤", "shelf": "S6", "unit": "2 Litres", "description": "Refreshing carbonated soft drink.", "imageUrl": "https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD067", "name": "Pepsi", "category": "Beverages", "price": 45.0, "stock": 56, "threshold": 20, "emoji": "🥤", "shelf": "S6", "unit": "750 ml", "description": "Crisp and cool cola drink.", "imageUrl": "https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD068", "name": "Tropicana Orange Juice", "category": "Beverages", "price": 125.0, "stock": 78, "threshold": 20, "emoji": "🍊", "shelf": "S6", "unit": "1 Litre", "description": "100% mixed fruit orange juice.", "imageUrl": "https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD069", "name": "Maaza Mango Drink", "category": "Beverages", "price": 75.0, "stock": 90, "threshold": 20, "emoji": "🥭", "shelf": "S6", "unit": "1.2 Litres", "description": "Delicious Alphonso mango juice.", "imageUrl": "https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD070", "name": "Red Bull Energy Drink", "category": "Beverages", "price": 115.0, "stock": 88, "threshold": 20, "emoji": "⚡", "shelf": "S6", "unit": "250 ml", "description": "Instant physical energy drink.", "imageUrl": "https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD071", "name": "Kinley Mineral Water", "category": "Beverages", "price": 20.0, "stock": 57, "threshold": 20, "emoji": "💧", "shelf": "S6", "unit": "1 Litre", "description": "Pure packaged drinking water.", "imageUrl": "https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD072", "name": "Nescafe Classic Coffee", "category": "Beverages", "price": 320.0, "stock": 24, "threshold": 20, "emoji": "☕", "shelf": "S6", "unit": "100 g", "description": "Rich instant coffee powder.", "imageUrl": "https://images.unsplash.com/photo-1559525839-b184a4d698c7?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD073", "name": "Taj Mahal Tea", "category": "Beverages", "price": 345.0, "stock": 61, "threshold": 20, "emoji": "🍵", "shelf": "S6", "unit": "500 g", "description": "Rich flavorful loose leaf tea.", "imageUrl": "https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD074", "name": "Bournvita Chocolate Health", "category": "Beverages", "price": 225.0, "stock": 38, "threshold": 20, "emoji": "🥛", "shelf": "S6", "unit": "500 g", "description": "Chocolate health drink powder.", "imageUrl": "https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD075", "name": "Lipton Green Tea", "category": "Beverages", "price": 165.0, "stock": 6, "threshold": 20, "emoji": "🍵", "shelf": "S6", "unit": "25 bags", "description": "Zero calorie healthy green tea leaves.", "imageUrl": "https://images.unsplash.com/photo-1544787210-2213d84ad960?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD076", "name": "Sprite", "category": "Beverages", "price": 95.0, "stock": 71, "threshold": 20, "emoji": "🥤", "shelf": "S6", "unit": "2 Litres", "description": "Clear lime flavored soda.", "imageUrl": "https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD077", "name": "Paper Boat Coconut Water", "category": "Beverages", "price": 50.0, "stock": 66, "threshold": 20, "emoji": "🥥", "shelf": "S6", "unit": "200 ml", "description": "100% natural tender coconut water.", "imageUrl": "https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD078", "name": "Surf Excel Matic Liquid", "category": "Cleaning & Household", "price": 210.0, "stock": 55, "threshold": 20, "emoji": "🧼", "shelf": "S7", "unit": "1 Litre", "description": "Top load automatic laundry liquid.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD079", "name": "Ariel Washing Powder", "category": "Cleaning & Household", "price": 320.0, "stock": 88, "threshold": 20, "emoji": "🧴", "shelf": "S7", "unit": "2 kg", "description": "Complete stain removal powder.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD080", "name": "Vim Dishwash Gel", "category": "Cleaning & Household", "price": 115.0, "stock": 23, "threshold": 20, "emoji": "🍋", "shelf": "S7", "unit": "500 ml", "description": "Lemon fragrant dishwash liquid.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD081", "name": "Lizol Floor Cleaner", "category": "Cleaning & Household", "price": 105.0, "stock": 94, "threshold": 20, "emoji": "🧹", "shelf": "S7", "unit": "1 Litre", "description": "Citrus scented disinfectant base.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD082", "name": "Harpic Toilet Cleaner", "category": "Cleaning & Household", "price": 95.0, "stock": 45, "threshold": 20, "emoji": "🚽", "shelf": "S7", "unit": "1 Litre", "description": "Powerful bathroom and toilet cleaner.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD083", "name": "Comfort Fabric Conditioner", "category": "Cleaning & Household", "price": 240.0, "stock": 39, "threshold": 20, "emoji": "🧺", "shelf": "S7", "unit": "860 ml", "description": "After wash fabric softener.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD084", "name": "Colin Glass Cleaner", "category": "Cleaning & Household", "price": 90.0, "stock": 19, "threshold": 20, "emoji": "🪟", "shelf": "S7", "unit": "500 ml", "description": "Shine booster glass spray.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD085", "name": "Scotch-Brite Scrub Pad", "category": "Cleaning & Household", "price": 60.0, "stock": 8, "threshold": 20, "emoji": "🧽", "shelf": "S7", "unit": "3 pcs", "description": "Heavy duty kitchen scrub pad.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD086", "name": "Hit Mosquito Killer", "category": "Cleaning & Household", "price": 190.0, "stock": 5, "threshold": 20, "emoji": "🦟", "shelf": "S7", "unit": "400 ml", "description": "Effective flying insect spray.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD087", "name": "Dettol Disinfectant Liquid", "category": "Cleaning & Household", "price": 340.0, "stock": 36, "threshold": 20, "emoji": "🏥", "shelf": "S7", "unit": "1 Litre", "description": "Antiseptic germ killing liquid.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD088", "name": "Tissue Paper Rolls", "category": "Cleaning & Household", "price": 180.0, "stock": 51, "threshold": 20, "emoji": "🧻", "shelf": "S7", "unit": "4 Rolls", "description": "Soft 2-ply toilet paper rolls.", "imageUrl": "https://images.unsplash.com/photo-1584432810601-6c7f27d2362b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD089", "name": "Garbage Bags Large", "category": "Cleaning & Household", "price": 75.0, "stock": 40, "threshold": 20, "emoji": "🗑️", "shelf": "S7", "unit": "30 pcs", "description": "Sturdy stretchable garbage bags.", "imageUrl": "https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD090", "name": "Dove Cream Beauty Bathing Bar", "category": "Personal Care", "price": 180.0, "stock": 32, "threshold": 20, "emoji": "🧼", "shelf": "S8", "unit": "3 x 100g", "description": "Moisturizing beauty cream soap.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD091", "name": "Pears Pure & Gentle Soap", "category": "Personal Care", "price": 150.0, "stock": 22, "threshold": 20, "emoji": "🧼", "shelf": "S8", "unit": "3 x 125g", "description": "Glycerin rich transparent soap.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD092", "name": "Head & Shoulders Shampoo", "category": "Personal Care", "price": 315.0, "stock": 36, "threshold": 20, "emoji": "🧴", "shelf": "S8", "unit": "650 ml", "description": "Anti-dandruff cool menthol shampoo.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD093", "name": "Sunsilk Black Shine", "category": "Personal Care", "price": 280.0, "stock": 58, "threshold": 20, "emoji": "🧴", "shelf": "S8", "unit": "650 ml", "description": "Nourishing herbal hair shampoo.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD094", "name": "Colgate MaxFresh Paste", "category": "Personal Care", "price": 190.0, "stock": 38, "threshold": 20, "emoji": "🦷", "shelf": "S8", "unit": "300 g", "description": "Cooling crystals red gel paste.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD095", "name": "Sensodyne Repair & Protect", "category": "Personal Care", "price": 210.0, "stock": 88, "threshold": 20, "emoji": "🦷", "shelf": "S8", "unit": "100 g", "description": "Tooth sensitivity relief paste.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD096", "name": "Nivea Body Lotion", "category": "Personal Care", "price": 350.0, "stock": 60, "threshold": 20, "emoji": "🧴", "shelf": "S8", "unit": "400 ml", "description": "Nourishing skin body moisturizer.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD097", "name": "Gillette Mach 3 Razor", "category": "Personal Care", "price": 240.0, "stock": 92, "threshold": 20, "emoji": "🪒", "shelf": "S8", "unit": "1 pc", "description": "Close and comfortable shaving razor.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD098", "name": "Old Spice After Shave", "category": "Personal Care", "price": 290.0, "stock": 71, "threshold": 20, "emoji": "💈", "shelf": "S8", "unit": "100 ml", "description": "Classic musk after shave lotion.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD099", "name": "Listerine Mouthwash", "category": "Personal Care", "price": 145.0, "stock": 14, "threshold": 20, "emoji": "👄", "shelf": "S8", "unit": "250 ml", "description": "Cool mint mouth freshness wash.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD100", "name": "Himalaya Neem Face Wash", "category": "Personal Care", "price": 180.0, "stock": 12, "threshold": 20, "emoji": "🌿", "shelf": "S8", "unit": "150 ml", "description": "Herbal purifying daily face wash.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD101", "name": "Whisper Ultra Clean", "category": "Personal Care", "price": 360.0, "stock": 19, "threshold": 20, "emoji": "🦋", "shelf": "S8", "unit": "15 pads", "description": "Wings XL sanitary protection.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
      {"id": "PRD102", "name": "Parachute Coconut Oil", "category": "Personal Care", "price": 120.0, "stock": 36, "threshold": 20, "emoji": "🥥", "shelf": "S8", "unit": "250 ml", "description": "100% pure edible coconut oil.", "imageUrl": "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=200", "supplierId": "SUP001"},
    ];

    final initialSales = [
      {
        'id': 'BILL-2026-0001',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'items': [
          {'id': 'BEV003', 'name': 'Tropicana Orange 1L', 'qty': 3, 'price': 125.0},
          {'id': 'DRY001', 'name': 'Amul Milk 1L', 'qty': 2, 'price': 58.0}
        ],
        'total': 491.0
      },
      {
        'id': 'BILL-2026-0002',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'items': [
          {'id': 'GRN002', 'name': 'Aashirvad Atta 10kg', 'qty': 1, 'price': 485.0},
          {'id': 'PC005', 'name': 'Dove Soap 100g', 'qty': 2, 'price': 72.0}
        ],
        'total': 660.75
      }
    ];

    final random = math.Random();
    for (var item in initialInventory) {
      if (!item.containsKey('expires')) {
        item['expires'] = DateTime.now().add(Duration(days: 10 + random.nextInt(170))).toIso8601String().split('T').first;
      }
      if (!item.containsKey('mfgDate')) {
        item['mfgDate'] = DateTime.now().subtract(Duration(days: 10 + random.nextInt(170))).toIso8601String().split('T').first;
      }
      await _inventoryBox.put(item['id'], item);
    }
    for (var item in initialSales) {
      await _salesBox.put(item['id'], item);
    }

    _loadData();
  }

  /// Seeds default suppliers only on first launch
  Future<void> _seedSuppliers() async {
    final initialSuppliers = [
      {'id': 'SUP001', 'name': 'Metro Cash & Carry', 'businessName': 'Metro Cash & Carry India Pvt Ltd', 'category': 'Wholesale · Grocery & FMCG', 'emoji': '🛒', 'status': 'Active', 'monthly': '₹1.2L', 'ontime': '98%', 'rating': '4.8', 'color': '6C63FF', 'phone': '919112692049', 'email': 'hrishita.s2409336202@vcet.edu.in', 'minOrder': '100'},
      {'id': 'SUP002', 'name': 'FreshFoods Co.', 'businessName': 'FreshFoods India Ltd', 'category': 'Organic & Fresh Produce', 'emoji': '🌱', 'status': 'Quote Pending', 'monthly': '₹68K', 'ontime': '91%', 'rating': '4.3', 'color': '10B981', 'phone': '919112692049', 'email': 'hrishita.s2409336202@vcet.edu.in', 'minOrder': '50'},
      {'id': 'SUP003', 'name': 'Unilever Distribution', 'businessName': 'Hindustan Unilever Limited', 'category': 'FMCG & Personal Care', 'emoji': '🧴', 'status': 'Active', 'monthly': '₹95K', 'ontime': '100%', 'rating': '4.9', 'color': '06B6D4', 'phone': '919112692049', 'email': 'hrishita.s2409336202@vcet.edu.in', 'minOrder': '50'},
    ];
    for (var item in initialSuppliers) {
      await _suppliersBox.put(item['id'], item);
    }
  }

  /// One-time fix for existing users to update their contact info
  Future<void> _fixExistingContacts() async {
    final fixPhone = '919112692049';
    final fixEmail = 'hrishita.s2409336202@vcet.edu.in';
    
    for (var s in _suppliers) {
      if (s.id.startsWith('SUP00') && (s.phone.isEmpty || s.phone == '919876543210')) {
        final updated = Supplier(
          id: s.id,
          name: s.name,
          businessName: s.businessName,
          category: s.category,
          emoji: s.emoji,
          status: s.status,
          monthly: s.monthly,
          ontime: s.ontime,
          rating: s.rating,
          color: s.color,
          phone: fixPhone,
          email: fixEmail,
          minOrder: s.minOrder,
        );
        await _suppliersBox.put(s.id, updated.toJson());
      }
    }
    _loadData();
  }

  void _loadData() {
    _inventory = _inventoryBox.values.map((v) => Product.fromJson(Map<dynamic, dynamic>.from(v))).toList();
    _sales = _salesBox.values.map((v) => Sale.fromJson(Map<dynamic, dynamic>.from(v))).toList();
    _suppliers = _suppliersBox.values.map((v) => Supplier.fromJson(Map<dynamic, dynamic>.from(v))).toList();
    
    _pendingOrders = _pendingOrdersBox.values
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  void _loadEvents() {
    if (_eventsBox.isNotEmpty) {
      _events.clear();
      _events.addAll(_eventsBox.values.cast<String>());
    }
  }

  void _loadLoyalty() {
    _loyaltyUsers = _loyaltyBox.values
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  void _loadPromotions() {
    _activePromotions = _promotionsBox.values.map((v) => Promotion.fromJson(Map<dynamic, dynamic>.from(v))).toList();
  }

  Future<void> togglePromotion(Promotion promo) async {
    final updated = Promotion(
      id: promo.id,
      title: promo.title,
      description: promo.description,
      type: promo.type,
      applicableProductIds: promo.applicableProductIds,
      discountPercent: promo.discountPercent,
      isActive: !promo.isActive,
      icon: promo.icon,
    );
    await _promotionsBox.put(updated.id, updated.toJson());
    _loadPromotions();
    addEvent("Promotion '${promo.title}' ${updated.isActive ? 'activated' : 'deactivated'}.");
    notifyListeners();
  }

  Future<void> addPromotion(Promotion promo) async {
    await _promotionsBox.put(promo.id, promo.toJson());
    _loadPromotions();
    notifyListeners();
  }




  Future<void> _seedLoyalty() async {
    final list = [
      {'name': 'Hrishikesh', 'points': 4500, 'spend': 12000.0, 'tier': 'Platinum', 'rank': '01'},
      {'name': 'Ananya', 'points': 2100, 'spend': 5400.0, 'tier': 'Gold', 'rank': '02'},
      {'name': 'Rahul', 'points': 1200, 'spend': 3200.0, 'tier': 'Silver', 'rank': '03'},
      {'name': 'Sneha', 'points': 850, 'spend': 1800.0, 'tier': 'Bronze', 'rank': '04'},
    ];
    for (var u in list) {
      await _loyaltyBox.put(u['name'], u);
    }
    _loadLoyalty();
  }

  void login(UserRole role) {
    _currentRole = role;
    _settingsBox.put('role', role == UserRole.admin ? 'admin' : 'staff');
    notifyListeners();
  }

  void logout() {
    _currentRole = null;
    _settingsBox.delete('role');
    notifyListeners();
  }

  // --- FEATURE: Loyalty Points Bridge ---
  void updateLoyaltyPoints(String userName, double billTotal) {
    final idx = _loyaltyUsers.indexWhere((u) => u['name'] == userName);
    if (idx != -1) {
      final user = Map<String, dynamic>.from(_loyaltyUsers[idx]);
      // 1 point per 10 currency units
      int earned = (billTotal / 10).floor();
      user['points'] = (user['points'] as int) + earned;
      user['spend'] = (user['spend'] as num) + billTotal;

      // Tier logic
      if (user['spend'] > 10000) user['tier'] = 'Platinum';
      else if (user['spend'] > 5000) user['tier'] = 'Gold';
      else if (user['spend'] > 2000) user['tier'] = 'Silver';
      
      _loyaltyUsers[idx] = user;
      _loyaltyBox.put(userName, user);
      addEvent("Loyalty credited: $userName earned $earned points.");
      notifyListeners();
    }
  }

  Future<void> addLoyaltyMember(String name) async {
    final newUser = {
      'name': name,
      'points': 0,
      'spend': 0.0,
      'tier': 'Bronze',
      'rank': '${(_loyaltyUsers.length + 1).toString().padLeft(2, '0')}'
    };
    await _loyaltyBox.put(name, newUser);
    _loadLoyalty(); // Refresh local list
    addEvent("New Loyalty Member added: $name");
    notifyListeners();
  }

  double getDiscountedPrice(Product p) {
    final promo = _activePromotions.firstWhere(
      (pr) => pr.isActive && pr.applicableProductIds.contains(p.id) && pr.type != 'bundle',
      orElse: () => Promotion(id: '', title: '', description: '', type: '', applicableProductIds: [], icon: ''),
    );
    if (promo.id.isEmpty) return p.price;
    return p.price * (1 - (promo.discountPercent / 100));
  }

  // ── Product Management ─────────────────
  Future<void> addProduct(Product product) async {
    await _inventoryBox.put(product.id, product.toJson());
    // Refresh local list
    final existingIndex = _inventory.indexWhere((p) => p.id == product.id);
    if (existingIndex != -1) {
      _inventory[existingIndex] = product;
    } else {
      _inventory.add(product);
    }
    addEvent("Product added/updated: ${product.name}");
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _inventoryBox.delete(id);
    _inventory.removeWhere((p) => p.id == id);
    addEvent("Product removed from inventory.");
    notifyListeners();
  }

  // ── Record a Sale (Offline Enabled) ─────────────────
  Future<Sale> recordSale(List<SaleItem> items, double total, {
    String paymentMethod = 'Cash', 
    double amountReceived = 0, 
    double changeReturned = 0,
    String? loyaltyUser,
  }) async {
    final id = 'BILL-${DateTime.now().year}-${(1000 + (DateTime.now().millisecond % 9000))}';
    final sale = Sale(
      id: id, 
      date: DateTime.now(), 
      items: items, 
      total: total, 
      paymentMethod: paymentMethod,
      amountReceived: amountReceived,
      changeReturned: changeReturned,
    );
    
    await _salesBox.put(id, sale.toJson());
    _sales.add(sale);
    
    if (loyaltyUser != null) {
      updateLoyaltyPoints(loyaltyUser, total);
    }
    
    // Update inventory locally
    for (var soldItem in items) {
      final index = _inventory.indexWhere((p) => p.id == soldItem.id);
      if (index != -1) {
        _inventory[index].stock = (_inventory[index].stock - soldItem.qty).clamp(0, 999999);
        await _inventoryBox.put(_inventory[index].id, _inventory[index].toJson());
        
        // Trigger Smart Notification for Low Stock
        if (_inventory[index].stock <= _inventory[index].threshold) {
          addEvent("${_inventory[index].name} stock is critical!");
          /*
          NotificationService.showNotification(
            id: _inventory[index].hashCode,
            title: 'Low Stock Alert',
            body: '${_inventory[index].name} stock is low: ${_inventory[index].stock} left.',
          );
          */
        }
      }
    }
    
    addEvent("Staff completed a sale of ₹${total.toInt()}.");

    // Track for sync
    _unsyncedCount++;
    await _settingsBox.put('unsynced_count', _unsyncedCount);

    if (_isOnline) {
      syncData();
    }
    
    notifyListeners();
    return sale;
  }

  // ── Automatic Data Synchronization ─────────────────
  Future<void> syncData() async {
    if (_isSyncing || !_isOnline || _unsyncedCount == 0) return;
    
    _isSyncing = true;
    notifyListeners();
    
    // Mock server delay
    await Future.delayed(const Duration(seconds: 3));
    
    // Sync logic: In a real app, this would be an API call
    _unsyncedCount = 0;
    await _settingsBox.put('unsynced_count', 0);
    
    _isSyncing = false;
    notifyListeners();
    
    print("Cloud Synced: ${_sales.length} records updated.");
    addEvent("Cloud synchronization completed.");
  }

  // ── Supplier Management ─────────────────
  Future<void> addSupplier(Supplier supplier) async {
    await _suppliersBox.put(supplier.id, supplier.toJson());
    _loadData();
    addEvent("New supplier added: ${supplier.name}");
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    await _suppliersBox.delete(id);
    _loadData();
    addEvent("Supplier removed.");
    notifyListeners();
  }

  // ── Order Tracking ─────────────────
  List<Map<String, dynamic>> get pendingOrders => _pendingOrders;

  Future<void> markAsOrdered(Product p, int qty, String supplierName) async {
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final newOrder = {
      'id': orderId,
      'productId': p.id,
      'productName': p.name,
      'qty': qty,
      'supplierName': supplierName,
      'date': DateTime.now().toIso8601String(),
      'status': 'Pending'
    };
    
    await _pendingOrdersBox.put(orderId, newOrder);
    _pendingOrders.add(newOrder);
    addEvent("Order marked as SENT: ${p.name} ($qty units)");
    notifyListeners();
  }

  Future<void> receiveOrder(String orderId) async {
    final order = _pendingOrders.firstWhere((o) => o['id'] == orderId);
    final productId = order['productId'];
    final qty = order['qty'] as int;
    
    // Update stock
    final pIdx = _inventory.indexWhere((p) => p.id == productId);
    if (pIdx != -1) {
      final updatedProduct = Product(
        id: _inventory[pIdx].id,
        name: _inventory[pIdx].name,
        category: _inventory[pIdx].category,
        price: _inventory[pIdx].price,
        stock: _inventory[pIdx].stock + qty,
        threshold: _inventory[pIdx].threshold,
        emoji: _inventory[pIdx].emoji,
        shelf: _inventory[pIdx].shelf,
        supplierId: _inventory[pIdx].supplierId,
        imageUrl: _inventory[pIdx].imageUrl,
        description: _inventory[pIdx].description,
        unit: _inventory[pIdx].unit,
        mfgDate: _inventory[pIdx].mfgDate,
        expires: _inventory[pIdx].expires,
        barcode: _inventory[pIdx].barcode,
      );
      await addProduct(updatedProduct);
    }
    
    await _pendingOrdersBox.delete(orderId);
    _pendingOrders.removeWhere((o) => o['id'] == orderId);
    addEvent("Order received & stock updated: ${order['productName']}");
    notifyListeners();
  }

  Future<void> cancelOrder(String orderId) async {
    await _pendingOrdersBox.delete(orderId);
    _pendingOrders.removeWhere((o) => o['id'] == orderId);
    addEvent("Order cancelled.");
    notifyListeners();
  }
  List<Map<String, dynamic>> getLeaderboard() {
    final demand = calculateDemand();
    var sorted = demand.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) {
      final p = _inventory.firstWhere((prod) => prod.name == e.key, 
        orElse: () => Product(id: '?', name: e.key, category: '?', price: 0, stock: 0, threshold: 0, emoji: '📦', shelf: '?', supplierId: 'unknown'));
      return {
        'name': e.key,
        'sold': e.value,
        'emoji': p.emoji,
      };
    }).toList();
  }

  // --- FEATURE: Daily Business Summary ---
  Map<String, dynamic> generateDailyReport() {
    final today = DateTime.now();
    final todaySales = _sales.where((s) => s.date.day == today.day && s.date.month == today.month);
    
    double revenue = todaySales.fold(0, (sum, item) => sum + item.total);
    int txCount = todaySales.length;
    
    final Map<String, int> prodQty = {};
    for (var s in todaySales) {
      for (var i in s.items) {
        prodQty[i.name] = (prodQty[i.name] ?? 0) + i.qty;
      }
    }
    
    var sortedProds = prodQty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String topProduct = sortedProds.isNotEmpty ? sortedProds.first.key : "N/A";

    return {
      'revenue': revenue,
      'transactions': txCount,
      'topProduct': topProduct,
      'lowStock': _inventory.where((p) => p.stock <= p.threshold).length,
      'expiryRisk': _inventory.where((p) => p.expires != null && p.expires!.contains('day')).length,
    };
  }

  // ── AI Calculations ─────────────────

  double calculateHealthScore() {
    if (_inventory.isEmpty) return 100.0;
    int healthyCount = 0;
    for (var p in _inventory) {
      bool isHealthy = true;
      if (p.stock <= p.threshold) isHealthy = false;
      if (p.expires != null && p.expires!.contains('day')) {
        int days = int.tryParse(p.expires!.split(' ')[0]) ?? 99;
        if (days < 5) isHealthy = false;
      }
      if (isHealthy) healthyCount++;
    }
    return (healthyCount / _inventory.length) * 100.0;
  }

  // --- FEATURE 2: Predictive Stock-Out Countdown ---
  double getDaysRemaining(String productId) {
    final p = _inventory.firstWhere((element) => element.id == productId);
    final sales7Days = _sales.where((s) => s.date.isAfter(DateTime.now().subtract(const Duration(days: 7))));
    
    int totalQty = 0;
    for (var s in sales7Days) {
      for (var item in s.items) {
        if (item.id == productId) totalQty += item.qty;
      }
    }
    
    double avgDaily = totalQty / 7.0;
    if (avgDaily == 0) return 999; // Sufficient stock or no sales
    return p.stock / avgDaily;
  }

  // --- FEATURE 4: Smart Bundle Recommendation ---
  List<Map<String, dynamic>> getBundleSuggestions() {
    final Map<String, int> pairFreq = {};
    for (var sale in _sales) {
      if (sale.items.length < 2) continue;
      for (int i = 0; i < sale.items.length; i++) {
        for (int j = i + 1; j < sale.items.length; j++) {
          final pair = [sale.items[i].name, sale.items[j].name]..sort();
          final key = pair.join(' + ');
          pairFreq[key] = (pairFreq[key] ?? 0) + 1;
        }
      }
    }
    
    var sorted = pairFreq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => {'bundle': e.key, 'freq': e.value}).toList();
  }



  // --- AI FEATURE: Smart Promotion Engine ---
  List<Promotion> generateAIPromotions() {
    final promos = <Promotion>[];

    // 1. Expiry Clearance
    for (var p in _inventory) {
      if (p.expires != null && p.expires!.contains('day')) {
        int days = int.tryParse(p.expires!.split(' ')[0]) ?? 99;
        if (days < 4) {
          promos.add(Promotion(
            id: 'PRO-EXP-${p.id}',
            title: 'Expiry Clearance: ${p.name}',
            description: 'Save $p.name before it expires! 50% Flat Discount.',
            type: 'clearance',
            applicableProductIds: [p.id],
            discountPercent: 50,
            icon: '🔥',
          ));
        }
      }
    }

    // 2. Bundle Deals (based on real correlations)
    final bundles = getBundleSuggestions();
    for (var b in bundles) {
      if (b['freq'] > 1) {
        promos.add(Promotion(
          id: 'PRO-BND-${b['bundle'].hashCode}',
          title: 'Smart Combo: ${b['bundle']}',
          description: 'Buy these together and save 15%!',
          type: 'bundle',
          applicableProductIds: [], // Logic to map names to IDs needed
          discountPercent: 15,
          icon: '🎁',
        ));
      }
    }

    // 3. Slow Moving Stock Drop
    final riskRadar = getRiskRadar();
    final slowItems = riskRadar.where((r) => r['score'] > 40 && (r['product'] as Product).stock > (r['product'] as Product).threshold * 3).toList();
    if (slowItems.isNotEmpty) {
      final p = slowItems[0]['product'] as Product;
      promos.add(Promotion(
        id: 'PRO-SLOW-${p.id}',
        title: 'Flash Sale: ${p.name}',
        description: 'Overstock alert! Get ${p.name} at a special price.',
        type: 'discount',
        applicableProductIds: [p.id],
        discountPercent: 20,
        icon: '⚡',
      ));
    }

    if (promos.isEmpty) {
      // Fallback AI Promotions so it never looks empty
      promos.add(Promotion(
        id: 'PRO-WELCOME-1',
        title: 'Weekend Super Saver',
        description: 'Flat 10% off on all items to boost traffic.',
        type: 'discount',
        applicableProductIds: [],
        discountPercent: 10,
        icon: '🚀',
      ));
      
      // Additional fallback based on first item
      if (_inventory.isNotEmpty) {
        final popular = _inventory.first;
        promos.add(Promotion(
          id: 'PRO-TOP-${popular.id}',
          title: 'Top Seller Special: ${popular.name}',
          description: 'Save 15% on one of our top selling products.',
          type: 'discount',
          applicableProductIds: [popular.id],
          discountPercent: 15,
          icon: '👑',
        ));
      }
    }

    return promos;
  }





  Map<String, int> calculateDemand() {
    final Map<String, int> demand = {};
    for (var sale in _sales) {
      for (var item in sale.items) {
        demand[item.name] = (demand[item.name] ?? 0) + item.qty;
      }
    }
    return demand;
  }

  List<Map<String, dynamic>> getAIAdvisorSuggestions() {
    final suggestions = <Map<String, dynamic>>[];
    
    // Low Stock Alert with Prediction
    final lowStock = _inventory.where((p) => p.stock <= p.threshold).toList();
    if (lowStock.isNotEmpty) {
      final days = getDaysRemaining(lowStock[0].id);
      suggestions.add({
        'title': '📦 Stock Alert',
        'text': AIResponseFormatter.formatStockAlert(lowStock[0], days),
        'type': 'warning',
        'icon': '📦'
      });
    }

    // Risk Alert
    final highRisk = getRiskRadar().where((r) => r['level'] == 'High').toList();
    if (highRisk.isNotEmpty) {
      suggestions.add({
        'title': '🛡️ Risk Warning',
        'text': AIResponseFormatter.formatRiskAlert(highRisk[0]['product'], 'High'),
        'type': 'critical',
        'icon': '🛡️'
      });
    }

    // Expiry Suggestion
    for (var p in _inventory) {
      if (p.expires != null && p.expires!.contains('day')) {
         int days = int.tryParse(p.expires!.split(' ')[0]) ?? 99;
         if (days < 5) {
            suggestions.add({
              'title': '⚠ Expiry Alert',
              'text': AIResponseFormatter.formatExpiryAlert(p),
              'type': 'info',
              'icon': '⚠'
            });
            break;
         }
      }
    }

    return suggestions;
  }

  // --- NEW: Trending KPIs ---
  Map<String, dynamic> getTrendingKPIs() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final todaySales = _sales.where((s) => s.date.day == today.day && s.date.month == today.month);
    final yesterdaySales = _sales.where((s) => s.date.day == yesterday.day && s.date.month == yesterday.month);

    double todayRev = todaySales.fold(0, (a, b) => a + b.total);
    double yesterdayRev = yesterdaySales.fold(0, (a, b) => a + b.total);

    double revTrend = yesterdayRev == 0 ? 100 : ((todayRev - yesterdayRev) / yesterdayRev * 100);
    int txTrend = todaySales.length - yesterdaySales.length;

    return {
      'revenue': todayRev,
      'revenueTrend': revTrend,
      'transactions': todaySales.length,
      'txTrend': txTrend,
    };
  }

  // --- NEW: Heatmap Data (Last 30 Days) ---
  Map<DateTime, int> getHeatmapData() {
    final Map<DateTime, int> data = {};
    for (var sale in _sales) {
      final date = DateTime(sale.date.year, sale.date.month, sale.date.day);
      data[date] = (data[date] ?? 0) + 1;
    }
    return data;
  }

  Future<void> updateSettings({
    required String storeName,
    required String upiId,
    required String upiName,
    required int threshold,
    required String currency,
    required double taxRate,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
  }) async {
    _storeName = storeName;
    _upiId = upiId;
    _upiName = upiName;
    _globalThreshold = threshold;
    _currency = currency;
    _taxRate = taxRate;

    if (ownerName != null) _ownerProfile['name'] = ownerName;
    if (ownerEmail != null) _ownerProfile['email'] = ownerEmail;
    if (ownerPhone != null) _ownerProfile['phone'] = ownerPhone;

    await _settingsBox.put('store_name', storeName);
    await _settingsBox.put('upi_id', upiId);
    await _settingsBox.put('upi_name', upiName);
    await _settingsBox.put('global_threshold', threshold);
    await _settingsBox.put('currency', currency);
    await _settingsBox.put('tax_rate', taxRate);
    await _settingsBox.put('owner_profile', _ownerProfile);

    addEvent("Settings & Profile updated.");
    notifyListeners();
  }

  Future<void> updateStaffProfile({required String name, required String email, required String phone}) async {
    _staffProfile = {
      'name': name,
      'email': email,
      'phone': phone,
    };
    await _settingsBox.put('staff_profile', _staffProfile);
    addEvent("Staff profile updated.");
    notifyListeners();
  }
}

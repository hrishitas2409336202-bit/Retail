import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'barcode_scanner_screen.dart';
import 'invoice_screen.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../models/promotion.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StaffBillingScreen extends StatefulWidget {
  const StaffBillingScreen({super.key});

  @override
  State<StaffBillingScreen> createState() => _StaffBillingScreenState();
}

class _StaffBillingScreenState extends State<StaffBillingScreen> {
  final Map<String, int> _cartItems = {}; // ProductID -> Quantity
  String _selectedPaymentMethod = 'Cash';
  double _cashReceived = 0;
  final TextEditingController _cashController = TextEditingController();
  String? _selectedLoyaltyUser;
  
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 14 categories matching Inventory for consistency
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Vegetables & Fruits', 'image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.leaf, 'color': Colors.greenAccent},
    {'name': 'Atta, Rice & Dal', 'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.wheat, 'color': Colors.orangeAccent},
    {'name': 'Oil, Ghee & Masala', 'image': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.flame, 'color': Colors.redAccent},
    {'name': 'Dairy, Bread & Eggs', 'image': 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.milk, 'color': Colors.blueAccent},
    {'name': 'Snacks & Packaged Foods', 'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.cookie, 'color': Colors.amberAccent},
    {'name': 'Beverages', 'image': 'https://images.unsplash.com/photo-1622597467822-5bb8952dc38e?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.cupSoda, 'color': Colors.cyanAccent},
    {'name': 'Cleaning & Household', 'image': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.sprayCan, 'color': Colors.indigoAccent},
    {'name': 'Personal Care', 'image': 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=80&w=400', 'icon': LucideIcons.heartPulse, 'color': Colors.pinkAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activePromos = state.activePromotions.where((p) => p.isActive).toList();

    // Filter products based on category or search
    List<Product> filteredProducts = state.inventory;
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    } else if (_selectedCategory != null) {
      filteredProducts = filteredProducts.where((p) => p.category == _selectedCategory).toList();
    }

    return WillPopScope(
      onWillPop: () async {
        if (_selectedCategory != null || _searchQuery.isNotEmpty) {
          setState(() {
            _selectedCategory = null;
            _searchQuery = "";
            _searchController.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(state.tr(_selectedCategory ?? 'billing'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _selectedCategory != null 
            ? IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => setState(() => _selectedCategory = null))
            : null,
          actions: [
            const SizedBox.shrink(),
          ],
        ),
        body: Column(
          children: [
            _buildPromoStrip(activePromos),
            _buildSearchBar(state),
            Expanded(
              child: (_selectedCategory == null && _searchQuery.isEmpty)
                  ? _buildCategoryGrid(state)
                  : _buildProductList(filteredProducts, activePromos, state),
            ),
            _buildCheckoutBar(state, activePromos),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.search, color: Colors.blueAccent.withValues(alpha: 0.6), size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: state.tr('Search items...'),
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(AppState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.25,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final Color color = cat['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['name']),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Large Background Icon Decor
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(cat['icon'], size: 80, color: color),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat['icon'], color: color, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        state.tr(cat['name']),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList(List<Product> products, List<Promotion> activePromos, AppState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final promo = activePromos.firstWhere(
          (pr) => pr.applicableProductIds.contains(p.id) && pr.type != 'bundle',
          orElse: () => Promotion(id: '', title: '', description: '', type: '', applicableProductIds: [], icon: ''),
        );
        
        final double discountFactor = promo.id.isNotEmpty ? (1 - (promo.discountPercent / 100)) : 1.0;
        final double currentPrice = p.price * discountFactor;
        final bool isLow = p.stock <= p.threshold;
        final double daysLeft = state.getDaysRemaining(p.id);
        final bool isHighRisk = daysLeft < 3 && p.stock > 0;
        final bool isHighDemand = daysLeft < 7 && daysLeft >= 3 && p.stock > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: promo.id.isNotEmpty ? Colors.orange.withOpacity(0.3) : (isLow ? Colors.orangeAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05))),
          ),
          child: ListTile(
            leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
            title: Text('${p.name}${p.unit != null ? ' (${p.unit})' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${state.currency}${currentPrice.toInt()} • ${p.stock} ${state.tr('in stock')}", 
                    style: TextStyle(color: isLow ? Colors.orangeAccent : Colors.white.withOpacity(0.4), fontSize: 11)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
                      ),
                      child: Text('📍 ${p.shelf}', style: const TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    if (p.expires != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('EXP: ${p.expires!.length > 10 ? p.expires!.substring(0, 10) : p.expires}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 9)),
                      ),
                    ],
                    if (isLow) ...[
                      const SizedBox(width: 6),
                      Text(state.tr("LOW STOCK"), style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ] else if (isHighRisk) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text("STOCK-OUT RISK", style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ] else if (isHighDemand) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text("HIGH DEMAND", style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_cartItems.containsKey(p.id)) ...[
                  IconButton(
                    icon: const Icon(LucideIcons.minusCircle, color: Colors.redAccent, size: 20),
                    onPressed: () => _removeFromCart(p),
                  ),
                  Text('${_cartItems[p.id]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
                IconButton(
                  icon: const Icon(LucideIcons.plusCircle, color: Colors.greenAccent, size: 20),
                  onPressed: p.stock > (_cartItems[p.id] ?? 0) ? () => _addToCart(p) : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addToCart(Product p) {
    setState(() {
      _cartItems[p.id] = (_cartItems[p.id] ?? 0) + 1;
    });
  }

  void _removeFromCart(Product p) {
    setState(() {
      if (_cartItems.containsKey(p.id)) {
        if (_cartItems[p.id]! > 1) {
          _cartItems[p.id] = _cartItems[p.id]! - 1;
        } else {
          _cartItems.remove(p.id);
        }
      }
    });
  }

  Widget _buildPromoStrip(List<Promotion> promotions) {
    if (promotions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promo = promotions[index];
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: promo.type == 'bundle' ? [Colors.blue, Colors.indigo] : [Colors.orange, Colors.red],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "${promo.icon} ${promo.title}",
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutBar(AppState state, List<Promotion> activePromos) {
    double subTotal = 0;
    _cartItems.forEach((id, qty) {
      final p = state.inventory.firstWhere((prod) => prod.id == id);
      final promo = activePromos.firstWhere(
        (pr) => pr.applicableProductIds.contains(p.id) && pr.type != 'bundle',
        orElse: () => Promotion(id: '', title: '', description: '', type: '', applicableProductIds: [], icon: ''),
      );
      final double discountFactor = promo.id.isNotEmpty ? (1 - (promo.discountPercent / 100)) : 1.0;
      subTotal += (p.price * discountFactor) * qty;
    });

    final double tax = subTotal * (state.taxRate / 100);
    final double finalTotal = subTotal + tax;

    if (_cartItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_cartItems.length} ${state.tr('items selected')}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                Text('${state.currency}${finalTotal.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                _buildLoyaltySelector(context, state),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showPaymentPicker(context, state, finalTotal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(state.tr('checkout').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentPicker(BuildContext context, AppState state, double total) {
    _cashController.text = total.toInt().toString();
    _cashReceived = total;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          double change = _cashReceived - total;
          return Container(
            padding: EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _paymentBtn('Cash', LucideIcons.banknote, Colors.green, setSheetState),
                const SizedBox(height: 12),
                _paymentBtn('Online', LucideIcons.qrCode, Colors.blue, setSheetState),
                
                if (_selectedPaymentMethod == 'Cash') ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Amount Received', labelStyle: TextStyle(color: Colors.white38)),
                    onChanged: (v) => setSheetState(() => _cashReceived = double.tryParse(v) ?? 0),
                  ),
                  const SizedBox(height: 10),
                  Text('Change: ${state.currency}${change < 0 ? 0 : change.toInt()}', style: const TextStyle(color: Colors.white70)),
                ],

                if (_selectedPaymentMethod == 'Online') ...[
                  const SizedBox(height: 20),
                  QrImageView(
                    data: "upi://pay?pa=${Uri.encodeComponent(state.upiId)}&pn=${Uri.encodeComponent(state.upiName)}&am=${total.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('Payment for Store Order')}&tr=${Uri.encodeComponent('BILL-${DateTime.now().millisecondsSinceEpoch}')}",
                    size: 150.0,
                    foregroundColor: Colors.white,
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _processCheckout(context, state, total);
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
                  child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _paymentBtn(String val, IconData icon, Color color, StateSetter setSheetState) {
    bool isSel = _selectedPaymentMethod == val;
    return InkWell(
      onTap: () => setSheetState(() => _selectedPaymentMethod = val),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? color : Colors.white38),
            const SizedBox(width: 16),
            Text(val, style: TextStyle(color: isSel ? color : Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _processCheckout(BuildContext context, AppState state, double total) async {
    final List<SaleItem> saleItems = [];
    _cartItems.forEach((id, qty) {
      final p = state.inventory.firstWhere((prod) => prod.id == id);
      final price = state.getDiscountedPrice(p);
      saleItems.add(SaleItem(id: p.id, name: p.name, qty: qty, price: price));
    });

    final sale = await state.recordSale(
      saleItems, 
      total, 
      paymentMethod: _selectedPaymentMethod,
      amountReceived: _selectedPaymentMethod == 'Cash' ? _cashReceived : total,
      changeReturned: _selectedPaymentMethod == 'Cash' ? (_cashReceived - total) : 0,
      loyaltyUser: _selectedLoyaltyUser,
    );
    
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => InvoiceScreen(sale: sale)));
    }
  }

  Widget _buildLoyaltySelector(BuildContext context, AppState state) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1E293B),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Select Loyalty Customer', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
              ListTile(
                leading: const Icon(LucideIcons.plusCircle, color: Colors.greenAccent),
                title: const Text('Register New Member', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showNewMemberDialog(context, state);
                },
              ),
              const Divider(color: Colors.white12),
              ...state.loyaltyUsers.map((u) => ListTile(
                leading: const Icon(LucideIcons.user, color: Colors.blueAccent),
                title: Text(u['name'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('${u['points']} points • ${u['tier']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                onTap: () {
                  setState(() => _selectedLoyaltyUser = u['name']);
                  Navigator.pop(ctx);
                },
              )),
              ListTile(
                leading: const Icon(LucideIcons.xCircle, color: Colors.redAccent),
                title: const Text('Clear Selection', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  setState(() => _selectedLoyaltyUser = null);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedLoyaltyUser != null ? Colors.blueAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _selectedLoyaltyUser != null ? Colors.blueAccent : Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(_selectedLoyaltyUser != null ? LucideIcons.userCheck : LucideIcons.userPlus, 
                 color: _selectedLoyaltyUser != null ? Colors.blueAccent : Colors.white38, size: 20),
            const SizedBox(height: 2),
            Text(_selectedLoyaltyUser != null ? _selectedLoyaltyUser! : 'LOYALTY', 
                 style: TextStyle(color: _selectedLoyaltyUser != null ? Colors.blueAccent : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showNewMemberDialog(BuildContext context, AppState state) {
    final TextEditingController nameC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Loyalty Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameC,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Customer Name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.trim().isNotEmpty) {
                state.addLoyaltyMember(nameC.text.trim());
                setState(() => _selectedLoyaltyUser = nameC.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Member "${nameC.text}" added!')),
                );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}


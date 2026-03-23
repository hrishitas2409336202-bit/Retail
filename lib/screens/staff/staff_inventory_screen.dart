import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StaffInventoryScreen extends StatefulWidget {
  const StaffInventoryScreen({super.key});

  @override
  State<StaffInventoryScreen> createState() => _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends State<StaffInventoryScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 14 categories with high-quality Network URLs for cross-device compatibility
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
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(state),
              Expanded(
                child: (_selectedCategory == null && _searchQuery.isEmpty)
                    ? _buildCategoryGrid(state)
                    : _buildProductList(filteredProducts, state),
              ),
            ],
          ),
        ),
        floatingActionButton: _selectedCategory != null ? FloatingActionButton(
          onPressed: () => _showAddProductDialog(context, state, _selectedCategory!),
          backgroundColor: AppTheme.primary,
          child: const Icon(LucideIcons.plus),
        ) : null,
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory ?? state.tr('inventory'),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state.tr('Manage your stock and products'),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                  ),
                ],
              ),
                const SizedBox.shrink(),
                if (_selectedCategory != null)
                  IconButton(
                    onPressed: () => setState(() => _selectedCategory = null),
                    icon: const Icon(LucideIcons.x, color: Colors.white54),
                  )
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchBar(state),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, color: Colors.blueAccent.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: state.tr('Search items, codes, or shelf...'),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.xCircle, size: 18, color: Colors.white38),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              },
            )
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(AppState state) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.25,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return _buildCategoryCard(cat, state);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, AppState state) {
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${state.inventory.where((p) => p.category == cat['name']).length} ${state.tr('Items')}",
                        style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(LucideIcons.arrowRight, color: Colors.white.withValues(alpha: 0.3), size: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products, AppState state) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, color: AppTheme.divider(context), size: 64),
            const SizedBox(height: 16),
            Text(state.tr("No products found"), style: TextStyle(color: Colors.white.withOpacity(0.3))),
            const SizedBox(height: 8),
            Text("${state.tr('Total Items')}: ${products.length}", style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final bool isLow = p.stock <= p.threshold;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLow ? Colors.orangeAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05),
              width: isLow ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 24))),
            ),
            title: Text('${p.name}${p.unit != null ? ' (${p.unit})' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.mfgDate != null || p.expires != null) ...[
                  Row(
                    children: [
                      if (p.mfgDate != null) Text('MFG: ${p.mfgDate}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                      if (p.mfgDate != null && p.expires != null) Text(' | ', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                      if (p.expires != null) Text('EXP: ${p.expires}', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    Text("${state.currency}${p.price.toInt()} • ${p.stock} ${state.tr('in stock')}", 
                        style: TextStyle(color: isLow ? Colors.orangeAccent : Colors.white.withOpacity(0.4), fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
                      ),
                      child: Text('📍 ${p.shelf}', style: const TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${p.stock}", style: TextStyle(
                      color: isLow ? Colors.orangeAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.edit2, size: 14, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
                if (isLow)
                  Text(state.tr("LOW STOCK"), style: const TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
            onTap: () => _showUpdateStockDialog(context, state, p),
          ),
        );
      },
    );
  }

  void _showUpdateStockDialog(BuildContext context, AppState state, Product p) {
    final controller = TextEditingController(text: p.stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Update Stock: ${p.name}", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Quantity", labelStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text) ?? p.stock;
              state.addProduct(Product(
                id: p.id,
                name: p.name,
                category: p.category,
                price: p.price,
                stock: newStock,
                threshold: p.threshold,
                emoji: p.emoji,
                shelf: p.shelf,
                supplierId: p.supplierId,
                barcode: p.barcode,
                mfgDate: p.mfgDate,
                expires: p.expires,
              ));
              Navigator.pop(ctx);
            },
            child: const Text("UPDATE"),
          )
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, AppState state, String category) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final mfgController = TextEditingController();
    final expController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("New Item in $category", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Product Name")),
              TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Price")),
              TextField(controller: stockController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Initial Stock")),
              TextField(controller: mfgController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "MFG Date (YYYY-MM-DD)", labelStyle: TextStyle(fontSize: 12))),
              TextField(controller: expController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Expiry Date (YYYY-MM-DD)", labelStyle: TextStyle(fontSize: 12))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final newProd = Product(
                id: 'GEN-${DateTime.now().millisecond}',
                name: nameController.text,
                category: category,
                price: double.tryParse(priceController.text) ?? 0.0,
                stock: int.tryParse(stockController.text) ?? 0,
                threshold: state.globalThreshold,
                emoji: '📦',
                shelf: 'A1',
                supplierId: 'SUP001',
                mfgDate: mfgController.text.isNotEmpty ? mfgController.text : null,
                expires: expController.text.isNotEmpty ? expController.text : null,
              );
              state.addProduct(newProd);
              Navigator.pop(ctx);
            },
            child: const Text("ADD PRODUCT"),
          )
        ],
      ),
    );
  }
}


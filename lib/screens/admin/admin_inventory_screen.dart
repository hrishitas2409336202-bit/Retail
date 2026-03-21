import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    final filteredProducts = state.inventory.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             p.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(state.tr('Master Inventory'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppTheme.accent),
            onPressed: () => _showAddProductDialog(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSearchBar(state),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final p = filteredProducts[index];
                final isLow = p.stock <= p.threshold;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLow ? Colors.orange.withOpacity(0.3) : AppTheme.divider(context),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.background(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 24))),
                    ),
                    title: Text('${p.name}${p.unit != null ? ' (${p.unit})' : ''}', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHeading(context))),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.category, style: TextStyle(color: AppTheme.textBody(context), fontSize: 11)),
                        const SizedBox(height: 4),
                        if (p.mfgDate != null || p.expires != null) ...[
                          Row(
                            children: [
                              if (p.mfgDate != null) Text('MFG: ${p.mfgDate}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              if (p.mfgDate != null && p.expires != null) const Text(' | ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              if (p.expires != null) Text('EXP: ${p.expires}', style: const TextStyle(fontSize: 10, color: Colors.redAccent)),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Text('${state.currency}${p.price.toInt()}', 
                                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLow ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${state.tr('Stock')}: ${p.stock}',
                                style: TextStyle(
                                  color: isLow ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.moreVertical, size: 20),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showEditProductDialog(context, state, p);
                        } else if (val == 'delete') {
                          _confirmDelete(context, state, p);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Text(state.tr('Edit details'))),
                        PopupMenuItem(value: 'delete', child: Text(state.tr('Delete product'), style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider(context)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: Colors.grey, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: AppTheme.textHeading(context)),
              decoration: InputDecoration(
                hintText: state.tr('Search master inventory...'),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, AppState state) {
    // Basic dialog for demonstration, similarly to Staff side
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final mfgCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    String category = 'Vegetables & Fruits';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg(context),
        title: Text(state.tr('Add Master Product')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Rice (5kg))')),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
              TextField(controller: mfgCtrl, decoration: const InputDecoration(labelText: 'MFG Date (YYYY-MM-DD)')),
              TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)')),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: ['Vegetables & Fruits', 'Atta, Rice & Dal', 'Oil, Ghee & Masala', 'Dairy, Bread & Eggs', 'Snacks & Packaged Foods', 'Beverages', 'Cleaning & Household', 'Personal Care']
                    .map((c) => DropdownMenuItem(value: c, child: Text(state.tr(c)))).toList(),
                onChanged: (v) => category = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(state.tr('Cancel'))),
          ElevatedButton(
            onPressed: () {
              final p = Product(
                id: 'PRD${DateTime.now().millisecond}',
                name: nameCtrl.text,
                category: category,
                price: double.tryParse(priceCtrl.text) ?? 0.0,
                stock: int.tryParse(stockCtrl.text) ?? 0,
                threshold: 20,
                emoji: '📦',
                shelf: 'S1',
                supplierId: 'SUP001',
                mfgDate: mfgCtrl.text.isNotEmpty ? mfgCtrl.text : null,
                expires: expCtrl.text.isNotEmpty ? expCtrl.text : null,
              );
              state.addProduct(p);
              Navigator.pop(ctx);
            },
            child: Text(state.tr('Add')),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, AppState state, Product p) {
    final priceCtrl = TextEditingController(text: p.price.toString());
    final stockCtrl = TextEditingController(text: p.stock.toString());
    final mfgCtrl = TextEditingController(text: p.mfgDate ?? '');
    final expCtrl = TextEditingController(text: p.expires ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg(context),
        title: Text('${state.tr('Update')} ${p.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Current Stock'), keyboardType: TextInputType.number),
              TextField(controller: mfgCtrl, decoration: const InputDecoration(labelText: 'MFG Date (YYYY-MM-DD)')),
              TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(state.tr('Cancel'))),
          ElevatedButton(
            onPressed: () {
              final updated = Product(
                id: p.id,
                name: p.name,
                category: p.category,
                price: double.tryParse(priceCtrl.text) ?? p.price,
                stock: int.tryParse(stockCtrl.text) ?? p.stock,
                threshold: p.threshold,
                emoji: p.emoji,
                shelf: p.shelf,
                unit: p.unit,
                description: p.description,
                imageUrl: p.imageUrl,
                supplierId: p.supplierId,
                mfgDate: mfgCtrl.text.isNotEmpty ? mfgCtrl.text : p.mfgDate,
                expires: expCtrl.text.isNotEmpty ? expCtrl.text : p.expires,
              );
              state.addProduct(updated);
              Navigator.pop(ctx);
            },
            child: Text(state.tr('Update')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg(context),
        title: Text(state.tr('Delete Product?')),
        content: Text('${state.tr('delete_confirm_msg')} (${p.name})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(state.tr('Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              state.deleteProduct(p.id);
              Navigator.pop(ctx);
            },
            child: Text(state.tr('Delete')),
          ),
        ],
      ),
    );
  }
}


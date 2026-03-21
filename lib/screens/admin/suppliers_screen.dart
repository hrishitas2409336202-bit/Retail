import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/supplier.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supplier_detail_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _sendingState = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final suppliers = state.suppliers;
    final orders = state.generatePurchaseOrders();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text('Suppliers & Orders',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHeading(context))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textHeading(context)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.textHeading(context),
          unselectedLabelColor: AppTheme.textBody(context),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.truck, size: 14),
                  const SizedBox(width: 6),
                  const Text('Suppliers'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.packagePlus, size: 14),
                  const SizedBox(width: 6),
                  Text('Orders ${orders.isNotEmpty ? "(${orders.length})" : ""}'),
                  if (orders.any((o) => o['priority'] == 'Urgent'))
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.clock, size: 14),
                  const SizedBox(width: 6),
                  Text('Pending ${state.pendingOrders.isNotEmpty ? "(${state.pendingOrders.length})" : ""}'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: SUPPLIERS ───
          _buildSuppliersTab(context, state, suppliers),
          // ─── TAB 2: REORDER NEEDED ───
          _buildOrdersTab(context, state, orders),
          // ─── TAB 3: PENDING DELIVERIES ───
          _buildPendingTab(context, state),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showAddSupplierSheet(context),
            backgroundColor: AppTheme.primary,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add Supplier',
                style: TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 1 — SUPPLIERS LIST
  // ══════════════════════════════════════════════
  Widget _buildSuppliersTab(
      BuildContext context, AppState state, List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.textBody(context).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.truck, size: 48, color: AppTheme.textBody(context).withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text('No suppliers yet',
                style: TextStyle(
                    color: AppTheme.textHeading(context), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Add a supplier to start sending purchase orders',
                style: TextStyle(color: AppTheme.textBody(context), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final s = suppliers[index];
        final supplierColor =
            Color(int.parse('FF${s.color}', radix: 16));
        // Count how many reorder items link to this supplier
        final supplierOrders = state
            .generatePurchaseOrders()
            .where((o) => (o['product'] as dynamic).supplierId == s.id)
            .length;

        return Dismissible(
          key: Key(s.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => state.deleteSupplier(s.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.redAccent.withOpacity(0.3))),
            child: const Icon(LucideIcons.trash2, color: Colors.redAccent),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => SupplierDetailScreen(supplier: s))),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.divider(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: supplierColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Text(s.emoji, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textHeading(context))),
                          const SizedBox(height: 2),
                          Text(s.category,
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textBody(context))),
                          if (s.phone.isNotEmpty || s.email.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  if (s.phone.isNotEmpty) ...[
                                    const Icon(LucideIcons.phone,
                                        size: 10, color: Colors.greenAccent),
                                    const SizedBox(width: 4),
                                    Text('+${s.phone}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.greenAccent)),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                          if (supplierOrders > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color:
                                        Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                    '$supplierOrders item${supplierOrders > 1 ? 's' : ''} need reorder',
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(s.monthly,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                                fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (s.status == 'Active'
                                    ? Colors.green
                                    : Colors.orange)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s.status,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: s.status == 'Active'
                                      ? Colors.greenAccent
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronRight,
                        size: 16, color: AppTheme.textBody(context)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  // TAB 2 — REORDER / PURCHASE ORDERS
  // ══════════════════════════════════════════════
  Widget _buildOrdersTab(BuildContext context, AppState state,
      List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle2,
                  size: 52, color: Colors.greenAccent),
            ),
            const SizedBox(height: 20),
            Text('All stock levels are healthy!',
                style: TextStyle(
                    color: AppTheme.textHeading(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('No reorder needed at this time.',
                style: TextStyle(color: AppTheme.textBody(context), fontSize: 13)),
          ],
        ),
      );
    }

    final totalCost = orders.fold<double>(
        0, (sum, o) => sum + (o['estCost'] as double));

    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Restock Cost',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('${state.currency}${totalCost.toInt()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _sendAllOrders(context, state, orders),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                icon: const Icon(LucideIcons.send, size: 14),
                label: const Text('Send All',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Orders list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final p = order['product'] as dynamic;
              final isUrgent = order['priority'] == 'Urgent';
              final isSending = _sendingState[p.id] ?? false;
              // Find linked supplier or null
              final linkedSupplier = state.suppliers
                  .where((s) => s.id == p.supplierId)
                  .isNotEmpty
                  ? state.suppliers
                      .firstWhere((s) => s.id == p.supplierId)
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isUrgent
                        ? Colors.redAccent.withOpacity(0.4)
                        : AppTheme.divider(context),
                    width: isUrgent ? 1.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Product header
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUrgent
                                ? [
                                    Colors.red.withOpacity(0.1),
                                    Colors.transparent
                                  ]
                                : [
                                    Colors.blue.withOpacity(0.06),
                                    Colors.transparent
                                  ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(p.emoji,
                                  style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: TextStyle(
                                          color: AppTheme.textHeading(context),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isUrgent
                                                  ? Colors.redAccent
                                                  : Colors.blueAccent)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Stock: ${p.stock} units',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isUrgent
                                                  ? Colors.redAccent
                                                  : Colors.blueAccent),
                                        ),
                                      ),
                                      if (isUrgent) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                            LucideIcons.alertTriangle,
                                            color: Colors.redAccent,
                                            size: 14),
                                        const SizedBox(width: 3),
                                        const Text('URGENT',
                                            style: TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ],
                                    ],
                                  ),
                                  if (linkedSupplier != null)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: InkWell(
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (c) =>
                                                    SupplierDetailScreen(
                                                        supplier:
                                                            linkedSupplier))),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.truck,
                                                size: 10,
                                                color: Colors.cyanAccent),
                                            const SizedBox(width: 4),
                                            Text(
                                                linkedSupplier.name,
                                                style: const TextStyle(
                                                    color: Colors.cyanAccent,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stats + buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _statBox(
                                        'REORDER QTY',
                                        '${order['recommended']} units',
                                        LucideIcons.packagePlus,
                                        Colors.cyanAccent)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _statBox(
                                        'EST. COST',
                                        '${state.currency}${(order['estCost'] as double).toInt()}',
                                        LucideIcons.indianRupee,
                                        Colors.amberAccent)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Send buttons
                            if (linkedSupplier != null) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isSending
                                          ? null
                                          : () => _sendViaWhatsApp(
                                              context,
                                              state,
                                              p,
                                              order,
                                              linkedSupplier),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF25D366),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(
                                          LucideIcons.messageCircle,
                                          size: 15),
                                      label: const Text('WhatsApp',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isSending
                                          ? null
                                          : () => _sendViaEmail(
                                              context,
                                              state,
                                              p,
                                              order,
                                              linkedSupplier),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(LucideIcons.mail,
                                          size: 15),
                                      label: const Text('Email',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => state.markAsOrdered(p,
                                    order['recommended'], linkedSupplier.name),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 42),
                                  side: BorderSide(
                                      color:
                                          Colors.purpleAccent.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(LucideIcons.listTodo,
                                    size: 14, color: Colors.purpleAccent),
                                label: const Text('Mark as Ordered (Track only)',
                                    style: TextStyle(
                                        color: Colors.purpleAccent,
                                        fontSize: 11)),
                              ),
                            ] else
                              // No supplier linked → show full-width button to assign
                              Column(
                                children: [
                                  const Text(
                                    'No supplier assigned to this product.',
                                    style: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showAddSupplierSheet(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            side: const BorderSide(color: Colors.cyanAccent),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(LucideIcons.plus, color: Colors.cyanAccent, size: 15),
                                          label: const Text('Add Supplier', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _tabController.animateTo(0),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            side: const BorderSide(color: Colors.white24),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(LucideIcons.link, color: Colors.white54, size: 15),
                                          label: const Text('Assign Existing', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statBox(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white38,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _sendViaWhatsApp(
    BuildContext context,
    AppState state,
    dynamic p,
    Map<String, dynamic> order,
    Supplier supplier,
  ) async {
    if (supplier.phone.isEmpty) {
      _showNoContactSnack(context, 'WhatsApp number');
      return;
    }
    setState(() => _sendingState[p.id] = true);
    try {
      final msg = _buildWhatsAppMessage(state, p, order, supplier);
      final phone = supplier.phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
      final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
      
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Show the mark-ordered prompt after a small delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _showMarkOrderedPrompt(context, state, p, order, supplier.name);
        });
      } catch (e) {
        if (!mounted) return;
        _showCantOpenSnack(context, 'WhatsApp');
      }
    } finally {
      if (mounted) setState(() => _sendingState[p.id] = false);
    }
  }

  Future<void> _sendViaEmail(
    BuildContext context,
    AppState state,
    dynamic p,
    Map<String, dynamic> order,
    Supplier supplier,
  ) async {
    if (supplier.email.isEmpty) {
      _showNoContactSnack(context, 'email address');
      return;
    }
    setState(() => _sendingState[p.id] = true);
    try {
      final body = _buildEmailMessage(state, p, order, supplier);
      final subject = Uri.encodeComponent('PURCHASE ORDER — ${p.name} — ${state.storeName}');
      final bodyEncoded = Uri.encodeComponent(body);
      final url = Uri.parse('mailto:${supplier.email}?subject=$subject&body=$bodyEncoded');
      
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Show the mark-ordered prompt after a small delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _showMarkOrderedPrompt(context, state, p, order, supplier.name);
        });
      } catch (e) {
        if (!mounted) return;
        _showCantOpenSnack(context, 'email client');
      }
    } finally {
      if (mounted) setState(() => _sendingState[p.id] = false);
    }
  }

  String _buildWhatsAppMessage(
      AppState state, dynamic p, Map<String, dynamic> order, Supplier supplier) {
    final qty = order['recommended'];
    final cost = (order['estCost'] as double).toInt();
    final now = DateTime.now();
    return '''Hello ${supplier.name},
 
This is an automated purchase order from *${state.storeName}*.

📦 *PURCHASE ORDER DETAILS*
----------------------------------------
*Product:* ${p.name}
*Quantity:* $qty units
*Est. Cost:* ${state.currency}$cost
*Order Date:* ${now.day}/${now.month}/${now.year}
----------------------------------------

Please confirm availability and the fastest delivery timeline.

Thanks,
*${state.storeName} Management*
_Sent via RetailIQ Smart Inventory_''';
  }

  String _buildEmailMessage(
      AppState state, dynamic p, Map<String, dynamic> order, Supplier supplier) {
    final qty = order['recommended'];
    final cost = (order['estCost'] as double).toInt();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final orderId = 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}';
    
    return '''PURCHASE ORDER: #$orderId

Dear ${supplier.name},

We would like to place a new purchase order for the following item:

ORDER DETAILS:
----------------------------------------
Order Reference: #$orderId
Product Name: ${p.name}
Quantity Requested: $qty units
Estimated Total: ${state.currency}$cost
Requested Date: $dateStr

STORE INFORMATION:
----------------------------------------
Store Name: ${state.storeName}
Contact: Order Management Team
System: RetailIQ Smart Inventory Integration

Payment Terms: As per existing agreement.
Billing UPI: ${state.upiId}

Please confirm the receipt of this order and providing us with the following:
1. Product availability
2. Proforma Invoice (if applicable)
3. Estimated delivery date

Thank you for your partnership.

Regards,

${state.storeName}
Procurement Department
RetailIQ Enterprise Suite''';
  }

  Widget _buildPendingTab(BuildContext context, AppState state) {
    final pending = state.pendingOrders;
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No pending deliveries', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final order = pending[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order['productName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('PENDING', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.truck, size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(order['supplierName'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const Spacer(),
                  Text('${order['qty']} units', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24, color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => state.cancelOrder(order['id']),
                      icon: const Icon(LucideIcons.xCircle, size: 14, color: Colors.redAccent),
                      label: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => state.receiveOrder(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        foregroundColor: Colors.greenAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.packageCheck, size: 14),
                      label: const Text('Receive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendAllOrders(
      BuildContext context, AppState state, List<Map<String, dynamic>> orders) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.mail, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Tap each supplier to send individual orders (${orders.length} pending)'),
          ],
        ),
        backgroundColor: Colors.purpleAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showNoContactSnack(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No $type saved for this supplier. Go to Suppliers tab and edit first.'),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCantOpenSnack(BuildContext context, String app) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open $app on this device.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMarkOrderedPrompt(
    BuildContext context,
    AppState state,
    dynamic p,
    Map<String, dynamic> order,
    String supplierName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.purpleAccent.withOpacity(0.5))),
        content: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Order Sent!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text('Mark "${p.name}" as ordered to track it?',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                state.markAsOrdered(p, order['recommended'], supplierName);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              child: const Text('TRACK IT'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSupplierSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSupplierSheet(),
    );
  }
}

// ═══════════════════════════════════════════════
// ➕ ADD SUPPLIER SHEET — Full Details Form
// ═══════════════════════════════════════════════

class AddSupplierSheet extends StatefulWidget {
  final Supplier? supplier;
  const AddSupplierSheet({super.key, this.supplier});

  @override
  State<AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<AddSupplierSheet> {
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _catController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _minOrderController = TextEditingController();
  String _selectedEmoji = '🚛';
  String _selectedColor = '6C63FF';

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      final s = widget.supplier!;
      _nameController.text = s.name;
      _businessNameController.text = s.businessName;
      _catController.text = s.category;
      _phoneController.text = s.phone;
      _emailController.text = s.email;
      _monthlyController.text = s.monthly;
      _minOrderController.text = s.minOrder;
      _selectedEmoji = s.emoji;
      _selectedColor = s.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _catController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _monthlyController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.truck,
                      color: Colors.cyanAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Supplier Details',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('Contact details used for WhatsApp & Email orders',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('👤 Basic Info'),
                  _buildField('Contact Name *', _nameController, LucideIcons.user),
                  const SizedBox(height: 12),
                  _buildField('Business / Company Name', _businessNameController, LucideIcons.building2),
                  const SizedBox(height: 12),
                  _buildField('Product Category (e.g. Dairy, Wholesale)', _catController, LucideIcons.tag),
                  const SizedBox(height: 20),

                  _sectionLabel('📞 Contact Details (for WhatsApp & Email orders)'),
                  _buildField(
                    'WhatsApp Number *',
                    _phoneController,
                    LucideIcons.phone,
                    hint: 'e.g. 919876543210 (country code first)',
                    keyboardType: TextInputType.phone,
                    helperText: 'Include country code (91 for India). No +, spaces, or dashes.',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    'Email Address *',
                    _emailController,
                    LucideIcons.mail,
                    hint: 'supplier@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel('📦 Order Details'),
                  _buildField('Monthly Volume (e.g. ₹50,000)', _monthlyController, LucideIcons.indianRupee),
                  const SizedBox(height: 12),
                  _buildField('Min. Order Quantity (units)', _minOrderController,
                      LucideIcons.packageCheck,
                      keyboardType: TextInputType.number, hint: 'e.g. 50'),
                  const SizedBox(height: 20),

                  _sectionLabel('🎨 Appearance'),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Icon',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedEmoji,
                                dropdownColor: const Color(0xFF1E293B),
                                underline: const SizedBox(),
                                style: const TextStyle(fontSize: 22),
                                isExpanded: true,
                                items: ['🚛', '🏬', '📦', '🥛', '🏭', '🛒', '🌾', '🥩', '🧴', '🌱', '🥬', '🥕', '🍎', '🥤', '🧼', '🦷', '🦋', '📦']
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedEmoji = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Theme Color',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedColor,
                                dropdownColor: const Color(0xFF1E293B),
                                underline: const SizedBox(),
                                isExpanded: true,
                                items: [
                                  {'name': 'Purple', 'hex': '6C63FF'},
                                  {'name': 'Green', 'hex': '10B981'},
                                  {'name': 'Cyan', 'hex': '06B6D4'},
                                  {'name': 'Orange', 'hex': 'F59E0B'},
                                  {'name': 'Pink', 'hex': 'EC4899'},
                                ].map((c) => DropdownMenuItem(
                                  value: c['hex'],
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                            color: Color(int.parse(
                                                'FF${c['hex']}',
                                                radix: 16)),
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(c['name']!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedColor = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _saveSupplier,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(LucideIcons.checkCircle, size: 20),
                    label: const Text('SAVE SUPPLIER',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSupplier() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the supplier name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_phoneController.text.isEmpty && _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least a phone or email to send orders'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final newSupplier = Supplier(
      id: widget.supplier?.id ?? 'SUP-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      businessName: _businessNameController.text.trim(),
      category: _catController.text.trim().isEmpty
          ? 'General'
          : _catController.text.trim(),
      emoji: _selectedEmoji,
      status: widget.supplier?.status ?? 'Active',
      monthly: _monthlyController.text.isEmpty
          ? '₹0'
          : _monthlyController.text.trim(),
      ontime: widget.supplier?.ontime ?? '100%',
      rating: widget.supplier?.rating ?? '5.0',
      color: _selectedColor,
      phone: _phoneController.text
          .trim()
          .replaceAll('+', '')
          .replaceAll(' ', '')
          .replaceAll('-', ''),
      email: _emailController.text.trim(),
      minOrder: _minOrderController.text.isEmpty
          ? '50'
          : _minOrderController.text.trim(),
    );

    context.read<AppState>().addSupplier(newSupplier);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(widget.supplier != null ? 'Details updated!' : '${newSupplier.name} added!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    String? hint,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(color: Colors.white54, fontSize: 13),
            hintText: hint,
            hintStyle:
                const TextStyle(color: Colors.white24, fontSize: 12),
            prefixIcon: Icon(icon, size: 18, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(helperText,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
          ),
      ],
    );
  }
}


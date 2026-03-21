import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/supplier.dart';
import '../../models/product.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'smart_command_screens.dart';
import 'suppliers_screen.dart'; // Added to use AddSupplierSheet

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;
  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final supplierProducts =
        state.inventory.where((p) => p.supplierId == widget.supplier.id).toList();

    int lowStockCount =
        supplierProducts.where((p) => p.stock <= p.threshold).length;
    double healthPercent = supplierProducts.isEmpty
        ? 100
        : (1 - (lowStockCount / supplierProducts.length)) * 100;

    final supplierColor =
        Color(int.parse('FF${widget.supplier.color}', radix: 16));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [supplierColor, supplierColor.withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 10,
                      child: IconButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddSupplierSheet(supplier: widget.supplier),
                        ),
                        icon: const Icon(LucideIcons.edit, color: Colors.white, size: 20),
                        tooltip: 'Edit Supplier',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(widget.supplier.emoji,
                                    style: const TextStyle(fontSize: 36)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.supplier.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                    Text(widget.supplier.category,
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(widget.supplier.status,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Key Stats ──
                  Row(
                    children: [
                      Expanded(
                          child: _statCard(
                              'Rating',
                              '${widget.supplier.rating}⭐',
                              LucideIcons.star,
                              Colors.amberAccent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard(
                              'On-Time',
                              widget.supplier.ontime,
                              LucideIcons.clock,
                              Colors.greenAccent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard(
                              'Volume',
                              widget.supplier.monthly,
                              LucideIcons.indianRupee,
                              Colors.cyanAccent)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stock Health ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stock Health',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${healthPercent.toInt()}% Availability',
                                style:
                                    const TextStyle(color: Colors.white70)),
                            Text('$lowStockCount low items',
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: healthPercent / 100,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                healthPercent > 70
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Supplier Info ──
                  const Text('Supplier Info',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(
                      children: [
                        _infoRow(LucideIcons.building2, 'Business Name',
                            widget.supplier.name),
                        _infoRow(LucideIcons.tag, 'Category',
                            widget.supplier.category),
                        _infoRow(LucideIcons.phone, 'WhatsApp',
                            widget.supplier.phone.isEmpty
                                ? 'Not added yet'
                                : '+${widget.supplier.phone}',
                            color: widget.supplier.phone.isNotEmpty ? Colors.greenAccent : Colors.white38),
                        _infoRow(LucideIcons.mail, 'Email',
                            widget.supplier.email.isEmpty
                                ? 'Not added yet'
                                : widget.supplier.email,
                            color: widget.supplier.email.isNotEmpty ? Colors.cyanAccent : Colors.white38),
                        _infoRow(LucideIcons.packageCheck, 'Min Order',
                            '${widget.supplier.minOrder} units'),
                        _infoRow(LucideIcons.calendarDays, 'Last Order',
                            'Mar 10, 2026'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── ACTION: Generate Purchase Order ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.2),
                          Colors.blue.withOpacity(0.1)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.zap,
                                color: Colors.purpleAccent, size: 18),
                            const SizedBox(width: 8),
                            const Text('Smart Purchase Order',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Generate a purchase order and send directly to ${widget.supplier.name} via WhatsApp or Email.',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => PurchaseOrderGeneratorSheet(
                                supplier: widget.supplier,
                                prefilledProduct: supplierProducts.isNotEmpty
                                    ? supplierProducts.first
                                    : null,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(LucideIcons.fileText, size: 18),
                            label: const Text('Generate & Send Order',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Supplied Products ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Supplied Products (${supplierProducts.length})',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (supplierProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Center(
                          child: Text(
                              'No products linked to this supplier yet.',
                              style: TextStyle(color: Colors.white38))),
                    )
                  else
                    ...supplierProducts.map((p) => _productRow(p, state)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              textAlign: TextAlign.center),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 12),
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color ?? Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _productRow(Product p, AppState state) {
    final isLow = p.stock <= p.threshold;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isLow
                ? Colors.redAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Text(p.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    'Stock: ${p.stock} | ${state.currency}${p.price.toInt()}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          isLow
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('LOW',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                )
              : const Icon(LucideIcons.checkCircle2,
                  color: Colors.greenAccent, size: 18),
        ],
      ),
    );
  }
}


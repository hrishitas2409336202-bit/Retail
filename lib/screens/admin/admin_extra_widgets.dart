import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import 'purchase_order_screen.dart';

// ══════════════════════════════════════════════════════
// 🗓  EXPIRY ALERT BANNER
// Shows products whose `expires` field signals urgency
// ══════════════════════════════════════════════════════
class ExpiryAlertBanner extends StatelessWidget {
  final AppState state;
  const ExpiryAlertBanner({super.key, required this.state});

  bool _isSoonExpiry(String? exp) {
    if (exp == null || exp.isEmpty) return false;
    return exp.contains('hour') ||
        exp.contains('1 day') ||
        exp.contains('2 day') ||
        exp.contains('3 day');
  }

  String _urgencyLabel(String? exp) {
    if (exp == null || exp.isEmpty) return '';
    if (exp.contains('hour')) return 'TODAY';
    if (exp.contains('1 day')) return '1 DAY';
    if (exp.contains('2 day')) return '2 DAYS';
    if (exp.contains('3 day')) return '3 DAYS';
    return exp;
  }

  Color _urgencyColor(String? exp) {
    if (exp == null) return Colors.deepOrange;
    if (exp.contains('hour') || exp.contains('1 day')) return Colors.redAccent;
    return Colors.deepOrange;
  }

  @override
  Widget build(BuildContext context) {
    final expiring = state.inventory.where((p) => _isSoonExpiry(p.expires)).toList();
    if (expiring.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.withOpacity(0.15), Colors.red.withOpacity(0.07)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.12), blurRadius: 14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.deepOrange, Colors.redAccent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.4), blurRadius: 8)],
                ),
                child: const Icon(LucideIcons.calendarX, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠ Expiry Alert',
                      style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '${expiring.length} product${expiring.length > 1 ? "s" : ""} expiring very soon',
                    style: TextStyle(color: Colors.deepOrange.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Product list
          ...expiring.map((p) {
            final labelColor = _urgencyColor(p.expires);
            final label = _urgencyLabel(p.expires);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: labelColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('Stock: ${p.stock} units  •  ${p.expires ?? ""}',
                            style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: labelColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: labelColor.withOpacity(0.4)),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: labelColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// 🎯  DAILY REVENUE TARGET CARD
// Circular progress ring with motivational status
// ══════════════════════════════════════════════════════
class DailyRevenueTargetCard extends StatelessWidget {
  final AppState state;
  static const double dailyTarget = 5000.0;

  const DailyRevenueTargetCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final revenue = state.todayRevenue;
    final progress = (revenue / dailyTarget).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    final isAchieved = revenue >= dailyTarget;

    final Color color = isAchieved
        ? Colors.greenAccent
        : progress > 0.6
            ? Colors.amberAccent
            : Colors.blueAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          // Circular ring
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$percent%',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('done',
                        style: TextStyle(color: color.withOpacity(0.6), fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.target, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    const Text('Daily Revenue Target',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${state.currency}${revenue.toStringAsFixed(0)}',
                    style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
                Text('of ${state.currency}${dailyTarget.toInt()} target',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 10),
                if (isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.partyPopper, color: Colors.greenAccent, size: 13),
                        SizedBox(width: 5),
                        Text('Target Achieved!',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  Text(
                    '${state.currency}${(dailyTarget - revenue).toStringAsFixed(0)} remaining',
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// 🔁  QUICK RESTOCK PANEL
// Top critical items with WhatsApp 1-tap restock
// ══════════════════════════════════════════════════════
class QuickRestockPanel extends StatelessWidget {
  final AppState state;
  const QuickRestockPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final critical = state.inventory.where((p) => p.stock <= p.threshold).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    if (critical.isEmpty) return const SizedBox.shrink();

    final top3 = critical.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.07), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.purpleAccent.withOpacity(0.35), blurRadius: 8)
                      ],
                    ),
                    child: const Icon(LucideIcons.zap, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Quick Restock',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${critical.length} critical',
                    style: const TextStyle(
                        color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Product rows
          ...top3.map((p) {
            final supplierList =
                state.suppliers.where((s) => s.id == p.supplierId).toList();
            final supplier = supplierList.isNotEmpty ? supplierList.first : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          p.stock == 0 ? '⚠ Out of stock' : 'Only ${p.stock} left',
                          style: TextStyle(
                              color: p.stock == 0 ? Colors.redAccent : Colors.orangeAccent,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (supplier != null && supplier.phone.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final phone = supplier.phone.replaceAll(RegExp(r'[^0-9]'), '');
                        final msg = Uri.encodeComponent(
                            'Hi ${supplier.name}, we need to restock ${p.name}.'
                            ' Current stock: ${p.stock} units. Please arrange supply. '
                            '— ${state.storeName} via RetailIQ');
                        final url = Uri.parse('https://wa.me/$phone?text=$msg');
                        if (await canLaunchUrl(url)) {
                          launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF25D366), Color(0xFF128C7E)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF25D366).withOpacity(0.3),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.messageCircle, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text('Restock',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PurchaseOrderScreen())),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                        ),
                        child: const Text('Order',
                            style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PurchaseOrderScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
              ),
              child: const Center(
                child: Text('View All Purchase Orders →',
                    style: TextStyle(
                        color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

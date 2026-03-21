import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state.dart';
import '../../models/sale.dart';
import 'invoice_screen.dart';

class BillsHistoryScreen extends StatefulWidget {
  const BillsHistoryScreen({super.key});

  @override
  State<BillsHistoryScreen> createState() => _BillsHistoryScreenState();
}

class _BillsHistoryScreenState extends State<BillsHistoryScreen> {
  String _searchQuery = '';
  String _filterMethod = 'All';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allSales = state.sales
      ..sort((a, b) => b.date.compareTo(a.date));

    final filtered = allSales.where((s) {
      final matchSearch = _searchQuery.isEmpty ||
          s.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.items.any((i) =>
              i.name.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchFilter = _filterMethod == 'All' || 
          s.paymentMethod == _filterMethod || 
          (_filterMethod == 'Online' && s.paymentMethod == 'UPI');
      return matchSearch && matchFilter;
    }).toList();

    // Group by date
    final Map<String, List<Sale>> grouped = {};
    for (var sale in filtered) {
      final key = _formatDateKey(sale.date);
      grouped.putIfAbsent(key, () => []).add(sale);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bills History',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Summary Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildSummaryBanner(state),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search bills or items...',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 13),
                        prefixIcon: Icon(LucideIcons.search,
                            color: Colors.white.withOpacity(0.3), size: 18),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter button
                PopupMenuButton<String>(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) => setState(() => _filterMethod = v),
                  itemBuilder: (context) => ['All', 'Cash', 'Online', 'Card']
                      .map((m) => PopupMenuItem(
                            value: m,
                            child: Row(
                              children: [
                                if (_filterMethod == m)
                                  const Icon(LucideIcons.check,
                                      size: 14, color: Colors.greenAccent),
                                const SizedBox(width: 8),
                                Text(m,
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ],
                            ),
                          ))
                      .toList(),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: _filterMethod != 'All'
                          ? Colors.blueAccent.withOpacity(0.2)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _filterMethod != 'All'
                              ? Colors.blueAccent.withOpacity(0.4)
                              : Colors.white.withOpacity(0.07)),
                    ),
                    child: Icon(LucideIcons.filter,
                        color: _filterMethod != 'All'
                            ? Colors.blueAccent
                            : Colors.white.withOpacity(0.4),
                        size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Bills List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileX,
                            color: Colors.white24, size: 48),
                        const SizedBox(height: 16),
                        const Text('No bills found',
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, groupIdx) {
                      final dateKey =
                          grouped.keys.elementAt(groupIdx);
                      final sales = grouped[dateKey]!;
                      final dayTotal = sales.fold(
                          0.0, (sum, s) => sum + s.total);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Separator
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(dateKey,
                                      style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white
                                            .withOpacity(0.06))),
                                const SizedBox(width: 10),
                                Text(
                                  '${context.read<AppState>().currency}${dayTotal.toInt()} · ${sales.length} bills',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.4),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ...sales
                              .map((s) => _buildBillCard(context, s))
                              ,
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(AppState state) {
    final totalRevenue = state.sales.fold(0.0, (sum, s) => sum + s.total);
    final todayRevenue = state.todayRevenue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.25),
            Colors.purpleAccent.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _summaryItem(LucideIcons.receipt, 'Total Bills',
              '${state.sales.length}', Colors.blueAccent),
          _summaryDivider(),
          _summaryItem(LucideIcons.trendingUp, 'All Time',
              '${state.currency}${totalRevenue.toInt()}', Colors.purpleAccent),
          _summaryDivider(),
          _summaryItem(LucideIcons.calendarDays, 'Today',
              '${state.currency}${todayRevenue.toInt()}', Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _summaryItem(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
        width: 1, height: 36, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildBillCard(BuildContext context, Sale sale) {
    Color methodColor;
    IconData methodIcon;
    switch (sale.paymentMethod) {
      case 'Online':
      case 'UPI':
        methodColor = Colors.purpleAccent;
        methodIcon = LucideIcons.qrCode;
        break;
      case 'Card':
        methodColor = Colors.blueAccent;
        methodIcon = LucideIcons.creditCard;
        break;
      default:
        methodColor = Colors.greenAccent;
        methodIcon = LucideIcons.banknote;
    }

    final timeStr = _formatTime(sale.date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => InvoiceScreen(sale: sale),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            // Left: payment icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(methodIcon, color: methodColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Middle: bill details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sale.id,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                      Text(
                        '${context.read<AppState>().currency}${sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock,
                          size: 11,
                          color: Colors.white.withOpacity(0.35)),
                      const SizedBox(width: 4),
                      Text(timeStr,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11)),
                      const SizedBox(width: 10),
                      Icon(LucideIcons.package,
                          size: 11,
                          color: Colors.white.withOpacity(0.35)),
                      const SizedBox(width: 4),
                      Text(
                        '${sale.items.length} item${sale.items.length == 1 ? '' : 's'}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: methodColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sale.paymentMethod == 'UPI' ? 'Online' : sale.paymentMethod,
                          style: TextStyle(
                              color: methodColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (sale.items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        sale.items.map((i) => i.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight,
                color: Colors.white.withOpacity(0.2), size: 16),
          ],
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    } else if (date.day == now.subtract(const Duration(days: 1)).day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Yesterday';
    }
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}


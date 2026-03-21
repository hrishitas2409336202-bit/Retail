import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'staff_billing_screen.dart';
import 'staff_inventory_screen.dart';
import 'barcode_scanner_screen.dart';
import 'support_screen.dart';
import 'profile_screen.dart';
import 'bills_history_screen.dart';
import '../../models/product.dart';
import 'dart:ui';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    String greetingEmoji = "☀️";
    if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
      greetingEmoji = "🌤️";
    }
    if (hour >= 17) {
      greeting = "Good Evening";
      greetingEmoji = "🌙";
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _buildGradientOrb(Colors.blue.withOpacity(0.12), 400),
          ),
          Positioned(
            bottom: 300,
            left: -150,
            child: _buildGradientOrb(Colors.purple.withOpacity(0.08), 350),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(greetingEmoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  "${state.tr('Welcome back')}, Staff",
                                  style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.storeName,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => const ProfileScreen()),
                          ),
                          child: _buildAvatar(),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Daily Sales Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _buildSalesSummary(state),
                  ),
                ),

                // 3. Quick Actions Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildActionCard(
                        context,
                        title: state.tr('billing'),
                        subtitle: '${state.todayBillsCount} ${state.tr('bills today')}',
                        icon: LucideIcons.shoppingCart,
                        color: Colors.blueAccent,
                        badge: state.todayBillsCount > 0 ? '${state.todayBillsCount}' : null,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (c) => const StaffBillingScreen())),
                        isDark: isDark,
                      ),
                      _buildActionCard(
                        context,
                        title: state.tr('AI Scanner'),
                        subtitle: state.tr('OpenFood Powered'),
                        icon: LucideIcons.scan,
                        color: Colors.greenAccent,
                        isAI: true,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (c) => const BarcodeScannerScreen())),
                        isDark: isDark,
                      ),
                      _buildActionCard(
                        context,
                        title: state.tr('inventory'),
                        subtitle: '${state.inventory.length} ${state.tr('products')}',
                        icon: LucideIcons.package,
                        color: Colors.amberAccent,
                        badge: state.lowStockCount > 0 ? '${state.lowStockCount}⚠' : null,
                        badgeColor: Colors.orangeAccent,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (c) => const StaffInventoryScreen())),
                        isDark: isDark,
                      ),
                      _buildActionCard(
                        context,
                        title: state.tr('support'),
                        subtitle: state.tr('Get help'),
                        icon: LucideIcons.helpCircle,
                        color: Colors.purpleAccent,
                        badge: state.activeTicketsCount > 0 ? '${state.activeTicketsCount}' : null,
                        badgeColor: Colors.purpleAccent,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (c) => const SupportScreen())),
                        isDark: isDark,
                      ),
                    ]),
                  ),
                ),

                // 4. Low Stock Alerts
                if (state.lowStockCount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: _buildLowStockSection(context, state),
                    ),
                  ),

                // 5. Bills History Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _buildBillsHistoryBanner(context, state),
                  ),
                ),

                // 6. Top Selling Today
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.tr("Top Selling Today"),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildTopSellingList(state),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildGlowingFAB(context, state),
    );
  }

  Widget _buildGradientOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF1E293B),
        child: Icon(LucideIcons.user, color: Colors.blueAccent.withValues(alpha: 0.8), size: 24),
      ),
    );
  }

  Widget _buildSalesSummary(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Summary",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),

            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem("Revenue", "${state.currency}${state.todayRevenue.toInt()}", LucideIcons.banknote, Colors.blueAccent),
              _summaryItem("Bills", "${state.todayBillsCount}", LucideIcons.receipt, Colors.purpleAccent),
              _summaryItem("Items", "${state.todayItemsSold}", LucideIcons.package, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    bool isAI = false,
    bool isDark = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isAI ? color.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.03) : Colors.black12)),
          boxShadow: isAI || !isDark ? [
            BoxShadow(color: isDark ? color.withOpacity(0.05) : Colors.black.withOpacity(0.05), blurRadius: 12, spreadRadius: 1),
          ] : [],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45, fontSize: 11)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? Colors.blueAccent).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (badgeColor ?? Colors.blueAccent).withOpacity(0.3)),
                  ),
                  child: Text(badge,
                      style: TextStyle(color: badgeColor ?? Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            if (isAI)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: const Text('AI', style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(state.tr("Low Stock Alerts"),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text("${state.lowStockCount} ${state.tr('ITEMS')}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: state.lowStockProducts.length,
            itemBuilder: (context, index) {
              final p = state.lowStockProducts[index];
              final isOut = p.stock == 0;
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOut ? Colors.redAccent : Colors.orangeAccent).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (isOut ? Colors.redAccent : Colors.orangeAccent).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                           Text(
                            isOut ? state.tr("Out of Stock!") : "${p.stock} ${state.tr('left')}",
                            style: TextStyle(
                                color: isOut ? Colors.redAccent : Colors.orangeAccent,
                                fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillsHistoryBanner(BuildContext context, AppState state) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BillsHistoryScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: const Icon(LucideIcons.history, color: Colors.blueAccent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bills History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("${state.sales.length} ${state.tr('total transactions')}",
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingList(AppState state) {
    final tops = state.getTopSellingProducts(3);
    if (tops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.trendingUp, color: Colors.white38, size: 20),
            SizedBox(width: 12),
            Text("No sales recorded today", style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      children: tops.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final rankColors = [Colors.amberAccent, Colors.white60, Colors.orangeAccent];
        final rankEmojis = ['🥇', '🥈', '🥉'];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Text(rankEmojis[idx], style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(item['emoji'], style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("${item['quantity']} ${state.tr('units sold')}",
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                  ],
                ),
              ),
              Text("${state.currency}${item['totalValue'].toInt()}",
                  style: TextStyle(color: rankColors[idx], fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _buildGlowingFAB(BuildContext context, AppState state) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 15, spreadRadius: 1),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const StaffBillingScreen()),
        ),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(state.tr("NEW BILL"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}


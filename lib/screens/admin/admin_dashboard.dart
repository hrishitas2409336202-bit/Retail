import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/sales_heatmap.dart';
import 'shelf_map_screen.dart';
import 'ai_advisor_chat.dart';
import 'admin_inventory_screen.dart';
import 'suppliers_screen.dart';
import 'promotions_screen.dart';
import 'loyalty_screen.dart';
import 'settings_screen.dart';
import 'admin_insights_screen.dart';
import '../staff/bills_history_screen.dart';
import 'smart_command_screens.dart';
import 'purchase_order_screen.dart';
import 'admin_extra_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
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
    final suggestions = state.getAIAdvisorSuggestions();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _buildGradientOrb(AppTheme.primary.withOpacity(0.12), 400),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: _buildGradientOrb(AppTheme.accent.withOpacity(0.08), 350),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header
                SliverToBoxAdapter(
                  child: _buildHeader(context, state),
                ),

                // 2. Live Stats from Staff Activity
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _buildLiveSalesSummary(state, context),
                  ),
                ),

                // 3. Low Stock Alert (Connected to real inventory)
                if (state.lowStockCount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: _buildLowStockAlert(context, state),
                    ),
                  ),

                // 4. AI Suggestions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: _buildAIAdvisorBanner(context, suggestions, state),
                  ),
                ),

                // 4b. Predictive Intelligence Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _buildPredictiveBanner(context, state),
                  ),
                ),

                // 4c. Stock-Out Forecast Inline
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _buildStockOutForecastCard(context, state),
                  ),
                ),

                // 4d. Risk Radar Inline
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _buildRiskRadarCard(context, state),
                  ),
                ),

                // 4e. Demand Trend Alerts Inline
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _buildDemandTrendsCard(context, state),
                  ),
                ),

                // 4f. Expiry Alert
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: ExpiryAlertBanner(state: state),
                  ),
                ),

                // 4g. Daily Revenue Target Ring
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: DailyRevenueTargetCard(state: state),
                  ),
                ),

                // 4h. Quick Restock Panel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: QuickRestockPanel(state: state),
                  ),
                ),

                // 5. Sales Performance Chart + Heatmap
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sales Performance',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildSalesChart(context, state),
                        const SizedBox(height: 24),
                        const Text('Sales Heatmap',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SalesHeatMap(sales: state.sales),
                      ],
                    ),
                  ),
                ),

                // 6. Feature Grid (All working)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: _buildFeatureGrid(context),
                  ),
                ),

                // 7. Top Selling (Connected to real sales data)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Top Sellers Today",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildTopSellingList(state),
                      ],
                    ),
                  ),
                ),

                // 8. Recent System Activity (Full & Connected to Staff)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: _buildSystemActivitySection(context, state),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),

          // Sync indicator
          if (state.isSyncing)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accent),
                      SizedBox(height: 16),
                      Text('Syncing data...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientOrb(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome back, Admin",
                  style: TextStyle(color: AppTheme.textBody(context), fontSize: 14)),
              const SizedBox(height: 4),
              Text(state.storeName,
                  style: TextStyle(color: AppTheme.textHeading(context), fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const SizedBox.shrink(),
              // Theme toggle
              GestureDetector(
                onTap: () => state.toggleTheme(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, color: AppTheme.textBody(context), size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Settings
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen())),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.settings, color: AppTheme.textBody(context), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, double score, AppState state) {
    // Health Score is now embedded in Live Sales Summary
    return const SizedBox.shrink();
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: AppTheme.textBody(context), fontSize: 9)),
      ],
    );
  }

  Widget _buildLiveSalesSummary(AppState state, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.divider(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Live Sales Summary",
                  style: TextStyle(
                      color: AppTheme.textHeading(context), fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (c) => const BillsHistoryScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: const Text("View Bills",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat('REVENUE', '${state.currency}${state.todayRevenue.toInt()}',
                  LucideIcons.banknote, Colors.blueAccent, context),
              _summaryStat('BILLS', '${state.todayBillsCount}',
                  LucideIcons.receipt, Colors.purpleAccent, context),
              _summaryStat('ITEMS SOLD', '${state.todayItemsSold}',
                  LucideIcons.package, Colors.orangeAccent, context),
              _summaryStat('LOW STOCK', '${state.lowStockCount}',
                  LucideIcons.alertTriangle, Colors.redAccent, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, IconData icon, Color color, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: AppTheme.textHeading(context), fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(
                color: AppTheme.textBody(context), fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildLowStockAlert(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  const Text("Inventory Alerts",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text("${state.lowStockCount} CRITICAL",
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: state.lowStockProducts.length,
              itemBuilder: (context, index) {
                final p = state.lowStockProducts[index];
                final isOut = p.stock == 0;
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: (isOut ? Colors.redAccent : Colors.orangeAccent)
                            .withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                            Text(
                              isOut ? "OUT OF STOCK" : "${p.stock} remaining",
                              style: TextStyle(
                                  color: isOut ? Colors.redAccent : Colors.orangeAccent,
                                  fontSize: 10),
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (c) => const PurchaseOrderScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shoppingBag, color: Colors.redAccent, size: 14),
                  SizedBox(width: 8),
                  Text("Create Purchase Order",
                      style: TextStyle(
                          color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAdvisorBanner(BuildContext context,
      List<Map<String, dynamic>> suggestions, AppState state) {
    final firstSuggestion = suggestions.isNotEmpty
        ? suggestions.first['text'] as String
        : "Your store is running smoothly. Tap to get detailed AI insights and recommendations.";

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (c) => const AIAdvisorChat())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF4F46E5).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RetailIQ AI Business Advisor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('Powered by Smart AI Analysis',
                        style: TextStyle(color: Colors.white60, fontSize: 10)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.arrowRight, color: Colors.white, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.messageSquare, color: Colors.white60, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      firstSuggestion,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text("Chat with AI Advisor →",
                    style: TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, AppState state) {
    // Build last 7 days revenue spots from real data
    final now = DateTime.now();
    final spots = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayRevenue = state.sales
          .where((s) =>
              s.date.day == day.day &&
              s.date.month == day.month &&
              s.date.year == day.year)
          .fold(0.0, (sum, s) => sum + s.total);
      return FlSpot(i.toDouble(), dayRevenue);
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: spots.isEmpty
          ? const Center(child: Text("No sales data", style: TextStyle(color: Colors.white38)))
          : LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.accent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.accent.withOpacity(0.12)),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Predictive Intelligence Banner ──
  Widget _buildPredictiveBanner(BuildContext context, AppState state) {
    final lowStockCount = state.inventory.where((p) => p.stock <= p.threshold).length;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictiveAnalyticsScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(LucideIcons.brain, color: Colors.purpleAccent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Predictive Intelligence',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    lowStockCount > 0
                        ? '$lowStockCount items may stock out soon — tap for full forecast'
                        : 'All stock levels healthy — tap for trend analysis',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Stock-Out Forecast Card (Inline) ──
  Widget _buildStockOutForecastCard(BuildContext context, AppState state) {
    final now = DateTime.now();
    final last7Days = state.sales.where((s) => now.difference(s.date).inDays <= 7).toList();
    final Map<String, int> salesCounts = {};
    for (var sale in last7Days) {
      for (var item in sale.items) {
        salesCounts[item.name] = (salesCounts[item.name] ?? 0) + item.qty;
      }
    }
    final forecasts = state.inventory.map((p) {
      final totalSold = salesCounts[p.name] ?? 0;
      final avgDaily = totalSold / 7.0;
      final days = avgDaily > 0 ? p.stock / avgDaily : 999.0;
      return {'product': p, 'days': days};
    }).where((f) => (f['days'] as double) < 15).toList();
    forecasts.sort((a, b) => (a['days'] as double).compareTo(b['days'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.clock, color: Colors.orangeAccent, size: 18),
                SizedBox(width: 8),
                Text('Stock-Out Forecast',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictiveAnalyticsScreen())),
              child: const Text('View All', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (forecasts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 18),
                SizedBox(width: 10),
                Text('All products have healthy stock levels!',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          )
        else
          ...forecasts.take(3).map((f) {
            final p = f['product'] as dynamic;
            final days = f['days'] as double;
            final color = days < 3 ? Colors.redAccent : days < 7 ? Colors.amberAccent : Colors.orangeAccent;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text('${days.toStringAsFixed(1)} days',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Risk Radar Card (Inline) — Redesigned ──
  Widget _buildRiskRadarCard(BuildContext context, AppState state) {
    final risks = state.getRiskRadar().take(4).toList();
    final highCount = risks.where((r) => r['level'] == 'High').length;
    final medCount = risks.where((r) => r['level'] == 'Medium').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.redAccent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
        ],
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
                      gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.35), blurRadius: 10)],
                    ),
                    child: const Icon(LucideIcons.radar, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Inventory Risk Radar',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictiveAnalyticsScreen())),
                child: const Text('View All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live risk summary chips
          Row(
            children: [
              _riskSummaryChip('$highCount High', Colors.redAccent),
              const SizedBox(width: 8),
              _riskSummaryChip('$medCount Medium', Colors.orangeAccent),
              const SizedBox(width: 8),
              _riskSummaryChip('${risks.where((r) => r['level'] == 'Healthy').length} Healthy', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 16),

          if (risks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.shieldCheck, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 10),
                  Text('No high-risk items detected today!',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            )
          else
            ...risks.map((r) {
              final p = r['product'] as dynamic;
              final level = r['level'] as String;
              final score = (r['score'] as double).clamp(0.0, 100.0);
              final color = level == 'High' ? Colors.redAccent : level == 'Medium' ? Colors.amberAccent : Colors.greenAccent;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: score / 100,
                                    backgroundColor: color.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${score.toInt()}/100',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.35)),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 6)],
                      ),
                      child: Text(level, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _riskSummaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)])),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Demand Trends Card (Inline) ──
  Widget _buildDemandTrendsCard(BuildContext context, AppState state) {
    final now = DateTime.now();
    final thisWeek = state.sales.where((s) => now.difference(s.date).inDays <= 3).toList();
    final lastWeek = state.sales.where((s) => now.difference(s.date).inDays > 3 && now.difference(s.date).inDays <= 7).toList();
    final Map<String, int> thisMap = {}, lastMap = {};
    for (var sale in thisWeek) for (var item in sale.items) {
      thisMap[item.name] = (thisMap[item.name] ?? 0) + item.qty;
    }
    for (var sale in lastWeek) for (var item in sale.items) {
      lastMap[item.name] = (lastMap[item.name] ?? 0) + item.qty;
    }
    final List<Map<String, dynamic>> trends = [];
    for (var name in thisMap.keys) {
      final cur = thisMap[name]!.toDouble();
      final prev = (lastMap[name] ?? 1).toDouble();
      final change = ((cur - prev) / prev) * 100;
      if (change.abs() >= 25) {
        trends.add({'name': name, 'change': change, 'type': change > 0 ? 'surge' : 'decline'});
      }
    }
    trends.sort((a, b) => (b['change'] as double).abs().compareTo((a['change'] as double).abs()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.trendingUp, color: Colors.cyanAccent, size: 18),
            SizedBox(width: 8),
            Text('Demand Trend Alerts',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        if (trends.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.activity, color: Colors.cyanAccent, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Demand patterns stable. No unusual movements detected.',
                    style: TextStyle(color: Colors.white70, fontSize: 13))),
              ],
            ),
          )
        else
          ...trends.take(3).map((t) {
            final isSurge = t['type'] == 'surge';
            final color = isSurge ? Colors.greenAccent : Colors.redAccent;
            final change = '${isSurge ? '+' : ''}${(t['change'] as double).toStringAsFixed(0)}%';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(isSurge ? LucideIcons.trendingUp : LucideIcons.trendingDown, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${t['name']} demand ${isSurge ? 'surging' : 'declining'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text(change, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'title': 'Inventory',
        'subtitle': 'Manage products',
        'icon': LucideIcons.boxes,
        'color': Colors.blueAccent,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminInventoryScreen())),
      },
      {
        'title': 'Suppliers & Orders',
        'subtitle': 'Vendors + Orders',
        'icon': LucideIcons.truck,
        'color': Colors.cyanAccent,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SuppliersScreen())),
      },
      {
        'title': 'AI Advisor',
        'subtitle': 'Smart AI Insights',
        'icon': LucideIcons.sparkles,
        'color': Color(0xFF7C3AED),
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AIAdvisorChat())),
        'isAI': true,
      },
      {
        'title': 'Predictive AI',
        'subtitle': 'Forecast & risk',
        'icon': LucideIcons.brain,
        'color': Colors.purpleAccent,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PredictiveAnalyticsScreen())),
        'isAI': true,
      },
      {
        'title': 'Store Twin',
        'subtitle': 'Visual shelf map',
        'icon': LucideIcons.map,
        'color': Colors.tealAccent,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StoreDigitalTwinScreen())),
      },
      {
        'title': 'Promotions',
        'subtitle': 'Create deals',
        'icon': LucideIcons.megaphone,
        'color': Colors.pinkAccent,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PromotionsScreen())),
      },
      {
        'title': 'Loyalty Hub',
        'subtitle': 'Customer rewards',
        'icon': LucideIcons.crown,
        'color': Colors.amberAccent,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoyaltyScreen())),
      },
      {
        'title': 'Analytics',
        'subtitle': 'Deep insights',
        'icon': LucideIcons.barChart3,
        'color': Colors.greenAccent,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminInsightsScreen())),
      },
      {
        'title': 'Bills History',
        'subtitle': 'All transactions',
        'icon': LucideIcons.history,
        'color': Colors.white70,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BillsHistoryScreen())),
      },
      {
        'title': 'Settings',
        'subtitle': 'Store config',
        'icon': LucideIcons.settings,
        'color': Colors.blueGrey,
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen())),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Store Management",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.5,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final f = features[index];
            final color = f['color'] as Color;
            final isAI = (f['isAI'] as bool?) ?? false;
            return GestureDetector(
              onTap: f['route'] as VoidCallback,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAI ? color.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                  ),
                  boxShadow: isAI
                      ? [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12)]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(f['icon'] as IconData, color: color, size: 18),
                        ),
                        const Spacer(),
                        if (isAI)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('AI',
                                style: TextStyle(
                                    color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(f['title'] as String,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(f['subtitle'] as String,
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopSellingList(AppState state) {
    final tops = state.getTopSellingProducts(5);
    if (tops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.trendingUp, color: Colors.white24, size: 20),
            SizedBox(width: 12),
            Text("No sales recorded today yet",
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      children: tops.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final rankEmojis = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Text(rankEmojis[idx], style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(item['emoji'], style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("${item['quantity']} units sold",
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Text("${state.currency}${item['totalValue'].toInt()}",
                  style: const TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── System Activity Section (connected to real staff events) ────────────
  Widget _buildSystemActivitySection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("System Activity",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAllActivitySheet(context, state),
              icon: const Icon(LucideIcons.externalLink, size: 14, color: Colors.blueAccent),
              label: const Text("View All",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Real-time staff activity & system events",
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (state.events.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(LucideIcons.activity, color: Colors.white24, size: 32),
                  SizedBox(height: 8),
                  Text("No activity recorded yet",
                      style: TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          Column(
            children: state.events.take(6).map((event) => _buildActivityTile(event)).toList(),
          ),
      ],
    );
  }

  Widget _buildActivityTile(String event) {
    String msg = event;
    String time = "";
    final regex = RegExp(r'^\[(\d+:\d+)\]\s*');
    final match = regex.firstMatch(event);
    if (match != null) {
      time = match.group(1)!;
      msg = event.replaceFirst(regex, '');
    }

    IconData icon = LucideIcons.activity;
    Color color = Colors.blueAccent;

    if (msg.toLowerCase().contains('sale') ||
        msg.toLowerCase().contains('bill') ||
        msg.toLowerCase().contains('checkout')) {
      icon = LucideIcons.shoppingCart;
      color = Colors.greenAccent;
    } else if (msg.toLowerCase().contains('scan') ||
        msg.toLowerCase().contains('barcode')) {
      icon = LucideIcons.scan;
      color = Colors.blueAccent;
    } else if (msg.toLowerCase().contains('stock') ||
        msg.toLowerCase().contains('critical')) {
      icon = LucideIcons.alertTriangle;
      color = Colors.orangeAccent;
    } else if (msg.toLowerCase().contains('product') ||
        msg.toLowerCase().contains('added') ||
        msg.toLowerCase().contains('inventory')) {
      icon = LucideIcons.package;
      color = Colors.amberAccent;
    } else if (msg.toLowerCase().contains('sync') ||
        msg.toLowerCase().contains('cloud')) {
      icon = LucideIcons.cloud;
      color = Colors.cyanAccent;
    } else if (msg.toLowerCase().contains('system') ||
        msg.toLowerCase().contains('initiali')) {
      icon = LucideIcons.zap;
      color = Colors.white38;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          ),
          const SizedBox(width: 8),
          if (time.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(time,
                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9)),
            ),
        ],
      ),
    );
  }

  void _showAllActivitySheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.activity,
                          color: Colors.blueAccent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("System Activity Log",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text("${state.events.length} events",
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Close",
                          style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: state.events.isEmpty
                    ? const Center(
                        child: Text("No system events",
                            style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        controller: sc,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: state.events.length,
                        itemBuilder: (ctx, idx) =>
                            _buildActivityTile(state.events[idx]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Select Language",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          ...['English', 'Hindi', 'Marathi'].map((lang) => ListTile(
                title: Text(lang, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  state.setLanguage(lang);
                  Navigator.pop(ctx);
                },
                trailing: state.currentLanguage == lang
                    ? const Icon(LucideIcons.check, color: Colors.greenAccent)
                    : null,
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


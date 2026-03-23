import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'shelf_map_screen.dart';
import 'ai_advisor_chat.dart';
import 'admin_insights_screen.dart';
import 'suppliers_screen.dart';
import 'settings_screen.dart';
import 'promotions_screen.dart';
import 'loyalty_screen.dart';
import 'admin_inventory_screen.dart';
import '../../widgets/sales_heatmap.dart';
import '../staff/profile_screen.dart';
import '../staff/support_screen.dart';
import 'admin_extra_widgets.dart';

class StoreCommandCenter extends StatelessWidget {
  const StoreCommandCenter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final trends = state.getTrendingKPIs();
    final suggestions = state.getAIAdvisorSuggestions();


    return Scaffold(
      appBar: AppBar(
        title: Text(state.tr('store_command_center'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          const SizedBox.shrink(),
          IconButton(
            icon: Icon(
              state.themeMode == ThemeMode.dark ? LucideIcons.sun : LucideIcons.moon,
            ),
            onPressed: () => state.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.userCircle),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, state),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Enhanced KPI Cards
            _buildEnhancedKPI(context, state, trends),
            const SizedBox(height: 24),

            // 2. AI Business Advisor Widget
            _buildAIAdvisorWidget(context, suggestions),
            const SizedBox(height: 24),

            // 2b. Expiry Alert
            ExpiryAlertBanner(state: state),

            // 3. Inventory Risk Radar
            _buildRiskRadar(context, state),
            const SizedBox(height: 24),

            // 4. Sales Activity Heatmap
            SalesHeatMap(sales: state.sales),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Smart Alerts removed per user request

  Widget _buildEnhancedKPI(BuildContext context, AppState state, Map<String, dynamic> trends) {
    final avgBill = state.todayBillsCount > 0
        ? (state.todayRevenue / state.todayBillsCount)
        : 0.0;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _kpiCard(context, state,
                title: 'Revenue',
                value: '${state.currency}${trends['revenue'].toInt()}',
                trend: trends['revenueTrend'],
                icon: LucideIcons.indianRupee,
                color: const Color(0xFF22C55E),
              )),
              const SizedBox(width: 14),
              Expanded(child: _kpiCard(context, state,
                title: 'Transactions',
                value: '${trends['transactions']}',
                trend: trends['txTrend'].toDouble(),
                icon: LucideIcons.shoppingCart,
                color: const Color(0xFF3B82F6),
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _kpiCard(context, state,
                title: 'Avg Bill Value',
                value: '${state.currency}${avgBill.toStringAsFixed(0)}',
                trend: 0,
                icon: LucideIcons.receipt,
                color: const Color(0xFF06B6D4),
                subValue: '${(avgBill / 500 * 100).clamp(0, 100).toInt()}% ${state.tr('of ₹500 target')}',
                progress: (avgBill / 500).clamp(0.0, 1.0),
              )),
              const SizedBox(width: 14),
              Expanded(child: _kpiCard(context, state,
                title: 'Low Stock',
                value: '${state.inventory.where((p) => p.stock <= p.threshold).length}',
                trend: 0,
                icon: LucideIcons.package2,
                color: const Color(0xFFF97316),
              )),
            ],
          ),
        ),
      ],
    );
  }


  Widget _kpiCard(
    BuildContext context, 
    AppState state, {
    required String title,
    required String value,
    required double trend,
    required IconData icon,
    required Color color,
    String? subValue,
    double? progress,
  }) {
    final isPositive = trend >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A2035), color.withOpacity(0.08)]
              : [Colors.white, color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background glow orb
          Positioned(
            right: -18, bottom: -18,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withOpacity(0.2), Colors.transparent]),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon bubble + trend badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.5), color.withOpacity(0.2)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  if (trend != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: (isPositive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                            color: isPositive ? Colors.greenAccent : Colors.redAccent,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text('${trend.abs().toInt()}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Big value
              Text(value,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textHeading(context),
                      letterSpacing: -1)),
              const SizedBox(height: 3),
              Text(state.tr(title),
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textBody(context),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2)),
              if (progress != null) ...[ 
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subValue ?? '',
                    style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
              ],
              const Spacer(),
              // Bottom glow bar
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.0)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildAIAdvisorWidget(BuildContext context, List<Map<String, dynamic>> suggestions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.8), AppTheme.secondary]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AIAdvisorChat())),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bot, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text('AI Business Advisor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(LucideIcons.chevronRight, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(16))),
              child: Text(
                suggestions.isNotEmpty ? suggestions.first['text'] : Provider.of<AppState>(context, listen: false).tr('ai_analysis_loading'),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskRadar(BuildContext context, AppState state) {
    return RiskRadarWidget(state: state);
  }


  Widget _buildDrawer(BuildContext context, AppState state) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary.withOpacity(0.8), AppTheme.secondary],
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.layoutDashboard, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(child: Text('Command Center', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(context, state.tr('Risk Report'), LucideIcons.shieldAlert, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ShelfMapScreen()))),
                _drawerTile(context, state.tr('Analytics'), LucideIcons.barChart3, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminInsightsScreen()))),
                _drawerTile(context, state.tr('AI Insight'), LucideIcons.sparkles, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AIAdvisorChat()))),
                _drawerTile(context, state.tr('Orders'), LucideIcons.truck, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SuppliersScreen()))),
                _drawerTile(context, state.tr('Promotions'), LucideIcons.megaphone, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PromotionsScreen()))),
                _drawerTile(context, state.tr('Loyalty Hub'), LucideIcons.crown, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoyaltyScreen()))),
                _drawerTile(context, state.tr('Inventory'), LucideIcons.boxes, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminInventoryScreen()))),
                _drawerTile(context, state.tr('Profile'), LucideIcons.user, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen()))),
                _drawerTile(context, state.tr('Support Tickets'), LucideIcons.ticket, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SupportScreen()))),
                _drawerTile(context, state.tr('Settings'), LucideIcons.settings, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
            title: Text(state.tr('Logout') ?? 'Logout', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => state.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHeading(context))),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }

  Widget _actionTile(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: AppTheme.cardBg(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider(context)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, List<Map<String, dynamic>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sales Leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.cardBg(context), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: data.take(3).map((item) => ListTile(
              leading: Text(item['emoji'], style: const TextStyle(fontSize: 24)),
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('${item['sold']} ${Provider.of<AppState>(context, listen: false).tr('Sold')}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      case 'info': return Colors.blue;
      default: return AppTheme.primary;
    }
  }
}

// ══════════════════════════════════════════════════════
// 📡 RISK RADAR — Stateful for chip filter selection
// ══════════════════════════════════════════════════════
class RiskRadarWidget extends StatefulWidget {
  final AppState state;
  const RiskRadarWidget({super.key, required this.state});

  @override
  State<RiskRadarWidget> createState() => _RiskRadarWidgetState();
}

class _RiskRadarWidgetState extends State<RiskRadarWidget> {
  // null = show all, 'out' / 'critical' / 'low' = filtered
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final all = widget.state.inventory
        .where((p) => p.stock <= p.threshold)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    // LOW = stock 1–10,  CRITICAL = stock 11–19,  OUT = stock 0
    final outCount  = all.where((p) => p.stock == 0).length;
    final lowCount  = all.where((p) => p.stock >= 1 && p.stock <= 10).length;
    final critCount = all.where((p) => p.stock >= 11 && p.stock < 20).length;

    // Apply filter
    final displayed = _selectedFilter == null
        ? all
        : _selectedFilter == 'out'
            ? all.where((p) => p.stock == 0).toList()
            : _selectedFilter == 'low'
                ? all.where((p) => p.stock >= 1 && p.stock <= 10).toList()
                : all.where((p) => p.stock >= 11 && p.stock < 20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 8)],
              ),
              child: const Icon(LucideIcons.radar, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.state.tr('Inventory Risk Radar'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading(context))),
                  Text(widget.state.tr('Products below restock threshold'),
                      style: TextStyle(fontSize: 11, color: AppTheme.textBody(context))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.divider(context)),
            boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.05), blurRadius: 20)],
          ),
          child: all.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 20),
                      SizedBox(width: 10),
                      Text(widget.state.tr('All products are well stocked!'),
                          style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tappable filter chips ──
                    Row(
                      children: [
                        _filterChip(outCount,  'OUT',      'out',      Colors.redAccent,    LucideIcons.alertTriangle),
                        const SizedBox(width: 8),
                        _filterChip(lowCount,   'LOW',      'low',      Colors.amberAccent,  LucideIcons.trendingDown),
                        const SizedBox(width: 8),
                        _filterChip(critCount,  'CRITICAL', 'critical', Colors.orangeAccent, LucideIcons.alertCircle),
                      ],
                    ),
                    if (_selectedFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = null),
                          child: Row(
                            children: [
                              Icon(LucideIcons.x, size: 12, color: AppTheme.textBody(context)),
                              const SizedBox(width: 4),
                              Text('${widget.state.tr('Clear filter')} — ${widget.state.tr('show all')} ${all.length}',
                                  style: TextStyle(color: AppTheme.textBody(context), fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    if (displayed.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(widget.state.tr('No products in this category'),
                              style: TextStyle(color: AppTheme.textBody(context))),
                        ),
                      )
                    else
                      ...displayed.map((p) {
                        final isOut  = p.stock == 0;
                        final isLow  = !isOut && p.stock >= 1 && p.stock <= 10;
                        final isCrit = !isOut && p.stock >= 11 && p.stock < 20;
                        final color  = isOut ? Colors.redAccent : isLow ? Colors.amberAccent : Colors.orangeAccent;
                        final label  = isOut ? widget.state.tr('Out') : isLow ? widget.state.tr('Low') : widget.state.tr('Critical');
                        final icon   = isOut ? LucideIcons.alertTriangle : isLow ? LucideIcons.trendingDown : LucideIcons.alertCircle;
                        final fill = p.threshold > 0 ? (p.stock / p.threshold).clamp(0.0, 1.0) : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(p.emoji, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(p.name,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                            color: AppTheme.textHeading(context)),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: color.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, color: color, size: 10),
                                        const SizedBox(width: 3),
                                        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: fill,
                                        backgroundColor: color.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                        minHeight: 7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${p.stock}/${p.threshold}',
                                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Need ${p.threshold - p.stock} more units to reach threshold',
                                  style: TextStyle(color: AppTheme.textBody(context), fontSize: 9)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _filterChip(int count, String label, String key, Color color, IconData icon) {
    final isSelected = _selectedFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = isSelected ? null : key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.25) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: Text('$count $label',
                    style: TextStyle(
                        color: color,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

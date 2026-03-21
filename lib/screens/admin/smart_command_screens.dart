import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/product.dart';
import '../../models/supplier.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════
// 🧠 PREDICTIVE ANALYTICS DASHBOARD
// Contains: Stock-Out Forecast, Risk Radar,
// Purchase Recommendations, Demand Trend Detector
// ═══════════════════════════════════════════════════

class PredictiveAnalyticsScreen extends StatelessWidget {
  const PredictiveAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Predictive Intelligence',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStockOutForecast(context, state),
          const SizedBox(height: 20),
          _buildRiskRadar(context, state),
          const SizedBox(height: 20),
          _buildDemandTrendDetector(context, state),
          const SizedBox(height: 20),
          _buildPurchaseRecommendations(context, state),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── 1. STOCK-OUT FORECAST ──
  Widget _buildStockOutForecast(BuildContext context, AppState state) {
    final forecasts = _calculateForecasts(state);

    return _GlassCard(
      gradient: const [Color(0xFF1E293B), Color(0xFF1E1B4B)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.clock, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock-Out Forecast',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('Days until stock runs out',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (forecasts.isEmpty)
            const Center(
                child: Text('No stock data available',
                    style: TextStyle(color: Colors.white54)))
          else
            ...forecasts.take(8).map((f) => _buildForecastRow(context, f)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateForecasts(AppState state) {
    final Map<String, int> salesCounts = {};
    final now = DateTime.now();
    final last7Days = state.sales
        .where((s) => now.difference(s.date).inDays <= 7)
        .toList();

    for (var sale in last7Days) {
      for (var item in sale.items) {
        salesCounts[item.name] = (salesCounts[item.name] ?? 0) + item.qty;
      }
    }

    final results = <Map<String, dynamic>>[];
    for (var p in state.inventory) {
      final totalSold = salesCounts[p.name] ?? 0;
      final avgDailyRate = totalSold / 7.0;
      final daysLeft = avgDailyRate > 0 ? p.stock / avgDailyRate : 999.0;

      results.add({
        'product': p,
        'daysLeft': daysLeft,
        'avgDaily': avgDailyRate,
        'urgency': daysLeft < 3
            ? 'critical'
            : daysLeft < 7
                ? 'warning'
                : 'healthy',
      });
    }

    results.sort(
        (a, b) => (a['daysLeft'] as double).compareTo(b['daysLeft'] as double));
    return results;
  }

  Widget _buildForecastRow(
      BuildContext context, Map<String, dynamic> forecast) {
    final p = forecast['product'] as Product;
    final days = forecast['daysLeft'] as double;
    final urgency = forecast['urgency'] as String;

    final color = urgency == 'critical'
        ? Colors.redAccent
        : urgency == 'warning'
            ? Colors.amberAccent
            : Colors.greenAccent;

    final daysText = days >= 999
        ? '∞ days'
        : '${days.toStringAsFixed(1)} days';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
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
                Text('${p.stock} units • ${(forecast['avgDaily'] as double).toStringAsFixed(1)}/day',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Text(daysText,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── 2. RISK RADAR ──
  Widget _buildRiskRadar(BuildContext context, AppState state) {
    final allRisks = state.getRiskRadar();
    final riskItems = allRisks.take(8).toList();
    final highCount = allRisks.where((r) => r['level'] == 'High').length;
    final medCount = allRisks.where((r) => r['level'] == 'Medium').length;
    final healthyCount = allRisks.where((r) => r['level'] == 'Healthy').length;
    final total = allRisks.length;

    return _GlassCard(
      gradient: const [Color(0xFF1E293B), Color(0xFF1B2A1E)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 10)],
                ),
                child: const Icon(LucideIcons.radar, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory Risk Radar',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Multi-factor risk analysis', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview stat row
          Row(
            children: [
              _riskOverviewChip('$highCount\nHIGH', Colors.redAccent, LucideIcons.alertTriangle),
              const SizedBox(width: 10),
              _riskOverviewChip('$medCount\nMEDIUM', Colors.amberAccent, LucideIcons.alertCircle),
              const SizedBox(width: 10),
              _riskOverviewChip('$healthyCount\nHEALTHY', Colors.greenAccent, LucideIcons.shieldCheck),
            ],
          ),
          const SizedBox(height: 16),

          // Stacked risk bar
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  if (highCount > 0)
                    Expanded(
                      flex: highCount,
                      child: Container(height: 6, color: Colors.redAccent),
                    ),
                  if (medCount > 0)
                    Expanded(
                      flex: medCount,
                      child: Container(height: 6, color: Colors.amberAccent),
                    ),
                  if (healthyCount > 0)
                    Expanded(
                      flex: healthyCount,
                      child: Container(height: 6, color: Colors.greenAccent),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('$total products analysed',
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 16),
          ],

          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Individual risk rows
          if (riskItems.isEmpty)
            const Center(child: Text('No inventory data', style: TextStyle(color: Colors.white54)))
          else
            ...riskItems.map((r) => _buildRiskRow(r)),
        ],
      ),
    );
  }

  Widget _riskOverviewChip(String text, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)])),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildRiskRow(Map<String, dynamic> riskData) {
    final p = riskData['product'] as Product;
    final level = riskData['level'] as String;
    final score = (riskData['score'] as double).clamp(0.0, 100.0);

    final color = level == 'High'
        ? Colors.redAccent
        : level == 'Medium'
            ? Colors.amberAccent
            : Colors.greenAccent;

    final icon = level == 'High'
        ? LucideIcons.alertTriangle
        : level == 'Medium'
            ? LucideIcons.alertCircle
            : LucideIcons.checkCircle2;

    // Determine risk factor labels
    final factors = <String>[];
    if (p.stock <= 0) factors.add('Out of stock');
    else if (p.stock <= p.threshold) factors.add('Low stock');
    if (p.expires != null && p.expires!.isNotEmpty &&
        (p.expires!.contains('day') || p.expires!.contains('hour'))) {
      factors.add('Expiring soon');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(p.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6)],
                ),
                child: Text(level, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Score bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${score.toInt()}/100',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: factors.map((f) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 6),
          Text('Stock: ${p.stock} units  •  Threshold: ${p.threshold}',
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  // ── 3. DEMAND TREND DETECTOR ──
  Widget _buildDemandTrendDetector(BuildContext context, AppState state) {
    final trends = _detectDemandTrends(state);

    return _GlassCard(
      gradient: const [Color(0xFF1E293B), Color(0xFF1B1E2A)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.trendingUp,
                    color: Colors.cyanAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demand Trend Detector',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('Unusual sales movements',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (trends.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(LucideIcons.info,
                      color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'No significant demand changes detected in the last 7 days. Things look stable!',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            ...trends.map((t) => _buildTrendAlert(t)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _detectDemandTrends(AppState state) {
    final now = DateTime.now();
    final thisWeek = state.sales
        .where((s) => now.difference(s.date).inDays <= 3)
        .toList();
    final lastWeek = state.sales
        .where((s) =>
            now.difference(s.date).inDays > 3 &&
            now.difference(s.date).inDays <= 7)
        .toList();

    final Map<String, int> thisWeekMap = {};
    final Map<String, int> lastWeekMap = {};

    for (var sale in thisWeek) {
      for (var item in sale.items) {
        thisWeekMap[item.name] = (thisWeekMap[item.name] ?? 0) + item.qty;
      }
    }
    for (var sale in lastWeek) {
      for (var item in sale.items) {
        lastWeekMap[item.name] = (lastWeekMap[item.name] ?? 0) + item.qty;
      }
    }

    final List<Map<String, dynamic>> trends = [];
    for (var name in thisWeekMap.keys) {
      final current = thisWeekMap[name]!.toDouble();
      final previous = (lastWeekMap[name] ?? 1).toDouble();
      final changePercent = ((current - previous) / previous) * 100;

      if (changePercent.abs() >= 30) {
        trends.add({
          'name': name,
          'change': changePercent,
          'type': changePercent > 0 ? 'surge' : 'decline',
          'emoji': state.inventory
                  .where((p) => p.name == name)
                  .isNotEmpty
              ? state.inventory.firstWhere((p) => p.name == name).emoji
              : '📦',
        });
      }
    }

    trends.sort((a, b) =>
        (b['change'] as double).abs().compareTo((a['change'] as double).abs()));
    return trends.take(5).toList();
  }

  Widget _buildTrendAlert(Map<String, dynamic> trend) {
    final isSurge = trend['type'] == 'surge';
    final color = isSurge ? Colors.greenAccent : Colors.redAccent;
    final icon = isSurge ? LucideIcons.trendingUp : LucideIcons.trendingDown;
    final changeText =
        '${isSurge ? '+' : ''}${(trend['change'] as double).toStringAsFixed(0)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(trend['emoji'], style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trend['name'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(
                    isSurge
                        ? 'Demand is surging — consider restocking now!'
                        : 'Sales declining — consider a flash sale or promotion.',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(changeText,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4. PURCHASE RECOMMENDATIONS ──
  Widget _buildPurchaseRecommendations(BuildContext context, AppState state) {
    final recommendations = state.generatePurchaseOrders();

    return _GlassCard(
      gradient: const [Color(0xFF1E293B), Color(0xFF1A2A1E)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.shoppingCart,
                    color: Colors.purpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchase Recommendations',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('AI-suggested restock quantities',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recommendations.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.2))),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2,
                      color: Colors.greenAccent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'All inventory levels are healthy! No purchase orders needed right now.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            ...recommendations
                .take(5)
                .map((r) => _buildRecommendationCard(context, r, state)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context, Map<String, dynamic> rec, AppState state) {
    final p = rec['product'] as Product;
    final priority = rec['priority'] as String;
    final recommended = rec['recommended'] as int;
    final estCost = rec['estCost'] as double;
    final isUrgent = priority == 'Urgent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent
              ? [
                  Colors.red.withOpacity(0.08),
                  Colors.orange.withOpacity(0.04)
                ]
              : [
                  Colors.purple.withOpacity(0.08),
                  Colors.blue.withOpacity(0.04)
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (isUrgent ? Colors.redAccent : Colors.purpleAccent)
                .withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Current: ${p.stock} units',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: (isUrgent ? Colors.redAccent : Colors.amber)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(priority,
                    style: TextStyle(
                        color: isUrgent ? Colors.redAccent : Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _recStat(
                    'Suggest Order', '$recommended units', Colors.cyanAccent),
              ),
              Expanded(
                child: _recStat('Est. Cost',
                    '${state.currency}${estCost.toInt()}', Colors.amberAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// 🏪 STORE DIGITAL TWIN — Visual Shelf Map
// ═══════════════════════════════════════════════════

class StoreDigitalTwinScreen extends StatelessWidget {
  const StoreDigitalTwinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Group products by shelf
    final Map<String, List<Product>> shelves = {};
    for (var p in state.inventory) {
      final shelf = p.shelf.isNotEmpty ? p.shelf : 'S0';
      shelves.putIfAbsent(shelf, () => []).add(p);
    }

    final sortedShelves = shelves.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Store Digital Twin',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _legendDot(Colors.greenAccent, 'Healthy'),
                const SizedBox(width: 10),
                _legendDot(Colors.amberAccent, 'Low'),
                const SizedBox(width: 10),
                _legendDot(Colors.redAccent, 'Critical'),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF1E1B4B)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _twinStat('${state.inventory.length}', 'Products',
                      Colors.cyanAccent),
                  _twinStat('${sortedShelves.length}', 'Shelves',
                      Colors.purpleAccent),
                  _twinStat('${state.lowStockCount}', 'Low Stock',
                      Colors.redAccent),
                  _twinStat(
                      '${state.inventory.where((p) => p.stock > p.threshold * 2).length}',
                      'Healthy',
                      Colors.greenAccent),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Store floor map label
            const Text('🏪 Store Floor Layout',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
                'Tap on any product to see details',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),

            // Shelf grid
            ...sortedShelves.map((shelfId) {
              final shelfProducts = shelves[shelfId]!;
              return _buildShelf(context, shelfId, shelfProducts, state);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShelf(BuildContext context, String shelfId,
      List<Product> products, AppState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.layers, color: Colors.white38, size: 14),
                const SizedBox(width: 8),
                Text('Shelf $shelfId',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Spacer(),
                Text('${products.length} products',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          // Product grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCell(
                    context, products[index], state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCell(
      BuildContext context, Product p, AppState state) {
    final ratio = p.stock / (p.threshold == 0 ? 1 : p.threshold);
    final Color cellColor = ratio <= 0
        ? Colors.redAccent
        : ratio < 1
            ? Colors.redAccent
            : ratio < 2
                ? Colors.amberAccent
                : Colors.greenAccent;

    final double fillLevel =
        (p.stock / (p.threshold * 3)).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showProductDetail(context, p, state),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cellColor.withOpacity(0.4)),
        ),
        child: Stack(
          children: [
            // Fill level indicator (bottom fill)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 80 * fillLevel,
                decoration: BoxDecoration(
                  color: cellColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12)),
                ),
              ),
            ),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.emoji,
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(p.name,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: cellColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${p.stock}',
                      style: TextStyle(
                          color: cellColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(
      BuildContext context, Product p, AppState state) {
    final ratio = p.stock / (p.threshold == 0 ? 1 : p.threshold);
    final status = ratio <= 0
        ? 'Out of Stock'
        : ratio < 1
            ? 'Critical'
            : ratio < 2
                ? 'Low Stock'
                : 'Healthy';
    final color = ratio <= 0
        ? Colors.redAccent
        : ratio < 1
            ? Colors.redAccent
            : ratio < 2
                ? Colors.amberAccent
                : Colors.greenAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(p.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(p.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(p.category,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _detailStat('Stock', '${p.stock}', Colors.white),
                _detailStat('Threshold', '${p.threshold}', Colors.amberAccent),
                _detailStat('Status', status, color),
                _detailStat('Price',
                    '${state.currency}${p.price.toInt()}', Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2))),
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text('Location: Shelf ${p.shelf}',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _twinStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// 🔄 PURCHASE ORDER GENERATOR WIDGET
// ═══════════════════════════════════════════════════

class PurchaseOrderGeneratorSheet extends StatefulWidget {
  final Supplier supplier;
  final Product? prefilledProduct;

  const PurchaseOrderGeneratorSheet(
      {super.key, required this.supplier, this.prefilledProduct});

  @override
  State<PurchaseOrderGeneratorSheet> createState() =>
      _PurchaseOrderGeneratorSheetState();
}

class _PurchaseOrderGeneratorSheetState
    extends State<PurchaseOrderGeneratorSheet> {
  Product? _selectedProduct;
  int _quantity = 50;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.prefilledProduct;
  }

  String get _orderMessage {
    final p = _selectedProduct;
    if (p == null) return '';
    final state = context.read<AppState>();
    final totalValue = _quantity * p.price * 0.7;

    return '''Hello ${widget.supplier.name},

We would like to place a purchase order:

🛒 *Purchase Order Details*
Product: ${p.name}
Quantity: $_quantity units
Price per unit: ${state.currency}${(p.price * 0.7).toStringAsFixed(2)}
Total Value: ${state.currency}${totalValue.toStringAsFixed(2)}
Order Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

Please confirm availability and expected delivery date.

Thanks,
${state.storeName} — via RetailIQ''';
  }

  Future<void> _sendViaWhatsApp() async {
    if (_selectedProduct == null) return;

    if (widget.supplier.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No WhatsApp number saved for this supplier. Please edit supplier details.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final phone = widget.supplier.phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
      final encoded = Uri.encodeComponent(_orderMessage);
      final url = Uri.parse('https://wa.me/$phone?text=$encoded');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp. Make sure it is installed.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendViaEmail() async {
    if (_selectedProduct == null) return;

    if (widget.supplier.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email saved for this supplier. Please edit supplier details.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final state = context.read<AppState>();
      final subject = Uri.encodeComponent(
          'Purchase Order from ${state.storeName} — RetailIQ');
      final body = Uri.encodeComponent(_orderMessage);
      final url = Uri.parse('mailto:${widget.supplier.email}?subject=$subject&body=$body');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No email client found on this device'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final supplierProducts =
        state.inventory.where((p) => p.supplierId == widget.supplier.id).toList();
    final products = supplierProducts.isEmpty ? state.inventory : supplierProducts;

    final p = _selectedProduct;
    final double totalValue = p != null ? _quantity * p.price * 0.7 : 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.fileText,
                      color: Colors.purpleAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Generate Purchase Order',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(widget.supplier.name,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Selector
                  const Text('Select Product',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1))),
                    child: DropdownButton<Product>(
                      isExpanded: true,
                      value: _selectedProduct,
                      dropdownColor: const Color(0xFF1E293B),
                      hint: const Text('Choose a product...',
                          style: TextStyle(color: Colors.white54)),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Row(
                            children: [
                              Text(product.emoji),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(product.name,
                                    style:
                                        const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(
                                  '${product.stock} left',
                                  style: TextStyle(
                                      color: product.stock <= product.threshold
                                          ? Colors.redAccent
                                          : Colors.white38,
                                      fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedProduct = v),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quantity Selector
                  const Text('Order Quantity',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1))),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              setState(() => _quantity = (_quantity - 10).clamp(1, 9999)),
                          icon: const Icon(LucideIcons.minus,
                              color: Colors.white, size: 18),
                        ),
                        Expanded(
                          child: Text('$_quantity units',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _quantity += 10),
                          icon: const Icon(LucideIcons.plus,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Order Preview Card
                  if (p != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.15),
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
                          const Row(
                            children: [
                              Icon(LucideIcons.fileCheck,
                                  color: Colors.purpleAccent, size: 16),
                              SizedBox(width: 8),
                              Text('Purchase Order Preview',
                                  style: TextStyle(
                                      color: Colors.purpleAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 24),
                          _orderRow('Supplier', widget.supplier.name),
                          _orderRow('Product',
                              '${p.emoji} ${p.name}'),
                          _orderRow('Quantity', '$_quantity units'),
                          _orderRow('Unit Price',
                              '${state.currency}${(p.price * 0.7).toStringAsFixed(2)}'),
                          _orderRow('Total Value',
                              '${state.currency}${totalValue.toStringAsFixed(2)}',
                              highlight: true),
                          _orderRow('Order Date',
                              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Send Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendViaWhatsApp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(LucideIcons.messageCircle,
                                size: 18),
                            label: const Text('WhatsApp',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendViaEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(LucideIcons.mail, size: 18),
                            label: const Text('Email',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: highlight ? Colors.cyanAccent : Colors.white,
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.w500,
                  fontSize: highlight ? 16 : 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 🔷 SHARED GLASS CARD WIDGET
// ═══════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradient;

  const _GlassCard({required this.child, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: child,
    );
  }
}


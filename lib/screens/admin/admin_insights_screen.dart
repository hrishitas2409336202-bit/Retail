import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/demand_prediction_engine.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminInsightsScreen extends StatelessWidget {
  const AdminInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final predictions = DemandPredictionEngine.getAllPredictions(state.inventory, state.sales);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text('Demand Forecasting', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHeading(context))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textHeading(context)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final pred = predictions[index];
                  // Find the respective product to get its details
                  final product = state.inventory.firstWhere((p) => p.id == pred['productId']);
                  return _buildPredictionCard(context, pred, product);
                },
                childCount: predictions.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.barChart4, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Prediction Engine', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Analyzing 14-day velocity to predict future stock-outs before they happen.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(BuildContext context, Map<String, dynamic> pred, product) {
    final hasHighDemand = pred['predictedDemand'] > 10;
    final needsRestock = pred['suggestedRestock'] > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: needsRestock ? Colors.orangeAccent.withOpacity(0.5) : AppTheme.divider(context),
          width: needsRestock ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (needsRestock)
            BoxShadow(color: Colors.orangeAccent.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (needsRestock ? Colors.orangeAccent : AppTheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(product.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pred['name'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Stock: ${product.stock}',
                      style: TextStyle(fontSize: 12, color: needsRestock ? Colors.orangeAccent : AppTheme.textBody(context), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (hasHighDemand && !needsRestock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.trendingUp, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('High Demand', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoBlock(context, 'DAILY AVG', '${pred['avgDaily'].toStringAsFixed(1)} units'),
                _divider(context),
                _infoBlock(context, '7-DAY DEMAND', '${pred['predictedDemand'].toStringAsFixed(0)} units', color: hasHighDemand ? AppTheme.accent : null),
                _divider(context),
                _infoBlock(context, 'SUGGESTION', needsRestock ? 'RESTOCK +${pred['suggestedRestock']}' : 'STABLE', 
                  color: needsRestock ? Colors.orangeAccent : AppTheme.accent),
              ],
            ),
          ),
          if (needsRestock) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orangeAccent.withOpacity(0.15), Colors.orangeAccent.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'High risk of stock-out based on current velocity. Purchase immediately.',
                      style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(width: 1, height: 24, color: AppTheme.divider(context), margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _infoBlock(BuildContext context, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textBody(context), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color ?? AppTheme.textHeading(context))),
      ],
    );
  }
}


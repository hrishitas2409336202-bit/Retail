import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/promotion.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final aiSuggestions = state.generateAIPromotions();
    final activePromos = state.activePromotions;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('AI Promotion Genius', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header
            _buildAIHeader(context),
            const SizedBox(height: 32),

            // 1. AI Suggested Deals
            _sectionHeader('AI RECOMMENDED DEALS'),
            const SizedBox(height: 16),
            if (aiSuggestions.isEmpty)
              _emptyState(context, 'No urgent deals needed. Your inventory is healthy!')
            else
              ...aiSuggestions.map((promo) => _buildPromoCard(context, promo, state, isSuggestion: true)),

            const SizedBox(height: 32),

            // 2. Active Promotions
            _sectionHeader('ACTIVATED STORE OFFERS'),
            const SizedBox(height: 16),
            if (activePromos.where((p) => p.isActive).isEmpty)
              _emptyState(context, 'No active promotions. Activate a suggestion above.')
            else
              ...activePromos.where((p) => p.isActive).map((promo) => _buildPromoCard(context, promo, state, isSuggestion: false)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAIHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, color: Colors.white, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Boost Your Sales', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('AI has analyzed your sales velocity and expiry dates to suggest these profit-saving deals.', 
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, Promotion promo, AppState state, {bool isSuggestion = false}) {
    final isAlreadyActive = state.activePromotions.any((p) => p.id == promo.id && p.isActive);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isAlreadyActive ? AppTheme.primary.withOpacity(0.5) : AppTheme.divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Text(promo.icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promo.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading(context))),
                    Text(promo.type.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              if (promo.discountPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('-${promo.discountPercent.toInt()}%', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(promo.description, style: TextStyle(fontSize: 13, color: AppTheme.textBody(context))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => state.togglePromotion(promo),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: isAlreadyActive ? Colors.red.withOpacity(0.1) : AppTheme.primary,
              foregroundColor: isAlreadyActive ? Colors.red : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isAlreadyActive ? 'DEACTIVATE OFFER' : 'ACTIVATE ON BILLING', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5));
  }

  Widget _emptyState(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(msg, style: TextStyle(color: AppTheme.textBody(context).withOpacity(0.5), fontStyle: FontStyle.italic, fontSize: 13)),
      ),
    );
  }
}


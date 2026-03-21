import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final users = state.loyaltyUsers;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Customer Loyalty Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Card
            _buildLoyaltyOverview(context, users),
            const SizedBox(height: 32),

            // Top Customers
            _sectionHeader('TOP RATED CUSTOMERS'),
            const SizedBox(height: 16),
            ...users.map((u) => _buildUserTile(context, u, state)),

            const SizedBox(height: 32),
            _buildRewardProgramCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        icon: const Icon(LucideIcons.userPlus),
        label: const Text('Enroll Customer'),
      ),
    );
  }

  Widget _buildLoyaltyOverview(BuildContext context, List<Map<String, dynamic>> users) {
    int totalPoints = users.fold(0, (sum, u) => sum + (u['points'] as int));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.divider(context)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _overviewItem('Active Members', users.length.toString(), LucideIcons.users, Colors.blue),
              _overviewItem('Total Points', totalPoints.toString(), LucideIcons.award, Colors.orange),
            ],
          ),
          const Divider(height: 40),
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              const Text('12% growth in repeat visits this month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user, AppState state) {
    Color tierColor = user['tier'] == 'Platinum' ? Colors.purple : user['tier'] == 'Gold' ? Colors.orange : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tierColor.withOpacity(0.1), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(user['rank'], style: TextStyle(color: tierColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${user['points']} Points • ${user['tier']}', style: TextStyle(fontSize: 12, color: tierColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${state.currency}${user['spend']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('Total Spend', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardProgramCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.gift, color: Colors.white, size: 32),
          const SizedBox(width: 20),
          const Expanded(
            child: Text(
              '3 Coupons ready to be sent to high spending customers.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
            child: const Text('SEND', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5));
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class ShelfMapScreen extends StatefulWidget {
  const ShelfMapScreen({super.key});

  @override
  State<ShelfMapScreen> createState() => _ShelfMapScreenState();
}

class _ShelfMapScreenState extends State<ShelfMapScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<AppState>().inventory;
    
    final displayedInventory = inventory.where((p) {
      if (_selectedFilter == 'All') return true;
      String status = _getStatusString(p.stock, p.threshold);
      return status == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Store Map'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(context),
            const SizedBox(height: 24),
            Expanded(
              child: displayedInventory.isEmpty
                  ? Center(
                      child: Text(
                        'No products match the selected filter.',
                        style: TextStyle(color: AppTheme.textBody(context)),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: displayedInventory.length,
                      itemBuilder: (context, index) {
                        final p = displayedInventory[index];
                        final statusColor = _getStatusColor(p.stock, p.threshold);
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.emoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(height: 8),
                              Text(
                                p.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textHeading(context)),
                              ),
                              Text(
                                'Shelf ${p.shelf}',
                                style: TextStyle(fontSize: 10, color: AppTheme.textBody(context)),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Stock: ${p.stock}',
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterItem(context, 'All', AppTheme.primary),
          const SizedBox(width: 8),
          _filterItem(context, 'Critical', Colors.red),
          const SizedBox(width: 8),
          _filterItem(context, 'Low', Colors.orange),
          const SizedBox(width: 8),
          _filterItem(context, 'Sufficient', Colors.green),
        ],
      ),
    );
  }

  Widget _filterItem(BuildContext context, String label, Color color) {
    final isSelected = _selectedFilter == label;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.divider(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'All')
              CircleAvatar(backgroundColor: color, radius: 4),
            if (label != 'All')
              const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppTheme.textBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusString(int stock, int threshold) {
    if (stock == 0) return 'Critical';
    if (stock <= threshold) return 'Low';
    return 'Sufficient';
  }

  Color _getStatusColor(int stock, int threshold) {
    if (stock == 0) return Colors.red;
    if (stock <= threshold) return Colors.orange;
    return Colors.green;
  }
}

